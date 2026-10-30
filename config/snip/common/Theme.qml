pragma Singleton

import QtQuick
import Quickshell

// Vesper tokens, trimmed copy of quickshell/common/Theme.qml (separate config,
// so it can't import the bar's module).
Singleton {
    readonly property color panel: "#E6101010"
    readonly property color hover: "#14FFFFFF"
    readonly property color press: "#22FFFFFF"
    readonly property color border: "#1AFFFFFF"
    readonly property color sheen: "#16FFFFFF"
    readonly property color outline: "#73000000"
    readonly property color divider: "#18FFFFFF"

    readonly property color text: "#F1F1F1"
    readonly property color soft: "#D3D3D3"
    readonly property color muted: "#8F8F8F"

    readonly property color peach: "#FFC799"
    readonly property color peachSoft: "#30FFC799"
    readonly property color red: "#FF8080"
    readonly property color onAccent: "#141414"

    readonly property color scrim: "#8C000000"       // outside the selection
    readonly property color scrimIdle: "#59000000"   // before anything is selected

    readonly property string font: "Instrument Sans"
    readonly property int fsSm: 11
    readonly property int fsMd: 12

    readonly property int fast: 120
    readonly property int med: 200
}
