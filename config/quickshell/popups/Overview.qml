import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.common
import qs.components
import qs.services

// Workspace overview, opened by hovering the workspace pills: a full-height
// overlay on the left edge, black fading to clear, no card. One row per
// workspace laid out like the scrolling layout's tape (columns left to right,
// stacked windows inside a column, a line under what's on screen).
// Drag a window along its row to reorder its column; drop it on another row
// to move it there. Click a window to focus it, a workspace number to go.
PanelWindow {
    id: root

    readonly property bool open: Ui.popup === "overview"
    property bool byHover: false                        // hover-opened: hover closes it, no focus grab
    readonly property bool hovered: contentHover.hovered

    readonly property int gutter: 56
    readonly property int rowGap: 10
    readonly property int colGap: 6
    readonly property int inset: 4                      // track padding around the columns
    readonly property int sideMargin: 20
    readonly property var fallbackMonitor: Hyprland.monitors.values.find(m => m.name === "DP-2") ?? Hyprland.monitors.values[0]
    readonly property int focusedId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    // occupied workspaces, the focused one, and the first free id as a drop target
    readonly property var rowIds: {
        const ids = Hyprland.workspaces.values.filter(w => w.id > 0 && w.toplevels.values.length > 0).map(w => w.id)
        if (!ids.includes(focusedId))
            ids.push(focusedId)
        let free = 1
        while (ids.includes(free))
            free++
        ids.push(free)
        return ids.sort((a, b) => a - b)
    }
    readonly property real availH: height - Theme.popupTop - 32
    readonly property int rowH: Math.max(64, Math.min(132, Math.floor((availH - (rowIds.length - 1) * rowGap) / rowIds.length)))
    readonly property real maxTape: width * 0.72 - gutter
    // adaptive: as wide as the longest tape (at rest, so drags don't resize it)
    readonly property real tapeW: {
        let w = 280
        for (let i = 0; i < rowsRep.count; i++) {
            const r = rowsRep.itemAt(i)
            if (r)
                w = Math.max(w, r.baseW)
        }
        return Math.min(maxTape, w)
    }

    function addr(t) {
        return "address:0x" + String(t.address).replace(/^0x/, "")
    }

    function moveWindow(t, wsId) {
        Hyprland.dispatch(`hl.dsp.window.move({ workspace = "${wsId}", window = "${addr(t)}", follow = false })`)
        Hyprland.refreshToplevels()
        refreshSoon.restart()
    }

    // Move column `from` to slot `to` without touching what's on screen.
    // Single-window columns bubble along with window.swap, which needs no
    // focus. Stacked columns only move as a whole through swapcol, which acts
    // on the focused window — fine on a visible workspace (focus comes back
    // after), refused on a hidden one since focusing would switch to it.
    function shiftColumn(cols, from, to) {
        if (from === to)
            return
        const dir = to > from ? 1 : -1
        const t = cols[from].wins[0]
        const steps = []
        if (cols[from].wins.length === 1 && cols.slice(Math.min(from, to), Math.max(from, to) + 1).every(c => c.wins.length === 1)) {
            for (let i = from + dir; i !== to + dir; i += dir)
                steps.push(`hl.dispatch(hl.dsp.window.swap({ window = "${addr(t)}", target = "${addr(cols[i].wins[0])}" }))`)
        } else {
            const mon = t.workspace ? t.workspace.monitor : null
            if (!mon || !mon.activeWorkspace || mon.activeWorkspace.id !== t.workspace.id)
                return
            steps.push(`hl.dispatch(hl.dsp.focus({ window = "${addr(t)}" }))`)
            for (let i = from; i !== to; i += dir)
                steps.push(`hl.dispatch(hl.dsp.layout("swapcol ${dir < 0 ? "l" : "r"}"))`)
            const prev = Hyprland.activeToplevel
            if (prev && prev !== t)
                steps.push(`hl.dispatch(hl.dsp.focus({ window = "${addr(prev)}" }))`)
        }
        // no cursor warps, and the keyboard's monitor stays where it was
        lua.command = ["hyprctl", "-q", "eval", [
            "local warps, mon = hl.get_config('cursor:no_warps'), hl.get_active_monitor()",
            "hl.config({ cursor = { no_warps = true } })",
            ...steps,
            "if mon then hl.dispatch(hl.dsp.focus({ monitor = mon.name })) end",
            "hl.config({ cursor = { no_warps = warps } })"
        ].join("\n")]
        lua.running = true
        refreshSoon.restart()
    }

    function focusWindow(t) {
        if (Date.now() - ghost.droppedAt < 500)       // a drop is never also a click
            return
        Hyprland.dispatch(`hl.dsp.focus({ window = "${addr(t)}" })`)
        Ui.close("overview")
    }

    function goTo(wsId) {
        Hyprland.dispatch(`hl.dsp.focus({ workspace = "${wsId}" })`)
        Ui.close("overview")
    }

    Process { id: lua }

    // ── hover open / close ─────────────────────────────────────────────
    Timer {
        id: openDelay
        interval: 320
        onTriggered: {
            if (Ui.wsHovered && Ui.popup === "") {
                root.byHover = true
                Ui.popup = "overview"
            }
        }
    }
    Connections {
        target: Ui
        function onWsHoveredChanged() {
            if (Ui.wsHovered) openDelay.restart()
            else openDelay.stop()
        }
    }
    Timer {
        // grace period so the pointer can travel from the pills into the rows
        interval: 280
        running: root.open && root.byHover && !Ui.wsHovered && !root.hovered && !ghost.dragging
        onTriggered: Ui.close("overview")
    }

    // window geometry lives in lastIpcObject, which only updates on refresh
    onOpenChanged: {
        if (open)
            Hyprland.refreshToplevels()
        else
            byHover = false
    }
    Timer {
        interval: 1000
        repeat: true
        running: root.open && !ghost.dragging
        onTriggered: Hyprland.refreshToplevels()
    }
    Timer {
        id: refreshSoon
        interval: 60
        onTriggered: {
            Hyprland.refreshToplevels()
            refreshLater.restart()
        }
    }
    Timer {
        // swaps land a frame or two later; catch the settled tape
        id: refreshLater
        interval: 350
        onTriggered: Hyprland.refreshToplevels()
    }

    // ── window ─────────────────────────────────────────────────────────
    property real progress: open ? 1 : 0
    Behavior on progress {
        NumberAnimation {
            duration: root.open ? Theme.slow : Theme.med
            easing.type: root.open ? Easing.OutCubic : Easing.InCubic
        }
    }

    // fixed full-screen surface (resizing it would wobble); input only on the rows
    visible: open || progress > 0
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-overview"
    WlrLayershell.keyboardFocus: open && !byHover ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: Region { item: stage }

    HyprlandFocusGrab {
        active: root.open && !root.byHover && root.visible
        windows: Ui.bar ? [root, Ui.bar] : [root]
        onCleared: Ui.close("overview")
    }

    // the shade: near-opaque behind the rows, fading to clear past them
    // (two pieces with fixed stops; stops bound to a ratio break while width is 0)
    Item {
        height: parent.height
        width: stage.x + stage.width + 420
        opacity: root.progress
        Behavior on width { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }

        Rectangle {
            id: body
            height: parent.height
            width: parent.width - 420
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#F2000000" }
                GradientStop { position: 1.0; color: "#D9000000" }
            }
        }
        Rectangle {
            x: body.width
            height: parent.height
            width: 420
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#D9000000" }
                GradientStop { position: 0.45; color: "#66000000" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    Item {
        id: stage
        x: Math.round(root.sideMargin - 24 * (1 - root.progress))
        y: Math.round(Theme.popupTop + Math.max(0, (root.availH - rows.implicitHeight) / 2))
        width: root.gutter + root.tapeW
        height: rows.implicitHeight
        opacity: root.progress
        Behavior on width { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }

        focus: true
        Keys.onEscapePressed: Ui.close("overview")
        HoverHandler { id: contentHover }

        Column {
            id: rows
            width: parent.width
            spacing: root.rowGap

            Repeater {
                id: rowsRep
                model: root.rowIds

                delegate: Item {
                    id: row
                    required property int modelData
                    required property int index
                    readonly property int wsId: modelData
                    readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
                    readonly property var mon: ws && ws.monitor ? ws.monitor : root.fallbackMonitor
                    readonly property bool focused: root.focusedId === wsId
                    readonly property bool onScreen: !!ws && !!ws.monitor && !!ws.monitor.activeWorkspace && ws.monitor.activeWorkspace.id === wsId
                    readonly property bool shared: !!ws && !!ws.monitor && ws.monitor.name.startsWith("SHARE-")
                    readonly property var wins: Hyprland.toplevels.values.filter(t => t.workspace && t.workspace.id === wsId)
                    readonly property real k: (root.rowH - root.inset * 2) / (mon ? mon.height : 1080)

                    // tape columns from window geometry: tiled windows sharing an x
                    // are one column (stacked by y); floating ones trail, one each
                    readonly property var cols: {
                        const tiled = [], floating = []
                        for (const t of wins) {
                            const ipc = t.lastIpcObject || {}
                            const at = ipc.at || [0, 0], sz = ipc.size || [1920, 1080]
                            if (ipc.floating) {
                                floating.push({ x0: at[0], w: sz[0], wins: [t], floating: true })
                                continue
                            }
                            const c = tiled.find(c => Math.abs(c.x0 - at[0]) < 8)
                            if (c) {
                                c.wins.push(t)
                                c.w = Math.max(c.w, sz[0])
                            } else {
                                tiled.push({ x0: at[0], w: sz[0], wins: [t], floating: false })
                            }
                        }
                        tiled.sort((a, b) => a.x0 - b.x0)
                        floating.sort((a, b) => a.x0 - b.x0)
                        for (const c of tiled)
                            c.wins.sort((a, b) => ((a.lastIpcObject || {}).at || [0, 0])[1] - ((b.lastIpcObject || {}).at || [0, 0])[1])
                        return tiled.concat(floating)
                    }
                    readonly property int tiledCount: cols.filter(c => !c.floating).length
                    readonly property real baseW: cols.reduce((w, c) => w + colW(c) + root.colGap, root.inset * 2 - root.colGap)

                    // drag state
                    readonly property int dragCol: ghost.dragging ? cols.findIndex(c => c.wins.includes(ghost.toplevel)) : -1
                    readonly property bool reordering: dragCol >= 0 && drop.containsDrag && !cols[dragCol].floating
                    readonly property bool incoming: ghost.dragging && dragCol < 0 && drop.containsDrag
                    property real hoverX: 0
                    readonly property int insertAt: {
                        if (!reordering)
                            return -1
                        // midpoints of the other columns, laid out without the dragged one
                        let x = root.inset, i = 0
                        for (let c = 0; c < tiledCount; c++) {
                            if (c === dragCol)
                                continue
                            const w = colW(cols[c])
                            if (hoverX < x + w / 2)
                                return i
                            x += w + root.colGap
                            i++
                        }
                        return i
                    }

                    function colW(c) {
                        return Math.max(18, Math.round(c.w * k))
                    }

                    // column index → x in the track, with the drag slot applied
                    readonly property var colX: {
                        const out = []
                        let x = root.inset
                        let pos = 0
                        for (let c = 0; c < cols.length; c++) {
                            if (reordering && c === dragCol)
                                continue
                            if (reordering && pos === insertAt)
                                x += colW(cols[dragCol]) + root.colGap
                            if (incoming && c === tiledCount)
                                x += ghost.width + root.colGap
                            out[c] = x
                            x += colW(cols[c]) + root.colGap
                            pos++
                        }
                        if (reordering && insertAt >= pos)
                            x += colW(cols[dragCol]) + root.colGap
                        if (reordering)
                            out[dragCol] = root.inset   // hidden while it rides the ghost
                        if (incoming && cols.length === tiledCount)
                            x += ghost.width + root.colGap
                        out.trackW = x - root.colGap + root.inset
                        return out
                    }

                    function place(t) {
                        const c = cols.findIndex(c => c.wins.includes(t))
                        if (c < 0)
                            return { x: 0, y: 0, w: 0, h: 0 }
                        const ipc = t.lastIpcObject || {}
                        const at = ipc.at || [0, 0], sz = ipc.size || [1920, 1080]
                        const col = cols[c]
                        const single = col.wins.length === 1 && !col.floating
                        return {
                            x: colX[c] ?? 0,
                            y: single ? root.inset : root.inset + Math.max(0, (at[1] - (mon ? mon.y : 0)) * k),
                            w: colW(col),
                            h: single ? root.rowH - root.inset * 2 : Math.max(10, sz[1] * k)
                        }
                    }

                    // columns overlapping the monitor right now
                    readonly property var visibleSpan: {
                        if (!onScreen || !mon)
                            return null
                        let lo = Infinity, hi = -Infinity
                        for (let c = 0; c < cols.length; c++) {
                            const col = cols[c]
                            if (col.floating || colX[c] === undefined)
                                continue
                            if (col.x0 + col.w > mon.x + 4 && col.x0 < mon.x + mon.width - 4) {
                                lo = Math.min(lo, colX[c])
                                hi = Math.max(hi, colX[c] + colW(col))
                            }
                        }
                        return lo < hi ? { x: lo, w: hi - lo } : null
                    }

                    width: rows.width
                    height: root.rowH

                    // rows arrive one after another
                    opacity: root.progress
                    transform: Translate { x: -14 * (1 - Math.min(1, Math.max(0, root.progress * 1.6 - row.index * 0.06))) }

                    // ── number ─────────────────────────────────────────
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.gutter - 14
                        horizontalAlignment: Text.AlignRight
                        text: row.wsId
                        font.family: Theme.font
                        font.pixelSize: 24
                        font.weight: row.focused ? Font.DemiBold : Font.Medium
                        renderType: Text.NativeRendering
                        color: row.focused ? Theme.peach
                             : numMouse.containsMouse ? Theme.text
                             : row.shared ? Theme.mint
                             : row.onScreen ? Theme.soft
                             : row.wins.length ? Theme.muted : "#3A3A3A"
                        Behavior on color { ColorAnimation { duration: Theme.fast } }

                        MouseArea {
                            id: numMouse
                            anchors.fill: parent
                            anchors.margins: -8
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.goTo(row.wsId)
                        }
                    }

                    // ── tape ───────────────────────────────────────────
                    Item {
                        id: track
                        x: root.gutter
                        width: parent.width - root.gutter
                        height: parent.height

                        // drop target wash
                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: row.incoming ? Theme.peachSoft : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.fast } }
                        }

                        Flickable {
                            id: flick
                            anchors.fill: parent
                            clip: true
                            interactive: false                       // window drags own the pointer; wheel scrolls
                            contentWidth: Math.max(width, row.colX.trackW)
                            contentHeight: height
                            Behavior on contentX { NumberAnimation { duration: Theme.med; easing.type: Easing.OutCubic } }

                            // first open: bring the on-screen part into view
                            Component.onCompleted: if (row.visibleSpan) contentX = Math.max(0, Math.min(contentWidth - width, row.visibleSpan.x - 40))

                            // what's on screen: a hairline under those columns
                            Rectangle {
                                visible: !!row.visibleSpan && !ghost.dragging
                                x: row.visibleSpan ? row.visibleSpan.x + 6 : 0
                                width: row.visibleSpan ? row.visibleSpan.w - 12 : 0
                                y: root.rowH - 2
                                height: 2
                                radius: 1
                                color: row.focused ? Theme.peach : "#8099FFE4"
                                Behavior on x { NumberAnimation { duration: Theme.med; easing.type: Easing.OutCubic } }
                                Behavior on width { NumberAnimation { duration: Theme.med; easing.type: Easing.OutCubic } }
                            }

                            Repeater {
                                model: row.wins

                                delegate: Item {
                                    id: tile
                                    required property var modelData
                                    readonly property var p: row.place(modelData)
                                    readonly property bool riding: ghost.dragging && (ghost.toplevel === modelData
                                        || (row.reordering && row.cols[row.dragCol].wins.includes(modelData)))

                                    x: p.x
                                    y: p.y
                                    width: p.w
                                    height: p.h
                                    z: (modelData.lastIpcObject || {}).floating ? 2 : 1
                                    opacity: riding ? 0 : 1
                                    Behavior on x { NumberAnimation { duration: Theme.med; easing.type: Easing.OutCubic } }
                                    Behavior on opacity { NumberAnimation { duration: Theme.fast } }

                                    WindowThumb {
                                        anchors.fill: parent
                                        toplevel: tile.modelData
                                        live: root.open
                                        radius: 8
                                        outline: false
                                        badge: Math.min(24, Math.round(root.rowH / 4))
                                        highlight: (tileMouse.containsMouse && !ghost.dragging) || Hyprland.activeToplevel === tile.modelData
                                    }

                                    MouseArea {
                                        id: tileMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: ghost.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                        drag.target: ghost
                                        drag.threshold: 5

                                        // released fires before clicked, so a drop would also
                                        // read as a click (and focus = switch workspace)
                                        property bool moved: false

                                        onPressed: {
                                            moved = false
                                            const q = tile.mapToItem(stage, 0, 0)
                                            ghost.x = q.x
                                            ghost.y = q.y
                                            ghost.width = tile.width
                                            ghost.height = tile.height
                                            ghost.toplevel = tile.modelData
                                        }
                                        onPositionChanged: if (drag.active && !ghost.dragging) {
                                            moved = true
                                            ghost.dragging = true
                                        }
                                        onReleased: {
                                            if (ghost.dragging) {
                                                ghost.droppedAt = Date.now()
                                                ghost.Drag.drop()
                                                fadeOut.restart()
                                            }
                                            ghost.dragging = false
                                        }
                                        onClicked: if (!moved) root.focusWindow(tile.modelData)
                                    }
                                }
                            }
                        }

                        WheelHandler {
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: e => {
                                const d = e.angleDelta.x !== 0 ? e.angleDelta.x : e.angleDelta.y
                                flick.contentX = Math.max(0, Math.min(flick.contentWidth - flick.width, flick.contentX - d))
                            }
                        }

                        DropArea {
                            id: drop
                            anchors.fill: parent
                            keys: ["window"]
                            onPositionChanged: d => row.hoverX = d.x + flick.contentX
                            onEntered: d => row.hoverX = d.x + flick.contentX
                            onDropped: d => {
                                const t = ghost.toplevel
                                if (!t)
                                    return
                                if (row.dragCol < 0)
                                    root.moveWindow(t, row.wsId)
                                else if (row.reordering)
                                    root.shiftColumn(row.cols, row.dragCol, row.insertAt)
                            }
                        }
                    }
                }
            }
        }

        // the dragged thumbnail, floating above every row
        Item {
            id: ghost
            property var toplevel: null
            property bool dragging: false
            property real droppedAt: 0
            // after a drop it lingers and fades while the real tile's capture starts
            visible: dragging || fadeOut.running
            z: 100
            scale: dragging ? 1.06 : 1
            Behavior on scale { NumberAnimation { duration: Theme.med; easing.type: Easing.OutBack } }

            Drag.active: dragging
            Drag.keys: ["window"]
            Drag.hotSpot.x: width / 2
            Drag.hotSpot.y: height / 2

            NumberAnimation on opacity {
                id: fadeOut
                running: false
                from: 1
                to: 0
                duration: 380
                easing.type: Easing.InCubic
                onStopped: ghost.opacity = 1
            }

            Rectangle {
                // soft lift shadow
                anchors.fill: parent
                anchors.margins: -4
                radius: 11
                color: "#80000000"
            }

            WindowThumb {
                anchors.fill: parent
                toplevel: ghost.toplevel
                live: ghost.dragging || fadeOut.running
                radius: 8
                highlight: true
            }
        }
    }
}
