import QtQuick
import qs.common

// Vertical hairline between groups in an island.
Rectangle {
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    implicitWidth: 1
    implicitHeight: 12
    color: Theme.divider
}
