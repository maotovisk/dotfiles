pragma Singleton

import QtQuick
import Quickshell

// UI state shared by the bar and popups. One popup open at a time.
Singleton {
    id: root

    property var bar: null                   // the bar PanelWindow (focus grabs include it)
    property string popup: ""                // "" | volume | network | notifs | sysmon | calendar | weather | player | overview
    property bool wsHovered: false           // pointer over the workspace pills (opens the overview)
    property string volumeTab: "output"      // output | input
    property string networkTab: "wifi"       // wifi | bluetooth

    function toggle(name) {
        popup = popup === name ? "" : name
    }

    function close(name) {
        if (name === undefined || popup === name)
            popup = ""
    }

    // tabbed popups: same chip again closes, the other chip switches tab
    function toggleTab(name, tab) {
        const key = name + "Tab"
        if (popup === name && root[key] === tab) {
            popup = ""
            return
        }
        root[key] = tab
        popup = name
    }

    // themed icon name, absolute path, or URL → something Image/IconImage can load
    function icon(name) {
        if (!name)
            return ""
        if (name.startsWith("/"))
            return "file://" + name
        if (name.includes("://"))
            return name
        return Quickshell.iconPath(name, true)
    }
}
