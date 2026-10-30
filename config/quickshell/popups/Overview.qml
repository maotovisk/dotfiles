import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common
import qs.components
import qs.services

// Workspace overview, opened by hovering the workspace pills. Each workspace
// is a mini monitor (its wallpaper, dimmed) with live window thumbnails at
// their real positions. Drag a thumbnail onto another workspace to move the
// window there; click one to focus it; click empty space to switch.
Popup {
    id: root

    readonly property real s: 0.1                      // monitor → thumbnail scale
    readonly property int gap: 10
    readonly property int count: Math.max(5, ...Hyprland.workspaces.values.filter(w => w.id > 0).map(w => w.id),
                                          Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1)
    readonly property var fallbackMonitor: Hyprland.monitors.values.find(m => m.name === "DP-2") ?? Hyprland.monitors.values[0]
    property var wallpapers: ({})                       // monitor name → file path
    property bool byHover: false                        // hover-opened: hover closes it, no focus grab

    open: Ui.popup === "overview"
    onDismissed: Ui.close("overview")
    ns: "quickshell-overview"
    align: "left"
    grab: !byHover                                      // hover-opened never steals the keyboard
    padding: 12
    cardWidth: count * (1920 * s) + (count - 1) * gap + padding * 2

    function addr(t) {
        return "address:0x" + String(t.address).replace(/^0x/, "")
    }

    function moveWindow(t, wsId) {
        Hyprland.dispatch(`hl.dsp.window.move({ workspace = "${wsId}", window = "${addr(t)}", silent = true })`)
        refreshSoon.restart()
    }

    function focusWindow(t) {
        Hyprland.dispatch(`hl.dsp.focus({ window = "${addr(t)}" })`)
        Ui.close("overview")
    }

    function goTo(wsId) {
        Hyprland.dispatch(`hl.dsp.focus({ workspace = "${wsId}" })`)
        Ui.close("overview")
    }

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
        // grace period so the pointer can travel from the pills into the card
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
        interval: 120
        onTriggered: Hyprland.refreshToplevels()
    }

    // wallpapers straight from hyprpaper's config
    FileView {
        path: Quickshell.env("HOME") + "/.config/hypr/hyprpaper.conf"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const out = {}
            const re = /wallpaper\s*\{([^}]*)\}/g
            let m
            while ((m = re.exec(text())) !== null) {
                const mon = (m[1].match(/monitor\s*=\s*(\S+)/) || [])[1]
                const path = (m[1].match(/path\s*=\s*(.+)/) || [])[1]
                if (mon && path)
                    out[mon] = path.trim().replace(/^~/, Quickshell.env("HOME"))
            }
            root.wallpapers = out
        }
    }

    // ── content ────────────────────────────────────────────────────────
    Item {
        id: stage
        width: parent.width
        height: strip.height

        Row {
            id: strip
            spacing: root.gap

            Repeater {
                model: root.count

                delegate: Column {
                    id: wsCol
                    required property int index
                    readonly property int wsId: index + 1
                    readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
                    readonly property var mon: ws && ws.monitor ? ws.monitor : root.fallbackMonitor
                    readonly property bool focused: !!Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
                    readonly property var windows: Hyprland.toplevels.values.filter(t => t.workspace && t.workspace.id === wsId)
                    spacing: 6

                    // header: number · monitor · window count
                    Row {
                        spacing: 6
                        leftPadding: 2
                        Label {
                            text: wsCol.wsId
                            color: wsCol.focused ? Theme.peach : Theme.soft
                            font.weight: Font.DemiBold
                        }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: (wsCol.ws && wsCol.ws.monitor ? wsCol.ws.monitor.name : "vazio")
                                + (wsCol.windows.length ? "  ·  " + wsCol.windows.length + (wsCol.windows.length > 1 ? " janelas" : " janela") : "")
                            color: Theme.dim
                            font.pixelSize: Theme.fsXs
                        }
                    }

                    // the mini monitor
                    ClippingRectangle {
                        id: screen
                        width: 1920 * root.s
                        height: 1080 * root.s
                        radius: 8
                        color: "#0B0B0B"

                        Image {
                            anchors.fill: parent
                            source: root.wallpapers[wsCol.mon ? wsCol.mon.name : ""] ? "file://" + root.wallpapers[wsCol.mon.name] : ""
                            sourceSize: Qt.size(width * 2, height * 2)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            opacity: wsCol.focused ? 0.55 : 0.32
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.goTo(wsCol.wsId)
                        }

                        Repeater {
                            model: wsCol.windows

                            delegate: Item {
                                id: tile
                                required property var modelData
                                readonly property var ipc: modelData.lastIpcObject || {}
                                readonly property var at: ipc.at || [0, 0]
                                readonly property var size: ipc.size || [1920, 1080]
                                readonly property bool lifted: ghost.dragging && ghost.toplevel === modelData

                                x: (at[0] - (wsCol.mon ? wsCol.mon.x : 0)) * root.s
                                y: (at[1] - (wsCol.mon ? wsCol.mon.y : 0)) * root.s
                                width: Math.max(12, size[0] * root.s)
                                height: Math.max(8, size[1] * root.s)
                                z: ipc.floating ? 2 : 1
                                opacity: lifted ? 0.3 : 1
                                Behavior on opacity { NumberAnimation { duration: Theme.fast } }

                                Thumb {
                                    anchors.fill: parent
                                    toplevel: tile.modelData
                                    live: root.open
                                    highlight: tileMouse.containsMouse && !ghost.dragging
                                }

                                MouseArea {
                                    id: tileMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: ghost.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                    drag.target: ghost
                                    drag.threshold: 4

                                    onPressed: {
                                        const p = tile.mapToItem(stage, 0, 0)
                                        ghost.x = p.x
                                        ghost.y = p.y
                                        ghost.width = tile.width
                                        ghost.height = tile.height
                                        ghost.toplevel = tile.modelData
                                    }
                                    onPositionChanged: if (drag.active && !ghost.dragging) ghost.dragging = true
                                    onReleased: {
                                        if (ghost.dragging)
                                            ghost.Drag.drop()
                                        ghost.dragging = false
                                    }
                                    onClicked: if (!ghost.dragging) root.focusWindow(tile.modelData)
                                }
                            }
                        }

                        // drop target: the whole mini monitor
                        DropArea {
                            id: drop
                            anchors.fill: parent
                            keys: ["window"]
                            onDropped: d => {
                                if (ghost.toplevel && (!ghost.toplevel.workspace || ghost.toplevel.workspace.id !== wsCol.wsId))
                                    root.moveWindow(ghost.toplevel, wsCol.wsId)
                            }
                        }

                        // frame on top: focus / drop highlight
                        Rectangle {
                            anchors.fill: parent
                            radius: 8                   // ClippingRectangle children sit in its content item
                            color: drop.containsDrag ? Theme.peachSoft : "transparent"
                            border.width: drop.containsDrag || wsCol.focused ? 2 : 1
                            border.color: drop.containsDrag ? Theme.peach : wsCol.focused ? "#99FFC799" : Theme.border
                            z: 5
                            Behavior on color { ColorAnimation { duration: Theme.fast } }
                        }
                    }
                }
            }
        }

        // the dragged thumbnail, floating above every workspace
        Item {
            id: ghost
            property var toplevel: null
            property bool dragging: false
            visible: dragging
            z: 100
            scale: dragging ? 1.06 : 1
            Behavior on scale { NumberAnimation { duration: Theme.med; easing.type: Easing.OutBack } }

            Drag.active: dragging
            Drag.keys: ["window"]
            Drag.hotSpot.x: width / 2
            Drag.hotSpot.y: height / 2

            Rectangle {
                // soft lift shadow
                anchors.fill: parent
                anchors.margins: -3
                radius: 7
                color: "#66000000"
            }

            Thumb {
                anchors.fill: parent
                toplevel: ghost.toplevel
                live: ghost.dragging
                highlight: true
            }
        }
    }

    component Thumb: Item {
        id: thumb
        property var toplevel: null
        property bool live: false
        property bool highlight: false
        readonly property var ipc: toplevel ? toplevel.lastIpcObject || {} : {}

        ClippingRectangle {
            anchors.fill: parent
            radius: 4
            color: "#1A1A1A"

            ScreencopyView {
                id: cap
                anchors.fill: parent
                captureSource: thumb.live && thumb.toplevel ? thumb.toplevel.wayland : null
                live: thumb.live
                constraintSize: Qt.size(thumb.width * 2, thumb.height * 2)
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 4
            color: "transparent"
            border.width: 1
            border.color: thumb.highlight ? Theme.peach : "#30FFFFFF"
            Behavior on border.color { ColorAnimation { duration: Theme.fast } }
        }

        // app badge: always there, so tiny/unsupported captures stay recognisable
        Rectangle {
            anchors.centerIn: parent
            width: 22
            height: 22
            radius: 11
            color: "#C0101010"
            visible: thumb.width > 26 && thumb.height > 26
            IconImage {
                anchors.centerIn: parent
                implicitSize: 14
                source: thumb.ipc.class ? Ui.icon(DesktopEntries.heuristicLookup(thumb.ipc.class)?.icon ?? thumb.ipc.class.toLowerCase()) : ""
            }
        }
    }
}
