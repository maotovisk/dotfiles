import QtQuick
import Quickshell.Hyprland
import qs.common
import qs.components
import qs.services

// Fixed-width numbered cells under one "liquid" peach pill. Its two edges
// animate separately: the leading edge moves fast, the trailing edge follows,
// so the pill stretches towards the target and settles into it.
Item {
    id: root

    readonly property int cell: 22
    readonly property int gap: 2
    readonly property var spaces: Hyprland.workspaces.values.filter(w => w.id > 0)
    readonly property int focusedId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    readonly property int count: Math.max(5, focusedId, ...spaces.map(w => w.id))

    // Hyprland 0.55 (Lua config): dispatch takes a Lua dispatcher expression
    function go(ws) {
        Hyprland.dispatch(`hl.dsp.focus({ workspace = "${ws}" })`)
    }

    function find(id) {
        return spaces.find(w => w.id === id) || null
    }

    implicitWidth: count * cell + (count - 1) * gap
    implicitHeight: Theme.chipH

    // ── the pill ───────────────────────────────────────────────────────
    // pill edges ("left"/"right" are taken by Item's anchor lines). Both are
    // derived from focusedId in one place — reading a dependent binding from a
    // change handler can see its stale value.
    property real lo: 0
    property real hi: cell

    function place(animate) {
        const l = (focusedId - 1) * (cell + gap)
        const forward = l > lo
        // leading edge: quick; trailing edge: lazier — the stretch comes from the gap between them
        leftAnim.duration = !animate ? 0 : forward ? 380 : 200
        rightAnim.duration = !animate ? 0 : forward ? 200 : 380
        lo = l
        hi = l + cell
    }

    onFocusedIdChanged: place(true)
    Component.onCompleted: {
        place(false)
        Hyprland.refreshMonitors()
        Hyprland.refreshWorkspaces()
    }

    Behavior on lo { NumberAnimation { id: leftAnim; easing.type: Easing.OutCubic } }
    Behavior on hi { NumberAnimation { id: rightAnim; easing.type: Easing.OutCubic } }

    Rectangle {
        x: root.lo
        width: root.hi - root.lo
        height: Theme.chipH
        radius: Theme.chipR
        color: Theme.peach
    }

    // ── cells ──────────────────────────────────────────────────────────
    Row {
        spacing: root.gap

        Repeater {
            model: root.count

            delegate: Item {
                id: cell
                required property int index
                readonly property int wsId: index + 1
                readonly property var ws: root.find(wsId)
                readonly property bool focused: wsId === root.focusedId
                readonly property bool occupied: !!ws && ws.toplevels.values.length > 0
                readonly property bool urgent: !!ws && ws.urgent
                // label flips to dark once the pill actually covers the cell
                readonly property bool covered: root.lo <= x + 4 && root.hi >= x + width - 4

                width: root.cell
                height: Theme.chipH

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.chipR
                    color: cell.urgent && !cell.focused ? Theme.redSoft
                         : mouse.containsMouse && !cell.covered ? Theme.hover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                }

                Label {
                    anchors.centerIn: parent
                    text: cell.wsId
                    font.pixelSize: Theme.fsXs
                    font.weight: Font.DemiBold
                    color: cell.covered ? Theme.onAccent
                         : cell.urgent ? Theme.red
                         : cell.occupied ? Theme.soft : Theme.dim
                    Behavior on color { ColorAnimation { duration: 90 } }
                }

                // occupied marker: a 2px dot under the number
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    width: 3
                    height: 2
                    radius: 1
                    color: cell.covered ? Theme.onAccent : Theme.muted
                    opacity: cell.occupied ? (cell.covered ? 0.5 : 0.8) : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.go(cell.wsId)
                }
            }
        }
    }

    HoverHandler {
        onHoveredChanged: Ui.wsHovered = hovered
    }

    WheelHandler {
        onWheel: e => root.go(e.angleDelta.y > 0 ? "r-1" : "r+1")
    }
}
