import QtQuick
import Quickshell.Services.Pipewire
import qs.common
import qs.components
import qs.services

// Volume Center under the right island: Saída / Entrada.
Popup {
    id: root

    readonly property bool input: Ui.volumeTab === "input"
    readonly property PwNode device: input ? Audio.source : Audio.sink
    readonly property real level: device && device.audio ? device.audio.volume : 0
    readonly property bool muted: !!(device && device.audio && device.audio.muted)

    open: Ui.popup === "volume"
    onDismissed: Ui.close("volume")
    ns: "quickshell-volume"
    cardWidth: 352
    spacing: 14

    PwNodePeakMonitor {
        id: peak
        node: root.device
        enabled: root.open && !root.muted
    }

    Segmented {
        model: [{ key: "output", label: "Saída", icon: "volume-2" }, { key: "input", label: "Entrada", icon: "mic" }]
        current: Ui.volumeTab
        onSelected: key => Ui.volumeTab = key
    }

    // ── master device ──────────────────────────────────────────────────
    Item {
        width: parent.width
        height: 34

        Rectangle {
            id: tile
            width: 34
            height: 34
            radius: 9
            color: root.muted ? Theme.redSoft : tileMouse.containsMouse ? Theme.press : Theme.well
            Behavior on color { ColorAnimation { duration: Theme.fast } }

            Icon {
                anchors.centerIn: parent
                size: 16
                name: root.input ? (root.muted ? "mic-off" : "mic")
                    : Audio.speakerIcon(Math.round(root.level * 100), root.muted)
                color: root.muted ? Theme.red : Theme.peach
            }

            MouseArea {
                id: tileMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Audio.toggleMute(root.device)
            }
        }

        Column {
            anchors.left: tile.right
            anchors.leftMargin: 12
            anchors.right: readout.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Label {
                width: parent.width
                elide: Text.ElideRight
                text: Audio.deviceName(root.device)
                color: Theme.text
                font.pixelSize: Theme.fsMd
                font.weight: Font.DemiBold
            }
            Label {
                text: root.muted ? "Silenciado" : root.input ? "Microfone padrão" : "Saída padrão"
                color: root.muted ? Theme.red : Theme.muted
                font.pixelSize: Theme.fsXs
            }
        }

        Column {
            id: readout
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Label {
                anchors.right: parent.right
                text: Math.round(root.level * 100) + "%"
                color: root.muted ? Theme.dim : Theme.text
                font.pixelSize: Theme.fsLg
                font.weight: Font.DemiBold
            }

            // tiny peak meter
            Rectangle {
                anchors.right: parent.right
                width: 32
                height: 3
                radius: 1.5
                color: "#14FFFFFF"

                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    width: parent.width * Math.min(1, peak.peak)
                    color: Theme.mint
                    Behavior on width { NumberAnimation { duration: 80 } }
                }
            }
        }
    }

    Slider {
        width: parent.width
        value: root.level
        dimmed: root.muted
        onMoved: v => Audio.setVolume(root.device, v)
    }

    // ── devices ────────────────────────────────────────────────────────
    Column {
        width: parent.width
        spacing: 4

        Caps { text: "Dispositivos"; leftPadding: 2; bottomPadding: 2 }

        Repeater {
            model: root.input ? Audio.sources : Audio.sinks
            delegate: DeviceRow {
                required property var modelData
                node: modelData
                input: root.input
            }
        }
    }

    // ── apps ───────────────────────────────────────────────────────────
    Column {
        readonly property var apps: root.input ? Audio.recording : Audio.playing
        width: parent.width
        spacing: 6

        Caps { text: "Aplicações"; leftPadding: 2; bottomPadding: 2 }

        Repeater {
            model: parent.apps
            delegate: AppRow {
                required property var modelData
                node: modelData
                input: root.input
                live: root.open
            }
        }

        Rectangle {
            visible: parent.apps.length === 0
            width: parent.width
            height: 44
            radius: 10
            color: "transparent"
            border.width: 1
            border.color: Theme.border

            Label {
                anchors.centerIn: parent
                text: root.input ? "Nenhum app usando o microfone" : "Nenhum app tocando áudio"
                color: Theme.muted
            }
        }
    }
}
