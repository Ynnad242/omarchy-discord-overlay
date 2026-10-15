import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

// Discord-style overlay with three widgets:
//  - Voice: who's in your voice channel (via discord_voice.py, which reads
//    Discord's local RPC). People light up while talking, faded otherwise.
//  - Stream: a live capture of a Go Live stream. When you leave the Discord
//    workspace while watching one, discord_a11y.py presses Discord's own
//    "Pop Out" button through the accessibility bus; the pop-out is tucked away
//    on a hidden special workspace in grid view, and every stream in it except
//    your own is cropped out and tiled: side by side, stacked, or auto
//    (1 → full, 2 → side by side, 3-4 → 2×2, …). Coming back to Discord closes that pop-out so the stream drops back
//    into Discord.
//  - Controller: a live drawing of the connected gamepad (via controller.py),
//    PS5 or Xbox style depending on what's plugged in.
//
// Normal mode: click-through, widgets float on top of every workspace.
// Edit mode (Super+Tab): screen dims, widgets can be dragged, the stream
// resized from its corner grip, and either removed with ×. The ⚙ next to the
// hint opens settings: when to show the overlay (always / only while a game is
// running) and buttons to add removed widgets back.
// The overlay always steps aside while the main Discord window is on screen.
// Enabled widgets never overlap: dragging slides along whatever is in the
// way, and when one appears or grows the others move to the nearest free spot.
Item {
  id: root

  property bool opened: true
  property bool editing: false
  property bool settingsOpen: false

  // Title regex for the stream window. Empty = Discord's pop-out window
  // (initial title "Discord Popout").
  property string match: ""
  property bool hideSource: true
  readonly property string stashWorkspace: "special:discord-stream"

  // ── Persisted settings ──────────────────────────────────────────────────
  property string showMode: "always" // "always" | "gaming"
  property bool voiceEnabled: true
  property bool streamEnabled: true
  property bool autoPopout: true
  // Extra window classes (regex) to treat as games, on top of the built-ins.
  property string extraGameClasses: ""
  property real streamX: -1
  property real streamY: -1
  property real streamWidth: 480
  property string streamLayout: "auto" // "auto" | "side" | "stacked"
  readonly property var streamLayouts: [
    { id: "auto", label: "Auto grid" }, { id: "side", label: "Side by side" }, { id: "stacked", label: "Stacked" }
  ]
  property real voiceX: -1
  property real voiceY: -1
  property bool controllerEnabled: true
  property string controllerStyle: "auto" // "auto" | "playstation" | "xbox"
  property real controllerX: -1
  property real controllerY: -1
  property real controllerWidth: 280
  readonly property int minStreamWidth: 240
  readonly property int minControllerWidth: 170

  // ── Live state ──────────────────────────────────────────────────────────
  property string voiceChannel: ""
  property var voiceMembers: []
  property var selfNames: [] // every name you show up as, to leave your stream out
  property var liveNames: [] // people in your voice channel who are streaming
  property var pad: ({ connected: false })
  // From discord_a11y.py
  property bool a11yDiscord: false
  property bool canPopout: false
  property var popoutGeom: null // { width, height, tile: { x, y, width, height } | null }
  property real lastPopoutPress: 0
  property real lastGridPress: 0
  // Address of the pop-out we opened ourselves; only that one gets closed
  // again when you return to Discord.
  property string autoPopoutAddress: ""

  function windowClass(t) {
    return (t.lastIpcObject && t.lastIpcObject.class) || ""
  }

  function isMainDiscord(t) {
    return /^discord$/i.test(windowClass(t)) && !isPopout(t) && !/updater/i.test(t.title)
  }

  function isPopout(t) {
    return /discord/i.test(windowClass(t)) && t.lastIpcObject && t.lastIpcObject.initialTitle === "Discord Popout"
  }

  readonly property var source: {
    const list = Hyprland.toplevels.values
    for (let i = 0; i < list.length; i++) {
      const t = list[i]
      if (!/discord/i.test(windowClass(t)) || !t.wayland) continue
      if (root.match !== "") {
        if (new RegExp(root.match, "i").test(t.title)) return t
      } else {
        // Only Discord's real pop-out; the main window briefly has other
        // titles while starting up, so title guessing isn't safe.
        if (isPopout(t)) return t
      }
    }
    return null
  }

  // First window that looks like a game: Steam games (steam_app_<id>),
  // Proton/Wine (*.exe), gamescope, plus any user-supplied classes.
  readonly property var game: {
    const extra = root.extraGameClasses !== "" ? new RegExp(root.extraGameClasses, "i") : null
    const list = Hyprland.toplevels.values
    for (let i = 0; i < list.length; i++) {
      const t = list[i]
      const ipc = t.lastIpcObject || {}
      const classes = [ipc.class || "", ipc.initialClass || ""]
      for (const c of classes) {
        if (/^steam_app_\d+$/i.test(c) || /\.exe$/i.test(c) || /^gamescope$/i.test(c)
            || (extra && extra.test(c)))
          return t
      }
    }
    return null
  }

  // True while the main Discord window's workspace is on screen.
  readonly property bool discordOnScreen: {
    const list = Hyprland.toplevels.values
    const monitors = Hyprland.monitors.values
    for (let i = 0; i < list.length; i++) {
      const t = list[i]
      if (!isMainDiscord(t) || !t.workspace) continue
      for (let j = 0; j < monitors.length; j++)
        if (monitors[j].activeWorkspace === t.workspace) return true
    }
    return false
  }

  readonly property bool active: root.opened && !root.discordOnScreen
    && (root.showMode === "always" || root.game !== null)
  readonly property bool hasStream: root.source !== null
  readonly property bool hasVoice: root.voiceChannel !== ""
  readonly property bool streamShown: root.streamEnabled
    && (root.editing || (root.active && root.hasStream && (!root.hasTileInfo || root.streamTiles.length > 0)))
  readonly property bool voiceShown: root.voiceEnabled
    && (root.editing || (root.active && root.hasVoice && root.voiceMembers.length > 0))
  readonly property bool controllerShown: root.controllerEnabled
    && (root.editing || (root.active && root.pad.connected === true))
  readonly property string controllerKind: root.controllerStyle !== "auto" ? root.controllerStyle
    : (root.pad.kind || "xbox")

  // Stream tiles to show: everyone's stream in the pop-out except yours. With
  // no accessibility info the whole pop-out window is one tile. If the pop-out
  // is seen but holds no stream tiles, nobody is streaming: show nothing.
  readonly property bool hasTileInfo: root.popoutGeom !== null && root.popoutGeom.width > 0
  readonly property var streamTiles: {
    if (!root.hasTileInfo) return []
    const mine = root.selfNames.map(n => n.toLowerCase())
    return (root.popoutGeom.tiles || []).filter(t => mine.indexOf(t.name.toLowerCase()) < 0)
  }

  onSourceChanged: {
    if (root.source && Date.now() - root.lastPopoutPress < 5000) root.autoPopoutAddress = root.source.address
    stash()
  }
  onDiscordOnScreenChanged: root.discordOnScreen ? popIn() : (tryPopout(), stash())
  onActiveChanged: tryPopout()
  onCanPopoutChanged: tryPopout()
  onStreamEnabledChanged: root.streamEnabled ? (tryPopout(), stash()) : unstash()
  onEditingChanged: if (!root.editing) root.settingsOpen = false
  // Switched off from the bar icon: give the stream back to Discord.
  onOpenedChanged: {
    if (root.opened) return
    if (root.source && root.source.address === root.autoPopoutAddress) popIn()
    else unstash()
  }

  function dispatchWindow(fn, address, extra) {
    Hyprland.dispatch("hl.dsp.window." + fn + "({ window = \"address:0x" + address + "\"" + (extra ? ", " + extra : "") + " })")
  }

  function dispatchMove(address, workspace) {
    dispatchWindow("move", address, "workspace = \"" + workspace + "\", follow = false")
  }

  // Hide the pop-out on a special workspace. It's kept tiled there so it fills
  // the space and the stream is captured at a decent size.
  function stash() {
    if (!root.opened || !root.hideSource || !root.streamEnabled || !root.source || root.discordOnScreen) return
    dispatchMove(root.source.address, root.stashWorkspace)
    if (root.source.lastIpcObject && root.source.lastIpcObject.floating)
      dispatchWindow("float", root.source.address, "action = \"toggle\"")
  }

  // Bring the real pop-out back so it can be watched, closed or reused.
  function unstash() {
    if (!root.source || !Hyprland.focusedWorkspace) return
    dispatchMove(root.source.address, Hyprland.focusedWorkspace.name)
  }

  // Left Discord while watching a stream: press Discord's Pop Out button.
  function tryPopout() {
    if (!root.autoPopout || !root.streamEnabled || !root.active || root.hasStream || !root.canPopout) return
    if (Date.now() - root.lastPopoutPress < 5000) return
    root.lastPopoutPress = Date.now()
    a11yHelper.write("popout\n")
  }

  readonly property bool wantsGrid: root.streamEnabled && root.active && root.hasStream && root.hideSource

  // A focused (blown-up) stream only shows one person; switch the hidden
  // pop-out back to Discord's grid so every stream can be tiled.
  function ensureGrid() {
    if (!root.popoutGeom || !root.popoutGeom.focused || !root.wantsGrid) return
    if (!root.source.workspace || root.source.workspace.name !== root.stashWorkspace) return
    if (Date.now() - root.lastGridPress < 3000) return
    root.lastGridPress = Date.now()
    a11yHelper.write("grid\n")
  }
  onPopoutGeomChanged: ensureGrid()
  onWantsGridChanged: ensureGrid()

  // Back on Discord: close the pop-out we opened so the stream drops back
  // into the main window. Pop-outs you opened yourself are left alone.
  function popIn() {
    if (!root.source || root.source.address !== root.autoPopoutAddress) return
    dispatchWindow("close", root.source.address)
    root.autoPopoutAddress = ""
  }

  // Payload: {"action": "edit" | "show" | "hide" | "toggle" | "init"} plus
  // optional width/match/hideSource overrides. "show", "hide" and "toggle"
  // switch the overlay on or off and remember it; "init" (used at login) keeps
  // whatever was saved.
  function open(payloadJson) {
    let p = {}
    try { p = JSON.parse(payloadJson || "{}") } catch (e) {}
    if (p.width !== undefined) root.streamWidth = p.width
    if (p.match !== undefined) root.match = p.match
    if (p.hideSource !== undefined) root.hideSource = p.hideSource
    Hyprland.refreshToplevels()
    if (p.action === "edit") {
      root.opened = true
      root.editing = !root.editing
    } else if (p.action === "hide" || p.action === "show" || p.action === "toggle") {
      setEnabled(p.action === "toggle" ? !root.opened : p.action === "show")
    } else if (p.action !== "init") {
      root.opened = true
    }
    stash()
  }

  // omarchy-shell shell call ynnad.discord-stream debugState ""
  function debugState() {
    return JSON.stringify({
      opened: root.opened, active: root.active, discordOnScreen: root.discordOnScreen,
      showMode: root.showMode, game: root.game ? root.game.title : null,
      streamEnabled: root.streamEnabled, autoPopout: root.autoPopout,
      hasStream: root.hasStream, canPopout: root.canPopout, a11yDiscord: root.a11yDiscord,
      sinceLastPress: Date.now() - root.lastPopoutPress, autoPopoutAddress: root.autoPopoutAddress,
      popoutGeom: root.popoutGeom, selfNames: root.selfNames, liveNames: root.liveNames,
      streamTiles: root.streamTiles.map(t => t.name), pad: root.pad
    })
  }

  function close() { root.editing = false; root.opened = false }
  function toggle() { root.opened ? close() : open("{}") }

  function setEnabled(on) {
    root.editing = false
    root.opened = on
    saveState()
  }

  function saveState() {
    state.setText(JSON.stringify({
      enabled: root.opened,
      showMode: root.showMode,
      voiceEnabled: root.voiceEnabled,
      streamEnabled: root.streamEnabled,
      autoPopout: root.autoPopout,
      extraGameClasses: root.extraGameClasses,
      controllerEnabled: root.controllerEnabled,
      controllerStyle: root.controllerStyle,
      stream: { x: root.streamX, y: root.streamY, width: root.streamWidth, layout: root.streamLayout },
      voice: { x: root.voiceX, y: root.voiceY },
      controller: { x: root.controllerX, y: root.controllerY, width: root.controllerWidth }
    }, null, 2))
  }

  FileView {
    id: state
    path: Quickshell.env("HOME") + "/.local/state/discord-stream-overlay.json"
    blockLoading: true
    printErrors: false
    Component.onCompleted: {
      try {
        const s = JSON.parse(state.text())
        if (s.showMode) root.showMode = s.showMode
        if (s.voiceEnabled !== undefined) root.voiceEnabled = s.voiceEnabled
        if (s.streamEnabled !== undefined) root.streamEnabled = s.streamEnabled
        if (s.autoPopout !== undefined) root.autoPopout = s.autoPopout
        if (s.extraGameClasses) root.extraGameClasses = s.extraGameClasses
        if (s.controllerEnabled !== undefined) root.controllerEnabled = s.controllerEnabled
        if (s.controllerStyle) root.controllerStyle = s.controllerStyle
        if (s.controller) {
          if (s.controller.width) root.controllerWidth = s.controller.width
          if (s.controller.x !== undefined) root.controllerX = s.controller.x
          if (s.controller.y !== undefined) root.controllerY = s.controller.y
        }
        if (s.stream) {
          if (s.stream.width) root.streamWidth = s.stream.width
          if (s.stream.layout) root.streamLayout = s.stream.layout
          if (s.stream.x !== undefined) root.streamX = s.stream.x
          if (s.stream.y !== undefined) root.streamY = s.stream.y
        }
        if (s.voice) {
          if (s.voice.x !== undefined) root.voiceX = s.voice.x
          if (s.voice.y !== undefined) root.voiceY = s.voice.y
        }
        if (s.enabled !== undefined) root.opened = s.enabled
      } catch (e) {}
    }
  }

  Process {
    id: voiceHelper
    command: ["python3", "-I", Qt.resolvedUrl("discord_voice.py").toString().replace(/^file:\/\//, "")]
    running: true
    stdout: SplitParser {
      onRead: line => {
        try {
          const msg = JSON.parse(line)
          root.voiceChannel = msg.connected ? (msg.channel || "") : ""
          root.voiceMembers = msg.connected ? (msg.members || []) : []
          if (msg.self) root.selfNames = msg.self
        } catch (e) {}
      }
    }
    onExited: restartHelper.start()
  }

  Timer {
    id: restartHelper
    interval: 5000
    onTriggered: voiceHelper.running = true
  }

  Process {
    id: a11yHelper
    command: ["python3", "-I", Qt.resolvedUrl("discord_a11y.py").toString().replace(/^file:\/\//, "")]
    running: true
    stdinEnabled: true
    stdout: SplitParser {
      onRead: line => {
        try {
          const msg = JSON.parse(line)
          root.a11yDiscord = msg.discord === true
          root.canPopout = msg.canPopout === true
          root.popoutGeom = msg.popout || null
          root.liveNames = msg.live || []
        } catch (e) {}
      }
    }
    onExited: restartA11y.start()
  }

  Timer {
    id: restartA11y
    interval: 5000
    onTriggered: a11yHelper.running = true
  }

  Process {
    id: padHelper
    command: ["python3", "-I", Qt.resolvedUrl("controller.py").toString().replace(/^file:\/\//, "")]
    running: true
    stdout: SplitParser {
      onRead: line => {
        try { root.pad = JSON.parse(line) } catch (e) {}
      }
    }
    onExited: restartPad.start()
  }

  Timer {
    id: restartPad
    interval: 5000
    onTriggered: padHelper.running = true
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name === "openwindow" || event.name === "closewindow" || event.name === "windowtitlev2"
          || event.name === "movewindowv2")
        Hyprland.refreshToplevels()
    }
  }

  // ── Small building blocks ───────────────────────────────────────────────
  component CloseButton: Rectangle {
    signal clicked()
    width: 24; height: 24; radius: 12
    color: closeArea.containsMouse ? "#ED4245" : Qt.rgba(0, 0, 0, 0.75)
    Text { anchors.centerIn: parent; text: "×"; color: "white"; font.pixelSize: 18 }
    MouseArea {
      id: closeArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: parent.clicked()
    }
  }

  component Button: Rectangle {
    id: btn
    property string label
    property bool clickable: true
    property bool selected: false
    signal clicked()
    width: btnLabel.implicitWidth + 24; height: 32; radius: 8
    color: !btn.clickable ? "#3a3c43" : btn.selected ? "#5865F2"
      : btnArea.containsMouse ? "#4e5058" : "#41434a"
    Text {
      id: btnLabel
      anchors.centerIn: parent
      text: btn.label
      color: btn.clickable ? "white" : "#949ba4"
      font.pixelSize: 14
    }
    MouseArea {
      id: btnArea
      anchors.fill: parent
      hoverEnabled: true
      enabled: btn.clickable
      cursorShape: Qt.PointingHandCursor
      onClicked: btn.clicked()
    }
  }

  // ── Keeping widgets apart ───────────────────────────────────────────────
  readonly property int widgetGap: 10

  function widgets() {
    return [
      { item: stream, on: root.streamEnabled, place: (x, y) => { root.streamX = x; root.streamY = y } },
      { item: voice, on: root.voiceEnabled, place: (x, y) => { root.voiceX = x; root.voiceY = y } },
      { item: controller, on: root.controllerEnabled, place: (x, y) => { root.controllerX = x; root.controllerY = y } }
    ].filter(w => w.on)
  }

  function rectOf(item, x, y) {
    return { x: x === undefined ? item.x : x, y: y === undefined ? item.y : y, w: item.width, h: item.height }
  }

  function touches(a, b) {
    const g = root.widgetGap
    return a.x < b.x + b.w + g && b.x < a.x + a.w + g && a.y < b.y + b.h + g && b.y < a.y + a.h + g
  }

  function isClear(r, others) { return others.every(o => !touches(r, o)) }

  function clampRect(r) {
    return { x: Math.max(0, Math.min(r.x, win.width - r.w)), y: Math.max(0, Math.min(r.y, win.height - r.h)), w: r.w, h: r.h }
  }

  // Nearest on-screen spot for r that keeps clear of every rect in others:
  // tries lining up beside, above or below each of them and the screen edges.
  function freeSpot(r, others) {
    if (isClear(r, others)) return r
    const g = root.widgetGap
    const xs = [r.x, 0, win.width - r.w], ys = [r.y, 0, win.height - r.h]
    for (const o of others) {
      xs.push(o.x - r.w - g, o.x + o.w + g, o.x)
      ys.push(o.y - r.h - g, o.y + o.h + g, o.y)
    }
    let best = null, bestDist = Infinity
    for (const x of xs) {
      for (const y of ys) {
        const c = clampRect({ x: x, y: y, w: r.w, h: r.h })
        if (!isClear(c, others)) continue
        const d = Math.hypot(c.x - r.x, c.y - r.y)
        if (d < bestDist) { best = c; bestDist = d }
      }
    }
    return best || r // screen too full: leave it be
  }

  // Dragging: go where the mouse says if that's clear, otherwise slide along
  // the one axis that still is.
  function dragTo(item, x, y) {
    const list = root.widgets()
    const me = list.find(w => w.item === item)
    if (!me) return
    const others = list.filter(w => w !== me).map(w => rectOf(w.item))
    const stuck = !isClear(rectOf(item), others) // already overlapping: let it out
    for (const c of [[x, y], [x, item.y], [item.x, y]]) {
      if (stuck || isClear(rectOf(item, c[0], c[1]), others)) { me.place(c[0], c[1]); return }
    }
  }

  // keep: widget that holds its place (just resized/grew); last: widget that
  // gives way to everything (just added back).
  property Item resolveKeep: null
  property Item resolveLast: null
  function queueResolve(keep, last) {
    if (keep) root.resolveKeep = keep
    if (last) root.resolveLast = last
    resolveTimer.restart()
  }

  function resolveOverlaps() {
    if (win.width <= 0 || win.height <= 0) return
    const rank = w => w.item === root.resolveKeep ? 0 : w.item === root.resolveLast ? 2 : 1
    const list = root.widgets().sort((a, b) => rank(a) - rank(b))
    root.resolveKeep = null
    root.resolveLast = null
    const placed = []
    let moved = false
    for (const w of list) {
      const r = rectOf(w.item)
      const f = freeSpot(r, placed)
      if (f.x !== r.x || f.y !== r.y) { w.place(f.x, f.y); moved = true }
      placed.push(f)
    }
    if (moved) root.saveState()
  }

  Timer {
    id: resolveTimer
    interval: 120
    onTriggered: root.resolveOverlaps()
  }

  // Drag-to-move handler; position is written back via onMoved.
  component MoveArea: MouseArea {
    required property Item target
    signal moved(real x, real y)
    anchors.fill: parent
    enabled: root.editing
    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
    property point start
    property point origin
    onPressed: mouse => {
      start = mapToItem(null, mouse.x, mouse.y)
      origin = Qt.point(target.x, target.y)
    }
    onPositionChanged: mouse => {
      const p = mapToItem(null, mouse.x, mouse.y)
      moved(Math.max(0, Math.min(origin.x + p.x - start.x, win.width - target.width)),
            Math.max(0, Math.min(origin.y + p.y - start.y, win.height - target.height)))
    }
    onReleased: root.saveState()
  }

  // Bottom-right grip that drags a widget's width; height follows its content.
  component ResizeGrip: Rectangle {
    id: grip
    required property Item target
    signal pinned()
    signal resized(real width)
    visible: root.editing
    anchors { right: parent.right; bottom: parent.bottom }
    width: 18; height: 18
    color: "#5865F2"
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.SizeFDiagCursor
      property real startX
      property real startWidth
      onPressed: mouse => {
        startX = mapToItem(null, mouse.x, mouse.y).x
        startWidth = grip.target.width
        grip.pinned()
      }
      onPositionChanged: mouse => {
        const dx = mapToItem(null, mouse.x, mouse.y).x - startX
        grip.resized(Math.min(startWidth + dx, win.width - grip.target.x))
      }
      onReleased: root.saveState()
    }
  }

  PanelWindow {
    id: win
    visible: root.editing || (root.active && (root.streamShown || root.voiceShown || root.controllerShown))
    screen: Quickshell.screens.find(s => Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name) || Quickshell.screens[0]
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.namespace: "discord-overlay"
    onWidthChanged: root.queueResolve(null, null)
    onHeightChanged: root.queueResolve(null, null)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.editing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    // Click-through unless editing.
    mask: Region { item: root.editing ? backdrop : noInput }

    Item { id: noInput; width: 0; height: 0 }

    Rectangle {
      id: backdrop
      anchors.fill: parent
      color: Qt.rgba(0, 0, 0, root.editing ? 0.55 : 0)
      Behavior on color { ColorAnimation { duration: 150 } }
      focus: root.editing
      Keys.onEscapePressed: root.settingsOpen ? root.settingsOpen = false : root.editing = false

      MouseArea {
        anchors.fill: parent
        enabled: root.editing
        onClicked: root.settingsOpen ? root.settingsOpen = false : root.editing = false
      }

      // Hint + settings gear
      Row {
        visible: root.editing
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        spacing: 12

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "Drag to move · drag the corner to resize · × to remove · Esc or Super+Tab when done"
          color: "white"
          font.pixelSize: 16
        }

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: 36; height: 36; radius: 18
          color: root.settingsOpen ? "#5865F2" : gearArea.containsMouse ? "#4e5058" : Qt.rgba(0, 0, 0, 0.6)
          Text {
            anchors.centerIn: parent
            text: "" // nf-fa-cog
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18
            color: "white"
          }
          MouseArea {
            id: gearArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.settingsOpen = !root.settingsOpen
          }
        }
      }
    }

    // ── Voice ─────────────────────────────────────────────────────────────
    Rectangle {
      id: voice
      onWidthChanged: root.queueResolve(voice, null)
      onHeightChanged: root.queueResolve(voice, null)
      visible: root.voiceShown
      x: root.voiceX >= 0 ? Math.min(root.voiceX, win.width - width) : 20
      y: root.voiceY >= 0 ? Math.min(root.voiceY, win.height - height) : 20
      width: Math.max(voiceList.width, placeholder.visible ? placeholder.implicitWidth : 0) + 16
      height: (placeholder.visible ? placeholder.implicitHeight : voiceList.height) + 16
      radius: 10
      color: root.editing ? Qt.rgba(0, 0, 0, 0.5) : "transparent"
      border.width: root.editing ? 2 : 0
      border.color: "#5865F2"

      MoveArea {
        target: voice
        onMoved: (x, y) => root.dragTo(voice, x, y)
      }

      Text {
        id: placeholder
        visible: root.voiceMembers.length === 0
        x: 8; y: 8
        text: "Voice list · not in a voice channel"
        color: "#b5bac1"
        font.pixelSize: 14
      }

      Column {
        id: voiceList
        x: 8; y: 8
        spacing: 6

        Repeater {
          model: root.voiceMembers
          delegate: Row {
            required property var modelData
            spacing: 8
            opacity: modelData.speaking || root.editing ? 1.0 : 0.35
            Behavior on opacity { NumberAnimation { duration: 120 } }

            Rectangle {
              width: 36; height: 36; radius: 18
              color: modelData.speaking ? "#23A55A" : "transparent"
              ClippingRectangle {
                anchors.centerIn: parent
                width: 32; height: 32; radius: 16
                color: "#313338"
                Image {
                  anchors.fill: parent
                  source: modelData.avatar
                  sourceSize: Qt.size(64, 64)
                  asynchronous: true
                  cache: true
                }
              }
            }

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: nameRow.implicitWidth + 16
              height: 24
              radius: 6
              color: Qt.rgba(0, 0, 0, 0.7)
              Row {
                id: nameRow
                anchors.centerIn: parent
                spacing: 6
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: modelData.name
                  color: "white"
                  font.pixelSize: 14
                  font.bold: modelData.speaking
                }
                // Muted and deafened each show their own icon, side by side.
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  visible: !!modelData.muted
                  text: "󰍭" // nf-md-microphone_off
                  font.family: "JetBrainsMono Nerd Font"
                  font.pixelSize: 15
                  color: "#ED4245"
                }
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  visible: !!modelData.deafened
                  text: "󰟎" // nf-md-headphones_off
                  font.family: "JetBrainsMono Nerd Font"
                  font.pixelSize: 15
                  color: "#ED4245"
                }
                // Discord's red LIVE pill while they're streaming.
                Rectangle {
                  anchors.verticalCenter: parent.verticalCenter
                  visible: root.liveNames.some(n => n.toLowerCase() === modelData.name.toLowerCase())
                  width: liveText.implicitWidth + 8
                  height: 16
                  radius: 4
                  color: "#ED4245"
                  Text {
                    id: liveText
                    anchors.centerIn: parent
                    text: "LIVE"
                    color: "white"
                    font.pixelSize: 11
                    font.bold: true
                  }
                }
              }
            }
          }
        }
      }

      CloseButton {
        visible: root.editing
        anchors { top: parent.top; right: parent.right; margins: -10 }
        onClicked: { root.voiceEnabled = false; root.saveState() }
      }
    }

    // ── Stream ────────────────────────────────────────────────────────────
    // One capture of the hidden pop-out; each stream tile in it is cropped out
    // with a ShaderEffectSource and laid out in a grid sized to the count.
    Item {
      id: stream
      onWidthChanged: root.queueResolve(stream, null)
      onHeightChanged: root.queueResolve(stream, null)
      visible: root.streamShown
      x: root.streamX >= 0 ? Math.min(root.streamX, win.width - width) : win.width - width - 20
      y: root.streamY >= 0 ? Math.min(root.streamY, win.height - height) : 20
      width: root.streamWidth

      // Size of the pop-out in the same coordinates as the tiles.
      readonly property real srcW: root.hasTileInfo ? root.popoutGeom.width : (view.sourceSize.width || 16)
      readonly property real srcH: root.hasTileInfo ? root.popoutGeom.height : (view.sourceSize.height || 9)
      readonly property var tiles: root.hasTileInfo ? root.streamTiles
        : root.hasStream ? [{ name: "", x: 0, y: 0, width: srcW, height: srcH }] : []
      readonly property int count: Math.max(1, tiles.length)
      readonly property int cols: root.streamLayout === "side" ? count
        : root.streamLayout === "stacked" ? 1 : Math.ceil(Math.sqrt(count))
      readonly property int rows: Math.ceil(count / cols)
      readonly property real gap: 6
      readonly property real cellW: (width - (cols - 1) * gap) / cols
      readonly property real cellH: Math.round(cellW * (tiles.length ? tiles[0].height / tiles[0].width : 9 / 16))
      readonly property real captureScale: tiles.length ? cellW / tiles[0].width : 1
      height: rows * cellH + (rows - 1) * gap

      ScreencopyView {
        id: view
        width: stream.srcW * stream.captureScale
        height: stream.srcH * stream.captureScale
        captureSource: root.streamShown && root.hasStream ? root.source.wayland : null
        live: true
        paintCursor: false
        visible: stream.tiles.length > 0
      }

      Repeater {
        model: stream.tiles
        delegate: ClippingRectangle {
          id: cell
          required property var modelData
          required property int index
          readonly property int row: Math.floor(index / stream.cols)
          // Centre a short last row (e.g. the third stream of three).
          readonly property int inRow: row === stream.rows - 1 ? stream.tiles.length - row * stream.cols : stream.cols
          x: (index % stream.cols) * (stream.cellW + stream.gap) + (stream.cols - inRow) * (stream.cellW + stream.gap) / 2
          y: row * (stream.cellH + stream.gap)
          width: stream.cellW
          height: stream.cellH
          radius: 10
          color: "#000000"

          ShaderEffectSource {
            anchors.fill: parent
            sourceItem: view
            hideSource: true
            live: true
            sourceRect: Qt.rect(cell.modelData.x * stream.captureScale, cell.modelData.y * stream.captureScale,
                                cell.modelData.width * stream.captureScale, cell.modelData.height * stream.captureScale)
          }

          Rectangle {
            visible: cell.modelData.name !== "" && stream.tiles.length > 1
            anchors { left: parent.left; bottom: parent.bottom; margins: 6 }
            width: tileName.implicitWidth + 12
            height: 20
            radius: 5
            color: Qt.rgba(0, 0, 0, 0.6)
            Text {
              id: tileName
              anchors.centerIn: parent
              text: cell.modelData.name
              color: "white"
              font.pixelSize: 12
            }
          }
        }
      }

      // Keep nudging a focused pop-out back to the grid in case a press is lost.
      Timer {
        interval: 3000
        repeat: true
        running: root.wantsGrid && root.popoutGeom !== null && root.popoutGeom.focused === true
        onTriggered: root.ensureGrid()
      }

      Rectangle {
        visible: stream.tiles.length === 0
        anchors.fill: parent
        radius: 10
        color: "#000000"
        Text {
          anchors.centerIn: parent
          width: parent.width - 32
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WordWrap
          text: root.hasStream
            ? "Streams · only your own stream is open"
            : root.autoPopout
              ? "Streams · watch streams in Discord, then leave the Discord workspace"
              : "Streams · click Pop Out on a stream in Discord and it shows here"
          color: "#b5bac1"
          font.pixelSize: 14
        }
      }

      Rectangle {
        anchors.fill: parent
        radius: 10
        color: "transparent"
        border.width: root.editing ? 2 : 0
        border.color: "#5865F2"
      }

      MoveArea {
        target: stream
        onMoved: (x, y) => root.dragTo(stream, x, y)
      }

      CloseButton {
        visible: root.editing
        anchors { top: parent.top; right: parent.right; margins: 8 }
        onClicked: { root.streamEnabled = false; root.saveState() }
      }

      // Click to cycle the layout: auto grid → side by side → stacked.
      Rectangle {
        visible: root.editing
        anchors { top: parent.top; left: parent.left; margins: 8 }
        width: layoutLabel.implicitWidth + 20
        height: 24
        radius: 12
        color: layoutArea.containsMouse ? "#5865F2" : Qt.rgba(0, 0, 0, 0.75)
        Text {
          id: layoutLabel
          anchors.centerIn: parent
          text: "▦ " + root.streamLayouts.find(l => l.id === root.streamLayout).label
          color: "white"
          font.pixelSize: 12
        }
        MouseArea {
          id: layoutArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            const ids = root.streamLayouts.map(l => l.id)
            root.streamLayout = ids[(ids.indexOf(root.streamLayout) + 1) % ids.length]
            root.saveState()
          }
        }
      }

      ResizeGrip {
        target: stream
        onPinned: { root.streamX = stream.x; root.streamY = stream.y }
        onResized: w => root.streamWidth = Math.max(root.minStreamWidth, w)
      }
    }

    // ── Controller ────────────────────────────────────────────────────────
    Rectangle {
      id: controller
      onWidthChanged: root.queueResolve(controller, null)
      onHeightChanged: root.queueResolve(controller, null)
      visible: root.controllerShown
      x: root.controllerX >= 0 ? Math.min(root.controllerX, win.width - width) : 20
      y: root.controllerY >= 0 ? Math.min(root.controllerY, win.height - height) : win.height - height - 20
      width: root.controllerWidth
      height: padView.height + (padNote.visible ? padNote.implicitHeight + 6 : 0)
      radius: 10
      color: root.editing ? Qt.rgba(0, 0, 0, 0.5) : "transparent"
      border.width: root.editing ? 2 : 0
      border.color: "#5865F2"

      ControllerView {
        id: padView
        width: parent.width
        kind: root.controllerKind
        connected: root.pad.connected === true
        buttons: root.pad.buttons || ({})
        axes: root.pad.axes || ({})
      }

      Text {
        id: padNote
        visible: root.editing
        anchors { top: padView.bottom; topMargin: 6; horizontalCenter: parent.horizontalCenter }
        text: root.pad.connected ? root.pad.name : "Controller · none connected"
        color: "#b5bac1"
        font.pixelSize: 12
        elide: Text.ElideRight
        width: Math.min(implicitWidth, parent.width - 16)
      }

      MoveArea {
        target: controller
        onMoved: (x, y) => root.dragTo(controller, x, y)
      }

      CloseButton {
        visible: root.editing
        anchors { top: parent.top; right: parent.right; margins: -10 }
        onClicked: { root.controllerEnabled = false; root.saveState() }
      }

      ResizeGrip {
        target: controller
        onPinned: { root.controllerX = controller.x; root.controllerY = controller.y }
        onResized: w => root.controllerWidth = Math.max(root.minControllerWidth, w)
      }
    }

    // ── Settings ──────────────────────────────────────────────────────────
    Rectangle {
      id: settings
      visible: root.editing && root.settingsOpen
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 96
      width: 460
      height: settingsCol.implicitHeight + 40
      radius: 12
      color: "#2b2d31"
      border.width: 1
      border.color: "#3f4147"

      // Swallow clicks so they don't close edit mode.
      MouseArea { anchors.fill: parent }

      Column {
        id: settingsCol
        x: 20; y: 20
        width: parent.width - 40
        spacing: 14

        Text { text: "Overlay settings"; color: "white"; font.pixelSize: 18; font.bold: true }

        Text { text: "Show the overlay"; color: "#b5bac1"; font.pixelSize: 13 }
        Row {
          spacing: 8
          Button {
            label: "All the time"
            selected: root.showMode === "always"
            onClicked: { root.showMode = "always"; root.saveState() }
          }
          Button {
            label: "Only while gaming"
            selected: root.showMode === "gaming"
            onClicked: { root.showMode = "gaming"; root.saveState() }
          }
        }
        Text {
          width: parent.width
          wrapMode: Text.WordWrap
          color: "#949ba4"
          font.pixelSize: 12
          text: (root.game
            ? "Game detected: " + (root.game.title || root.windowClass(root.game))
            : "No game detected right now")
            + ". Always hidden while the main Discord window is on screen."
        }

        Rectangle { width: parent.width; height: 1; color: "#3f4147" }

        Text { text: "Streams"; color: "#b5bac1"; font.pixelSize: 13 }
        Row {
          spacing: 8
          Button {
            label: "Pop out automatically"
            selected: root.autoPopout
            onClicked: { root.autoPopout = true; root.saveState() }
          }
          Button {
            label: "Only when I pop out"
            selected: !root.autoPopout
            onClicked: { root.autoPopout = false; root.saveState() }
          }
        }
        Text {
          width: parent.width
          wrapMode: Text.WordWrap
          color: "#949ba4"
          font.pixelSize: 12
          text: !root.a11yDiscord
            ? "Discord isn't exposing its accessibility info, so automatic pop-out can't work. Start Discord with ACCESSIBILITY_ENABLED=1 and --force-renderer-accessibility."
            : "When you leave the Discord workspace while watching streams, they pop out into the overlay (everyone's but yours, tiled to fit), and go back into Discord when you return."
        }

        Text { text: "Stream layout"; color: "#b5bac1"; font.pixelSize: 13 }
        Row {
          spacing: 8
          Repeater {
            model: root.streamLayouts
            delegate: Button {
              required property var modelData
              label: modelData.label
              selected: root.streamLayout === modelData.id
              onClicked: { root.streamLayout = modelData.id; root.saveState() }
            }
          }
        }

        Rectangle { width: parent.width; height: 1; color: "#3f4147" }

        Text { text: "Controller style"; color: "#b5bac1"; font.pixelSize: 13 }
        Row {
          spacing: 8
          Repeater {
            model: [
              { id: "auto", label: "Match controller" },
              { id: "playstation", label: "PS5" },
              { id: "xbox", label: "Xbox" }
            ]
            delegate: Button {
              required property var modelData
              label: modelData.label
              selected: root.controllerStyle === modelData.id
              onClicked: { root.controllerStyle = modelData.id; root.saveState() }
            }
          }
        }

        Rectangle { width: parent.width; height: 1; color: "#3f4147" }

        Text { text: "Widgets"; color: "#b5bac1"; font.pixelSize: 13 }

        Repeater {
          model: [
            { name: "Voice list", enabled: root.voiceEnabled,
              note: root.hasVoice ? "In " + root.voiceChannel : "Not in a voice channel",
              add: () => { root.voiceEnabled = true; root.saveState(); root.queueResolve(null, voice) } },
            { name: "Streams", enabled: root.streamEnabled,
              note: !root.hasStream ? "Pop out a stream in Discord to show it"
                : root.streamTiles.length === 1 ? "Showing 1 stream"
                : "Showing " + root.streamTiles.length + " streams",
              add: () => { root.streamEnabled = true; root.saveState(); root.queueResolve(null, stream) } },
            { name: "Controller", enabled: root.controllerEnabled,
              note: root.pad.connected ? root.pad.name : "No controller connected",
              add: () => { root.controllerEnabled = true; root.saveState(); root.queueResolve(null, controller) } }
          ]
          delegate: Item {
            required property var modelData
            width: settingsCol.width
            height: 36
            Column {
              anchors.verticalCenter: parent.verticalCenter
              Text { text: modelData.name; color: "white"; font.pixelSize: 14 }
              Text { text: modelData.note; color: "#949ba4"; font.pixelSize: 12 }
            }
            Button {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              label: modelData.enabled ? "✓ On screen" : "Add"
              clickable: !modelData.enabled
              selected: !modelData.enabled
              onClicked: modelData.add()
            }
          }
        }
      }
    }
  }
}
