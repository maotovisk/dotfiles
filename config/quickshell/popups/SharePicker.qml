import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common
import qs.components
import qs.services

// Screen-share picker for xdg-desktop-portal-hyprland. xdph runs
// ~/.local/bin/qs-share-picker, which calls pick() over IPC and blocks on a
// FIFO until we write "<flags>/<kind>:<id>" (or nothing, to cancel).
// Previews are composed from wallpaper + live window captures, never from the
// output itself — capturing the screen this overlay sits on would mirror it.
PanelWindow {
    id: root

    property bool open: Ui.popup === "share"
    property string answerPath: ""                   // FIFO of the pending request
    property var shareable: []                       // xdph's window list: [{ handle, cls, name, addr }]
    property bool remember: false                    // restore token ("r" flag)
    property string tab: "screen"                    // screen | window | workspace
    property int cursor: 0

    readonly property int cols: tab === "screen" ? 2 : 3     // screens get bigger previews
    readonly property int gap: 12
    readonly property int cardW: 940
    readonly property int pad: 16
    readonly property real cellW: Math.floor((cardW - pad * 2 - gap * (cols - 1)) / cols)
    readonly property real previewH: Math.round(cellW * 9 / 16)

    // ── what can be shared ─────────────────────────────────────────────
    readonly property var monitors: Hyprland.monitors.values
        .filter(m => !m.name.startsWith("SHARE-"))
        .sort((a, b) => a.x - b.x)
    readonly property var screenItems: monitors.map(m => ({
        kind: "screen", id: m.name, mon: m, ws: m.activeWorkspace,
        caption: m.name, sub: `${m.width}×${m.height}` + (m.focused ? "  ·  em foco" : "")
    }))
    readonly property var windowItems: shareable.map(w => {
        const t = Hyprland.toplevels.values.find(t => w.addr !== 0 && Number("0x" + String(t.address).replace(/^0x/, "")) === w.addr)
               ?? Hyprland.toplevels.values.find(t => (t.lastIpcObject || {}).class === w.cls && t.title === w.name)
               ?? null
        return {
            kind: "window", id: String(w.handle), toplevel: t, cls: w.cls,
            caption: w.name || w.cls, sub: w.cls + (t && t.workspace ? `  ·  workspace ${t.workspace.id}` : ""),
            wsId: t && t.workspace ? t.workspace.id : 999
        }
    }).sort((a, b) => a.wsId - b.wsId)
    readonly property var workspaceItems: Hyprland.workspaces.values
        .filter(w => w.id > 0 && w.toplevels.values.length > 0 && !(w.monitor && w.monitor.name.startsWith("SHARE-")))
        .sort((a, b) => a.id - b.id)
        .map(w => ({
            kind: "workspace", id: String(w.id), ws: w, mon: w.monitor,
            caption: "Workspace " + w.id,
            sub: (w.monitor ? w.monitor.name + "  ·  " : "") + w.toplevels.values.length + (w.toplevels.values.length > 1 ? " janelas" : " janela")
        }))
    readonly property var items: tab === "screen" ? screenItems : tab === "window" ? windowItems : workspaceItems
    readonly property var current: items[Math.min(cursor, items.length - 1)] ?? null

    // ── IPC ────────────────────────────────────────────────────────────
    IpcHandler {
        target: "sharepicker"

        function pick(answer: string, windows: string, allowToken: string): void {
            if (root.answerPath !== "")
                root.reply("")                       // a newer request replaces a pending one
            root.answerPath = answer
            root.shareable = root.parseList(windows)
            root.remember = allowToken === "1"
            root.tab = "screen"
            root.cursor = Math.max(0, root.monitors.findIndex(m => m.focused))
            Hyprland.refreshToplevels()
            Ui.popup = "share"
        }
        function cancel(): void { root.reply("") }
        function tab(name: string): void { root.setTab(name) }
    }

    // "<handle>[HC>]<class>[HT>]<title>[HE>]<window id>[HA>]…"
    function parseList(s) {
        return s.split("[HA>]").filter(e => e.includes("[HC>]")).map(e => {
            const [handle, rest] = e.split("[HC>]")
            const [cls, rest2] = rest.split("[HT>]")
            const [name, addr] = rest2.split("[HE>]")
            return { handle: Number(handle), cls, name, addr: Number(addr) || 0 }
        })
    }

    function reply(sel) {
        if (answerPath === "")
            return
        // detached: must outlive this object (hot reload while a request is pending)
        Quickshell.execDetached(["sh", "-c", 'printf %s "$1" > "$2"', "sh", sel, answerPath])
        answerPath = ""
        Ui.close("share")
    }

    function share() {
        if (current)
            reply((remember ? "r" : "") + "/" + current.kind + ":" + current.id)
    }

    function setTab(t) {
        if (tab === t)
            return
        tab = t
        cursor = 0
        grid.contentY = 0
    }

    function move(d) {
        if (items.length === 0)
            return
        cursor = Math.max(0, Math.min(items.length - 1, cursor + d))
        // keep the cursor's row in view
        const rowY = Math.floor(cursor / cols) * (cellH + gap)
        if (rowY < grid.contentY)
            grid.contentY = rowY
        else if (rowY + cellH > grid.contentY + grid.height)
            grid.contentY = rowY + cellH - grid.height
    }

    readonly property real cellH: previewH + 44

    Component.onDestruction: reply("")

    // the picker went away some other way (another popup, shell IPC): don't leave xdph hanging
    onOpenChanged: if (!open && answerPath !== "") reply("")

    Timer {
        interval: 1000
        repeat: true
        running: root.open
        onTriggered: Hyprland.refreshToplevels()
    }

    // ── window ─────────────────────────────────────────────────────────
    property real progress: open ? 1 : 0
    Behavior on progress {
        NumberAnimation {
            duration: root.open ? Theme.med : Theme.fast
            easing.type: root.open ? Easing.OutCubic : Easing.InCubic
        }
    }

    visible: open || progress > 0
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-share"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // scrim: below ignore_alpha, so only the card gets blurred
    Rectangle {
        anchors.fill: parent
        color: "#73000000"
        opacity: root.progress
        MouseArea {
            anchors.fill: parent
            onClicked: root.reply("")
        }
    }

    Item {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round((parent.height - height) / 2 - 10 * (1 - root.progress))
        width: root.cardW
        height: Math.round(body.implicitHeight + root.pad * 2)
        opacity: root.progress
        scale: 0.97 + 0.03 * root.progress

        focus: true
        Keys.onPressed: e => {
            const k = e.key
            if (k === Qt.Key_Escape) root.reply("")
            else if (k === Qt.Key_Return || k === Qt.Key_Enter) root.share()
            else if (k === Qt.Key_Left || k === Qt.Key_H) root.move(-1)
            else if (k === Qt.Key_Right || k === Qt.Key_L) root.move(1)
            else if (k === Qt.Key_Up || k === Qt.Key_K) root.move(-root.cols)
            else if (k === Qt.Key_Down || k === Qt.Key_J) root.move(root.cols)
            else if (k === Qt.Key_1) root.setTab("screen")
            else if (k === Qt.Key_2) root.setTab("window")
            else if (k === Qt.Key_3) root.setTab("workspace")
            else if (k === Qt.Key_Tab || k === Qt.Key_Backtab) {
                const order = ["screen", "window", "workspace"]
                const i = order.indexOf(root.tab) + (k === Qt.Key_Backtab || e.modifiers & Qt.ShiftModifier ? 2 : 1)
                root.setTab(order[i % 3])
            }
            else if (k === Qt.Key_R) root.remember = !root.remember
            else return
            e.accepted = true
        }

        // swallow clicks so they don't reach the scrim
        MouseArea { anchors.fill: parent }

        Glass {
            anchors.fill: parent
            radius: Theme.popupR + 2
            color: Theme.panel
        }

        Column {
            id: body
            x: root.pad
            y: root.pad
            width: root.cardW - root.pad * 2
            spacing: 14

            // header
            Item {
                width: parent.width
                height: 34

                Rectangle {
                    id: badge
                    width: 34
                    height: 34
                    radius: 10
                    color: Theme.peachSoft
                    Icon {
                        anchors.centerIn: parent
                        name: "screen-share"
                        size: 17
                        color: Theme.peach
                    }
                }
                Column {
                    anchors.left: badge.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Label {
                        text: "Compartilhar tela"
                        color: Theme.text
                        font.pixelSize: Theme.fsLg
                        font.weight: Font.DemiBold
                    }
                    Label {
                        text: "Um app pediu para gravar ou transmitir. Escolha o que ele vai ver."
                        color: Theme.muted
                        font.pixelSize: Theme.fsXs
                    }
                }
                Segmented {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 390
                    model: [
                        { key: "screen", label: "Telas  " + root.screenItems.length, icon: "monitor" },
                        { key: "window", label: "Janelas  " + root.windowItems.length, icon: "app-window" },
                        { key: "workspace", label: "Workspaces  " + root.workspaceItems.length, icon: "layout-grid" }
                    ]
                    current: root.tab
                    onSelected: k => root.setTab(k)
                }
            }

            // grid of previews
            Flickable {
                id: grid
                width: parent.width
                // fixed: two rows of the 3-column grid and a peek of the third,
                // so switching tabs never resizes (and re-centres) the card
                height: Math.round((Math.floor((root.cardW - root.pad * 2 - root.gap * 2) / 3) * 9 / 16 + 44) * 2.35 + root.gap * 2)
                contentHeight: Math.max(cells.implicitHeight, root.cellH)
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Behavior on contentY { NumberAnimation { duration: Theme.med; easing.type: Easing.OutCubic } }

                Grid {
                    id: cells
                    columns: root.cols
                    spacing: root.gap

                    Repeater {
                        model: root.items

                        delegate: Item {
                            id: cell
                            required property var modelData
                            required property int index
                            readonly property bool selected: index === root.cursor
                            readonly property bool hot: hit.containsMouse

                            width: root.cellW
                            height: root.cellH

                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                color: cell.selected ? Theme.peachSoft : cell.hot ? Theme.hover : "transparent"
                                border.width: cell.selected ? 1 : 0
                                border.color: "#66FFC799"
                                Behavior on color { ColorAnimation { duration: Theme.fast } }
                            }

                            // preview
                            Item {
                                id: preview
                                x: 5
                                y: 5
                                width: parent.width - 10
                                height: root.previewH - 10
                                scale: cell.hot && !cell.selected ? 1.015 : 1
                                Behavior on scale { NumberAnimation { duration: Theme.med; easing.type: Easing.OutCubic } }

                                MiniWorkspace {
                                    visible: cell.modelData.kind !== "window"
                                    anchors.fill: parent
                                    workspace: cell.modelData.ws ?? null
                                    monitor: cell.modelData.mon ?? null
                                    live: root.open && visible
                                    dim: cell.selected ? 0.6 : 0.4
                                }

                                // window: centred, aspect kept, over a faint wallpaper
                                ClippingRectangle {
                                    visible: cell.modelData.kind === "window"
                                    anchors.fill: parent
                                    radius: 8
                                    color: "#0E0E0E"

                                    Image {
                                        anchors.fill: parent
                                        source: visible ? Wallpapers.url("DP-2") : ""
                                        sourceSize: Qt.size(width, height)
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        opacity: 0.16
                                    }

                                    WindowThumb {
                                        readonly property var sz: (cell.modelData.toplevel?.lastIpcObject ?? {}).size ?? [16, 9]
                                        readonly property real k: Math.min((parent.width - 24) / sz[0], (parent.height - 20) / sz[1])
                                        anchors.centerIn: parent
                                        width: Math.round(sz[0] * k)
                                        height: Math.round(sz[1] * k)
                                        toplevel: cell.modelData.toplevel ?? null
                                        live: root.open && parent.visible
                                        radius: 6
                                        badge: 0
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 8
                                    color: "transparent"
                                    border.width: cell.selected ? 2 : 1
                                    border.color: cell.selected ? Theme.peach : Theme.border
                                }
                            }

                            // caption
                            Row {
                                anchors.top: preview.bottom
                                anchors.topMargin: 8
                                x: 9
                                width: parent.width - 18
                                spacing: 8

                                Item {
                                    width: 24
                                    height: 24
                                    anchors.verticalCenter: parent.verticalCenter
                                    Icon {
                                        visible: cell.modelData.kind !== "window"
                                        anchors.centerIn: parent
                                        name: cell.modelData.kind === "screen" ? "monitor" : "layout-grid"
                                        size: 15
                                        color: cell.selected ? Theme.peach : Theme.muted
                                    }
                                    IconImage {
                                        visible: cell.modelData.kind === "window"
                                        anchors.centerIn: parent
                                        implicitSize: 20
                                        source: cell.modelData.kind === "window" ? Ui.appIcon(cell.modelData.cls) : ""
                                    }
                                }
                                Column {
                                    width: parent.width - 32
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 1
                                    Label {
                                        width: parent.width
                                        text: cell.modelData.caption
                                        color: cell.selected ? Theme.text : Theme.soft
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }
                                    Label {
                                        width: parent.width
                                        text: cell.modelData.sub
                                        color: Theme.dim
                                        font.pixelSize: Theme.fsXs
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            MouseArea {
                                id: hit
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.cursor = cell.index
                                onDoubleClicked: {
                                    root.cursor = cell.index
                                    root.share()
                                }
                            }
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    visible: root.items.length === 0
                    text: root.tab === "window" ? "Nenhuma janela disponível" : "Nada por aqui"
                    color: Theme.dim
                }
            }

            // what this kind of share means
            Rectangle {
                width: parent.width
                height: 32
                radius: 9
                color: Theme.well
                Row {
                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: root.tab === "workspace" ? "eye-off" : root.tab === "window" ? "app-window" : "monitor"
                        size: 13
                        color: root.tab === "workspace" ? Theme.peach : Theme.muted
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.tab === "screen" ? "Tudo o que aparece no monitor, inclusive notificações e a barra."
                            : root.tab === "window" ? "Só a janela escolhida — o que estiver por cima dela não aparece."
                            : "A workspace vai para uma tela virtual enquanto é compartilhada e some da sua tela. O ícone na barra traz ela de volta."
                        color: Theme.muted
                        font.pixelSize: Theme.fsXs
                    }
                }
            }

            // footer
            Item {
                width: parent.width
                height: 28

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Toggle {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: root.remember
                        onToggled: root.remember = !root.remember
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Lembrar escolha para este app"
                        color: Theme.soft
                    }
                }

                Label {
                    anchors.centerIn: parent
                    text: "←↑↓→ escolher  ·  Tab / 1-3 abas  ·  Enter compartilhar  ·  Esc cancelar"
                    color: Theme.dim
                    font.pixelSize: Theme.fsXs
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Button {
                        text: "Cancelar"
                        onClicked: root.reply("")
                    }
                    Button {
                        icon: "screen-share"
                        text: "Compartilhar"
                        tone: "accent"
                        opacity: root.current ? 1 : 0.4
                        onClicked: root.share()
                    }
                }
            }
        }
    }
}
