import QtQuick
import qs.common

// Compact bordered action: [icon] label. `tone`: "" | "accent" | "danger".
Rectangle {
    id: root

    property string icon: ""
    property string text: ""
    property string tone: ""
    signal clicked()

    readonly property color ink: tone === "accent" ? Theme.onAccent : tone === "danger" ? Theme.red : Theme.soft

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 26
    radius: 7
    color: tone === "accent" ? (mouse.containsMouse ? "#FFD4AE" : Theme.peach)
         : mouse.pressed ? Theme.press : mouse.containsMouse ? Theme.hover : Theme.well
    border.width: tone === "accent" ? 0 : 1
    border.color: tone === "danger" && mouse.containsMouse ? "#55FF8080" : Theme.border
    Behavior on color { ColorAnimation { duration: Theme.fast } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5
        Icon {
            visible: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            size: 12
            color: root.ink
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.ink
            font.weight: Font.DemiBold
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
