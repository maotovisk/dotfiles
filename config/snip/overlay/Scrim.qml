import QtQuick

// Dims everything except `hole` (local coordinates).
Item {
    id: root

    property rect hole
    property bool hasHole: false
    property color color

    readonly property real l: Math.max(0, Math.min(width, hole.x))
    readonly property real t: Math.max(0, Math.min(height, hole.y))
    readonly property real r: Math.max(0, Math.min(width, hole.x + hole.width))
    readonly property real b: Math.max(0, Math.min(height, hole.y + hole.height))

    Rectangle { visible: !root.hasHole; anchors.fill: parent; color: root.color }

    Rectangle { visible: root.hasHole; color: root.color; x: 0; y: 0; width: root.width; height: root.t }
    Rectangle { visible: root.hasHole; color: root.color; x: 0; y: root.b; width: root.width; height: root.height - root.b }
    Rectangle { visible: root.hasHole; color: root.color; x: 0; y: root.t; width: root.l; height: root.b - root.t }
    Rectangle { visible: root.hasHole; color: root.color; x: root.r; y: root.t; width: root.width - root.r; height: root.b - root.t }
}
