#!/usr/bin/env python3
"""Bridge Discord's local RPC voice events to JSON lines on stdout.

Talks to the running Discord client over its IPC socket, authorizes as the
Discord StreamKit overlay app (the same approach Discover uses), and prints the
current voice channel's members and who is speaking every time it changes:

  {"connected": true, "channel": "General", "self": ["username", ...],
   "members": [
     {"id": "...", "name": "...", "avatar": "file://...", "speaking": false,
      "muted": false, "deafened": false,           # either way, for the icon
      "serverMuted": false, "serverDeafened": false}, ...]}

"self" lists every name you might show up as (username, display name, server
nickname), so the overlay can leave your own stream out.
"""

import json
import os
import socket
import struct
import sys
import time
import urllib.request
import uuid

CLIENT_ID = "207646673902501888"  # Discord StreamKit
TOKEN_URL = "https://streamkit.discord.com/overlay/token"
STATE_DIR = os.path.expanduser("~/.local/state")
TOKEN_FILE = os.path.join(STATE_DIR, "discord-overlay-token.json")
AVATAR_DIR = os.path.expanduser("~/.cache/discord-overlay/avatars")
USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64)"

OP_HANDSHAKE, OP_FRAME, OP_CLOSE = 0, 1, 2
VOICE_EVENTS = ("VOICE_STATE_CREATE", "VOICE_STATE_UPDATE", "VOICE_STATE_DELETE",
                "SPEAKING_START", "SPEAKING_STOP")


def emit(obj):
    print(json.dumps(obj), flush=True)


def log(msg):
    print(f"discord_voice: {msg}", file=sys.stderr, flush=True)


class Ipc:
    def __init__(self):
        self.sock = None
        base = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"
        for i in range(10):
            path = os.path.join(base, f"discord-ipc-{i}")
            if not os.path.exists(path):
                continue
            try:
                s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                s.connect(path)
                self.sock = s
                return
            except OSError:
                continue
        raise ConnectionError("Discord is not running")

    def send(self, op, payload):
        data = json.dumps(payload).encode()
        self.sock.sendall(struct.pack("<II", op, len(data)) + data)

    def _read(self, n):
        buf = b""
        while len(buf) < n:
            chunk = self.sock.recv(n - len(buf))
            if not chunk:
                raise ConnectionError("Discord closed the connection")
            buf += chunk
        return buf

    def recv(self):
        op, length = struct.unpack("<II", self._read(8))
        payload = json.loads(self._read(length))
        if op == OP_CLOSE:
            raise ConnectionError(payload.get("message", "closed"))
        return payload

    def command(self, cmd, args=None, evt=None):
        msg = {"cmd": cmd, "args": args or {}, "nonce": str(uuid.uuid4())}
        if evt:
            msg["evt"] = evt
        self.send(OP_FRAME, msg)
        return msg["nonce"]

    def wait_for(self, nonce, on_event):
        while True:
            msg = self.recv()
            if msg.get("nonce") == nonce:
                return msg
            on_event(msg)


def load_token():
    try:
        with open(TOKEN_FILE) as f:
            return json.load(f).get("access_token")
    except (OSError, ValueError):
        return None


