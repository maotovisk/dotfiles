pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// UI state shared by the bar and popups. One popup open at a time.
Singleton {
    id: root

    property var bar: null                   // the bar PanelWindow (focus grabs include it)
    property string popup: ""                // "" | volume | network | notifs | sysmon | calendar | weather | player | overview | share
    property bool wsHovered: false           // pointer over the workspace pills (opens the overview)
    property string volumeTab: "output"      // output | input
    property string networkTab: "wifi"       // wifi | bluetooth
    property var looseIcons: ({})            // icon name → path, for unthemed files (see icon())

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
        return Quickshell.iconPath(name, true) || (looseIcons[name] ? "file://" + looseIcons[name] : "")
    }

    // AppImage managers drop bare PNGs in ~/.local/share/icons, which the icon theme
    // spec (and Qt) never search. Index those plus pixmaps; rescan when apps change.
    Process {
        id: iconScan
        running: true
        command: ["find", "-L", Quickshell.env("HOME") + "/.local/share/icons", "/usr/share/pixmaps",
            "-maxdepth", "1", "-type", "f", "(", "-name", "*.png", "-o", "-name", "*.svg", "-o", "-name", "*.xpm", ")"]
        stdout: StdioCollector {
            onStreamFinished: {
                const map = {}
                for (const path of text.split("\n").filter(l => l)) {
                    const name = path.replace(/^.*\//, "").replace(/\.[^.]+$/, "")
                    if (!(name in map))
                        map[name] = path
                }
                root.looseIcons = map
            }
        }
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { iconScan.running = true }
    }

    // window class → its desktop entry's icon
    function appIcon(cls) {
        if (!cls)
            return ""
        return icon(DesktopEntries.heuristicLookup(cls)?.icon ?? cls.toLowerCase())
    }
}
