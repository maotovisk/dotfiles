import QtQuick
import qs.common

// Pixel magnifier around `at` (local coordinates) for precise edges.
Item {
    id: root

    property url source
    property size sourceSize
    property point at
    property string caption: ""
    readonly property int zoom: 8
    readonly property int box: 136

    width: box
    height: box + 30

    Rectangle {
        id: frame
        width: root.box
        height: root.box
        radius: 12
        color: "black"
        clip: true
        border.width: 0

        Image {
            source: root.source
            smooth: false
            width: root.sourceSize.width * root.zoom
            height: root.sourceSize.height * root.zoom
            x: root.box / 2 - (Math.floor(root.at.x) + 0.5) * root.zoom
            y: root.box / 2 - (Math.floor(root.at.y) + 0.5) * root.zoom
        }

        // the pixel under the cursor
        Rectangle {
            width: root.zoom + 2
            height: root.zoom + 2
            anchors.centerIn: parent
            color: "transparent"
            border.width: 1
            border.color: Theme.peach
        }
        Rectangle { x: 0; width: parent.width / 2 - root.zoom / 2 - 1; height: 1; anchors.verticalCenter: parent.verticalCenter; color: "#80FFC799" }
        Rectangle { x: parent.width / 2 + root.zoom / 2 + 1; width: parent.width - x; height: 1; anchors.verticalCenter: parent.verticalCenter; color: "#80FFC799" }
        Rectangle { y: 0; height: parent.height / 2 - root.zoom / 2 - 1; width: 1; anchors.horizontalCenter: parent.horizontalCenter; color: "#80FFC799" }
        Rectangle { y: parent.height / 2 + root.zoom / 2 + 1; height: parent.height - y; width: 1; anchors.horizontalCenter: parent.horizontalCenter; color: "#80FFC799" }
    }

    Rectangle {
        anchors.fill: frame
        radius: frame.radius
        color: "transparent"
        border.width: 1
        border.color: Theme.border
    }

    Pill {
        anchors.horizontalCenter: frame.horizontalCenter
        anchors.top: frame.bottom
        anchors.topMargin: 6
        text: root.caption
    }
}
