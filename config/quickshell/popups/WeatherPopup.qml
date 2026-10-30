import QtQuick
import qs.common
import qs.components
import qs.services

// Weather card under the center island: now, three readings, next hours, sun.
Popup {
    id: root

    readonly property var cur: Weather.current
    readonly property var now: cur ? Weather.info(cur.code, cur.night) : null
    readonly property var today: Weather.today

    open: Ui.popup === "weather"
    onDismissed: Ui.close("weather")
    ns: "quickshell-weather"
    align: "center"
    cardWidth: 340
    spacing: 14

    // ── now ────────────────────────────────────────────────────────────
    Item {
        width: parent.width
        height: 34

        Rectangle {
            id: tile
            width: 34
            height: 34
            radius: 9
            color: Theme.well

            Icon {
                anchors.centerIn: parent
                size: 18
                name: root.now ? root.now.icon : "cloud"
                color: root.now ? Theme[root.now.accent] : Theme.muted
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
                text: root.cur ? root.cur.desc : "—"
                color: Theme.text
                font.pixelSize: Theme.fsMd
                font.weight: Font.DemiBold
            }
            Label {
                text: Weather.place + (root.cur ? "  ·  sensação " + root.cur.feels + "°" : "")
                color: Theme.muted
                font.pixelSize: Theme.fsXs
            }
        }

        Column {
            id: readout
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Label {
                anchors.right: parent.right
                text: root.cur ? root.cur.temp + "°" : "—"
                color: Theme.text
                font.pixelSize: Theme.fsLg
                font.weight: Font.DemiBold
            }
            Label {
                anchors.right: parent.right
                text: root.today ? "↑ " + root.today.max + "°  ↓ " + root.today.min + "°" : ""
                color: Theme.muted
                font.pixelSize: Theme.fsXs
            }
        }
    }

    // ── readings ───────────────────────────────────────────────────────
    Row {
        id: readings
        width: parent.width
        spacing: 6

        Repeater {
            model: root.cur ? [
                { icon: "droplets", tint: "blue", label: "Umidade", value: root.cur.hum + "%" },
                { icon: "wind", tint: "muted", label: "Vento", value: root.cur.wind + " km/h" },
                { icon: "cloud-rain", tint: "blue", label: "Chuva", value: (Weather.hourly.length ? Weather.hourly[0].rain : 0) + "%" }
            ] : []

            delegate: Rectangle {
                required property var modelData
                width: (readings.width - readings.spacing * 2) / 3
                height: 50
                radius: 10
                color: Theme.well

                Column {
                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    Row {
                        spacing: 5
                        Icon { anchors.verticalCenter: parent.verticalCenter; name: modelData.icon; size: 11; color: Theme[modelData.tint] }
                        Caps { anchors.verticalCenter: parent.verticalCenter; text: modelData.label }
                    }
                    Label {
                        text: modelData.value
                        color: Theme.text
                        font.pixelSize: Theme.fsMd
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }

    // ── next hours ─────────────────────────────────────────────────────
    Column {
        width: parent.width
        spacing: 8

        Caps { text: "Próximas horas"; leftPadding: 2 }

        Row {
            id: hours
            width: parent.width

            Repeater {
                model: Weather.hourly

                delegate: Column {
                    id: hour
                    required property var modelData
                    required property int index
                    readonly property var w: Weather.info(modelData.code, modelData.night)
                    width: hours.width / Math.max(1, Weather.hourly.length)
                    spacing: 6

                    // columns rise in one after another when the card opens
                    opacity: root.open ? 1 : 0
                    transform: Translate { y: root.open ? 0 : 6; Behavior on y { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } } }
                    Behavior on opacity {
                        SequentialAnimation {
                            PauseAnimation { duration: root.open ? 60 + hour.index * 35 : 0 }
                            NumberAnimation { duration: Theme.med }
                        }
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: hour.modelData.time
                        color: Theme.muted
                        font.pixelSize: Theme.fsXs
                    }
                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: hour.w.icon
                        size: 16
                        color: Theme[hour.w.accent]
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: hour.modelData.temp + "°"
                        color: Theme.text
                        font.weight: Font.DemiBold
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: hour.modelData.rain > 0 ? hour.modelData.rain + "%" : "·"
                        color: hour.modelData.rain >= 40 ? Theme.blue : Theme.dim
                        font.pixelSize: Theme.fsCaps
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }

    // ── sun ────────────────────────────────────────────────────────────
    Rectangle {
        width: parent.width
        height: 1
        color: Theme.divider
    }

    Item {
        width: parent.width
        height: 16

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            Icon { anchors.verticalCenter: parent.verticalCenter; name: "sunrise"; size: 13; color: Theme.peach }
            Label { anchors.verticalCenter: parent.verticalCenter; text: root.today ? Weather.clock24(root.today.rise) : "—"; font.weight: Font.DemiBold }
            Label { anchors.verticalCenter: parent.verticalCenter; text: "nascer"; color: Theme.muted; font.pixelSize: Theme.fsXs }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            Label { anchors.verticalCenter: parent.verticalCenter; text: "pôr"; color: Theme.muted; font.pixelSize: Theme.fsXs }
            Label { anchors.verticalCenter: parent.verticalCenter; text: root.today ? Weather.clock24(root.today.set) : "—"; font.weight: Font.DemiBold }
            Icon { anchors.verticalCenter: parent.verticalCenter; name: "sunset"; size: 13; color: Theme.peach }
        }
    }
}
