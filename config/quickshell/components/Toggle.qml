import QtQuick
import qs.common

// Pill switch. Emits toggled(); the owner decides the new state.
Item {
    id: root

    property bool checked: false
    property bool busy: false
    signal toggled()

    implicitWidth: 32
    implicitHeight: 18

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.peach : "#20FFFFFF"
        Behavior on color { ColorAnimation { duration: Theme.med } }

        Rectangle {
            width: 14
            height: 14
            radius: 7
            y: 2
            x: root.checked ? parent.width - width - 2 : 2
            color: root.checked ? Theme.onAccent : Theme.soft
            opacity: root.busy ? 0.5 : 1
            Behavior on x { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutBack } }
            Behavior on color { ColorAnimation { duration: Theme.med } }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
