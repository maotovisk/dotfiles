import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.common
import qs.components
import qs.services

// App icon + focused window title. Crossfades only when the focused *window*
// changes; title updates within the same window are applied in place.
Item {
    id: root

    readonly property var client: Hyprland.activeToplevel
    readonly property bool present: !!client && !!client.workspace && client.workspace === Hyprland.focusedWorkspace
    readonly property string appClass: present && client.lastIpcObject ? (client.lastIpcObject.class || "") : ""
    // terminals and TUIs (Claude Code, btop, …) prefix titles with spinners
    // and status glyphs that tick every second — drop them so the text and
    // the island width stay still
    readonly property string caption: present
        ? client.title.replace(/^[\s\u2800-\u28FF\u25D0-\u25D3\u2722-\u273D\u00B7*•]+/, "")
        : "Área de trabalho"

    onClientChanged: fade.restart()
    onPresentChanged: fade.restart()

    implicitWidth: row.implicitWidth + 14
    implicitHeight: Theme.chipH

    Row {
        id: row
        x: 7
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7

        IconImage {
            visible: root.present && source != ""
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: 14
            source: root.appClass ? Ui.icon(DesktopEntries.heuristicLookup(root.appClass)?.icon ?? root.appClass.toLowerCase()) : ""
        }

        Label {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 340)
            elide: Text.ElideRight
            text: root.caption
            color: root.present ? Theme.soft : Theme.dim

            NumberAnimation {
                id: fade
                target: label
                property: "opacity"
                from: 0.2
                to: 1
                duration: Theme.med
                easing.type: Easing.OutCubic
            }
        }
    }
}
