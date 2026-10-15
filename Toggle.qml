import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

// Discord icon in the bar: left-click turns the overlay on/off, right-click
// opens its edit mode (same as Super+Tab). The on/off state is read from the
// overlay's own settings file so the icon always matches.
BarWidget {
  id: root
  moduleName: "ynnad.discord-stream"

  property bool overlayOn: true

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function summon(action) {
    root.bar.run("omarchy-shell shell summon ynnad.discord-stream '{\"action\":\"" + action + "\"}'")
  }

  FileView {
    id: state
    path: Quickshell.env("HOME") + "/.local/state/discord-stream-overlay.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        const s = JSON.parse(text())
        root.overlayOn = s.enabled !== false
      } catch (e) {}
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰙯"
    active: root.overlayOn
    opacity: root.overlayOn ? 1 : 0.4
    tooltipText: root.overlayOn ? "Discord overlay on (click to turn off, right-click to edit)"
                                : "Discord overlay off (click to turn on)"
    onPressed: function(b) {
      if (b === Qt.RightButton) {
        root.summon("edit")
      } else {
        root.overlayOn = !root.overlayOn
        root.summon("toggle")
      }
    }
  }
}
