#!/usr/bin/env python3
"""Watch Discord through the accessibility bus (AT-SPI), the interface screen
readers use. Needs Discord started with ACCESSIBILITY_ENABLED=1 and
--force-renderer-accessibility.

Twice a second it checks, and prints one JSON line whenever something changed:

  {"discord": true,              # Discord is exposing its accessibility tree
                                 # (false too when it runs without the flag)
   "canPopout": true,            # main window has a stream with a Pop Out button
   "popout": {"title": "General", "width": 960, "height": 540,          # pop-out window size
              "focused": false,  # one stream blown up instead of the grid
              "collapsed": false,  # has streams, but Discord never laid them out
              "tiles": [{"name": "alice", "x": 21, "y": 24,
                         "width": 918, "height": 516}, ...]},
   "live": ["alice"]}            # people streaming in your voice channel

"tiles" are where each stream's video sits inside the pop-out window, so the
overlay can crop away the call header and window buttons, and show every
stream separately (leaving out your own).

Reads commands from stdin, one per line:
  popout   press Discord's own "Pop Out" button in the main window
  grid     in the pop-out, press the focused stream so Discord goes back to
           the grid of all streams
"""

import json
import select
import sys
import time

import gi

gi.require_version("Atspi", "2.0")
from gi.repository import Atspi  # noqa: E402

WINDOW = Atspi.CoordType.WINDOW
POLL = 0.5  # seconds between checks; one check costs ~15 ms


def log(msg):
    print(f"discord_a11y: {msg}", file=sys.stderr, flush=True)


def discord_app():
    desk = Atspi.get_desktop(0)
    for i in range(desk.get_child_count()):
        app = desk.get_child_at_index(i)
        if app is not None and app.get_name() == "Discord":
            return app
    return None


def walk(node, visit):
    """Depth-first walk; visit returns True to stop."""
    try:
        if visit(node):
            return True
        for i in range(node.get_child_count()):
            child = node.get_child_at_index(i)
            if child is not None and walk(child, visit):
                return True
    except Exception:
        pass
    return False


def frames(app):
    main, popouts = None, []
    for i in range(app.get_child_count()):
        frame = app.get_child_at_index(i)
        if frame is None:
            continue
        if (frame.get_name() or "").endswith(" - Discord"):
            main = frame
        else:
            popouts.append(frame)
    return main, popouts


def find_all(frame, role, role_name):
    """Every node with this role under frame.

    Asks Discord to do the search itself (AT-SPI Collection): one bus call
    instead of one per node, ~100x faster on a busy window. Falls back to
    walking the tree if Collection isn't available."""
    try:
        rule = Atspi.MatchRule.new(
            Atspi.StateSet.new([]), Atspi.CollectionMatchType.ALL,
            None, Atspi.CollectionMatchType.ALL,
            [role], Atspi.CollectionMatchType.ANY,
            [], Atspi.CollectionMatchType.ALL, False)
        found = frame.get_collection_iface().get_matches(
            rule, Atspi.CollectionSortOrder.CANONICAL, 0, True)
        return [n for n in found if n is not None]
    except Exception:
        found = []
        walk(frame, lambda n: n.get_role_name() == role_name and found.append(n) and False)
        return found


def buttons(frame):
    return find_all(frame, Atspi.Role.PUSH_BUTTON, "button")


def find_button(frame, name, all_buttons=None):
    for n in all_buttons if all_buttons is not None else buttons(frame):
        if n.get_name() == name:
            return n
    return None


def in_list(node, frame):
    """True if node sits inside a list (stops at frame)."""
    try:
        n = node.get_parent()
        while n is not None and n != frame:
            if n.get_role_name() == "list":
                return True
            n = n.get_parent()
    except Exception:
        pass
    return False


TILE_PREFIX = "Call tile, stream, "


