import QtQuick
import qs.state

// Everything drawn so far plus the stroke in progress. Its origin is the
// desktop origin; the owner offsets it to its own view.
Item {
    id: root

    property bool exporting: false

    Repeater {
        model: Snip.items
        Annotation {
            required property var modelData
            a: modelData
        }
    }

    Annotation {
        a: Snip.draft
        editing: Snip.editingText && !root.exporting
    }
}
