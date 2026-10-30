import QtQuick
import qs.common
import "Lucide.js" as Lucide

// Same renderer as the bar's Icon: inline SVG with the stroke colour baked in.
Item {
    id: root

    property string name: ""
    property color color: Theme.soft
    property int size: 16
    property real stroke: 2

    implicitWidth: size
    implicitHeight: size

    Image {
        anchors.fill: parent
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        smooth: true
        mipmap: true
        opacity: root.color.a
        source: root.name === "" ? ""
            : "data:image/svg+xml;utf8," + encodeURIComponent(Lucide.svg(root.name, String(Qt.rgba(root.color.r, root.color.g, root.color.b, 1)), root.stroke))
    }
}