def stream_tiles(frame, all_buttons=None):
    """Every 'Call tile, stream, <user>' button in the frame, in window coords.

    In Discord's grid view the tiles sit inside a list; a stream tile outside
    one is the focused (blown up) stream. A pop-out that opened straight onto a
    hidden workspace is never laid out, so its tiles are 0 pixels tall
    ("collapsed"). Returns (tiles, focused tile node, collapsed)."""
    tiles, focused = [], None
    collapsed = False
    try:
        for n in all_buttons if all_buttons is not None else buttons(frame):
            name = n.get_name() or ""
            if not name.startswith(TILE_PREFIX):
                continue
            e = n.get_extents(WINDOW)
            if e.width <= 0 or e.height <= 0:
                collapsed = True
                continue
            tiles.append({"name": name[len(TILE_PREFIX):], "x": e.x, "y": e.y,
                          "width": e.width, "height": e.height})
            if focused is None and not in_list(n, frame):
                focused = n
    except Exception:
        pass
    return tiles, focused, collapsed


def voice_users(main):
    """(name, live) for everyone under a voice channel in the channel sidebar.

    Each user is a panel holding a button with their name; a streaming user's
    panel also has Discord's "LIVE" pill (text "Live")."""
    users = []

    def visit_channel(item):
        for i in range(item.get_child_count()):
            group = item.get_child_at_index(i)
            if group is None or group.get_role_name() != "panel":
                continue
            for j in range(group.get_child_count()):
                panel = group.get_child_at_index(j)
                if panel is None:
                    continue
                names, texts = [], []

                def collect(n):
                    role = n.get_role_name()
                    if role == "button":
                        names.append(n.get_name() or "")
                    elif role == "static":
                        texts.append(n.get_name() or "")
                    return False

                walk(panel, collect)
                if names and names[0]:
                    users.append((names[0], any(t.strip().lower() == "live" for t in texts)))

    for n in find_all(main, Atspi.Role.LIST, "list"):
        if n.get_name() != "Channels":
            continue
        for i in range(n.get_child_count()):
            item = n.get_child_at_index(i)
            if item is not None and walk(item, lambda x: x.get_role_name() == "link"
                                         and "(voice channel)" in (x.get_name() or "")):
                visit_channel(item)
        break
    return users


def has_content(frame, enough=20):
    """Discord relaunched without --force-renderer-accessibility (it does that
    after an auto-update) still shows up on the bus, but with an empty window."""
    count = 0

    def visit(n):
        nonlocal count
        count += 1
        return count >= enough

    walk(frame, visit)
    return count >= enough


def snapshot():
    """Returns (state, {"popout": Pop Out button, "focused": focused tile})."""
    app = discord_app()
    if app is None:
        return {"discord": False, "canPopout": False, "popout": None, "live": []}, {}
    main, popouts = frames(app)
    if main is None or not has_content(main):
        return {"discord": False, "canPopout": False, "popout": None, "live": []}, {}
    live = set()
    main_buttons = buttons(main)
    pop_button = find_button(main, "Pop Out", main_buttons)
    popout, focused = None, None
    for frame in popouts:
        e = frame.get_extents(WINDOW)
        tiles, focus, collapsed = stream_tiles(frame)
        live.update(t["name"] for t in tiles)
        if tiles or popout is None:
            popout = {"title": frame.get_name() or "", "width": e.width, "height": e.height,
                      "focused": focus is not None,
                      "collapsed": collapsed and not tiles, "tiles": tiles}
            focused = focus
    live.update(t["name"] for t in stream_tiles(main, main_buttons)[0])
    live.update(name for name, is_live in voice_users(main) if is_live)
    state = {"discord": True, "canPopout": pop_button is not None and not popouts, "popout": popout,
             "live": sorted(live)}
    return state, {"popout": pop_button, "focused": focused}


def press(node, what):
    if node is None:
        return
    try:
        node.do_action(0)  # "press"
    except Exception as e:
        log(f"{what} failed: {e}")


def main():
    last = None
    while True:
        try:
            state, nodes = snapshot()
        except Exception as e:  # Discord restarting, bus hiccups, ...
            log(f"snapshot failed: {e}")
            state, nodes = {"discord": False, "canPopout": False, "popout": None, "live": []}, {}

        line = json.dumps(state)
        if line != last:
            print(line, flush=True)
            last = line

        ready, _, _ = select.select([sys.stdin], [], [], POLL)
        if ready:
            cmd = sys.stdin.readline()
            if not cmd:
                return  # overlay went away
            cmd = cmd.strip()
            if cmd == "popout" and state["canPopout"]:
                press(nodes.get("popout"), "pop out")
            elif cmd == "grid":
                press(nodes.get("focused"), "back to grid")
            time.sleep(0.3)


if __name__ == "__main__":
    main()
