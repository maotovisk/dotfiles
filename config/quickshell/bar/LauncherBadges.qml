import QtQuick
import Quickshell
import qs.common
import qs.components
import qs.services

// Unread badges from apps (Unity LauncherEntry): tiny app icon + count orb.
// L: focus the app's window.
Row {
    id: root
    spacing: 0
    visible: Badges.shown.length > 0

    Repeater {
        // keyed by app so a delegate survives count updates (and can bump)
        model: ScriptModel {
            values: Badges.shown
            objectProp: "app"
        }

        delegate: Item {
            id: badge
            required property var modelData
            readonly property int count: modelData.count
            width: Theme.chipH + 6
            height: Theme.chipH

            Rectangle {
                anchors.fill: parent
                radius: Theme.chipR
                color: mouse.pressed ? Theme.press : mouse.containsMouse ? Theme.hover : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.fast } }
            }

            Image {
                id: icon
                x: 5
                anchors.verticalCenter: parent.verticalCenter
                width: 15
                height: 15
                sourceSize: Qt.size(30, 30)
                smooth: true
                mipmap: true
                source: Badges.icon(badge.modelData.app)
                opacity: mouse.containsMouse ? 1 : 0.9
            }

            // count orb, ringed in the island tint so it reads over the icon
            Rectangle {
                id: orb
                x: icon.x + icon.width - width / 2 - 1
                y: icon.y - 3
                height: 13
                width: Math.max(height, num.implicitWidth + 7)
                radius: height / 2
                color: Theme.peach
                border.width: 1.5
                border.color: Theme.bg
                scale: 0

                Component.onCompleted: scale = 1
                Behavior on scale { NumberAnimation { duration: Theme.med; easing.type: Easing.OutBack } }

                Label {
                    id: num
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 0
                    visible: badge.count > 0
                    text: badge.count > 99 ? "99+" : badge.count
                    color: Theme.onAccent
                    font.pixelSize: Theme.fsCaps
                    font.weight: Font.Bold
                    font.letterSpacing: 0
                }
            }

            // bump when the count changes
            SequentialAnimation {
                id: bump
                NumberAnimation { target: orb; property: "scale"; to: 1.25; duration: 90; easing.type: Easing.OutQuad }
                NumberAnimation { target: orb; property: "scale"; to: 1; duration: Theme.fast; easing.type: Easing.OutBack }
            }
            onCountChanged: bump.restart()

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Badges.focus(badge.modelData)
            }
        }
    }
}
