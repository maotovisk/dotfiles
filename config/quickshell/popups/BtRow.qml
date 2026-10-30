import QtQuick
import Quickshell.Bluetooth
import qs.common
import qs.components
import qs.services

// One Bluetooth device. Click connects/disconnects (or pairs, if new);
// paired devices get a forget button on hover.
Item {
    id: root

    required property var device
    readonly property bool busy: device.pairing
        || device.state === BluetoothDeviceState.Connecting
        || device.state === BluetoothDeviceState.Disconnecting
    readonly property string status: device.pairing ? "Pareando…"
        : device.state === BluetoothDeviceState.Connecting ? "Conectando…"
        : device.state === BluetoothDeviceState.Disconnecting ? "Desconectando…"
        : device.connected ? "Conectado"
        : device.paired || device.bonded ? "Pareado" : "Toque para parear"

    width: parent ? parent.width : 0
    height: 36

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: mouse.pressed ? Theme.press : mouse.containsMouse ? Theme.hover
             : root.device.connected ? Theme.well : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    Icon {
        id: icon
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        size: 14
        name: Bt.deviceIcon(root.device)
        color: root.device.connected ? Theme.peach : Theme.muted
    }

    Column {
        anchors.left: icon.right
        anchors.leftMargin: 10
        anchors.right: trail.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        Label {
            width: parent.width
            elide: Text.ElideRight
            text: root.device.name || root.device.deviceName
            color: root.device.connected ? Theme.text : Theme.soft
            font.weight: root.device.connected ? Font.DemiBold : Font.Medium
        }
        Label {
            text: root.status
            color: root.busy ? Theme.peach : Theme.muted
            font.pixelSize: Theme.fsXs
        }
    }

    Row {
        id: trail
        z: 1                                 // above the row's MouseArea so forget is clickable
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Row {
            visible: root.device.batteryAvailable
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: root.device.battery > 0.5 ? "battery" : "battery-medium"
                size: 13
                color: root.device.battery < 0.2 ? Theme.red : Theme.muted
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(root.device.battery * 100) + "%"
                color: root.device.battery < 0.2 ? Theme.red : Theme.soft
                font.pixelSize: Theme.fsXs
                font.weight: Font.DemiBold
            }
        }

        Icon {
            visible: root.busy
            anchors.verticalCenter: parent.verticalCenter
            name: "loader-circle"
            size: 13
            color: Theme.peach
            RotationAnimation on rotation {
                running: root.busy
                from: 0; to: 360
                duration: 900
                loops: Animation.Infinite
            }
        }

        // forget: only on hover, only for known devices
        Chip {
            visible: (root.device.paired || root.device.bonded) && mouse.containsMouse || hovered
            anchors.verticalCenter: parent.verticalCenter
            pad: 5
            icon: "trash-2"
            iconSize: 12
            iconColor: hovered ? Theme.red : Theme.muted
            onClicked: root.device.forget()
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Bt.toggle(root.device)
    }
}
