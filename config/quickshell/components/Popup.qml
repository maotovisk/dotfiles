import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.common
import qs.services

// A glass card hanging under the bar. Owns its window, its open/close motion,
// click-away (Hyprland focus grab, bar stays clickable) and Esc.
PanelWindow {
    id: win

    property bool open: false
    property int cardWidth: 352
    property string align: "right"          // "left" | "center" | "right" — which island it hangs from
    property bool grab: true                // click-away + keyboard; off for hover-driven popups
    property string ns: "quickshell-popup"
    property int padding: 14
    default property alias content: column.data
    property alias backdrop: backdropHost.data       // full-bleed layer behind the content
    readonly property bool hovered: cardHover.hovered
    property alias spacing: column.spacing

    signal dismissed()

    // headroom so the drop-in offset and outer ring never get clipped
    readonly property int room: 10
    property real progress: open ? 1 : 0
    Behavior on progress {
        NumberAnimation {
            duration: win.open ? Theme.med : Theme.fast
            easing.type: win.open ? Easing.OutCubic : Easing.InCubic
        }
    }

    visible: open || progress > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors.top: true
    anchors.left: align === "left"
    anchors.right: align === "right"
    margins.top: Theme.popupTop - room
    margins.left: align === "left" ? Theme.edge - room : 0
    margins.right: align === "right" ? Theme.edge - room : 0
    implicitWidth: cardWidth + room * 2
    // Fixed height: content can grow/shrink/animate without resizing the
    // surface every frame (resizes land on the compositor's clock, not ours,
    // and make everything wobble). Transparent + masked to the card.
    implicitHeight: (screen ? screen.height : 1080) - Theme.popupTop + room

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: ns
    WlrLayershell.keyboardFocus: open && grab ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: Region { item: card }

    HyprlandFocusGrab {
        active: win.grab && win.open && win.visible
        windows: Ui.bar ? [win, Ui.bar] : [win]
        onCleared: win.dismissed()
    }

    Item {
        id: card
        x: win.room
        y: Math.round(win.room - 8 * (1 - win.progress))
        width: win.cardWidth
        height: Math.round(column.implicitHeight + win.padding * 2)
        opacity: win.progress
        scale: 0.965 + 0.035 * win.progress
        transformOrigin: win.align === "right" ? Item.TopRight : win.align === "left" ? Item.TopLeft : Item.Top

        focus: true
        Keys.onEscapePressed: win.dismissed()
        HoverHandler { id: cardHover }

        Glass {
            anchors.fill: parent
            radius: Theme.popupR
            color: Theme.panel
        }

        ClippingRectangle {
            id: backdropClip
            anchors.fill: parent
            anchors.margins: 1                       // keep the hairline border on top
            radius: Theme.popupR - 1
            color: "transparent"

            // children of a ClippingRectangle are only clipped inside its content item
            Item {
                id: backdropHost
                anchors.fill: parent
            }
        }

        Column {
            id: column
            x: win.padding
            y: win.padding
            width: win.cardWidth - win.padding * 2
            spacing: 12
        }
    }
}
