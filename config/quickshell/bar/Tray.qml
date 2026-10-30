import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.common
import qs.services

// System tray: L activate, M secondary, R menu.
Row {
    id: root
    spacing: 0

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: entry
            required property SystemTrayItem modelData
            width: Theme.chipH + 2
            height: Theme.chipH

            Rectangle {
                anchors.fill: parent
                radius: Theme.chipR
                color: mouse.pressed ? Theme.press : mouse.containsMouse ? Theme.hover : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.fast } }
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: 14
                source: entry.modelData.icon
                // tray icons come in every colour; desaturate a bit so they sit with the palette
                opacity: mouse.containsMouse ? 1 : 0.82
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: m => {
                    const item = entry.modelData
                    if (m.button === Qt.RightButton || (m.button === Qt.LeftButton && item.onlyMenu)) {
                        if (item.hasMenu) {
                            const p = entry.mapToItem(null, 0, entry.height + 6)
                            item.display(Ui.bar, p.x, p.y)
                        }
                    } else if (m.button === Qt.MiddleButton) {
                        item.secondaryActivate()
                    } else {
                        item.activate()
                    }
                }
                onWheel: w => entry.modelData.scroll(w.angleDelta.y, false)
            }
        }
    }
}
