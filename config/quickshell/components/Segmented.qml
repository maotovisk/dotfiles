import QtQuick
import qs.common

// Two-or-more segment tabs with a sliding peach pill.
Rectangle {
    id: root

    property var model: []                   // [{ key, label, icon }]
    property string current: ""
    signal selected(string key)

    readonly property int index: Math.max(0, model.findIndex(m => m.key === current))
    readonly property real segment: (width - 6) / Math.max(1, model.length)

    width: parent ? parent.width : 200
    height: 30
    radius: 9
    color: Theme.well

    Rectangle {
        x: 3 + root.index * root.segment
        y: 3
        width: root.segment
        height: parent.height - 6
        radius: 7
        color: Theme.peach
        Behavior on x { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
    }

    Row {
        anchors.fill: parent
        anchors.margins: 3

        Repeater {
            model: root.model

            delegate: Item {
                required property var modelData
                readonly property bool on: root.current === modelData.key
                width: root.segment
                height: parent.height

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: modelData.icon
                        size: 13
                        color: on ? Theme.onAccent : Theme.muted
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        color: on ? Theme.onAccent : Theme.soft
                        font.weight: Font.DemiBold
                        Behavior on color { ColorAnimation { duration: Theme.med } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selected(modelData.key)
                }
            }
        }
    }
}
