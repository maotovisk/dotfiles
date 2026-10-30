pragma Singleton

import QtQuick
import Quickshell

// Vesper design tokens. Everything visual reads from here.
Singleton {
    // ── surfaces ────────────────────────────────────────────────────────
    readonly property color bg: "#101010"
    readonly property color island: "#B8101010"      // α .72: dark tint over Hyprland blur
    readonly property color panel: "#CC0F0F0F"       // popups a touch denser for legibility
    readonly property color well: "#0BFFFFFF"        // recessed blocks inside panels
    readonly property color hover: "#10FFFFFF"
    readonly property color press: "#1AFFFFFF"

    // ── lines ───────────────────────────────────────────────────────────
    readonly property color border: "#12FFFFFF"
    readonly property color borderHover: "#42FFC799"
    readonly property color sheen: "#16FFFFFF"       // 1px inner top highlight
    readonly property color outline: "#73000000"     // outer dark ring, separates from bright wallpapers
    readonly property color divider: "#14FFFFFF"

    // ── text ────────────────────────────────────────────────────────────
    readonly property color text: "#F1F1F1"
    readonly property color soft: "#D3D3D3"
    readonly property color muted: "#8F8F8F"
    readonly property color dim: "#5A5A5A"

    // ── accents ─────────────────────────────────────────────────────────
    readonly property color peach: "#FFC799"
    readonly property color peachSoft: "#24FFC799"
    readonly property color mint: "#99FFE4"
    readonly property color blue: "#9DB2E8"
    readonly property color red: "#FF8080"
    readonly property color redSoft: "#26FF8080"
    readonly property color onAccent: "#141414"

    // ── type: one scale, one family ─────────────────────────────────────
    readonly property string font: "Instrument Sans"
    readonly property int fsCaps: 9
    readonly property int fsXs: 10
    readonly property int fsSm: 11
    readonly property int fsMd: 12
    readonly property int fsLg: 15

    // ── metrics: bar window 34 + top margin 4 = 38px reserved (≤ 42) ────
    readonly property int barMargin: 4
    readonly property int barH: 34
    readonly property int islandH: 30
    readonly property int islandR: 9
    readonly property int chipH: 22
    readonly property int chipR: 6
    readonly property int edge: 8            // screen-edge gap for islands and popups
    readonly property int popupR: 14
    readonly property int popupGap: 6
    readonly property int popupTop: barMargin + barH + popupGap

    // ── motion ──────────────────────────────────────────────────────────
    readonly property int fast: 150
    readonly property int med: 220
    readonly property int slow: 300
}
