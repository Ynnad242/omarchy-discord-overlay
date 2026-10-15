# Discord Overlay for Omarchy

A Discord-style in-game overlay for the Omarchy shell, with three widgets that
float on top of every workspace:

- **Voice**: who's in your voice channel. People light up while talking, with
  mute and deafen icons.
- **Stream**: everyone else's Go Live streams, tiled to fit (auto grid, side by
  side, or stacked). When you leave the Discord workspace while watching a
  stream, the overlay presses Discord's own **Pop Out** button, hides the
  pop-out window on a special workspace, and crops each stream out of it. Go
  back to Discord and the stream drops back into the main window.
- **Controller**: a live drawing of your gamepad, PlayStation or Xbox style
  depending on what's plugged in.

The overlay is click-through and steps aside while the main Discord window is
on screen. Settings let you show it always or only while a game is running.

## Install

```bash
omarchy plugin add https://github.com/Ynnad242/omarchy-discord-overlay --enable
```

### Edit-mode keybinding

Add to `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + TAB", "Discord overlay", [[omarchy-shell shell summon ynnad.discord-stream '{"action":"edit"}']])
```

In edit mode you can drag widgets, resize the stream from its corner, remove
widgets with ×, and open settings with ⚙. Press Esc or Super+Tab when done.

### Optional bar toggle

[omarchy-discord-overlay-toggle](https://github.com/Ynnad242/omarchy-discord-overlay-toggle)
adds a bar icon that turns the overlay on and off.

## Requirements

- **Voice widget**: just a running Discord desktop client. The first time, Discord
  asks you to authorize the StreamKit overlay app; the token is saved to
  `~/.local/state/discord-overlay-token.json`.
- **Stream widget**: Discord has to expose its accessibility tree, so launch it
  with:

  ```bash
  env ACCESSIBILITY_ENABLED=1 discord --force-renderer-accessibility
  ```

  (Update your Discord keybinding and `.desktop` file to match.) Also needs
  `python-gobject` and `at-spi2-core`. Add this window rule to
  `~/.config/hypr/hyprland.lua` so the hidden pop-out keeps rendering:

  ```lua
  hl.window_rule({ name = "discord-popout-render", match = { class = "^discord$", initial_title = "^Discord Popout$" }, render_unfocused = true })
  ```

- **Controller widget**: read access to `/dev/input/event*`, which the
  logged-in user normally has. No extra Python packages.

Layout and settings are saved in `~/.local/state/discord-stream-overlay.json`.

This isn't affiliated with Discord. It uses Discord's local RPC and
accessibility interfaces, which could change with any Discord update.

## License

MIT, see [LICENSE](LICENSE).

Built with [Claude Code](https://claude.com/claude-code).
