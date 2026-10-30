import QtQuick
import qs.state

// Frozen desktop pixels for one global rect, stitched from every monitor.
Item {
    id: root

    property rect region
    property bool smoothed: false

    width: region.width
    height: region.height
    clip: true

    Repeater {
        model: Snip.screens

        Image {
            required property var modelData
            x: modelData.x - root.region.x
            y: modelData.y - root.region.y
            width: modelData.w
            height: modelData.h
            source: modelData.src
            asynchronous: false
            smooth: root.smoothed || modelData.scale !== 1
            mipmap: root.smoothed
        }
    }
}
