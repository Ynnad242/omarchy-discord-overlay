#!/usr/bin/env python3
"""Watch Discord through the accessibility bus (AT-SPI), the interface screen
readers use. Needs Discord started with ACCESSIBILITY_ENABLED=1 and
--force-renderer-accessibility.

Every second it prints one JSON line:

  {"discord": true,              # Discord is exposing its accessibility tree
   "canPopout": true,            # main window has a stream with a Pop Out button
   "popout": {"width": 960, "height": 540,          # pop-out window size
              "focused": false,  # one stream blown up instead of the grid
              "tiles": [{"name": "alice", "x": 21, "y": 24,
                         "width": 918, "height": 516}, ...]}}

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


def find_button(frame, name):
    found = []
    walk(frame, lambda n: n.get_role_name() == "button" and n.get_name() == name
         and found.append(n) is None)
    return found[0] if found else None


TILE_PREFIX = "Call tile, stream, "


def stream_tiles(frame):
    """Every 'Call tile, stream, <user>' button in the frame, in window coords.

    In Discord's grid view the tiles sit inside a list; a stream tile outside
    one is the focused (blown up) stream. Returns (tiles, focused tile node)."""
    tiles, focused = [], None

    def visit(n, in_list):
        nonlocal focused
        role = n.get_role_name()
        name = n.get_name() or ""
        if role == "button" and name.startswith(TILE_PREFIX):
            e = n.get_extents(WINDOW)
            if e.width > 0 and e.height > 0:
                tiles.append({"name": name[len(TILE_PREFIX):], "x": e.x, "y": e.y,
                              "width": e.width, "height": e.height})
                if not in_list and focused is None:
                    focused = n
            return
        in_list = in_list or role == "list"
        for i in range(n.get_child_count()):
            child = n.get_child_at_index(i)
            if child is not None:
                visit(child, in_list)

    try:
        visit(frame, False)
    except Exception:
        pass
    return tiles, focused


def snapshot():
    """Returns (state, {"popout": Pop Out button, "focused": focused tile})."""
    app = discord_app()
    if app is None:
        return {"discord": False, "canPopout": False, "popout": None}, {}
    main, popouts = frames(app)
    pop_button = find_button(main, "Pop Out") if main is not None else None
    popout, focused = None, None
    for frame in popouts:
        e = frame.get_extents(WINDOW)
        tiles, focus = stream_tiles(frame)
        if tiles or popout is None:
            popout = {"width": e.width, "height": e.height, "focused": focus is not None, "tiles": tiles}
            focused = focus
    state = {"discord": True, "canPopout": pop_button is not None and not popouts, "popout": popout}
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
            state, nodes = {"discord": False, "canPopout": False, "popout": None}, {}

        line = json.dumps(state)
        if line != last:
            print(line, flush=True)
            last = line

        ready, _, _ = select.select([sys.stdin], [], [], 1.0)
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
