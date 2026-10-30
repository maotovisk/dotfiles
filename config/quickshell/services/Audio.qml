pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Pipewire view: default devices, device lists and per-app streams.
// Every node exposed here is tracked so its volume/mute stay bound.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property var nodes: Pipewire.ready ? Pipewire.nodes.values : []
    // filter on `type`: `properties` stays empty until a node is tracked, and
    // only filtered nodes get tracked
    readonly property var sinks: nodes.filter(n => n.type === PwNodeType.AudioSink && !internal(n))
    readonly property var sources: nodes.filter(n => n.type === PwNodeType.AudioSource && !internal(n))
    readonly property var playing: nodes.filter(n => n.type === PwNodeType.AudioOutStream && !internal(n) && !ours(n))
    readonly property var recording: nodes.filter(n => n.type === PwNodeType.AudioInStream && !internal(n) && !ours(n))

    readonly property int volume: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool muted: !!(sink && sink.audio && sink.audio.muted)
    readonly property int micVolume: source && source.audio ? Math.round(source.audio.volume * 100) : 0
    readonly property bool micMuted: !!(source && source.audio && source.audio.muted)
    readonly property bool micLive: recording.length > 0 && !micMuted

    PwObjectTracker {
        objects: [root.sink, root.source].concat(root.sinks, root.sources, root.playing, root.recording)
    }

    function kind(n) {
        return (n.properties && n.properties["media.class"]) || ""
    }

    // loopback/split plumbing (".../Internal" classes) isn't something to pick or mix
    function internal(n) {
        return kind(n).endsWith("/Internal")
    }

    // the shell's own peak monitors show up as capture streams — hide them
    function ours(n) {
        return /quickshell/i.test((n.properties && n.properties["application.name"]) || n.name || "")
    }

    function deviceName(n) {
        return n ? (n.description || n.nickname || n.name) : "Nenhum dispositivo"
    }

    function appName(n) {
        const p = n.properties || {}
        return p["application.name"] || n.description || n.name
    }

    function appDetail(n) {
        const p = n.properties || {}
        return p["media.name"] && p["media.name"] !== appName(n) ? p["media.name"] : ""
    }

    function appIcon(n) {
        const p = n.properties || {}
        return p["application.icon-name"] || (p["application.process.binary"] || appName(n) || "").toLowerCase()
    }

    function speakerIcon(vol, muted) {
        return muted || vol === 0 ? "volume-x" : vol < 34 ? "volume" : vol < 67 ? "volume-1" : "volume-2"
    }

    function setVolume(n, v) {
        if (n && n.audio) {
            n.audio.muted = false
            n.audio.volume = Math.max(0, Math.min(1.5, v))
        }
    }

    function nudge(n, delta) {
        if (n && n.audio)
            setVolume(n, Math.min(1, n.audio.volume + delta))
    }

    function toggleMute(n) {
        if (n && n.audio)
            n.audio.muted = !n.audio.muted
    }

    function setDefault(n) {
        if (n.type === PwNodeType.AudioSink)
            Pipewire.preferredDefaultAudioSink = n
        else
            Pipewire.preferredDefaultAudioSource = n
    }
}
