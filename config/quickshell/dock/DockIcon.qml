import QtQuick
import Quickshell
import qs.common
import qs.components
import qs.services

// One dock slot, purely visual (DockPanel owns the pointer). Width and icon
// size follow `mag` (magnification); the icon grows upward out of the glass.
// Dots under it count windows, an orb shows Unity badges, and it hops while
// launching or when a window wants attention. While dragged it's `ghosted`
// (an empty gap); `collapsed` closes the gap (dragging a pin off the dock).
Item {
    id: slot

    required property var modelData
    required property int index
    property real mag: 1
    property int baseIcon: 44
    property int baseSlot: 52
    property int pad: 8
    property bool sepBefore: false
    property int sepW: 0
    property bool tipAllowed: true
    property bool hovered: false
    property bool pressed: false
    property bool ghosted: false

    readonly property var app: modelData
    readonly property bool active: Dock.activeKey === app.key
    readonly property bool urgent: app.windows.some(t => t.urgent)
    readonly property var badge: Badges.entries[app.key] ?? null
    readonly property int count: badge ? badge.count : 0
    readonly property real iconSize: baseIcon * mag
    readonly property real centerX: cell.x + cell.width / 2

    property real collapse: app.collapsed ? 0 : 1
    Behavior on collapse { NumberAnimation { duration: Theme.med; easing.type: Easing.OutCubic } }

    width: (baseSlot * mag + (sepBefore ? sepW : 0)) * collapse
    height: parent ? parent.height : 0
    clip: collapse < 1

    // pinned | running divider
    Rectangle {
        visible: slot.sepBefore
        x: Math.round(slot.sepW / 2) - 1
        y: slot.height - slot.pad - slot.baseIcon + 4
        width: 1
        height: slot.baseIcon - 8
        color: Theme.divider
    }

    Item {
        id: cell
        x: slot.sepBefore ? slot.sepW : 0
        width: slot.baseSlot * slot.mag
        height: slot.height
        opacity: slot.ghosted ? 0 : 1

        // ── icon ──────────────────────────────────────────────────────
        Image {
            id: img
            width: slot.iconSize
            height: slot.iconSize
            x: (cell.width - width) / 2
            y: cell.height - slot.pad - height - hop.y
            sourceSize: Qt.size(128, 128)
            smooth: true
            mipmap: true
            asynchronous: true
            source: slot.app.icon
            opacity: slot.pressed ? 0.65 : 1
            Behavior on opacity { NumberAnimation { duration: Theme.fast } }
        }

        // hop height lives in its own object so the animation never fights layout
        QtObject {
            id: hop
            property real y: 0
        }
        SequentialAnimation {
            running: Dock.isLaunching(slot.app.key) || (slot.urgent && !slot.active)
            loops: Animation.Infinite
            alwaysRunToEnd: true
            NumberAnimation { target: hop; property: "y"; to: 16; duration: 230; easing.type: Easing.OutQuad }
            NumberAnimation { target: hop; property: "y"; to: 0; duration: 230; easing.type: Easing.InQuad }
            PauseAnimation { duration: 140 }
        }

        // ── badge ─────────────────────────────────────────────────────
        Rectangle {
            id: orb
            visible: orb.scale > 0.01
            x: img.x + img.width - width + 4
            y: img.y - 3
            height: Math.round(16 * Math.sqrt(slot.mag))
            width: Math.max(height, num.implicitWidth + 9)
            radius: height / 2
            color: Theme.peach
            border.width: 1.5
            border.color: Theme.bg
            scale: slot.count > 0 || (slot.badge && slot.badge.urgent) ? 1 : 0
            Behavior on scale { NumberAnimation { duration: Theme.med; easing.type: Easing.OutBack } }

            Label {
                id: num
                anchors.centerIn: parent
                visible: slot.count > 0
                text: slot.count > 99 ? "99+" : slot.count
                color: Theme.onAccent
                font.pixelSize: Theme.fsXs
                font.weight: Font.Bold
                font.letterSpacing: 0
            }
        }

        // ── running dots ──────────────────────────────────────────────
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: cell.height - slot.pad + 2
            spacing: 3
            Repeater {
                model: Math.min(slot.app.windows.length, 3)
                Rectangle {
                    width: 4
                    height: 4
                    radius: 2
                    color: slot.active ? Theme.peach : Theme.soft
                    opacity: slot.active ? 1 : 0.6
                    Behavior on color { ColorAnimation { duration: Theme.med } }
                }
            }
        }

        // ── tooltip ───────────────────────────────────────────────────
        Item {
            id: tip
            readonly property bool show: slot.hovered && slot.tipAllowed && !slot.pressed
            width: tipText.implicitWidth + 20
            height: 24
            x: Math.round((cell.width - width) / 2)
            y: Math.round(img.y - height - 10 + (show ? 0 : 4))
            opacity: show ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.fast } }
            Behavior on y { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }

            Glass {
                anchors.fill: parent
                radius: 7
                color: Theme.panel
            }
            Label {
                id: tipText
                anchors.centerIn: parent
                text: slot.app.name
                color: Theme.text
            }
        }
    }
}
