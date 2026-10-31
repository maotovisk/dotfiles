import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common
import qs.components
import qs.services

// Bottom dock, macOS-style: magnifies under the pointer, dots for running
// windows, badges, bounce on launch. It gets out of the way of windows: when
// any window on the visible workspace overlaps the dock's resting area it
// slides off-screen, and comes back while the pointer rests on the bottom edge.
//
// The surface is a fixed full-width strip (resizing a layer surface wobbles);
// input is masked to the dock, or to a 2px edge strip while hidden.
PanelWindow {
    id: root

    // ── metrics ────────────────────────────────────────────────────────
    readonly property int iconSize: 44
    readonly property int slotW: 52                 // icon + gap
    readonly property int pad: 8                    // glass padding around the icons
    readonly property int inPad: pad - (slotW - iconSize) / 2
    readonly property int dockH: iconSize + pad * 2
    readonly property int bottomGap: Theme.edge
    readonly property int sepW: 13
    readonly property real maxMag: 1.55
    readonly property real range: slotW * 2.8       // magnification falloff radius

    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property var apps: Dock.apps
    // what the row shows: `apps`, rearranged live while a pin is dragged
    readonly property var shownApps: {
        if (!dragApp)
            return apps
        if (dropMode === "remove" || (dropMode === "" && removing))
            return apps.map(a => a.key === dragKey ? Object.assign({}, a, { collapsed: true }) : a)
        if (dragTarget < 0)
            return apps
        const list = apps.filter(a => a.key !== dragKey)
        list.splice(dragTarget, 0, Object.assign({}, dragApp, { pinned: true }))
        return list
    }
    readonly property int sepIndex: sepOf(shownApps)
    readonly property real restW: widthOf(shownApps)
    readonly property real restLeft: (width - restW) / 2
    // the same for the real list, so the drag target never feeds back into itself
    readonly property real baseLeft: (width - widthOf(apps)) / 2

    function sepOf(list) {
        const i = list.findIndex(a => !a.pinned)
        return i > 0 ? i : -1
    }
    function widthOf(list) {
        return list.filter(a => !a.collapsed).length * slotW + inPad * 2 + (sepOf(list) >= 0 ? sepW : 0)
    }
    // x of a slot's left edge in `list`, from the row's left edge
    function slotX(list, key) {
        const sep = sepOf(list)
        let x = inPad
        for (let i = 0; i < list.length; i++) {
            if (i === sep)
                x += sepW
            if (list[i].key === key)
                return x
            if (!list[i].collapsed)
                x += slotW
        }
        return x
    }

    // ── drag to reorder pins ───────────────────────────────────────────
    // Drag any icon: within the pinned group it moves the pin, a running
    // app dropped there gets pinned, and a pin dragged up off the dock is
    // removed. The Repeater reorders live, so input lives on the panel.
    property string dragKey: ""
    property real dragX: 0
    property real dragY: 0
    property string dropMode: ""                      // "" while dragging | move | stay | remove
    readonly property bool dragging: dragKey !== ""
    readonly property var dragApp: dragging ? apps.find(a => a.key === dragKey) ?? null : null
    readonly property bool removing: !!dragApp && dragApp.pinned && dragY < glass.y - 40
    // insertion index among pins, or -1: a running app left outside the pins
    readonly property int dragTarget: {
        if (!dragApp)
            return -1
        const pins = apps.filter(a => a.pinned && a.key !== dragKey).length
        const t = Math.floor((dragX - baseLeft - inPad) / slotW)
        if (!dragApp.pinned && t > pins)
            return -1
        return Math.max(0, Math.min(pins, t))
    }

    function startDrag(app, x, y) {
        land.stop()
        poof.stop()
        dropMode = ""
        dragKey = app.key
        ghost.opacity = 1
        ghost.scale = 1
        moveDrag(x, y)
    }

    function moveDrag(x, y) {
        dragX = x
        dragY = y
        ghost.x = x - ghost.width / 2
        ghost.y = y - ghost.height / 2
    }

    function endDrag() {
        if (!dragApp)
            return clearDrag()
        if (removing) {
            dropMode = "remove"
            Dock.togglePin(dragKey)
            poof.start()
            return
        }
        dropMode = dragTarget >= 0 ? "move" : "stay"
        if (dropMode === "move")
            Dock.movePin(dragKey, dragTarget)
        // fly into the slot it now owns (magnification is off while dragging)
        land.toX = restLeft + slotX(shownApps, dragKey) + (slotW - iconSize) / 2
        land.toY = root.height - bottomGap - dockH + pad
        land.start()
    }

    function clearDrag() {
        dragKey = ""
        dropMode = ""
    }

    // ── visibility: avoid windows ──────────────────────────────────────
    readonly property bool overlapped: {
        const m = monitor
        if (!m || !m.activeWorkspace || !screen)
            return false
        const ws = [m.activeWorkspace.id]
        const sp = m.lastIpcObject && m.lastIpcObject.specialWorkspace
        if (sp && sp.id)
            ws.push(sp.id)
        const zx = screen.x + restLeft, zw = restW
        const zy = screen.y + screen.height - bottomGap - dockH, zh = dockH + bottomGap
        for (const t of Hyprland.toplevels.values) {
            if (!t.workspace || !ws.includes(t.workspace.id))
                continue
            const o = t.lastIpcObject
            if (!o || !o.at || !o.size || o.hidden || o.mapped === false)
                continue
            const x = o.at[0], y = o.at[1], w = o.size[0], h = o.size[1]
            if (x < zx + zw && x + w > zx && y < zy + zh && y + h > zy)
                return true
        }
        return false
    }
    property bool revealed: false                    // pointer asked for it
    property bool forced: false                      // ipc toggle
    readonly property bool menuOpen: menuApp !== null
    readonly property bool shown: apps.length > 0 && (!overlapped || revealed || forced || menuOpen || dragging)
    readonly property bool hovered: pointer.containsMouse || pointer.pressed

    property real reveal: shown ? 1 : 0
    Behavior on reveal {
        NumberAnimation {
            duration: root.shown ? Theme.slow : Theme.med
            easing.type: root.shown ? Easing.OutCubic : Easing.InCubic
        }
    }

    Timer {
        id: revealDelay
        interval: 90
        onTriggered: if (root.hovered) root.revealed = true
    }
    Timer {
        id: hideDelay
        interval: 450
        onTriggered: if (!root.hovered && !root.menuOpen && !root.dragging) root.revealed = false
    }
    onDraggingChanged: if (!dragging && !hovered) hideDelay.restart()
    onHoveredChanged: {
        if (hovered) {
            hideDelay.stop()
            if (!shown) revealDelay.restart()
            else revealed = true
        } else {
            revealDelay.stop()
            hideDelay.restart()
        }
    }
    onMenuOpenChanged: if (!menuOpen && !hovered) hideDelay.restart()

    // window geometry lives in lastIpcObject, refreshed on Hyprland events
    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            if (ev.name === "activespecial" || ev.name === "focusedmon")
                Hyprland.refreshMonitors()
            refresh.restart()
        }
    }
    Timer {
        id: refresh
        interval: 40
        onTriggered: {
            Hyprland.refreshToplevels()
            settle.restart()
        }
    }
    Timer {
        // windows animate into place; catch where they land
        id: settle
        interval: 450
        onTriggered: Hyprland.refreshToplevels()
    }
    Timer {
        // floating drags and resizes emit no events
        interval: 1500
        repeat: true
        running: true
        onTriggered: Hyprland.refreshToplevels()
    }
    Component.onCompleted: {
        Hyprland.refreshMonitors()
        Hyprland.refreshToplevels()
    }

    // ── surface ────────────────────────────────────────────────────────
    anchors { bottom: true; left: true; right: true }
    implicitHeight: 160
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-dock"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: Region {
        item: root.reveal > 0.5 ? hit : trigger
        Region { item: root.menuOpen ? menu : null }
    }

    HyprlandFocusGrab {
        active: root.menuOpen
        windows: [root]
        onCleared: root.menuApp = null
    }

    Item {
        id: trigger
        x: root.restLeft
        y: root.height - 2
        width: root.restW
        height: 2
    }

    // ── dock ───────────────────────────────────────────────────────────
    Item {
        id: body
        anchors.fill: parent

        // pointer x, kept after leaving so the shrink animates from where it was
        property real px: 0

        property real magOn: root.hovered && root.reveal > 0.5 && !root.menuOpen && !root.dragging ? 1 : 0
        Behavior on magOn { NumberAnimation { duration: Theme.med; easing.type: Easing.OutCubic } }

        readonly property real lift: (1 - root.reveal) * (root.dockH + root.bottomGap + 8)

        function magFor(i) {
            const c = root.restLeft + root.inPad + i * root.slotW + root.slotW / 2
                + (root.sepIndex >= 0 && i >= root.sepIndex ? root.sepW : 0)
            const d = Math.abs(px - c)
            if (d >= root.range)
                return 1
            return 1 + (root.maxMag - 1) * (1 + Math.cos(Math.PI * d / root.range)) / 2 * magOn
        }

        Glass {
            id: glass
            width: row.width + root.inPad * 2
            height: root.dockH
            x: Math.round((root.width - width) / 2)
            y: root.height - root.bottomGap - root.dockH + body.lift
            radius: 16
            lit: root.hovered || root.menuOpen
            opacity: Math.min(1, root.reveal * 1.6)
        }

        // the hit area: glass plus the room magnified icons grow into
        Item {
            id: hit
            x: glass.x
            width: glass.width
            y: glass.y - root.iconSize * (root.maxMag - 1) - 4
            height: root.height - y
        }

        Row {
            id: row
            x: glass.x + root.inPad
            height: root.height - root.bottomGap
            y: glass.y + root.dockH - height
            opacity: glass.opacity

            // neighbours slide aside while a pin is dragged (only then:
            // magnification also moves them, and that must not lag)
            move: Transition {
                enabled: root.dragging
                NumberAnimation { properties: "x"; duration: Theme.med; easing.type: Easing.OutCubic }
            }

            Repeater {
                id: rep
                model: ScriptModel {
                    values: root.shownApps
                    objectProp: "key"
                }
                delegate: DockIcon {
                    mag: body.magFor(index)
                    baseIcon: root.iconSize
                    baseSlot: root.slotW
                    pad: root.pad
                    sepBefore: index === root.sepIndex
                    sepW: root.sepW
                    tipAllowed: !root.menuOpen && !root.dragging
                    hovered: pointer.containsMouse && pointer.hoverKey === modelData.key
                    pressed: pointer.pressed && !pointer.moved && pointer.pressKey === modelData.key
                    ghosted: root.dragKey === modelData.key
                }
            }
        }

        // all pointer input: hover, clicks, drags. Full width so its
        // coordinates are window coordinates (the mask trims it to the dock).
        MouseArea {
            id: pointer

            property string hoverKey: ""
            property string pressKey: ""
            property point pressPos
            property bool moved: false

            // the slot under window x, by the row's real (magnified) geometry
            function slotAt(x) {
                const it = row.childAt(x - row.x, row.height - 2)
                return it && it.app ? it : null
            }

            x: 0
            width: root.width
            y: hit.y
            height: root.height - y
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            cursorShape: root.dragging ? Qt.ClosedHandCursor : hoverKey !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor

            onPositionChanged: m => {
                if (!root.dragging) {
                    body.px = m.x
                    const s = slotAt(m.x)
                    hoverKey = s ? s.app.key : ""
                }
                if (!pressed || pressKey === "" || !(pressedButtons & Qt.LeftButton))
                    return
                if (!moved && Math.hypot(m.x - pressPos.x, m.y - pressPos.y) > 6) {
                    moved = true
                    const s = root.apps.find(a => a.key === pressKey)
                    if (s)
                        root.startDrag(s, m.x, m.y + y)
                }
                if (moved && root.dragging)
                    root.moveDrag(m.x, m.y + y)
            }
            onExited: if (!pressed) hoverKey = ""
            onPressed: m => {
                moved = false
                pressPos = Qt.point(m.x, m.y)
                const s = slotAt(m.x)
                pressKey = s ? s.app.key : ""
            }
            onReleased: if (moved && root.dragging) root.endDrag()
            onCanceled: if (moved && root.dragging) root.endDrag()
            onClicked: m => {
                if (moved)
                    return
                const s = slotAt(m.x)
                if (!s)
                    return
                if (m.button === Qt.RightButton) {
                    root.menuApp = s.app
                    root.menuX = s.mapToItem(null, s.centerX, 0).x
                } else if (m.button === Qt.MiddleButton) {
                    Dock.launch(s.app)
                } else {
                    Dock.activate(s.app)
                }
            }
        }
    }

    // the dragged icon follows the pointer; flies into its slot on drop,
    // or shrinks away when a pin is dragged off the dock
    Item {
        id: ghost
        visible: root.dragging
        width: root.iconSize
        height: root.iconSize

        Image {
            anchors.fill: parent
            sourceSize: Qt.size(128, 128)
            smooth: true
            mipmap: true
            source: root.dragApp ? root.dragApp.icon : ""
            scale: root.dropMode !== "" ? 1 : root.removing ? 0.8 : 1.12
            opacity: root.removing && root.dropMode === "" ? 0.6 : 1
            Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: Theme.fast } }
        }

        // "remove" hint while a pin hovers above the dock
        Rectangle {
            x: parent.width - width / 2 - 4
            y: -height / 2 + 4
            width: 18
            height: 18
            radius: 9
            color: Theme.red
            border.width: 1.5
            border.color: Theme.bg
            scale: root.removing && root.dropMode === "" ? 1 : 0
            Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutBack } }

            Icon {
                anchors.centerIn: parent
                name: "x"
                size: 11
                color: Theme.onAccent
            }
        }
    }

    ParallelAnimation {
        id: land
        property real toX: 0
        property real toY: 0
        NumberAnimation { target: ghost; property: "x"; to: land.toX; duration: Theme.med; easing.type: Easing.OutCubic }
        NumberAnimation { target: ghost; property: "y"; to: land.toY; duration: Theme.med; easing.type: Easing.OutCubic }
        onFinished: root.clearDrag()
    }

    ParallelAnimation {
        id: poof
        NumberAnimation { target: ghost; property: "opacity"; to: 0; duration: Theme.med; easing.type: Easing.OutCubic }
        NumberAnimation { target: ghost; property: "scale"; to: 0.4; duration: Theme.med; easing.type: Easing.InCubic }
        onFinished: root.clearDrag()
    }

    // ── context menu ───────────────────────────────────────────────────
    property var menuApp: null
    property real menuX: 0
    readonly property var menuItems: {
        const a = menuApp
        if (!a)
            return []
        const items = a.windows.slice(0, 8).map(t => ({
            label: t.title || a.name,
            icon: "app-window",
            run: () => Dock.focus(t)
        }))
        if (items.length > 0)
            items.push({ sep: true })
        items.push({ label: "New Window", icon: "plus", run: () => Dock.launch(a) })
        items.push({
            label: Dock.pinned.includes(a.key) ? "Remove from Dock" : "Keep in Dock",
            icon: Dock.pinned.includes(a.key) ? "x" : "check",
            run: () => Dock.togglePin(a.key)
        })
        if (a.windows.length > 0)
            items.push({
                label: a.windows.length > 1 ? `Close ${a.windows.length} Windows` : "Close",
                icon: "trash-2",
                danger: true,
                run: () => Dock.close(a)
            })
        return items
    }

    Item {
        id: menu
        visible: root.menuOpen || opacity > 0
        opacity: root.menuOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.fast } }
        width: 240
        height: col.implicitHeight + 12
        x: Math.round(Math.max(Theme.edge, Math.min(root.width - width - Theme.edge, root.menuX - width / 2)))
        y: Math.round(glass.y - height - 12 + (root.menuOpen ? 0 : 6))
        Behavior on y { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }

        Glass {
            anchors.fill: parent
            radius: 12
            color: Theme.panel
            lit: true
        }

        Column {
            id: col
            x: 6
            y: 6
            width: parent.width - 12

            Label {
                width: parent.width
                height: 24
                leftPadding: 8
                text: root.menuApp ? root.menuApp.name : ""
                color: Theme.muted
                font.pixelSize: Theme.fsXs
                elide: Text.ElideRight
            }

            Repeater {
                model: root.menuItems
                delegate: Item {
                    id: entry
                    required property var modelData
                    width: col.width
                    height: modelData.sep ? 9 : 28

                    Rectangle {
                        visible: !!entry.modelData.sep
                        anchors.verticalCenter: parent.verticalCenter
                        x: 6
                        width: parent.width - 12
                        height: 1
                        color: Theme.divider
                    }

                    Rectangle {
                        visible: !entry.modelData.sep
                        anchors.fill: parent
                        radius: 7
                        color: m.pressed ? Theme.press : m.containsMouse ? (entry.modelData.danger ? Theme.redSoft : Theme.hover) : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.fast } }
                    }

                    Icon {
                        visible: !entry.modelData.sep
                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        name: entry.modelData.icon ?? ""
                        size: 13
                        color: entry.modelData.danger ? Theme.red : Theme.muted
                    }

                    Label {
                        visible: !entry.modelData.sep
                        x: 30
                        width: parent.width - 38
                        anchors.verticalCenter: parent.verticalCenter
                        text: entry.modelData.label ?? ""
                        color: entry.modelData.danger ? Theme.red : Theme.text
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: m
                        anchors.fill: parent
                        enabled: !entry.modelData.sep
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const run = entry.modelData.run
                            root.menuApp = null
                            run()
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "dock"

        function toggle(): void { root.forced = !root.forced }
        function pin(): void { root.forced = true }
        function unpin(): void { root.forced = false; root.revealed = false }
        function state(): string {
            return JSON.stringify({ shown: root.shown, overlapped: root.overlapped, revealed: root.revealed, forced: root.forced, apps: root.apps.map(a => a.key + ":" + a.windows.length) })
        }
    }
}
