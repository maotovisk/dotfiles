import QtQuick
import qs.common

// Shared surface for islands and popups: translucent dark tint over the
// compositor blur, outer dark ring, hairline border (warms when `lit`) and a
// 1px inner top highlight.
Item {
    id: root

    property real radius: Theme.islandR
    property color color: Theme.island
    property bool lit: false
    property color borderColor: lit ? Theme.borderHover : Theme.border

    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        radius: root.radius + 1
        color: "transparent"
        border.width: 1
        border.color: Theme.outline
    }

    Rectangle {
        id: body
        anchors.fill: parent
        radius: root.radius
        color: root.color
        border.width: 1
        border.color: root.borderColor
        Behavior on border.color { ColorAnimation { duration: Theme.med } }
    }

    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: 1
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - root.radius * 2
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.5; color: Theme.sheen }
            GradientStop { position: 1; color: "transparent" }
        }
    }
}
