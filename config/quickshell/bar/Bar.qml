import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.components
import qs.services

// Top strip: three floating islands. 34px window + 4px margin = 38px reserved.
// Only the islands take input; the gaps click through to the desktop.
PanelWindow {
    id: bar

    anchors { top: true; left: true; right: true }
    margins.top: Theme.barMargin
    implicitHeight: Theme.barH
    color: "transparent"
    exclusionMode: ExclusionMode.Auto

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Component.onCompleted: Ui.bar = bar

    mask: Region {
        Region { item: left }
        Region { item: center }
        Region { item: right }
    }

    // ── left: workspaces + focused window ──────────────────────────────
    Island {
        id: left
        anchors.left: parent.left
        anchors.leftMargin: Theme.edge
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Workspaces { anchors.verticalCenter: parent.verticalCenter }
        Divider {}
        WindowTitle { anchors.verticalCenter: parent.verticalCenter }
    }

    // ── center: clock · media · weather ────────────────────────────────
    Island {
        id: center
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        lit: ["calendar", "weather", "player"].includes(Ui.popup)
        spacing: 4

        Clock { anchors.verticalCenter: parent.verticalCenter }
        Divider { visible: media.visible }
        MediaChip { id: media; anchors.verticalCenter: parent.verticalCenter }
        Divider { visible: weather.visible }

        Chip {
            id: weather
            readonly property var cur: Weather.current
            readonly property var info: cur ? Weather.info(cur.code, cur.night) : null
            anchors.verticalCenter: parent.verticalCenter
            visible: Weather.ready
            icon: info ? info.icon : "cloud"
            iconSize: 15
            iconColor: info ? Theme[info.accent] : Theme.muted
            text: cur ? cur.temp + "°" : ""
            textColor: Theme.text
            highlighted: Ui.popup === "weather"
            onClicked: Ui.toggle("weather")
        }
    }

    // ── right: bell · tray · stats · net · bluetooth · volume · mic ────────────────
    Island {
        id: right
        anchors.right: parent.right
        anchors.rightMargin: Theme.edge
        anchors.verticalCenter: parent.verticalCenter
        lit: ["volume", "notifs", "network", "sysmon"].includes(Ui.popup)

        Chip {
            anchors.verticalCenter: parent.verticalCenter
            icon: Notifs.dnd ? "bell-off" : Notifs.count > 0 ? "bell-dot" : "bell"
            iconColor: Notifs.dnd ? Theme.dim : Notifs.count > 0 ? Theme.peach : Theme.muted
            text: Notifs.count > 0 && !Notifs.dnd ? Notifs.count : ""
            textColor: Theme.peach
            highlighted: Ui.popup === "notifs"
            onClicked: m => m.button === Qt.RightButton ? Notifs.dnd = !Notifs.dnd : Ui.toggle("notifs")
        }

        Tray { anchors.verticalCenter: parent.verticalCenter }
        Divider {}

        StatChip {
            anchors.verticalCenter: parent.verticalCenter
            icon: "cpu"
            value: Stats.cpu
            warn: 65
            crit: 88
            history: Stats.history
        }
        StatChip {
            anchors.verticalCenter: parent.verticalCenter
            icon: "memory-stick"
            value: Stats.mem
            warn: 75
            crit: 92
        }
        StatChip {
            anchors.verticalCenter: parent.verticalCenter
            icon: "hard-drive"
            value: Stats.disk
            warn: 80
            crit: 93
            command: ["kitty", "--class=fileman", "ranger"]
        }

        Divider {}
        NetChip { anchors.verticalCenter: parent.verticalCenter }

        Chip {
            visible: Bt.available
            anchors.verticalCenter: parent.verticalCenter
            icon: Bt.icon
            iconColor: !Bt.enabled ? Theme.dim : Bt.connected.length > 0 ? Theme.peach : Theme.muted
            highlighted: Ui.popup === "network" && Ui.networkTab === "bluetooth"
            onClicked: m => m.button === Qt.RightButton ? Bt.setEnabled(!Bt.enabled) : Ui.toggleTab("network", "bluetooth")
        }

        Chip {
            anchors.verticalCenter: parent.verticalCenter
            icon: Audio.speakerIcon(Audio.volume, Audio.muted)
            iconColor: Audio.muted ? Theme.dim : Theme.muted
            text: Audio.volume + "%"
            textColor: Audio.muted ? Theme.dim : Theme.soft
            highlighted: Ui.popup === "volume" && Ui.volumeTab === "output"
            onClicked: m => m.button === Qt.RightButton ? Audio.toggleMute(Audio.sink) : Ui.toggleTab("volume", "output")
            onWheeled: w => Audio.nudge(Audio.sink, w.angleDelta.y > 0 ? 0.02 : -0.02)
        }

        Chip {
            anchors.verticalCenter: parent.verticalCenter
            icon: Audio.micMuted ? "mic-off" : "mic"
            iconColor: Audio.micMuted ? Theme.dim : Audio.micLive ? Theme.peach : Theme.muted
            text: Audio.micVolume + "%"
            textColor: Audio.micMuted ? Theme.dim : Theme.soft
            highlighted: Ui.popup === "volume" && Ui.volumeTab === "input"
            onClicked: m => m.button === Qt.RightButton ? Audio.toggleMute(Audio.source) : Ui.toggleTab("volume", "input")
            onWheeled: w => Audio.nudge(Audio.source, w.angleDelta.y > 0 ? 0.02 : -0.02)
        }
    }
}
