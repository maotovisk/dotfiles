import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.components
import qs.services

// Content of one notification. Works on a live Notification (center) or a
// toast snapshot; both expose appName/appIcon/image/summary/body.
Item {
    id: root

    required property var notif
    property bool critical: false
    property string time: ""
    property var actions: []
    readonly property bool hovered: hover.hovered

    signal dismiss()
    signal invoke(var action)

    readonly property string iconSource: Notifs.iconFor(notif.appIcon, notif.image)

    implicitHeight: Math.max(36, body.implicitHeight)
    HoverHandler { id: hover }

    // icon tile: app image, or the app's themed icon, or a bell
    Rectangle {
        id: tile
        width: 36
        height: 36
        radius: 10
        color: Theme.well
        clip: true

        ClippingRectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            visible: !!root.notif.image
            Image {
                anchors.fill: parent
                source: root.notif.image || ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(72, 72)
            }
        }
        IconImage {
            anchors.centerIn: parent
            implicitSize: 20
            visible: !root.notif.image && source != ""
            source: root.notif.image ? "" : root.iconSource
        }
        Icon {
            anchors.centerIn: parent
            visible: !root.notif.image && root.iconSource === ""
            name: "bell"
            size: 15
            color: root.critical ? Theme.red : Theme.muted
        }
    }

    Column {
        id: body
        anchors.left: tile.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        spacing: 3

        Item {
            width: parent.width
            height: 14

            Caps {
                anchors.left: parent.left
                anchors.right: meta.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: root.notif.appName || "Notificação"
                color: root.critical ? Theme.red : Theme.muted
            }

            Item {
                id: meta
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(ago.implicitWidth, 16)
                height: 16

                Label {
                    id: ago
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.time
                    color: Theme.dim
                    font.pixelSize: Theme.fsXs
                    opacity: root.hovered ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                }

                // close swaps in for the timestamp on hover
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    height: 18
                    radius: 6
                    color: closeMouse.containsMouse ? Theme.press : Theme.hover
                    opacity: root.hovered ? 1 : 0
                    scale: root.hovered ? 1 : 0.6
                    Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                    Behavior on scale { NumberAnimation { duration: Theme.med; easing.type: Easing.OutBack } }

                    Icon {
                        anchors.centerIn: parent
                        name: "x"
                        size: 11
                        color: Theme.soft
                    }
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        enabled: root.hovered
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dismiss()
                    }
                }
            }
        }

        Label {
            width: parent.width
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            text: root.notif.summary
            color: Theme.text
            font.pixelSize: Theme.fsMd
            font.weight: Font.DemiBold
        }

        Label {
            visible: text !== ""
            width: parent.width
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
            textFormat: Text.StyledText
            linkColor: Theme.peach
            text: root.notif.body || ""
            color: Theme.soft
            lineHeight: 1.15
            onLinkActivated: link => Qt.openUrlExternally(link)
        }

        Flow {
            visible: root.actions.length > 0
            width: parent.width
            spacing: 6
            topPadding: 5

            Repeater {
                model: root.actions
                delegate: Button {
                    required property var modelData
                    text: modelData.text
                    onClicked: root.invoke(modelData)
                }
            }
        }
    }
}
