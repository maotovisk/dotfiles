import QtQuick
import qs.common

// 5px track, peach fill, thumb that grows on hover/drag.
// Animates value changes from outside, never while the user drags.
Item {
    id: root

    property real value: 0                 // 0..1
    property color fill: Theme.peach
    property bool dimmed: false
    readonly property bool dragging: mouse.pressed
    readonly property bool hovered: mouse.containsMouse

    signal moved(real value)

    implicitHeight: 16
    implicitWidth: 200

    property real shown: value
    Behavior on shown {
        enabled: !root.dragging
        NumberAnimation { duration: Theme.med; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 5
        radius: 2.5
        color: "#16FFFFFF"

        Rectangle {
            width: Math.max(height, track.width * Math.min(1, root.shown))
            height: parent.height
            radius: parent.radius
            color: root.dimmed ? Theme.dim : root.fill
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }
    }

    Rectangle {
        property int d: root.dragging ? 14 : root.hovered ? 12 : 8
        width: d
        height: d
        radius: d / 2
        x: Math.max(0, Math.min(root.width - d, track.width * Math.min(1, root.shown) - d / 2))
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.text
        border.width: root.dragging ? 3 : 0
        border.color: root.dimmed ? Theme.dim : root.fill
        Behavior on d { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutBack } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.topMargin: -4
        anchors.bottomMargin: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        function set(x) {
            root.moved(Math.max(0, Math.min(1, x / width)))
        }
        onPressed: m => set(m.x)
        onPositionChanged: m => { if (pressed) set(m.x) }
        onWheel: w => root.moved(Math.max(0, Math.min(1, root.value + (w.angleDelta.y > 0 ? 0.02 : -0.02))))
    }
}
