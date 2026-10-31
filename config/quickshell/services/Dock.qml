pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Dock model: pinned apps (persisted) followed by running apps that aren't
// pinned, each with its windows. Windows are grouped by desktop entry id
// (falling back to the window class) so a pin and its running windows meet.
Singleton {
    id: root

    readonly property var pinned: store.loaded ? adapter.pinned : []
    property var launching: ({})             // key → launch time, while the icon bounces

    readonly property var apps: {
        const groups = {}
        const order = []
        for (const t of Hyprland.toplevels.values) {
            const c = windowClass(t)
            if (!c)
                continue
            const k = keyFor(c)
            if (!groups[k]) {
                groups[k] = []
                order.push(k)
            }
            groups[k].push(t)
        }
        const out = []
        for (const id of pinned)
            out.push(make(id, groups[id] ?? [], true))
        for (const k of order)
            if (!pinned.includes(k))
                out.push(make(k, groups[k], false))
        return out
    }

    readonly property string activeKey: {
        const t = Hyprland.activeToplevel
        const c = t ? windowClass(t) : ""
        return c ? keyFor(c) : ""
    }

    function windowClass(t) {
        return (t.lastIpcObject && t.lastIpcObject.class) || (t.wayland && t.wayland.appId) || ""
    }

    function keyFor(cls) {
        const e = DesktopEntries.byId(cls) ?? DesktopEntries.heuristicLookup(cls)
        return e ? e.id : cls
    }

    function make(key, wins, isPinned) {
        const e = DesktopEntries.byId(key) ?? DesktopEntries.heuristicLookup(key)
        // most recently focused first (focusHistoryID 0 = current)
        const sorted = wins.slice().sort((a, b) => fh(a) - fh(b))
        return {
            key: key,
            entry: e,
            name: e ? e.name : key,
            icon: (e && e.icon ? Ui.icon(e.icon) : "") || Ui.appIcon(key) || Quickshell.iconPath("application-x-executable"),
            windows: sorted,
            pinned: isPinned
        }
    }

    function fh(t) {
        const o = t.lastIpcObject
        return o && o.focusHistoryID !== undefined ? o.focusHistoryID : 999
    }

    function addr(t) {
        return "address:0x" + String(t.address).replace(/^0x/, "")
    }

    // ── actions ────────────────────────────────────────────────────────
    // nothing open → launch; app focused → cycle its windows; else → its last window
    function activate(app) {
        if (app.windows.length === 0)
            return launch(app)
        const active = Hyprland.activeToplevel
        const i = app.windows.indexOf(active)
        let target = app.windows[0]
        if (i >= 0) {
            // cycle in a stable order (address), not focus order, or it ping-pongs
            const stable = app.windows.slice().sort((a, b) => String(a.address).localeCompare(String(b.address)))
            target = stable[(stable.indexOf(active) + 1) % stable.length]
        }
        focus(target)
    }

    function focus(t) {
        Hyprland.dispatch(`hl.dsp.focus({ window = "${addr(t)}" })`)
    }

    function launch(app) {
        if (app.entry)
            app.entry.execute()
        else
            Quickshell.execDetached([app.key])
        const l = Object.assign({}, launching)
        l[app.key] = Date.now()
        launching = l
        launchExpiry.restart()
    }

    function close(app) {
        for (const t of app.windows)
            Hyprland.dispatch(`hl.dsp.window.close({ window = "${addr(t)}" })`)
    }

    function togglePin(key) {
        adapter.pinned = pinned.includes(key) ? pinned.filter(k => k !== key) : pinned.concat([key])
    }

    function movePin(key, to) {
        const list = pinned.filter(k => k !== key)
        list.splice(Math.max(0, Math.min(to, list.length)), 0, key)
        adapter.pinned = list
    }

    function isLaunching(key) {
        return launching[key] !== undefined
    }

    // a launch stops bouncing once a window shows up, or after 8s
    onAppsChanged: pruneLaunching()
    function pruneLaunching() {
        const now = Date.now()
        let changed = false
        const l = Object.assign({}, launching)
        for (const k in l) {
            const app = apps.find(a => a.key === k)
            if (now - l[k] > 8000 || (app && app.windows.length > 0)) {
                delete l[k]
                changed = true
            }
        }
        if (changed)
            launching = l
    }
    Timer {
        id: launchExpiry
        interval: 8100
        onTriggered: root.pruneLaunching()
    }

    // ── persistence: ~/.local/state/quickshell/…/dock.json ──────────────
    FileView {
        id: store
        property bool loaded: false
        path: Quickshell.statePath("dock.json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: loaded = true
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter()
            loaded = true
        }
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: adapter
            property list<string> pinned: ["zen", "kitty", "org.kde.dolphin", "com.microsoft.VSCode", "discord", "obsidian", "spotify"]
        }
    }
}
