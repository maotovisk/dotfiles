import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.common
import qs.components
import qs.services

// History under the right island: DND, clear all, staggered cards.
Popup {
    id: root

    open: Ui.popup === "notifs"
    onDismissed: Ui.close("notifs")
    ns: "quickshell-notifications"
    cardWidth: 384
    spacing: 12

    // ── header ─────────────────────────────────────────────────────────
    Item {
        width: parent.width
        height: 26

        Row {
            anchors.verticalCenter: parent.verticalCenter
            leftPadding: 2
            spacing: 8

            Caps {
                anchors.verticalCenter: parent.verticalCenter
                text: "Notificações"
                color: Theme.soft
            }
            Rectangle {
                visible: Notifs.count > 0
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(18, countLabel.implicitWidth + 10)
                height: 16
                radius: 8
                color: Theme.peachSoft
                Label {
                    id: countLabel
                    anchors.centerIn: parent
                    text: Notifs.count
                    color: Theme.peach
                    font.pixelSize: Theme.fsXs
                    font.weight: Font.DemiBold
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Button {
                icon: "moon"
                text: Notifs.dnd ? "Silenciado" : "Não perturbe"
                tone: Notifs.dnd ? "accent" : ""
                onClicked: Notifs.dnd = !Notifs.dnd
            }
            Button {
                visible: Notifs.count > 0
                icon: "trash-2"
                text: "Limpar"
                onClicked: Notifs.clearAnimated()
            }
        }
    }

    // ── body: list or empty state, never shorter than minBody ──────────
    Item {
        readonly property int minBody: 200
        width: parent.width
        height: Math.max(minBody, Notifs.count > 0 ? flick.height : 0)

        // ── cards ──────────────────────────────────────────────────────────
        Flickable {
            id: flick
            visible: Notifs.count > 0
            width: parent.width
            height: Math.min(cards.implicitHeight, 560)
            contentHeight: cards.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: cards
                width: parent.width

                Repeater {
                    model: ScriptModel { values: Notifs.list.slice().reverse() }

                    delegate: Item {
                        id: slot
                        required property var modelData
                        required property int index
                        property bool leaving: false
                        property bool collapsed: false
                        readonly property bool critical: modelData.urgency === NotificationUrgency.Critical

                        // The slot only starts closing once its card is gone, so cards
                        // below glide up one at a time instead of everything squashing.
                        // Animate a real, render whole pixels (see Toasts.qml).
                        property real h: collapsed ? 0 : card.height + 6
                        Behavior on h { NumberAnimation { duration: 220; easing.type: Easing.InOutCubic } }
                        width: cards.width
                        height: Math.round(h)
                        clip: collapsed

                        function leave(delay) {
                            if (leaving)
                                return
                            leaving = true
                            exit.delay = Math.max(0, delay)
                            exit.start()
                        }

                        // stagger → slide + fade out → collapse the gap → dismiss
                        SequentialAnimation {
                            id: exit
                            property int delay: 0
                            PauseAnimation { duration: exit.delay }
                            ParallelAnimation {
                                NumberAnimation { target: card; property: "x"; to: 48; duration: 220; easing.type: Easing.InCubic }
                                NumberAnimation { target: card; property: "opacity"; to: 0; duration: 180 }
                            }
                            ScriptAction { script: slot.collapsed = true }
                            PauseAnimation { duration: 220 }
                            ScriptAction { script: if (slot.modelData) slot.modelData.dismiss() }
                        }

                        Connections {
                            target: Notifs
                            function onClearing() { slot.leave(slot.index * 40) }
                        }

                        Rectangle {
                            id: card
                            width: parent.width
                            height: content.implicitHeight + 24
                            radius: 12
                            color: content.hovered ? "#12FFFFFF" : Theme.well
                            border.width: 1
                            border.color: slot.critical ? "#66FF8080" : Theme.border
                            Behavior on color { ColorAnimation { duration: Theme.fast } }

                            // staggered entrance each time the center opens
                            property real shown: root.open ? 1 : 0
                            Behavior on shown {
                                SequentialAnimation {
                                    PauseAnimation { duration: root.open ? Math.max(0, Math.min(slot.index, 8)) * 60 : 0 }
                                    NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic }
                                }
                            }
                            opacity: shown          // the exit animation takes over from here
                            scale: 0.96 + 0.04 * shown
                            transform: Translate { y: (1 - card.shown) * -6 }

                            NotificationCard {
                                id: content
                                x: 12
                                y: 12
                                width: parent.width - 24
                                notif: slot.modelData
                                critical: slot.critical
                                time: Notifs.ago(slot.modelData.id, Time.now.getTime())
                                actions: slot.modelData.actions.filter(a => a.identifier !== "default")
                                onDismiss: slot.leave(0)
                                onInvoke: a => a.invoke()
                            }
                        }
                    }
                }
            }
        }

        // ── empty ──────────────────────────────────────────────────────────
        Column {
            anchors.centerIn: parent
            width: parent.width
            spacing: 8
            opacity: Notifs.count === 0 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.med } }

            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: Notifs.dnd ? "moon" : "bell"
                size: 22
                color: Theme.dim
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Tudo em dia"
                color: Theme.soft
                font.pixelSize: Theme.fsMd
                font.weight: Font.DemiBold
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Notifs.dnd ? "Não perturbe ativo: só alertas críticos aparecem" : "Nenhuma notificação"
                color: Theme.muted
            }
        }
    }
}
