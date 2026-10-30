import QtQuick
import Quickshell
import qs.overlay
import qs.state

// snip: frozen-desktop capture + annotation. Launched per shot by
// ~/.local/bin/snip, which grabs every output first and reads the exit code.
ShellRoot {
    // one-shot overlay: a hot reload mid-capture would replay/lose state
    settings.watchFiles: false

    Variants {
        model: Quickshell.screens
        ScreenOverlay {}
    }

    // dev only: SNIP_TEST=<json file> replays [{"do":"press"|"move"|"release"|"key"|"tool"|"accept", ...}]
    Loader {
        active: Quickshell.env("SNIP_TEST") !== null && Quickshell.env("SNIP_TEST") !== ""
        sourceComponent: TestDriver {}
    }
}
