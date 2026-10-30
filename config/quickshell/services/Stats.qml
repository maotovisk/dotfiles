pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// System stats from /proc and /sys via FileView. The bar needs three numbers;
// the monitor popout sets `detailed` and gets per-core load, temperatures,
// GPU, memory breakdown, network rates and top processes on top.
Singleton {
    id: root

    property bool detailed: false            // the monitor popout is open

    // ── bar ─────────────────────────────────────────────────────────────
    property int cpu: 0
    property int mem: 0
    property int disk: 0
    readonly property var history: cpuHistory.slice(-16)   // bar sparkline, 0..1

    // ── detail ──────────────────────────────────────────────────────────
    property var cpuHistory: []              // last 60 samples, 0..1
    property var memHistory: []
    property var cores: []                   // per-thread %, 0..100
    property real memTotal: 0                // bytes
    property real memUsed: 0
    property real memCached: 0
    property real swapTotal: 0
    property real swapUsed: 0
    property real diskUsed: 0
    property real diskSize: 0
    property int cpuTemp: 0
    property int gpu: -1                     // -1: no GPU readout
    property int gpuTemp: 0
    property real vramUsed: 0
    property real vramTotal: 0
    property int nvmeTemp: 0
    property real rx: 0                      // bytes/s on the routed interface
    property real tx: 0
    property var netHistory: []              // { rx, tx } last 60
    property real uptime: 0
    property string load: ""
    property var procs: []                   // [{ pid, name, cpu, mem }]
    readonly property string host: hostFile.text().trim()
    readonly property string cpuModel: model.text().match(/model name\s*:\s*(.+)/)?.[1]?.replace(/\s+\d+-Core Processor/, "") ?? ""

    property var lastTicks: []               // per line of /proc/stat: [idle, total]
    property var lastNet: null

    FileView { id: procStat; path: "/proc/stat" }
    FileView { id: procMem; path: "/proc/meminfo" }
    FileView { id: netDev; path: "/proc/net/dev" }
    FileView { id: upFile; path: "/proc/uptime" }
    FileView { id: loadFile; path: "/proc/loadavg" }
    FileView { id: model; path: "/proc/cpuinfo"; blockLoading: true }
    FileView { id: hostFile; path: "/etc/hostname"; blockLoading: true }

    // sensor paths, resolved once (hwmon numbering isn't stable across boots)
    property string cpuTempPath: ""
    property string gpuTempPath: ""
    property string nvmeTempPath: ""
    property string gpuDevice: ""
    FileView { id: cpuTempFile; path: root.cpuTempPath }
    FileView { id: gpuTempFile; path: root.gpuTempPath }
    FileView { id: nvmeTempFile; path: root.nvmeTempPath }
    FileView { id: gpuBusy; path: root.gpuDevice ? root.gpuDevice + "/gpu_busy_percent" : "" }
    FileView { id: vramUsedFile; path: root.gpuDevice ? root.gpuDevice + "/mem_info_vram_used" : "" }
    FileView { id: vramTotalFile; path: root.gpuDevice ? root.gpuDevice + "/mem_info_vram_total" : "" }

    Process {
        running: true
        command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do echo \"hwmon $h $(cat $h/name)\"; done; "
            + "for c in /sys/class/drm/card[0-9]*; do [ -e $c/device/gpu_busy_percent ] && echo \"gpu $c/device\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    const [kind, path, name] = line.split(" ")
                    // first match wins for each sensor
                    if (kind === "gpu" && !root.gpuDevice) root.gpuDevice = path
                    else if ((name === "k10temp" || name === "coretemp") && !root.cpuTempPath) root.cpuTempPath = path + "/temp1_input"
                    else if (name === "amdgpu" && !root.gpuTempPath) root.gpuTempPath = path + "/temp1_input"
                    else if (name === "nvme" && !root.nvmeTempPath) root.nvmeTempPath = path + "/temp1_input"
                }
            }
        }
    }

    Timer {
        interval: root.detailed ? 1000 : 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            procStat.reload()
            procMem.reload()
            root.sampleCpu(procStat.text())
            root.sampleMem(procMem.text())
            if (root.detailed)
                root.sampleDetail()
        }
    }

    function sampleCpu(text) {
        // "cpu" (total) then "cpu0".."cpuN"
        const lines = text.split("\n").filter(l => l.startsWith("cpu"))
        const ticks = lines.map(l => {
            const f = l.trim().split(/\s+/).slice(1).map(Number)
            return [f[3] + f[4], f.reduce((a, b) => a + b, 0)]
        })
        const pct = ticks.map((t, i) => {
            const prev = lastTicks[i]
            if (!prev || t[1] <= prev[1])
                return 0
            const dt = t[1] - prev[1]
            return Math.max(0, Math.min(100, Math.round(100 * (dt - (t[0] - prev[0])) / dt)))
        })
        const first = lastTicks.length === 0
        lastTicks = ticks
        if (first)
            return
        cpu = pct[0]
        cores = pct.slice(1)
        cpuHistory = cpuHistory.slice(-59).concat([cpu / 100])
    }

    function kb(text, key) {
        return Number((text.match(new RegExp(key + ":\\s+(\\d+)")) || [])[1] || 0) * 1024
    }

    function sampleMem(text) {
        memTotal = kb(text, "MemTotal")
        if (memTotal <= 0)
            return
        memUsed = memTotal - kb(text, "MemAvailable")
        memCached = kb(text, "Cached") + kb(text, "Buffers")
        swapTotal = kb(text, "SwapTotal")
        swapUsed = swapTotal - kb(text, "SwapFree")
        mem = Math.round(100 * memUsed / memTotal)
        memHistory = memHistory.slice(-59).concat([memUsed / memTotal])
    }

    function sampleDetail() {
        for (const f of [netDev, upFile, loadFile, cpuTempFile, gpuTempFile, nvmeTempFile, gpuBusy, vramUsedFile, vramTotalFile])
            if (f.path !== "") f.reload()

        uptime = Number(upFile.text().split(" ")[0]) || 0
        load = loadFile.text().split(" ").slice(0, 3).join("  ")
        if (cpuTempPath) cpuTemp = Math.round(Number(cpuTempFile.text()) / 1000)
        if (gpuTempPath) gpuTemp = Math.round(Number(gpuTempFile.text()) / 1000)
        if (nvmeTempPath) nvmeTemp = Math.round(Number(nvmeTempFile.text()) / 1000)
        if (gpuDevice) {
            gpu = Number(gpuBusy.text()) || 0
            vramUsed = Number(vramUsedFile.text()) || 0
            vramTotal = Number(vramTotalFile.text()) || 0
        }

        // network: bytes/s on the routed interface
        const row = netDev.text().split("\n").find(l => l.trim().startsWith(Net.iface + ":"))
        if (row) {
            const f = row.split(":")[1].trim().split(/\s+/).map(Number)
            const now = { t: Date.now(), rx: f[0], tx: f[8] }
            if (lastNet && now.t > lastNet.t) {
                const dt = (now.t - lastNet.t) / 1000
                rx = Math.max(0, (now.rx - lastNet.rx) / dt)
                tx = Math.max(0, (now.tx - lastNet.tx) / dt)
                netHistory = netHistory.slice(-59).concat([{ rx: rx, tx: tx }])
            }
            lastNet = now
        }
    }

    // ── disk: statvfs isn't reachable from JS — one tiny df per minute ──
    Process {
        id: df
        command: ["df", "-B1", "--output=used,size,pcent", "/"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const f = (text.split("\n")[1] || "").trim().split(/\s+/)
                root.diskUsed = Number(f[0]) || 0
                root.diskSize = Number(f[1]) || 0
                root.disk = parseInt(f[2]) || 0
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: df.running = true
    }

    // ── top processes: top's *second* frame is a real 0.8s sample
    //    (ps %cpu is a lifetime average). Only while the popout is open. ──
    Process {
        id: top
        command: ["top", "-b", "-n", "2", "-d", "0.8", "-o", "%CPU", "-w", "256"]
        stdout: StdioCollector {
            onStreamFinished: {
                const frames = text.split(/^top - /m)
                const last = frames[frames.length - 1].split("\n")
                const head = last.findIndex(l => /^\s*PID\s/.test(l))
                if (head < 0)
                    return
                const cols = last[head].trim().split(/\s+/)
                const ci = cols.indexOf("%CPU"), mi = cols.indexOf("%MEM"), ni = cols.indexOf("COMMAND")
                root.procs = last.slice(head + 1).filter(l => l.trim() !== "").slice(0, 6).map(l => {
                    const f = l.trim().split(/\s+/)
                    return { pid: f[0], name: f.slice(ni).join(" "), cpu: Number(f[ci].replace(",", ".")), mem: Number(f[mi].replace(",", ".")) }
                })
            }
        }
    }

    Timer {
        interval: 2500
        running: root.detailed
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!top.running) top.running = true
    }

    onDetailedChanged: if (detailed) df.running = true

    // ── formatting ──────────────────────────────────────────────────────
    function bytes(b, digits) {
        const u = ["B", "KB", "MB", "GB", "TB"]
        let i = 0
        while (b >= 1024 && i < u.length - 1) { b /= 1024; i++ }
        return b.toFixed(i >= 3 ? (digits ?? 1) : 0) + " " + u[i]
    }

    function rate(b) {
        return bytes(b, 1) + "/s"
    }

    function duration(s) {
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60)
        return d > 0 ? d + "d " + h + "h" : h > 0 ? h + "h " + m + "min" : m + " min"
    }
}
