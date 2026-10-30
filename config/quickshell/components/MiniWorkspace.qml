import QtQuick
import Quickshell.Widgets
import qs.common
import qs.services

// A workspace drawn as a tiny monitor: its wallpaper plus live thumbnails of
// its windows at their real positions. Windows scrolled off-screen (scrolling
// layout) are clipped, exactly like the real output.
ClippingRectangle {
    id: root

    property var workspace: null                     // HyprlandWorkspace
    property var monitor: workspace ? workspace.monitor : null
    property bool live: false
    property real dim: 0.45                          // wallpaper opacity
    readonly property real s: width / (monitor ? monitor.width : 1920)

    radius: 8
    color: "#0B0B0B"

    Image {
        anchors.fill: parent
        source: Wallpapers.url(root.monitor ? root.monitor.name : "")
        sourceSize: Qt.size(root.width * 2, root.height * 2)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: root.dim
    }

    Repeater {
        model: root.workspace ? root.workspace.toplevels : null

        delegate: WindowThumb {
            id: win
            required property var modelData
            readonly property var at: ipc.at || [0, 0]
            readonly property var sz: ipc.size || [1920, 1080]

            toplevel: modelData
            live: root.live
            badge: Math.min(22, Math.round(root.height / 5))
            x: (at[0] - (root.monitor ? root.monitor.x : 0)) * root.s
            y: (at[1] - (root.monitor ? root.monitor.y : 0)) * root.s
            width: Math.max(10, sz[0] * root.s)
            height: Math.max(8, sz[1] * root.s)
            z: ipc.floating ? 2 : 1
        }
    }
}
