import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import qs.common
import qs.components
import qs.services

// Per-app stream: icon, name, %, mute, its own slider and a live 2px level.
Rectangle {
    id: root

    required property PwNode node
    property bool input: false
    property bool live: false                // only meter while the popup is open
    readonly property bool muted: !!(node.audio && node.audio.muted)
    readonly property real volume: node.audio ? node.audio.volume : 0

    width: parent ? parent.width : 0
    height: 58
    radius: 10
    color: Theme.well
    clip: true

    PwNodePeakMonitor {
        id: peak
        node: root.node
        enabled: root.live && !root.muted
    }

    Item {
        id: head
        x: 10
        y: 8
        width: parent.width - 20
        height: 22

        Item {
            id: appIcon
            width: 16
            height: 16
            anchors.verticalCenter: parent.verticalCenter

            IconImage {
                id: img
                anchors.fill: parent
                source: Ui.icon(Audio.appIcon(root.node))
                visible: source != ""
            }
            Icon {
                anchors.centerIn: parent
                visible: !img.visible
                name: root.input ? "mic" : "app-window"
                size: 14
                color: Theme.muted
            }
        }

        Label {
            id: name
            anchors.left: appIcon.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 130)
            elide: Text.ElideRight
            text: Audio.appName(root.node)
            color: root.muted ? Theme.muted : Theme.text
            font.weight: Font.DemiBold
        }

        Label {
            anchors.left: name.right
            anchors.leftMargin: 6
            anchors.right: pct.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            text: Audio.appDetail(root.node)
            color: Theme.dim
            font.pixelSize: Theme.fsXs
        }

        Label {
            id: pct
            anchors.right: mute.left
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.volume * 100) + "%"
            color: root.muted ? Theme.dim : Theme.soft
            font.pixelSize: Theme.fsXs
            font.weight: Font.DemiBold
        }

        Chip {
            id: mute
            anchors.right: parent.right
            anchors.rightMargin: -6
            anchors.verticalCenter: parent.verticalCenter
            pad: 5
            icon: root.input ? (root.muted ? "mic-off" : "mic")
                : Audio.speakerIcon(Math.round(root.volume * 100), root.muted)
            iconSize: 13
            iconColor: root.muted ? Theme.red : Theme.muted
            onClicked: Audio.toggleMute(root.node)
        }
    }

    Slider {
        anchors.top: head.bottom
        anchors.topMargin: 4
        x: 10
        width: parent.width - 20
        value: root.volume
        dimmed: root.muted
        onMoved: v => Audio.setVolume(root.node, v)
    }

    // live level along the bottom edge, inset clear of the corner radius
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 1
        x: 10
        height: 2
        radius: 1
        width: (parent.width - 20) * Math.min(1, peak.peak)
        color: Theme.mint
        opacity: 0.75
        Behavior on width { NumberAnimation { duration: 80 } }
    }
}
