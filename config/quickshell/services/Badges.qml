pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Unity LauncherEntry badges (the count Discord & co. show on a dock icon).
// Apps only broadcast com.canonical.Unity.LauncherEntry.Update signals — there
// is nothing to query — so we sit on the bus with busctl and keep the latest
// state per app. Badges vanish when the sender drops off the bus.
Singleton {
    id: root

    property var entries: ({})               // app id → { app, sender, count, urgent, progress }
    readonly property var shown: Object.values(entries).filter(e => e.count > 0 || e.urgent)
        .sort((a, b) => a.app.localeCompare(b.app))

    function entry(app) {
        return DesktopEntries.byId(app) ?? DesktopEntries.heuristicLookup(app)
    }

    function icon(app) {
        const d = entry(app)
        return Ui.icon(d && d.icon ? d.icon : app) || Quickshell.iconPath("application-x-executable")
    }

    function focus(e) {
        const d = entry(e.app)
        const cls = d && d.startupClass ? d.startupClass : e.app
        Hyprland.dispatch(`hl.dsp.focus({ window = "class:^(${cls})$" })`)
    }

    function update(sender, uri, props) {
        const app = uri.replace(/^application:\/\//, "").replace(/\.desktop$/, "")
        const prev = entries[app] ?? { app: app, count: 0, urgent: false, progress: -1 }
        const val = k => props[k] ? props[k].data : undefined
        const next = Object.assign({}, prev, { sender: sender })

        if (val("count") !== undefined) next.rawCount = Number(val("count"))
        if (val("count-visible") !== undefined) next.countVisible = val("count-visible")
        if (val("urgent") !== undefined) next.urgent = val("urgent")
        if (val("progress") !== undefined) next.rawProgress = val("progress")
        if (val("progress-visible") !== undefined) next.progressVisible = val("progress-visible")
        next.count = next.countVisible ? (next.rawCount ?? 0) : 0
        next.progress = next.progressVisible ? (next.rawProgress ?? 0) : -1

        const all = Object.assign({}, entries)
        all[app] = next
        entries = all
    }

    function forget(sender) {
        const all = Object.assign({}, entries)
        let changed = false
        for (const k in all) {
            if (all[k].sender === sender) {
                delete all[k]
                changed = true
            }
        }
        if (changed)
            entries = all
    }

    Process {
        id: monitor
        running: true
        command: ["busctl", "--user", "monitor", "--json=short",
            "--match", "type='signal',interface='com.canonical.Unity.LauncherEntry',member='Update'",
            "--match", "type='signal',sender='org.freedesktop.DBus',member='NameOwnerChanged'"]
        stdout: SplitParser {
            onRead: line => {
                if (line[0] !== "{")
                    return
                let m
                try { m = JSON.parse(line) } catch (e) { return }
                const d = m.payload ? m.payload.data : null
                if (!d)
                    return
                if (m.member === "Update")
                    root.update(m.sender, d[0], d[1])
                else if (m.member === "NameOwnerChanged" && d[2] === "")
                    root.forget(d[0])
            }
        }
        onExited: restart.start()
    }

    Timer {
        id: restart
        interval: 3000
        onTriggered: monitor.running = true
    }
}
