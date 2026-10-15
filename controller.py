#!/usr/bin/env python3
"""Watch the first connected gamepad and print its state as JSON lines.

Reads /dev/input/event* directly (no python-evdev needed). A gamepad is any
device with a south face button (BTN_SOUTH) and a left stick (ABS_X). While
nothing is plugged in it rescans every 2 seconds.

  {"connected": true, "name": "DualSense Wireless Controller",
   "kind": "playstation" | "xbox" | "nintendo" | "generic",
   "buttons": {"south": false, "east": false, "north": false, "west": false,
               "l1": false, "r1": false, "l2": false, "r2": false,
               "select": false, "start": false, "home": false,
               "l3": false, "r3": false,
               "up": false, "down": false, "left": false, "right": false},
   "axes": {"lx": 0.0, "ly": 0.0, "rx": 0.0, "ry": 0.0,   # -1 .. 1
            "lt": 0.0, "rt": 0.0}}                         #  0 .. 1

  {"connected": false}
"""

import array
import fcntl
import glob
import json
import os
import select
import struct
import sys
import time

EV_SYN, EV_KEY, EV_ABS = 0x00, 0x01, 0x03
SYN_REPORT = 0
EVENT = struct.Struct("llHHi")
ABSINFO = struct.Struct("iiiiii")  # value, min, max, fuzz, flat, resolution

BUTTONS = {
    0x130: "south", 0x131: "east", 0x133: "north", 0x134: "west",
    0x136: "l1", 0x137: "r1", 0x138: "l2", 0x139: "r2",
    0x13a: "select", 0x13b: "start", 0x13c: "home", 0x13d: "l3", 0x13e: "r3",
    0x220: "up", 0x221: "down", 0x222: "left", 0x223: "right",
}
STICKS = {0x00: "lx", 0x01: "ly", 0x03: "rx", 0x04: "ry"}
TRIGGERS = {0x02: "lt", 0x05: "rt"}
HAT_X, HAT_Y = 0x10, 0x11
BTN_SOUTH, ABS_X = 0x130, 0x00

MIN_INTERVAL = 1 / 30  # don't flood the overlay with stick noise


def ioc(direction, nr, size):
    return (direction << 30) | (size << 16) | (ord("E") << 8) | nr


def eviocgname():
    return ioc(2, 0x06, 256)


def eviocgbit(ev, size):
    return ioc(2, 0x20 + ev, size)


def eviocgabs(code):
    return ioc(2, 0x40 + code, ABSINFO.size)


def log(msg):
    print(f"controller: {msg}", file=sys.stderr, flush=True)


def emit(obj):
    print(json.dumps(obj), flush=True)


def has_bit(fd, ev, code, nbytes):
    buf = array.array("B", [0] * nbytes)
    fcntl.ioctl(fd, eviocgbit(ev, nbytes), buf, True)
    return bool(buf[code // 8] & (1 << (code % 8)))


def kind_of(name):
    n = name.lower()
    if any(k in n for k in ("sony", "dualsense", "dualshock", "playstation", "wireless controller")):
        return "playstation"
    if any(k in n for k in ("nintendo", "pro controller", "joy-con")):
        return "nintendo"
    if any(k in n for k in ("xbox", "x-box", "microsoft", "xinput")):
        return "xbox"
    return "generic"


def find_gamepad():
    for path in sorted(glob.glob("/dev/input/event*"), key=lambda p: int(p.rsplit("event", 1)[1])):
        try:
            fd = os.open(path, os.O_RDONLY | os.O_NONBLOCK)
        except OSError:
            continue
        try:
            if has_bit(fd, EV_KEY, BTN_SOUTH, 96) and has_bit(fd, EV_ABS, ABS_X, 8):
                buf = array.array("B", [0] * 256)
                fcntl.ioctl(fd, eviocgname(), buf, True)
                name = buf.tobytes().split(b"\0", 1)[0].decode(errors="replace")
                return fd, name
        except OSError:
            pass
        os.close(fd)
    return None, None


class Pad:
    def __init__(self, fd, name):
        self.fd, self.name = fd, name
        self.ranges = {}
        for code in list(STICKS) + list(TRIGGERS):
            try:
                buf = bytearray(ABSINFO.size)
                fcntl.ioctl(fd, eviocgabs(code), buf, True)
                value, lo, hi, _fuzz, flat, _res = ABSINFO.unpack(buf)
                if hi > lo:
                    self.ranges[code] = (lo, hi, flat)
            except OSError:
                pass
        self.buttons = {b: False for b in BUTTONS.values()}
        self.axes = {"lx": 0.0, "ly": 0.0, "rx": 0.0, "ry": 0.0, "lt": 0.0, "rt": 0.0}

    def norm(self, code, value):
        lo, hi, flat = self.ranges.get(code, (-32768, 32767, 0))
        if code in TRIGGERS:
            return round(max(0.0, min(1.0, (value - lo) / (hi - lo))), 3)
        mid = (lo + hi) / 2
        if abs(value - mid) <= flat:
            return 0.0
        return round(max(-1.0, min(1.0, (value - mid) / ((hi - lo) / 2))), 3)

    def apply(self, etype, code, value):
        if etype == EV_KEY and code in BUTTONS:
            self.buttons[BUTTONS[code]] = value != 0
        elif etype == EV_ABS:
            if code in STICKS:
                self.axes[STICKS[code]] = self.norm(code, value)
            elif code in TRIGGERS:
                self.axes[TRIGGERS[code]] = self.norm(code, value)
            elif code == HAT_X:
                self.buttons["left"], self.buttons["right"] = value < 0, value > 0
            elif code == HAT_Y:
                self.buttons["up"], self.buttons["down"] = value < 0, value > 0

    def state(self):
        return {"connected": True, "name": self.name, "kind": kind_of(self.name),
                "buttons": self.buttons, "axes": self.axes}


def run(fd, name):
    pad = Pad(fd, name)
    log(f"using {name}")
    emit(pad.state())
    last_line, last_emit, dirty = None, 0.0, False
    while True:
        timeout = max(0.0, MIN_INTERVAL - (time.monotonic() - last_emit)) if dirty else None
        ready, _, _ = select.select([fd], [], [], timeout)
        if ready:
            try:
                data = os.read(fd, EVENT.size * 64)
            except BlockingIOError:
                continue
            if not data:
                raise OSError("device went away")
            for off in range(0, len(data) - EVENT.size + 1, EVENT.size):
                _s, _us, etype, code, value = EVENT.unpack_from(data, off)
                if etype == EV_SYN and code == SYN_REPORT:
                    dirty = True
                else:
                    pad.apply(etype, code, value)
        if dirty and time.monotonic() - last_emit >= MIN_INTERVAL:
            line = json.dumps(pad.state())
            if line != last_line:
                print(line, flush=True)
                last_line = line
            last_emit, dirty = time.monotonic(), False


def main():
    connected = None
    while True:
        fd, name = find_gamepad()
        if fd is None:
            if connected is not False:
                emit({"connected": False})
                connected = False
            time.sleep(2)
            continue
        connected = True
        try:
            run(fd, name)
        except OSError as e:
            log(f"{name}: {e}")
        finally:
            os.close(fd)
        emit({"connected": False})
        connected = False
        time.sleep(1)


if __name__ == "__main__":
    main()
