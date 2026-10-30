import QtQuick
import Quickshell.Services.Pipewire
import qs.common
import qs.components
import qs.services

// One output/input device. Click makes it the default.
Item {
    id: root

    required property PwNode node
    property bool input: false
    readonly property bool active: node === (input ? Audio.source : Audio.sink)
    readonly property string label: Audio.deviceName(node)

    width: parent ? parent.width : 0
    height: 32

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: mouse.pressed ? Theme.press : mouse.containsMouse ? Theme.hover
             : root.active ? Theme.well : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    Icon {
        id: icon
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        size: 14
        name: root.input ? "mic" : /fone|phone|headset/i.test(root.label) ? "headphones" : "speaker"
        color: root.active ? Theme.peach : Theme.muted
    }

    Label {
        anchors.left: icon.right
        anchors.leftMargin: 10
        anchors.right: check.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        text: root.label
        color: root.active ? Theme.text : Theme.soft
        font.weight: root.active ? Font.DemiBold : Font.Medium
    }

    Icon {
        id: check
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        size: 13
        name: "check"
        color: Theme.peach
        opacity: root.active ? 1 : 0
        scale: root.active ? 1 : 0.5
        Behavior on opacity { NumberAnimation { duration: Theme.med } }
        Behavior on scale { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutBack } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Audio.setDefault(root.node)
    }
}
