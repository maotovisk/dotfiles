import QtQuick
import qs.common

// Single-line input in a recessed well. Password mode gets a reveal toggle.
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: ""
    property bool password: false
    property bool error: false
    property bool reveal: false
    signal accepted()

    function focusInput() { input.forceActiveFocus() }

    width: parent ? parent.width : 200
    height: 30
    radius: 8
    color: Theme.well
    border.width: 1
    border.color: root.error ? Theme.red : input.activeFocus ? Theme.borderHover : Theme.border
    Behavior on border.color { ColorAnimation { duration: Theme.fast } }

    TextInput {
        id: input
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.right: eye.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        color: Theme.text
        selectionColor: Theme.peachSoft
        selectedTextColor: Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fsSm
        font.weight: Font.Medium
        font.letterSpacing: 0.25
        echoMode: root.password && !root.reveal ? TextInput.Password : TextInput.Normal
        passwordCharacter: "•"
        onAccepted: root.accepted()
        Keys.onEscapePressed: e => { e.accepted = false }

        Label {
            visible: input.text === ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.placeholder
            color: Theme.dim
        }
    }

    Icon {
        id: eye
        visible: root.password
        anchors.right: parent.right
        anchors.rightMargin: 9
        anchors.verticalCenter: parent.verticalCenter
        size: 13
        name: root.reveal ? "eye-off" : "eye"
        color: eyeMouse.containsMouse ? Theme.soft : Theme.muted

        MouseArea {
            id: eyeMouse
            anchors.fill: parent
            anchors.margins: -5
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.reveal = !root.reveal
        }
    }
}
