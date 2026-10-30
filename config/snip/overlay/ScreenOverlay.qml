import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.state

// One frozen monitor. Overlay layer, so it sits above fullscreen games too.
PanelWindow {
    id: win

    required property var modelData
    readonly property var info: Snip.screens.find(s => s.name === modelData.name) || ({ x: 0, y: 0, w: 0, h: 0, src: "" })
    // the off-screen exporter only needs to exist once
    readonly property bool exportHost: Snip.screens.length > 0 && Snip.screens[0].name === info.name

    readonly property rect sel: Qt.rect(Snip.selection.x - info.x, Snip.selection.y - info.y, Snip.selection.width, Snip.selection.height)
    readonly property bool cursorHere: Snip.cursor.x >= info.x && Snip.cursor.x < info.x + info.w
                                    && Snip.cursor.y >= info.y && Snip.cursor.y < info.y + info.h
    readonly property bool busy: Snip.exporting !== ""

    screen: modelData
    color: "black"
    exclusionMode: ExclusionMode.Ignore
    anchors { left: true; right: true; top: true; bottom: true }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "snip"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    function gx(x) { return x + info.x }
    function gy(y) { return y + info.y }

    // ── the frozen frame + annotations ──────────────────────────────────
    Image {
        anchors.fill: parent
        source: win.info.src
        asynchronous: false
        smooth: win.info.scale !== 1
    }

    AnnotationLayer {
        x: -win.info.x
        y: -win.info.y
    }

    // ── chrome ──────────────────────────────────────────────────────────
    Scrim {
        anchors.fill: parent
        color: Snip.hasSelection ? Theme.scrim : Theme.scrimIdle
        hasHole: Snip.hasSelection || Snip.hoverWindow !== null
        hole: Snip.hasSelection ? win.sel
            : Snip.hoverWindow ? Qt.rect(Snip.hoverWindow.x - win.info.x, Snip.hoverWindow.y - win.info.y, Snip.hoverWindow.w, Snip.hoverWindow.h)
            : Qt.rect(0, 0, 0, 0)
    }

    // window under the pointer, before anything is selected
    Rectangle {
        readonly property var w: Snip.hoverWindow
        visible: w !== null && !Snip.hasSelection
        x: w ? w.x - win.info.x : 0
        y: w ? w.y - win.info.y : 0
        width: w ? w.w : 0
        height: w ? w.h : 0
        color: "transparent"
        border.width: 2
        border.color: Theme.peach

        Pill {
            visible: parent.w !== null && parent.width > 160
            x: 8; y: 8
            text: parent.w ? (parent.w.title || parent.w.class) + "   " + parent.w.w + " × " + parent.w.h : ""
            width: Math.min(implicitWidth, parent.width - 16)
            clip: true
        }
    }

    // selection frame + handles
    Item {
        visible: Snip.hasSelection
        x: win.sel.x
        y: win.sel.y
        width: win.sel.width
        height: win.sel.height

        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            color: "transparent"
            border.width: 1
            border.color: Theme.peach
        }

        Repeater {
            model: Snip.tool === "select" && !win.busy ? [[0, 0], [0.5, 0], [1, 0], [0, 0.5], [1, 0.5], [0, 1], [0.5, 1], [1, 1]] : []
            Rectangle {
                required property var modelData
                width: 9; height: 9; radius: 4.5
                x: modelData[0] * parent.width - width / 2
                y: modelData[1] * parent.height - height / 2
                color: Theme.text
                border.width: 1.5
                border.color: Theme.peach
            }
        }
    }

    // size readout, tucked inside when the selection hugs the top edge
    Pill {
        readonly property bool here: Snip.hasSelection && win.sel.x >= 0 && win.sel.x < win.width && win.sel.y >= 0 && win.sel.y < win.height
        visible: here
        text: Snip.selection.width + " × " + Snip.selection.height
        x: win.sel.x
        y: win.sel.y >= height + 6 ? win.sel.y - height - 6 : win.sel.y + 6
    }

    // ── input ───────────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        enabled: !win.busy && !Snip.testing
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Snip.cursorShapeAt(Snip.cursor.x, Snip.cursor.y)
        onPressed: m => Snip.press(win.gx(m.x), win.gy(m.y), m.button, m.modifiers)
        onPositionChanged: m => Snip.move(win.gx(m.x), win.gy(m.y), m.modifiers)
        onReleased: m => Snip.release(win.gx(m.x), win.gy(m.y))
        onDoubleClicked: m => Snip.doubleClick(win.gx(m.x), win.gy(m.y))
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: ev => Snip.key(ev)
    }

    // ── floating UI ─────────────────────────────────────────────────────
    Pill {
        visible: !Snip.hasSelection && Snip.mode === "none" && !win.busy
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 48
        text: "Drag to select  ·  Click a window or screen  ·  Ctrl+A all screens  ·  Enter this screen  ·  Esc cancel"
    }

    Toolbar {
        id: toolbar
        readonly property bool here: Snip.toolbarPos.x >= win.info.x && Snip.toolbarPos.x < win.info.x + win.info.w
                                  && Snip.toolbarPos.y >= win.info.y && Snip.toolbarPos.y < win.info.y + win.info.h
        x: Snip.toolbarPos.x - win.info.x
        y: Snip.toolbarPos.y - win.info.y
        visible: here && opacity > 0
        opacity: Snip.hasSelection && Snip.mode === "none" && !win.busy ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.med; easing.type: Easing.OutCubic } }
        Component.onCompleted: Snip.toolbarSize = Qt.size(implicitWidth, implicitHeight)
    }

    Loupe {
        readonly property point at: Qt.point(Snip.cursor.x - win.info.x, Snip.cursor.y - win.info.y)
        visible: win.cursorHere && (Snip.mode === "new" || Snip.mode === "resize")
        source: win.info.src
        sourceSize: Qt.size(win.info.w, win.info.h)
        caption: Math.round(Snip.cursor.x) + ", " + Math.round(Snip.cursor.y)
        x: at.x + 24 + width > win.width ? at.x - 24 - width : at.x + 24
        y: at.y + 24 + height > win.height ? at.y - 24 - height : at.y + 24
    }

    Loader {
        active: win.busy && win.exportHost
        sourceComponent: Exporter {}
    }
}
