pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Wallpaper per monitor, straight from hyprpaper's config.
Singleton {
    id: root

    property var byMonitor: ({})                     // monitor name → file path

    function url(monitorName) {
        const p = byMonitor[monitorName]
        return p ? "file://" + p : ""
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/hypr/hyprpaper.conf"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const out = {}
            const re = /wallpaper\s*\{([^}]*)\}/g
            let m
            while ((m = re.exec(text())) !== null) {
                const mon = (m[1].match(/monitor\s*=\s*(\S+)/) || [])[1]
                const path = (m[1].match(/path\s*=\s*(.+)/) || [])[1]
                if (mon && path)
                    out[mon] = path.trim().replace(/^~/, Quickshell.env("HOME"))
            }
            root.byMonitor = out
        }
    }
}
