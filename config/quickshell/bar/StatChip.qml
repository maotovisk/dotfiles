import QtQuick
import Quickshell
import qs.common
import qs.components
import qs.services

// icon + percent, muted when calm, peach when warm, red when hot.
// Optional sparkline of recent samples. L: system monitor, R: `command`.
Chip {
    id: root

    property int value: 0
    property int warn: 70
    property int crit: 90
    property var history: []
    property var command: ["kitty", "--class=monitor", "btop"]

    readonly property color tone: value >= crit ? Theme.red : value >= warn ? Theme.peach : Theme.muted

    text: value + "%"
    iconColor: tone
    textColor: value >= warn ? tone : Theme.soft
    highlighted: Ui.popup === "sysmon"
    onClicked: m => m.button === Qt.RightButton ? Quickshell.execDetached(command) : Ui.toggle("sysmon")

    Row {
        visible: root.history.length > 0
        anchors.verticalCenter: parent.verticalCenter
        height: 12
        spacing: 1

        Repeater {
            model: root.history
            delegate: Rectangle {
                required property real modelData
                required property int index
                anchors.bottom: parent.bottom
                width: 2
                radius: 1
                height: Math.max(2, Math.round(modelData * 12))
                color: index === root.history.length - 1 ? root.tone : Theme.dim
                Behavior on height { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }
            }
        }
    }
}
