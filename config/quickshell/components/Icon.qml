import QtQuick
import qs.common
import "../common/Lucide.js" as Lucide

// Lucide icon rendered from an inline SVG with the exact stroke colour —
// no colourisation shader, crisp at every size.
Item {
    id: root

    property string name: ""
    property color color: Theme.soft
    property int size: 14
    property real stroke: size <= 12 ? 2.25 : 2

    implicitWidth: size
    implicitHeight: size

    Image {
        anchors.fill: parent
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        smooth: true
        mipmap: true
        // SVG can't parse #AARRGGBB: stroke gets the opaque rgb, alpha goes to opacity
        opacity: root.color.a
        source: root.name === "" ? ""
            : "data:image/svg+xml;utf8," + encodeURIComponent(Lucide.svg(root.name, String(Qt.rgba(root.color.r, root.color.g, root.color.b, 1)), root.stroke))
    }
}
