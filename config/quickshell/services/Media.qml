pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// MPRIS players. `player` follows whatever is playing unless the user
// picked one in the player popout.
Singleton {
    id: root

    readonly property var players: Mpris.players.values.filter(p => p.identity.toLowerCase() !== "playerctld")
    property var pinned: null                // user's pick; cleared when it disappears
    readonly property var player: (pinned && players.includes(pinned)) ? pinned
        : players.find(p => p.isPlaying) ?? players[0] ?? null
    readonly property bool playing: !!player && player.isPlaying
    readonly property bool hasTrack: !!player && (player.trackTitle || "") !== ""

    readonly property bool timed: !!player && player.lengthSupported && player.length > 0
    readonly property real progress: timed ? Math.min(1, player.position / player.length) : 0

    // MprisPlayer.position doesn't notify on its own while playing
    property bool ticking: false
    Timer {
        interval: 1000
        repeat: true
        running: root.ticking && root.playing && root.timed
        onTriggered: root.player.positionChanged()
    }

    function seek(fraction) {
        if (player && player.canSeek && timed)
            player.position = fraction * player.length
    }

    function cycleLoop() {
        if (!player || !player.loopSupported)
            return
        player.loopState = player.loopState === MprisLoopState.None ? MprisLoopState.Playlist
            : player.loopState === MprisLoopState.Playlist ? MprisLoopState.Track
            : MprisLoopState.None
    }

    function clock(seconds) {
        const s = Math.max(0, Math.floor(seconds))
        const h = Math.floor(s / 3600)
        const m = Math.floor(s % 3600 / 60)
        const ss = String(s % 60).padStart(2, "0")
        return h > 0 ? h + ":" + String(m).padStart(2, "0") + ":" + ss : m + ":" + ss
    }

    function appIcon(p) {
        return p && p.desktopEntry ? Ui.icon(DesktopEntries.byId(p.desktopEntry)?.icon ?? p.desktopEntry) : ""
    }
}
