import QtQuick
import Quickshell
import Quickshell.Io
import qs.state

// Dev aid: replays a scripted session so the overlay can be checked headless.
Item {
    id: root
    property var steps: []
    property int i: 0

    FileView {
        path: Quickshell.env("SNIP_TEST")
        onLoaded: { root.steps = JSON.parse(text()); tick.start() }
    }

    Timer {
        id: tick
        interval: 40
        repeat: true
        onTriggered: {
            if (root.i >= root.steps.length) { stop(); return }
            const s = root.steps[root.i++]
            const m = s.shift ? Qt.ShiftModifier : 0
            switch (s.do) {
            case "press": Snip.press(s.x, s.y, s.right ? Qt.RightButton : Qt.LeftButton, m); break
            case "move": Snip.move(s.x, s.y, m); break
            case "release": Snip.release(s.x, s.y); break
            case "tool": Snip.setTool(s.tool); break
            case "color": Snip.color = s.color; break
            case "size": Snip.sizeIndex = s.size; break
            case "type": Snip.typeText(Snip.draft.text + s.text); break
            case "commit": Snip.commitText(); break
            case "wait": interval = s.ms; return
            case "accept": Snip.accept(s.action); break
            }
            interval = 40
        }
    }
}