def save_token(token):
    os.makedirs(STATE_DIR, exist_ok=True)
    fd = os.open(TOKEN_FILE, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        json.dump({"access_token": token}, f)


def exchange_code(code):
    req = urllib.request.Request(
        TOKEN_URL, data=json.dumps({"code": code}).encode(),
        headers={"Content-Type": "application/json", "User-Agent": USER_AGENT},
        method="POST")
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.load(resp)["access_token"]


def avatar_url(user):
    if user.get("avatar"):
        return f"https://cdn.discordapp.com/avatars/{user['id']}/{user['avatar']}.png?size=64"
    return f"https://cdn.discordapp.com/embed/avatars/{(int(user['id']) >> 22) % 6}.png"


def avatar_file(user):
    """Download the avatar once into a local cache and return a file:// URL.

    The overlay only loads local files: having Qt fetch HTTPS images inside the
    shell crashed it once (in OpenSSL while loading CA certificates)."""
    name = f"{user['id']}-{user.get('avatar') or 'default'}.png"
    path = os.path.join(AVATAR_DIR, name)
    if not os.path.exists(path):
        try:
            os.makedirs(AVATAR_DIR, exist_ok=True)
            req = urllib.request.Request(avatar_url(user), headers={"User-Agent": USER_AGENT})
            with urllib.request.urlopen(req, timeout=10) as resp:
                data = resp.read()
            tmp = path + ".tmp"
            with open(tmp, "wb") as f:
                f.write(data)
            os.replace(tmp, path)
        except OSError as e:
            log(f"avatar download failed for {user['id']}: {e}")
            return ""
    return "file://" + path


class Voice:
    def __init__(self, ipc, me):
        self.ipc = ipc
        self.me = me or {}
        self.channel_id = None
        self.channel_name = ""
        self.members = {}
        self.speaking = set()

    def publish(self):
        members = sorted(self.members.values(), key=lambda m: m["name"].lower())
        for m in members:
            m["speaking"] = m["id"] in self.speaking
        names = {self.me.get("username"), self.me.get("global_name")}
        if self.me.get("id") in self.members:
            names.add(self.members[self.me["id"]]["name"])
        emit({"connected": True, "channel": self.channel_name if self.channel_id else "",
              "self": sorted(n for n in names if n), "members": members})

    def set_member(self, state):
        user = state["user"]
        vs = state.get("voice_state", {})
        self.members[user["id"]] = {
            "id": user["id"],
            "name": state.get("nick") or user.get("global_name") or user["username"],
            "avatar": avatar_file(user),
            "speaking": False,
            # state["mute"] is you muting them locally.
            "muted": bool(vs.get("mute") or vs.get("self_mute") or state.get("mute")),
            "deafened": bool(vs.get("deaf") or vs.get("self_deaf")),
            "serverMuted": bool(vs.get("mute")),
            "serverDeafened": bool(vs.get("deaf")),
        }

    def switch_channel(self, channel_id):
        if self.channel_id:
            for evt in VOICE_EVENTS:
                self.ipc.command("UNSUBSCRIBE", {"channel_id": self.channel_id}, evt)
        self.channel_id, self.channel_name = None, ""
        self.members, self.speaking = {}, set()
        if channel_id:
            nonce = self.ipc.command("GET_CHANNEL", {"channel_id": channel_id})
            reply = self.ipc.wait_for(nonce, self.handle)
            data = reply.get("data") or {}
            self.load_channel(data)
        self.publish()

    def load_channel(self, data):
        if not data or not data.get("id"):
            return
        self.channel_id = data["id"]
        self.channel_name = data.get("name", "")
        for state in data.get("voice_states", []):
            self.set_member(state)
        for evt in VOICE_EVENTS:
            self.ipc.command("SUBSCRIBE", {"channel_id": self.channel_id}, evt)

    def handle(self, msg):
        evt, data = msg.get("evt"), msg.get("data") or {}
        if msg.get("cmd") != "DISPATCH" or not evt:
            return
        if evt == "VOICE_CHANNEL_SELECT":
            self.switch_channel(data.get("channel_id"))
            return
        if evt in ("VOICE_STATE_CREATE", "VOICE_STATE_UPDATE"):
            self.set_member(data)
        elif evt == "VOICE_STATE_DELETE":
            uid = data["user"]["id"]
            self.members.pop(uid, None)
            self.speaking.discard(uid)
        elif evt == "SPEAKING_START":
            self.speaking.add(data["user_id"])
        elif evt == "SPEAKING_STOP":
            self.speaking.discard(data["user_id"])
        else:
            return
        self.publish()


def authenticate(ipc):
    token = load_token()
    if token:
        nonce = ipc.command("AUTHENTICATE", {"access_token": token})
        reply = ipc.wait_for(nonce, lambda m: None)
        if reply.get("evt") != "ERROR":
            return (reply.get("data") or {}).get("user")
        log("saved token rejected, re-authorizing")

    # Shows an "Authorize" prompt inside Discord the first time.
    nonce = ipc.command("AUTHORIZE", {"client_id": CLIENT_ID, "scopes": ["rpc"], "prompt": "none"})
    reply = ipc.wait_for(nonce, lambda m: None)
    if reply.get("evt") == "ERROR":
        raise PermissionError(reply["data"].get("message", "authorization denied"))
    token = exchange_code(reply["data"]["code"])
    save_token(token)

    nonce = ipc.command("AUTHENTICATE", {"access_token": token})
    reply = ipc.wait_for(nonce, lambda m: None)
    if reply.get("evt") == "ERROR":
        raise PermissionError(reply["data"].get("message", "authentication failed"))
    return (reply.get("data") or {}).get("user")


def run():
    ipc = Ipc()
    ipc.send(OP_HANDSHAKE, {"v": 1, "client_id": CLIENT_ID})
    ready = ipc.recv()
    if ready.get("evt") != "READY":
        raise ConnectionError(f"unexpected handshake reply: {ready}")

    voice = Voice(ipc, authenticate(ipc))
    ipc.command("SUBSCRIBE", {}, "VOICE_CHANNEL_SELECT")

    nonce = ipc.command("GET_SELECTED_VOICE_CHANNEL")
    reply = ipc.wait_for(nonce, voice.handle)
    voice.load_channel(reply.get("data"))
    voice.publish()

    while True:
        voice.handle(ipc.recv())


def main():
    while True:
        try:
            run()
        except PermissionError as e:
            log(f"not authorized: {e}")
            emit({"connected": False, "error": "authorize"})
            time.sleep(30)
        except (ConnectionError, OSError, ValueError) as e:
            emit({"connected": False})
            log(str(e))
            time.sleep(5)


if __name__ == "__main__":
    main()
