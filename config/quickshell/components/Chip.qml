import QtQuick
import qs.common

// 22px hover-tinted unit inside an island: [icon][label][extra...]
Item {
    id: root

    property string icon: ""
    property color iconColor: Theme.muted
    property int iconSize: 14
    property string text: ""
    property color textColor: Theme.soft
    property bool highlighted: false          // peach wash, e.g. a muted device
    property bool interactive: true
    property int pad: 7
    default property alias extra: row.data
    readonly property bool hovered: mouse.containsMouse

    signal clicked(var mouse)
    signal wheeled(var wheel)

    implicitWidth: row.implicitWidth + pad * 2
    implicitHeight: Theme.chipH

    Rectangle {
        anchors.fill: parent
        radius: Theme.chipR
        color: mouse.pressed ? Theme.press
             : mouse.containsMouse ? Theme.hover
             : root.highlighted ? Theme.peachSoft : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    Row {
        id: row
        x: root.pad
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Icon {
            visible: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            size: root.iconSize
            color: root.iconColor
        }

        Label {
            visible: root.text !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.textColor
            font.weight: Font.DemiBold
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: m => root.clicked(m)
        onWheel: w => root.wheeled(w)
    }
}
