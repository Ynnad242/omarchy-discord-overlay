# Changelog

Each release lists the Discord desktop version it was tested with. The overlay
reads Discord's accessibility tree, which can change with any Discord update,
so if something breaks, compare your version (Discord → User Settings, bottom
of the left column) with the one below.

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
