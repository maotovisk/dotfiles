import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common
import qs.services

// Live capture of one Hyprland toplevel, with an app badge so tiny or
// uncapturable windows stay recognisable.
Item {
    id: thumb

    property var toplevel: null                      // HyprlandToplevel
    property bool live: false
    property bool highlight: false
    property int radius: 4
    property int badge: 22
    property bool outline: true
    readonly property var ipc: toplevel ? toplevel.lastIpcObject || {} : {}

    // Hyprland fails a toplevel capture when its window changes workspace,
    // and Quickshell then ends that recording for good. Re-arm it.
    property bool armed: true
    function rearm() {
        armed = false
        Qt.callLater(() => thumb.armed = true)
    }
    Connections {
        target: thumb.toplevel
        function onWorkspaceChanged() { thumb.rearm() }
    }
    Timer {
        interval: 600
        repeat: true
        running: thumb.live && !!thumb.toplevel && !cap.hasContent
        onTriggered: thumb.rearm()
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: thumb.radius
        color: "#1A1A1A"

        ScreencopyView {
            id: cap
            anchors.fill: parent
            // a fresh capture is blank until its first frame: fade in, don't pop
            opacity: hasContent ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.med } }
            captureSource: thumb.live && thumb.armed && thumb.toplevel ? thumb.toplevel.wayland : null
            live: thumb.live
            constraintSize: Qt.size(thumb.width * 2, thumb.height * 2)
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: thumb.radius
        color: "transparent"
        border.width: thumb.highlight ? 2 : 1
        border.color: thumb.highlight ? Theme.peach : thumb.outline ? "#30FFFFFF" : "transparent"
        Behavior on border.color { ColorAnimation { duration: Theme.fast } }
    }

    Rectangle {
        anchors.centerIn: parent
        width: thumb.badge
        height: thumb.badge
        radius: thumb.badge / 2
        color: "#C0101010"
        visible: badgeIcon.source != "" && thumb.width > thumb.badge + 4 && thumb.height > thumb.badge + 4
        IconImage {
            id: badgeIcon
            anchors.centerIn: parent
            implicitSize: Math.round(thumb.badge * 0.64)
            source: Ui.appIcon(thumb.ipc.class)
        }
    }
}
