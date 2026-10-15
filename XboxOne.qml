import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

// Xbox Wireless Controller (Carbon Black) on a 340×268 canvas, the same as
// the DualSense. The shell outline and every button position were traced from
// a front render of the real controller. LT/RT stand up behind the bumpers
// and press down and fill as they're pulled. Nintendo and generic pads reuse it with their own
// face labels and guide icon.
Item {
  id: xb

  property var buttons: ({})
  property var axes: ({})
  // Face labels/colors clockwise from the top: north, east, south, west.
  property var face: [{ t: "Y", c: "#f2c230" }, { t: "B", c: "#e0463c" }, { t: "A", c: "#5fbf3f" }, { t: "X", c: "#3c8be0" }]
  property string homeGlyph: "\u{f05b9}" // nf-md-microsoft_xbox

  width: 340
  height: 268

  function b(name) { return !!(xb.buttons && xb.buttons[name]) }
  function a(name) { return (xb.axes && xb.axes[name]) || 0 }
  // Trigger pull 0..1 in whole percents; the digital button only counts for
  // pads without analog triggers.
  function pull(axis, btn) {
    const v = xb.a(axis)
    return v > 0 ? Math.round(v * 100) / 100 : xb.b(btn) ? 1 : 0
  }

  // Rim light so the black pad stays visible over dark scenes.
  readonly property color edge: "#62666f"
  readonly property color glow: "#3fbf4f" // Xbox green, for anything held down
  readonly property color symbol: "#e6e8ec"
  readonly property real detail: 3

  // Traced paths (left side for the mirrored parts).
  readonly property string bodyPath: "M 168.0 28.6 C 166.3 28.6 164.5 28.6 162.7 28.6 C 160.9 28.6 159.1 28.6 157.3 28.6 C 155.6 28.6 153.8 28.6 152.0 28.6 C 150.2 28.6 148.4 28.6 146.6 28.6 C 144.9 28.6 143.1 28.6 141.3 28.6 C 139.5 28.6 137.7 28.6 135.9 28.6 C 134.2 28.6 132.4 28.6 130.6 28.6 C 128.8 28.6 127.0 28.6 125.2 28.6 C 123.5 28.6 121.7 28.6 119.9 28.6 C 118.1 28.6 116.3 28.6 114.5 28.6 C 112.8 28.6 111.0 28.6 109.2 28.6 C 107.4 28.6 105.6 28.6 103.8 28.6 C 102.1 28.6 100.3 28.6 98.5 28.6 C 96.7 28.6 94.9 28.6 93.2 28.6 C 91.4 28.6 89.6 28.6 87.8 28.6 C 86.0 28.6 84.2 28.6 82.5 28.6 C 80.7 28.6 78.9 28.6 77.1 28.6 C 75.3 28.6 73.5 28.4 71.8 28.7 C 70.1 29.0 68.4 29.6 66.9 30.4 C 65.3 31.2 63.9 32.5 62.5 33.7 C 61.1 34.9 59.7 36.3 58.5 37.7 C 57.3 39.1 56.4 40.6 55.5 42.1 C 54.5 43.5 53.9 45.1 53.0 46.5 C 52.1 48.0 51.0 49.4 50.1 50.8 C 49.2 52.3 48.3 53.6 47.4 55.1 C 46.6 56.6 45.8 58.2 45.1 59.8 C 44.3 61.5 43.6 63.1 42.9 64.7 C 42.2 66.4 41.7 68.0 41.1 69.7 C 40.5 71.3 39.9 73.0 39.3 74.6 C 38.7 76.1 37.9 77.6 37.2 79.2 C 36.6 80.7 36.0 82.4 35.4 84.0 C 34.8 85.6 34.2 87.3 33.6 88.9 C 33.0 90.5 32.5 92.2 31.8 93.8 C 31.2 95.4 30.4 97.1 29.7 98.7 C 29.1 100.3 28.5 102.0 28.0 103.6 C 27.4 105.3 27.0 106.9 26.5 108.5 C 26.0 110.2 25.4 111.8 24.9 113.4 C 24.4 115.1 23.8 116.7 23.3 118.3 C 22.7 120.0 22.1 121.6 21.5 123.2 C 20.9 124.9 20.3 126.5 19.7 128.1 C 19.1 129.8 18.4 131.4 17.9 133.0 C 17.4 134.7 16.9 136.3 16.4 138.0 C 16.0 139.7 15.5 141.5 15.1 143.2 C 14.7 145.0 14.2 146.8 13.8 148.5 C 13.3 150.1 12.7 151.7 12.2 153.4 C 11.7 155.1 11.1 156.8 10.8 158.6 C 10.4 160.3 10.4 162.1 10.0 163.9 C 9.6 165.6 8.9 167.2 8.5 168.9 C 8.2 170.7 8.0 172.5 7.7 174.3 C 7.3 176.0 6.8 177.6 6.5 179.3 C 6.2 181.1 6.1 182.8 5.8 184.6 C 5.6 186.4 5.2 188.2 5.0 190.0 C 4.8 191.7 4.7 193.5 4.5 195.3 C 4.4 197.1 4.3 198.9 4.2 200.7 C 4.2 202.4 4.2 204.2 4.2 206.0 C 4.3 207.8 4.4 209.6 4.7 211.4 C 4.9 213.1 5.2 214.8 5.6 216.5 C 5.9 218.2 6.2 220.0 6.6 221.7 C 7.0 223.4 7.4 225.0 8.1 226.6 C 8.7 228.1 9.7 229.6 10.6 231.1 C 11.4 232.5 12.0 234.1 13.0 235.5 C 14.0 236.9 15.1 238.4 16.3 239.6 C 17.5 240.9 18.9 242.1 20.3 243.2 C 21.7 244.3 23.3 245.3 24.8 246.2 C 26.3 247.1 27.7 248.0 29.2 248.7 C 30.8 249.3 32.2 250.0 34.0 250.2 C 35.8 250.4 38.0 250.5 39.7 250.0 C 41.5 249.5 42.7 248.3 44.2 247.3 C 45.7 246.3 47.2 245.1 48.6 244.0 C 50.1 242.8 51.4 241.6 52.7 240.4 C 54.1 239.2 55.4 238.0 56.7 236.7 C 58.0 235.4 59.3 233.9 60.5 232.5 C 61.7 231.1 62.9 229.7 64.1 228.3 C 65.3 227.0 66.5 225.7 67.6 224.3 C 68.7 222.9 69.7 221.3 70.7 220.0 C 71.8 218.6 72.8 217.3 73.9 215.9 C 74.9 214.6 76.1 213.1 77.3 211.6 C 78.4 210.2 79.7 208.6 80.8 207.2 C 81.9 205.7 82.9 204.2 84.1 202.8 C 85.2 201.5 86.4 200.1 87.6 198.8 C 88.9 197.6 90.1 196.3 91.5 195.2 C 92.9 194.0 94.4 193.0 95.9 192.0 C 97.4 191.1 98.8 190.2 100.4 189.5 C 101.9 188.7 103.4 188.1 105.1 187.7 C 106.7 187.3 108.5 187.2 110.3 187.0 C 112.0 186.7 113.8 186.4 115.6 186.3 C 117.4 186.1 119.2 186.2 121.0 186.2 C 122.7 186.2 124.5 186.2 126.3 186.2 C 128.1 186.2 129.9 186.2 131.7 186.2 C 133.4 186.2 135.2 186.2 137.0 186.2 C 138.8 186.2 140.6 186.2 142.4 186.2 C 144.1 186.2 145.9 186.2 147.7 186.2 C 149.5 186.2 151.3 186.2 153.1 186.2 C 154.8 186.2 156.6 186.2 158.4 186.2 C 160.2 186.2 162.0 186.2 163.8 186.2 C 165.5 186.2 167.2 186.2 169.1 186.2 C 171.0 186.2 173.3 186.2 175.2 186.2 C 177.1 186.2 178.7 186.2 180.5 186.2 C 182.3 186.2 184.1 186.2 185.9 186.2 C 187.7 186.2 189.4 186.2 191.2 186.2 C 193.0 186.2 194.8 186.2 196.6 186.2 C 198.4 186.2 200.1 186.2 201.9 186.2 C 203.7 186.2 205.5 186.2 207.3 186.2 C 209.0 186.2 210.8 186.2 212.6 186.2 C 214.4 186.2 216.2 186.2 218.0 186.2 C 219.7 186.2 221.5 186.1 223.3 186.2 C 225.1 186.3 226.9 186.6 228.7 186.8 C 230.4 187.0 232.3 187.1 233.9 187.5 C 235.6 187.8 237.2 188.4 238.7 189.0 C 240.3 189.7 241.7 190.6 243.2 191.5 C 244.7 192.4 246.2 193.4 247.6 194.5 C 249.0 195.6 250.4 196.8 251.6 198.1 C 252.9 199.3 254.1 200.7 255.2 202.0 C 256.4 203.4 257.4 204.8 258.6 206.3 C 259.7 207.7 260.8 209.3 262.0 210.7 C 263.2 212.2 264.4 213.7 265.5 215.1 C 266.6 216.5 267.6 217.8 268.6 219.2 C 269.7 220.5 270.7 222.0 271.8 223.4 C 272.9 224.8 274.0 226.2 275.2 227.5 C 276.4 228.9 277.6 230.2 278.8 231.6 C 280.0 233.0 281.2 234.6 282.5 235.9 C 283.7 237.3 285.1 238.5 286.5 239.7 C 287.8 240.9 289.1 242.1 290.5 243.3 C 291.9 244.4 293.4 245.7 294.9 246.7 C 296.4 247.7 297.7 248.8 299.4 249.4 C 301.0 250.0 303.3 250.5 305.0 250.4 C 306.8 250.3 308.3 249.7 309.9 249.1 C 311.4 248.5 312.8 247.6 314.3 246.8 C 315.8 245.9 317.4 244.9 318.8 243.9 C 320.2 242.8 321.6 241.6 322.9 240.4 C 324.2 239.2 325.4 237.8 326.4 236.4 C 327.4 235.0 328.2 233.4 329.0 232.0 C 329.8 230.5 330.8 229.0 331.5 227.5 C 332.1 226.0 332.7 224.4 333.2 222.7 C 333.6 221.0 333.8 219.2 334.2 217.5 C 334.5 215.8 335.0 214.2 335.2 212.4 C 335.5 210.7 335.6 208.9 335.7 207.1 C 335.8 205.3 335.8 203.5 335.8 201.7 C 335.8 199.9 335.6 198.2 335.5 196.4 C 335.4 194.6 335.4 192.8 335.2 191.0 C 335.0 189.2 334.6 187.5 334.3 185.7 C 334.1 183.9 334.0 182.1 333.7 180.4 C 333.4 178.6 332.9 177.0 332.5 175.3 C 332.2 173.6 332.0 171.7 331.6 170.0 C 331.3 168.2 330.7 166.6 330.3 164.9 C 329.9 163.1 329.8 161.4 329.4 159.6 C 329.0 157.9 328.6 156.1 328.1 154.4 C 327.6 152.7 327.0 151.1 326.5 149.4 C 326.0 147.8 325.6 146.1 325.2 144.3 C 324.7 142.6 324.3 140.7 323.8 139.0 C 323.4 137.3 323.0 135.7 322.4 134.0 C 321.9 132.4 321.3 130.7 320.7 129.1 C 320.1 127.5 319.5 125.8 318.9 124.2 C 318.3 122.6 317.7 120.9 317.1 119.3 C 316.5 117.7 315.9 116.0 315.4 114.4 C 314.8 112.8 314.4 111.1 313.9 109.5 C 313.4 107.9 312.9 106.2 312.3 104.6 C 311.8 103.0 311.3 101.3 310.7 99.7 C 310.0 98.1 309.2 96.4 308.6 94.8 C 307.9 93.2 307.4 91.5 306.8 89.9 C 306.2 88.3 305.6 86.6 305.0 85.0 C 304.4 83.4 303.8 81.7 303.2 80.1 C 302.5 78.5 301.7 77.1 301.1 75.5 C 300.4 73.9 299.9 72.3 299.3 70.6 C 298.7 69.0 298.1 67.4 297.5 65.7 C 296.8 64.1 296.1 62.4 295.4 60.8 C 294.7 59.2 293.9 57.5 293.1 56.0 C 292.3 54.5 291.4 53.1 290.4 51.6 C 289.5 50.2 288.4 48.9 287.5 47.4 C 286.6 46.0 285.9 44.4 285.0 43.0 C 284.1 41.5 283.3 40.0 282.2 38.6 C 281.1 37.2 279.6 35.8 278.3 34.5 C 276.9 33.3 275.5 31.9 274.0 31.0 C 272.5 30.0 270.9 29.3 269.2 28.9 C 267.6 28.5 265.7 28.6 264.0 28.6 C 262.2 28.6 260.4 28.6 258.6 28.6 C 256.8 28.6 255.1 28.6 253.3 28.6 C 251.5 28.6 249.7 28.6 247.9 28.6 C 246.1 28.6 244.4 28.6 242.6 28.6 C 240.8 28.6 239.0 28.6 237.2 28.6 C 235.4 28.6 233.7 28.6 231.9 28.6 C 230.1 28.6 228.3 28.6 226.5 28.6 C 224.7 28.6 223.0 28.6 221.2 28.6 C 219.4 28.6 217.6 28.6 215.8 28.6 C 214.0 28.6 212.3 28.6 210.5 28.6 C 208.7 28.6 206.9 28.6 205.1 28.6 C 203.3 28.6 201.6 28.6 199.8 28.6 C 198.0 28.6 196.2 28.6 194.4 28.6 C 192.6 28.6 190.9 28.6 189.1 28.6 C 187.3 28.6 185.5 28.6 183.7 28.6 C 181.9 28.6 180.2 28.6 178.4 28.6 C 176.6 28.6 174.8 28.6 173.0 28.6 C 171.3 28.6 169.8 28.6 168.0 28.6 Z"
  readonly property string triggerPath: "M 62 25 C 63 10 76 -4 98 -7.5 C 112 -9 121 -2 124 6 C 125 9 125.5 12 125.5 15 "
    + "C 114 13 102 12.5 90 14 C 78 15.5 68 19 62 25 Z" // bottom follows the bumper, 4px above it
  readonly property string triggerShinePath: "M 67 13 C 73 3 84 -4 98 -5.5 C 108 -6.5 116 -2 120 6"
  // Thick across the top, tapering to a point where it wraps the corner.
  readonly property string bumperPath: "M 51 49 C 55 34 70 21 90 18 C 102 16.5 114 17 121 19.5 "
    + "C 125.5 21 126.5 25 124.5 29 C 113 28 100 28.5 88 31 C 74 34 63 41 56.5 51 C 55 53.5 50.5 52.5 51 49 Z"
  readonly property string bumperShinePath: "M 55 41 C 62 29 74 21.5 90 19.5 C 102 18 112 18.5 119 21"
  readonly property string bumperSeamPath: "M 57 52.5 C 63 43 74 35.5 88 32.5 C 100 30 113 29.5 124 30.5"

  component Mirrored: Shape {
    id: m
    property bool mirrored
    width: 340; height: 256
    preferredRendererType: Shape.CurveRenderer
    transform: Scale { xScale: m.mirrored ? -1 : 1; origin.x: 170 }
  }

  Item { // the drawing, 12px down so the triggers have room above it
    y: 12
    width: 340; height: 256

    // ── Triggers: press down and fill as they're pulled ────────────────────
    Repeater {
      model: [{ mirrored: false, axis: "lt", btn: "l2" }, { mirrored: true, axis: "rt", btn: "r2" }]
      delegate: Item {
        id: trig
        required property var modelData
        readonly property real pull: xb.pull(modelData.axis, modelData.btn)
        width: 340; height: 256
        transform: [
        Translate { y: -3 }, // more air between trigger and bumper, like the DualSense
        Scale { origin.y: 12; yScale: 1 - 0.35 * trig.pull }
      ]

        Mirrored {
          mirrored: trig.modelData.mirrored
          ShapePath {
            strokeColor: trig.pull > 0 ? xb.glow : xb.edge
            strokeWidth: 1
            fillGradient: LinearGradient {
              x1: 0; y1: -8; x2: 0; y2: 24
              GradientStop { position: 0; color: "#4a4d55" }
              GradientStop { position: 0.5; color: "#1d1e22" }
              GradientStop { position: 1; color: "#0c0c0e" }
            }
            PathSvg { path: xb.triggerPath }
          }
          ShapePath { // light along the top curve
            fillColor: "transparent"
            strokeColor: Qt.rgba(1, 1, 1, 0.12)
            strokeWidth: 1.5
            capStyle: ShapePath.RoundCap
            PathSvg { path: xb.triggerShinePath }
          }
        }
        Item { // green fill rising from the bottom with the pull
          y: 25 - 33 * trig.pull
          width: 340; height: 33 * trig.pull
          clip: true
          Mirrored {
            y: -parent.y
            mirrored: trig.modelData.mirrored
            ShapePath {
              strokeColor: "transparent"
              fillColor: Qt.rgba(0.25, 0.75, 0.31, 0.85)
              PathSvg { path: xb.triggerPath }
            }
          }
        }
      }
    }

    // ── Shell ──────────────────────────────────────────────────────────────
    Shape {
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer
      ShapePath {
        strokeColor: xb.edge
        strokeWidth: 1
        fillGradient: LinearGradient {
          x1: 0; y1: 28; x2: 0; y2: 250
          GradientStop { position: 0; color: "#2a2b30" }
          GradientStop { position: 0.45; color: "#1a1b1e" }
          GradientStop { position: 1; color: "#0c0c0e" }
        }
        PathSvg { path: xb.bodyPath }
      }
    }

    Shape {
      id: bodyMask
      anchors.fill: parent
      visible: false
      layer.enabled: true
      layer.textureSize: Qt.size(width * xb.detail, height * xb.detail)
      preferredRendererType: Shape.CurveRenderer
      ShapePath { fillColor: "white"; strokeColor: "transparent"; PathSvg { path: xb.bodyPath } }
    }

    Item { // light catching the outer edges, clipped to the shell
      anchors.fill: parent
      layer.enabled: true
      layer.textureSize: Qt.size(width * xb.detail, height * xb.detail)
      layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: bodyMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
      }
      Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
          fillColor: "transparent"
          strokeColor: Qt.rgba(1, 1, 1, 0.07)
          strokeWidth: 9
          PathSvg { path: xb.bodyPath }
        }
      }
    }

    // ── Bumpers ────────────────────────────────────────────────────────────
    Repeater { // shadow where each bumper meets the shell
      model: [false, true]
      delegate: Mirrored {
        required property bool modelData
        mirrored: modelData
        ShapePath {
          fillColor: "transparent"
          strokeColor: Qt.rgba(0, 0, 0, 0.55)
          strokeWidth: 2.5
          capStyle: ShapePath.RoundCap
          PathSvg { path: xb.bumperSeamPath }
        }
      }
    }
    Repeater {
      model: [{ mirrored: false, btn: "l1" }, { mirrored: true, btn: "r1" }]
      delegate: Mirrored {
        id: bumper
        required property var modelData
        readonly property bool down: xb.b(modelData.btn)
        mirrored: modelData.mirrored
        ShapePath {
          strokeColor: bumper.down ? xb.glow : xb.edge
          strokeWidth: 1
          joinStyle: ShapePath.RoundJoin
          fillGradient: LinearGradient {
            x1: 0; y1: 20; x2: 0; y2: 48
            GradientStop { position: 0; color: bumper.down ? "#7fe08a" : "#4b4e56" }
            GradientStop { position: 0.35; color: bumper.down ? xb.glow : "#25262b" }
            GradientStop { position: 1; color: bumper.down ? "#23862f" : "#101012" }
          }
          PathSvg { path: xb.bumperPath }
        }
        ShapePath { // light catching the top edge
          fillColor: "transparent"
          strokeColor: bumper.down ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(1, 1, 1, 0.2)
          strokeWidth: 1.6
          capStyle: ShapePath.RoundCap
          PathSvg { path: xb.bumperShinePath }
        }
      }
    }

    // Guide button: a lit logo in a dark well
    Rectangle {
      x: 170 - 13; y: 48 - 13
      width: 26; height: 26; radius: 13
      border.width: 1
      border.color: xb.b("home") ? xb.glow : "#3a3d44"
      gradient: Gradient {
        GradientStop { position: 0; color: "#0b0b0d" }
        GradientStop { position: 1; color: "#26282d" }
      }
      Text {
        anchors.centerIn: parent
        text: xb.homeGlyph
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 20
        color: xb.b("home") ? xb.glow : "#f2f3f5"
      }
    }

    // View / Menu, and Share under them
    Repeater {
      model: [{ n: "select", x: 146.3, glyph: "⧉" }, { n: "start", x: 193.7, glyph: "≡" }]
      delegate: Rectangle {
        id: mid
        required property var modelData
        readonly property bool down: xb.b(modelData.n)
        x: modelData.x - 7.5; y: 82.6 - 7.5
        width: 15; height: 15; radius: 7.5
        border.width: 1
        border.color: down ? xb.glow : "#43464d"
        gradient: Gradient {
          GradientStop { position: 0; color: mid.down ? "#7fe08a" : "#2e3035" }
          GradientStop { position: 1; color: mid.down ? "#23862f" : "#0c0c0e" }
        }
        Text {
          anchors.centerIn: parent
          text: mid.modelData.glyph
          font.pixelSize: 9
          color: xb.symbol
        }
      }
    }
    Rectangle {
      x: 170 - 8.5; y: 100.5 - 4
      width: 17; height: 8; radius: 4
      border.width: 1
      border.color: "#43464d"
      gradient: Gradient {
        GradientStop { position: 0; color: "#2e3035" }
        GradientStop { position: 1; color: "#0c0c0e" }
      }
      Rectangle { // the little "upload" mark
        anchors.centerIn: parent
        width: 6; height: 2.4; radius: 0.6
        color: "transparent"
        border.width: 0.8
        border.color: xb.symbol
      }
    }

    // ── D-pad: the faceted dish ────────────────────────────────────────────
    Rectangle {
      x: 126 - 25; y: 136.5 - 25
      width: 50; height: 50; radius: 25
      border.width: 1
      border.color: "#3a3d44"
      gradient: Gradient {
        GradientStop { position: 0; color: "#2c2e33" }
        GradientStop { position: 1; color: "#0b0b0d" }
      }
    }
    Repeater {
      model: [{ n: "up", r: 0 }, { n: "right", r: 90 }, { n: "down", r: 180 }, { n: "left", r: 270 }]
      delegate: Item {
        id: arm
        required property var modelData
        readonly property bool down: xb.b(modelData.n)
        x: 126 - 25; y: 136.5 - 25
        width: 50; height: 50
        rotation: modelData.r
        Shape {
          anchors.fill: parent
          preferredRendererType: Shape.CurveRenderer
          ShapePath {
            strokeColor: arm.down ? xb.glow : "#4a4d55"
            strokeWidth: 1
            joinStyle: ShapePath.RoundJoin
            fillGradient: LinearGradient {
              x1: 0; y1: 4; x2: 0; y2: 25
              GradientStop { position: 0; color: arm.down ? "#7fe08a" : "#3a3c42" }
              GradientStop { position: 0.45; color: arm.down ? xb.glow : "#18191c" }
              GradientStop { position: 1; color: arm.down ? "#23862f" : "#0e0e10" }
            }
            PathSvg { path: "M 19.5 6 Q 19.5 4 21.5 4 L 28.5 4 Q 30.5 4 30.5 6 L 30.5 19.5 L 25 25 L 19.5 19.5 Z" }
          }
        }
      }
    }

    // ── Face buttons ───────────────────────────────────────────────────────
    Repeater {
      model: [
        { n: "north", i: 0, dx: 0, dy: -22.5 }, { n: "east", i: 1, dx: 22.5, dy: 0 },
        { n: "south", i: 2, dx: 0, dy: 22.5 }, { n: "west", i: 3, dx: -22.5, dy: 0 }
      ]
      delegate: Rectangle {
        id: faceBtn
        required property var modelData
        readonly property bool down: xb.b(modelData.n)
        readonly property var look: xb.face[modelData.i]
        x: 256 + modelData.dx - 11; y: 84 + modelData.dy - 11
        width: 22; height: 22; radius: 11
        border.width: 1
        border.color: down ? look.c : "#4a4d55"
        gradient: Gradient {
          GradientStop { position: 0; color: faceBtn.down ? Qt.lighter(faceBtn.look.c, 1.25) : "#2e3035" }
          GradientStop { position: 0.45; color: faceBtn.down ? faceBtn.look.c : "#111214" }
          GradientStop { position: 1; color: faceBtn.down ? Qt.darker(faceBtn.look.c, 1.3) : "#070708" }
        }
        Text {
          anchors.centerIn: parent
          text: faceBtn.look.t
          color: faceBtn.down ? "white" : faceBtn.look.c
          font.pixelSize: 12
          font.bold: true
        }
      }
    }

    // ── Sticks: left high, right low ───────────────────────────────────────
    Repeater {
      model: [{ x: 84, y: 83.7, ax: "lx", ay: "ly", btn: "l3" }, { x: 214, y: 134, ax: "rx", ay: "ry", btn: "r3" }]
      delegate: Item {
        id: stick
        required property var modelData
        readonly property real sx: xb.a(modelData.ax)
        readonly property real sy: xb.a(modelData.ay)
        readonly property bool moved: Math.abs(sx) + Math.abs(sy) > 0.15
        readonly property bool down: xb.b(modelData.btn)
        x: modelData.x - 24; y: modelData.y - 24
        width: 48; height: 48
        Rectangle { // well
          anchors.fill: parent
          radius: 24
          border.width: 1
          border.color: "#2a2c33"
          gradient: Gradient {
            GradientStop { position: 0; color: "#050506" }
            GradientStop { position: 1; color: "#1e2025" }
          }
        }
        Rectangle { // cap: rubber rim with a concave top
          width: 38; height: 38; radius: 19
          x: 5 + stick.sx * 5
          y: 5 + stick.sy * 5
          border.width: 1.4
          border.color: stick.moved ? xb.glow : "#3a3d44"
          gradient: Gradient {
            GradientStop { position: 0; color: stick.down ? "#7fe08a" : "#35373d" }
            GradientStop { position: 1; color: stick.down ? "#23862f" : "#0b0b0d" }
          }
          Rectangle {
            anchors.centerIn: parent
            width: 26; height: 26; radius: 13
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)
            gradient: Gradient {
              GradientStop { position: 0; color: stick.down ? "#23862f" : "#08080a" }
              GradientStop { position: 1; color: stick.down ? "#7fe08a" : "#2a2c31" }
            }
          }
        }
      }
    }
  }
}
