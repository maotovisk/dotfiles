import QtQuick
import Quickshell
import qs.common
import qs.components
import qs.services

// System monitor under the right island: CPU (graph, per-thread load, temp),
// memory / swap / disk / GPU meters, network rates and the busiest processes.
Popup {
    id: root

    open: Ui.popup === "sysmon"
    onDismissed: Ui.close("sysmon")
    ns: "quickshell-sysmon"
    cardWidth: 380
    spacing: 14

    Binding { target: Stats; property: "detailed"; value: root.open }

    function tone(v, warn, crit) {
        return v >= crit ? Theme.red : v >= warn ? Theme.peach : Theme.soft
    }

    // ── header ─────────────────────────────────────────────────────────
    Item {
        width: parent.width
        height: 16
        Caps { anchors.verticalCenter: parent.verticalCenter; text: "Sistema"; color: Theme.soft; leftPadding: 2 }
        Label {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: Stats.host
            color: Theme.muted
            font.pixelSize: Theme.fsXs
        }
    }

    // ── CPU ────────────────────────────────────────────────────────────
    Rectangle {
        width: parent.width
        height: cpuCol.implicitHeight + 24
        radius: 12
        color: Theme.well

        Column {
            id: cpuCol
            x: 12
            y: 12
            width: parent.width - 24
            spacing: 10

            Item {
                width: parent.width
                height: 30

                Rectangle {
                    id: cpuTile
                    width: 30
                    height: 30
                    radius: 8
                    color: Theme.well
                    Icon { anchors.centerIn: parent; name: "cpu"; size: 15; color: Stats.cpu >= 88 ? Theme.red : Theme.peach }
                }
                Column {
                    anchors.left: cpuTile.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    Label { text: "Processador"; color: Theme.text; font.weight: Font.DemiBold }
                    Label { text: Stats.cpuModel + "  ·  " + Stats.cores.length + " threads"; color: Theme.muted; font.pixelSize: Theme.fsXs }
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    TempChip { value: Stats.cpuTemp; warn: 75; crit: 88 }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Stats.cpu + "%"
                        color: Stats.cpu >= 65 ? root.tone(Stats.cpu, 65, 88) : Theme.text
                        font.pixelSize: Theme.fsLg
                        font.weight: Font.DemiBold
                    }
                }
            }

            Graph {
                width: parent.width
                height: 54
                values: Stats.cpuHistory
                color: Stats.cpu >= 88 ? Theme.red : Theme.peach
            }

            // per-thread load
            Row {
                id: coresRow
                width: parent.width
                spacing: 3
                Repeater {
                    model: Stats.cores
                    delegate: Rectangle {
                        required property int modelData
                        width: (coresRow.width - coresRow.spacing * (Stats.cores.length - 1)) / Math.max(1, Stats.cores.length)
                        height: 18
                        radius: 3
                        color: "#12FFFFFF"
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: Math.max(2, Math.round(parent.height * modelData / 100))
                            radius: 3
                            color: modelData >= 88 ? Theme.red : modelData >= 50 ? Theme.peach : "#80FFC799"
                            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: 12
                Label { text: "Carga  " + Stats.load; color: Theme.muted; font.pixelSize: Theme.fsXs }
                Label { anchors.right: parent.right; text: "Ligado há " + Stats.duration(Stats.uptime); color: Theme.muted; font.pixelSize: Theme.fsXs }
            }
        }
    }

    // ── meters ─────────────────────────────────────────────────────────
    Column {
        width: parent.width
        spacing: 12

        Meter {
            icon: "memory-stick"
            label: "Memória"
            accent: Theme.blue
            fraction: Stats.memTotal > 0 ? Stats.memUsed / Stats.memTotal : 0
            detail: Stats.bytes(Stats.memUsed) + " de " + Stats.bytes(Stats.memTotal)
            warn: 0.75
            crit: 0.92
        }
        Meter {
            visible: Stats.swapTotal > 0
            icon: "memory-stick"
            label: "Swap"
            accent: Theme.blue
            fraction: Stats.swapTotal > 0 ? Stats.swapUsed / Stats.swapTotal : 0
            detail: Stats.bytes(Stats.swapUsed) + " de " + Stats.bytes(Stats.swapTotal)
            warn: 0.5
            crit: 0.85
        }
        Meter {
            icon: "hard-drive"
            label: "Disco  /"
            accent: Theme.mint
            fraction: Stats.diskSize > 0 ? Stats.diskUsed / Stats.diskSize : 0
            detail: Stats.bytes(Stats.diskUsed) + " de " + Stats.bytes(Stats.diskSize) + (Stats.nvmeTemp ? "  ·  " + Stats.nvmeTemp + "°" : "")
            warn: 0.8
            crit: 0.93
        }
        Meter {
            visible: Stats.gpu >= 0
            icon: "monitor"
            label: "GPU"
            accent: Theme.peach
            fraction: Stats.gpu / 100
            detail: Stats.gpu + "%  ·  VRAM " + Stats.bytes(Stats.vramUsed) + " de " + Stats.bytes(Stats.vramTotal) + (Stats.gpuTemp ? "  ·  " + Stats.gpuTemp + "°" : "")
            warn: 0.85
            crit: 0.97
        }
    }

    // ── network ────────────────────────────────────────────────────────
    Rectangle {
        width: parent.width
        height: 64
        radius: 12
        color: Theme.well
        clip: true

        Graph {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 34
            max: 0
            values: Stats.netHistory.map(s => s.rx)
            color: Theme.mint
            fillOpacity: 0.16
        }
        Graph {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 34
            max: 0
            values: Stats.netHistory.map(s => s.tx)
            color: Theme.peach
            fillOpacity: 0.1
        }

        Row {
            x: 12
            y: 10
            spacing: 18
            Row {
                spacing: 5
                Label { text: "↓"; color: Theme.mint; font.weight: Font.Bold }
                Label { text: Stats.rate(Stats.rx); color: Theme.text; font.weight: Font.DemiBold }
            }
            Row {
                spacing: 5
                Label { text: "↑"; color: Theme.peach; font.weight: Font.Bold }
                Label { text: Stats.rate(Stats.tx); color: Theme.text; font.weight: Font.DemiBold }
            }
        }
        Label {
            anchors.right: parent.right
            anchors.rightMargin: 12
            y: 10
            text: Net.iface + (Net.ip ? "  ·  " + Net.ip : "")
            color: Theme.muted
            font.pixelSize: Theme.fsXs
        }
    }

    // ── processes ──────────────────────────────────────────────────────
    Column {
        width: parent.width
        spacing: 2

        Item {
            width: parent.width
            height: 18
            Caps { anchors.verticalCenter: parent.verticalCenter; text: "Processos"; leftPadding: 2 }
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0
                Caps { width: 52; horizontalAlignment: Text.AlignRight; text: "CPU" }
                Caps { width: 52; horizontalAlignment: Text.AlignRight; text: "MEM" }
            }
        }

        Repeater {
            model: Stats.procs
            delegate: Rectangle {
                required property var modelData
                width: parent.width
                height: 26
                radius: 7
                color: rowHover.hovered ? Theme.hover : "transparent"
                HoverHandler { id: rowHover }

                Label {
                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 10 - 104 - 20
                    elide: Text.ElideRight
                    text: modelData.name
                    color: Theme.soft
                }
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    Label {
                        width: 52
                        horizontalAlignment: Text.AlignRight
                        text: modelData.cpu.toFixed(1) + "%"
                        color: root.tone(modelData.cpu, 50, 90)
                        font.weight: Font.DemiBold
                    }
                    Label {
                        width: 52
                        horizontalAlignment: Text.AlignRight
                        text: modelData.mem.toFixed(1) + "%"
                        color: Theme.muted
                        font.weight: Font.DemiBold
                    }
                }
            }
        }

        Label {
            visible: Stats.procs.length === 0
            leftPadding: 10
            text: "Amostrando…"
            color: Theme.muted
        }
    }

    Button {
        anchors.right: parent.right
        icon: "activity"
        text: "Abrir btop"
        onClicked: {
            Quickshell.execDetached(["kitty", "--class=monitor", "btop"])
            Ui.close("sysmon")
        }
    }

    // ── pieces ─────────────────────────────────────────────────────────
    component TempChip: Row {
        property int value: 0
        property int warn: 75
        property int crit: 90
        visible: value > 0
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        spacing: 3
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: "thermometer"
            size: 12
            color: root.tone(parent.value, parent.warn, parent.crit) === Theme.soft ? Theme.muted : root.tone(parent.value, parent.warn, parent.crit)
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.value + "°"
            color: root.tone(parent.value, parent.warn, parent.crit)
            font.weight: Font.DemiBold
        }
    }

    component Meter: Item {
        id: m
        property string icon: ""
        property string label: ""
        property string detail: ""
        property real fraction: 0
        property color accent: Theme.peach
        property real warn: 0.8
        property real crit: 0.95
        readonly property color barColor: fraction >= crit ? Theme.red : fraction >= warn ? Theme.peach : accent

        width: parent ? parent.width : 0
        height: 32

        Icon {
            id: mIcon
            x: 2
            y: 1
            name: m.icon
            size: 13
            color: Theme.muted
        }
        Label {
            anchors.left: mIcon.right
            anchors.leftMargin: 8
            anchors.verticalCenter: mIcon.verticalCenter
            text: m.label
            color: Theme.soft
            font.weight: Font.DemiBold
        }
        Label {
            anchors.right: parent.right
            anchors.verticalCenter: mIcon.verticalCenter
            text: m.detail
            color: Theme.muted
            font.pixelSize: Theme.fsXs
        }
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            width: parent.width
            height: 5
            radius: 2.5
            color: "#16FFFFFF"
            Rectangle {
                width: Math.max(height, parent.width * Math.min(1, m.fraction))
                height: parent.height
                radius: parent.radius
                color: m.barColor
                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: Theme.med } }
            }
        }
    }
}
