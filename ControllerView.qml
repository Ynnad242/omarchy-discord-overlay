import QtQuick

// Live drawing of a gamepad on a 340×268 canvas, scaled to fit. "kind" picks
// the drawing: "playstation" uses DualSense.qml, everything else XboxOne.qml
// ("nintendo" and "generic" with their own face letters and icon).
Item {
  id: pad

  property string kind: "xbox"
  property var buttons: ({})
  property var axes: ({})
  property bool connected: true

  readonly property bool ps: kind === "playstation"
  readonly property real s: width / 340

  implicitWidth: 340
  implicitHeight: 268
  height: width * 268 / 340

  // Face button labels/colors, clockwise from the top (north, east, south, west).
  readonly property var face: kind === "nintendo"
      ? [{ t: "X", c: "#b5bac1" }, { t: "A", c: "#b5bac1" }, { t: "B", c: "#b5bac1" }, { t: "Y", c: "#b5bac1" }]
      : [{ t: "Y", c: "#f2c230" }, { t: "B", c: "#e0463c" }, { t: "A", c: "#5fbf3f" }, { t: "X", c: "#3c8be0" }]

  DualSense {
    visible: pad.ps
    scale: pad.s
    transformOrigin: Item.TopLeft
    opacity: pad.connected ? 1 : 0.45
    buttons: pad.buttons
    axes: pad.axes
  }

  XboxOne {
    visible: !pad.ps
    scale: pad.s
    transformOrigin: Item.TopLeft
    opacity: pad.connected ? 1 : 0.45
    buttons: pad.buttons
    axes: pad.axes
    face: pad.face
    homeGlyph: pad.kind === "xbox" ? "\u{f05b9}" : "\u{f0297}" // nf-md-microsoft_xbox / nf-md-gamepad_variant
  }
}
