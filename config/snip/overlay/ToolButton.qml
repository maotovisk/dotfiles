import QtQuick
import qs.common

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property string tip: ""
    property bool active: false
    property bool primary: false
    property bool enabledLook: true

    signal clicked()
    signal hoverTip(string tip, Item item)

    implicitWidth: label !== "" ? row.implicitWidth + 20 : 30
    implicitHeight: 30
    radius: 8
    color: primary ? (mouse.pressed ? Qt.darker(Theme.peach, 1.15) : mouse.containsMouse ? Qt.lighter(Theme.peach, 1.06) : Theme.peach)
         : active ? Theme.peachSoft
         : mouse.pressed ? Theme.press : mouse.containsMouse ? Theme.hover : "transparent"
    opacity: enabledLook ? 1 : 0.35

    Behavior on color { ColorAnimation { duration: Theme.fast } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            size: 16
            color: root.primary ? Theme.onAccent : root.active ? Theme.peach : Theme.soft
        }
        Text {
            visible: root.label !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.primary ? Theme.onAccent : Theme.soft
            font.family: Theme.font
            font.pixelSize: Theme.fsMd
            font.weight: Font.DemiBold
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onContainsMouseChanged: root.hoverTip(containsMouse ? root.tip : "", root)
    }
}
