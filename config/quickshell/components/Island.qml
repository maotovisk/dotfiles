import QtQuick
import qs.common

// One bar island: Glass pill holding a centred row of chips.
Item {
    id: root

    default property alias content: row.data
    property int hPad: 4
    property alias spacing: row.spacing
    property bool lit: false
    readonly property bool hovered: hover.hovered

    implicitWidth: row.implicitWidth + hPad * 2
    implicitHeight: Theme.islandH

    Glass {
        anchors.fill: parent
        lit: root.hovered || root.lit
    }

    HoverHandler { id: hover }

    Row {
        id: row
        x: root.hPad
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
    }
}
