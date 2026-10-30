import QtQuick
import qs.state

// The final image: frozen pixels + annotations, cropped to the selection.
// Lives under the opaque view (never seen) and is grabbed off-screen at the
// monitor's native resolution.
Item {
    id: root

    readonly property rect sel: Snip.selection

    z: -100
    width: sel.width
    height: sel.height
    clip: true

    Backdrop { region: root.sel }

    AnnotationLayer {
        x: -root.sel.x
        y: -root.sel.y
        exporting: true
    }

    // let the scene graph pick the item up before grabbing it
    Timer {
        running: true
        interval: 16
        onTriggered: {
            const sc = Snip.screenAt(root.sel.x + root.sel.width / 2, root.sel.y + root.sel.height / 2) || Snip.screens[0]
            const size = Qt.size(Math.round(root.sel.width * sc.scale), Math.round(root.sel.height * sc.scale))
            const ok = root.grabToImage(r => Snip.finish(r.saveToFile(Snip.outPath)), size)
            if (!ok) Snip.finish(false)
        }
    }
}
