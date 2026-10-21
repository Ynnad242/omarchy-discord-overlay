# Changelog

Each release lists the Discord desktop version it was tested with. The overlay
reads Discord's accessibility tree, which can change with any Discord update,
so if something breaks, compare your version (Discord → User Settings, bottom
of the left column) with the one below.

## 0.6.0 (2026-10-21)

Tested with **Discord 1.0.164** (Electron 42.11.15).

- Much lighter accessibility helper: it now asks Discord to find buttons and
  lists itself (AT-SPI Collection) instead of walking the whole window node by
  node three times. One check went from ~0.86 s to ~15 ms, and the helper's
  CPU use from ~19% to ~1.5%, while checking twice as often (every 0.5 s), so
  auto pop-out reacts faster.
- Avatars download in the background. A slow or failing download no longer
  freezes the voice list (who's talking) for up to 10 seconds, and failed
  downloads are retried at most once a minute instead of on every mute.
- "Only while gaming" also recognises native games and emulators (Skate 3,
  RPCS3, PCSX2, Dolphin, Ryujinx, RetroArch, Minecraft, ...).

## 0.5.3 (2026-10-19)

Tested with **Discord 1.0.162** (Electron 42.11.12).

- The LIVE tag now also shows for people who are muted or deafened. Discord's
  sidebar adds the status to their name ("alice, Muted"), which the overlay
  didn't match before.

## 0.5.2 (2026-10-19)

Tested with **Discord 1.0.162** (Electron 42.11.12).

- Pop-outs that Discord opens already titled with the channel name (e.g.
  "General") instead of "Discord Popout" are recognised again. Before, such a
  pop-out was ignored: it wasn't hidden and its stream never showed in the
  overlay. The overlay now also matches the window the accessibility helper
  sees as the pop-out.

## 0.5.1 (2026-10-16)

Tested with **Discord 1.0.162** (Electron 42.11.12).

- Switching the overlay off (or the plugin reloading) while you're on
  another workspace no longer loses the stream. Closing the pop-out while the
  main Discord window is hidden makes Discord drop back to a text channel, so
  the overlay now brings the pop-out to you instead, and leaves it alone
  during a reload.
- The overlay remembers which pop-out it opened across reloads.

## 0.5.0 (2026-10-16)

Tested with **Discord 1.0.162** (Electron 42.11.12).

- Auto pop-out works again. A pop-out opened straight onto the hidden
  workspace was never laid out by Discord (black window, 0-pixel stream
  tiles), so the overlay showed nothing. The overlay now resizes the hidden
  pop-out once, which makes Discord lay it out without it showing on screen.
- Discord relaunches itself after an auto-update without
  `--force-renderer-accessibility`. The overlay now notices the empty
  accessibility tree, warns in settings, and offers a
  **Restart Discord with accessibility** button.

## 0.4.0 (2026-10-15)

Tested with **Discord 1.0.161**.

- LIVE tag next to people who are streaming.
- Stream panel hides when the pop-out has no streams.
- The bar icon is now part of this plugin.
- Initial release.
