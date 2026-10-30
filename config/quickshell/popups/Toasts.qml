import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.components
import qs.services

// Toasts at the top-right of the primary output, under the bar. Newest sits
// closest to the corner (on top). Each one owns its lifetime (paused on
// hover), slides in with a little overshoot, and leaves by fading while its
// slot collapses. They step aside while a right-hand popup holds that corner.
PanelWindow {
    id: win

    readonly property int room: 10
    readonly property int cardWidth: 360

    readonly property bool cornerTaken: ["volume", "network", "notifs", "sysmon"].includes(Ui.popup)

    visible: Notifs.toasts.length > 0 && !cornerTaken
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; right: true }
    margins.top: Theme.popupTop - room
    margins.right: Theme.edge - room
    implicitWidth: cardWidth + room * 2
    // fixed height, masked to the cards: collapsing slots never resize the surface
    implicitHeight: (screen ? screen.height : 1080) - Theme.popupTop + room

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-toasts"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: Region { item: stack }

    Column {
        id: stack
        x: win.room
        y: win.room
        width: win.cardWidth

        Repeater {
            model: ScriptModel { values: Notifs.toasts.slice().reverse() }

            delegate: Item {
                id: slot
                required property var modelData
                readonly property var entry: modelData
                property bool leaving: false
                property bool collapsed: false            // set once the card has faded out
                property real life: 1                   // 1 → 0 over the timeout

                // animate a real, render whole pixels: fractional y under native
                // text rendering makes text and its card drift apart
                property real h: collapsed ? 0 : card.height + 8
                Behavior on h { NumberAnimation { duration: 240; easing.type: Easing.InOutCubic } }
                width: stack.width
                height: Math.round(h)

                function leave() {
                    if (leaving)
                        return
                    leaving = true
                    exit.start()
                }

                // lifetime: a Timer, not an animation. Animations follow the
                // window's render loop and freeze while the window is hidden.
                // Hovering holds the toast; leaving restarts the full timeout.
                Timer {
                    interval: slot.entry.timeout
                    running: !card.hovered && !slot.leaving
                    onTriggered: slot.leave()
                    onRunningChanged: {
                        if (running) {
                            slot.life = 1
                            lifeBar.restart()
                        } else {
                            lifeBar.stop()
                        }
                    }
                    Component.onCompleted: lifeBar.start()   // no change signal for the initial `running: true`
                }

                // purely cosmetic countdown line
                NumberAnimation {
                    id: lifeBar
                    target: slot
                    property: "life"
                    from: 1
                    to: 0
                    duration: slot.entry.timeout
                }

                SequentialAnimation {
                    id: exit
                    ParallelAnimation {
                        NumberAnimation { target: card; property: "opacity"; to: 0; duration: 220 }
                        NumberAnimation { target: card; property: "scale"; to: 0.94; duration: 220; easing.type: Easing.InCubic }
                    }
                    // only then close the gap, so the others glide instead of squash
                    ScriptAction { script: slot.collapsed = true }
                    PauseAnimation { duration: 240 }
                    ScriptAction { script: Notifs.dropToast(slot.entry) }
                }

                // the app withdrew it
                Connections {
                    target: slot.entry.n
                    ignoreUnknownSignals: true
                    function onClosed() { slot.leave() }
                }

                Item {
                    id: card
                    readonly property bool hovered: hover.hovered
                    width: parent.width
                    height: content.implicitHeight + 28
                    transformOrigin: Item.Right

                    // entrance: slide from the right with a light overshoot
                    opacity: 0
                    scale: 0.92
                    transform: Translate { id: shift; x: 60 }
                    Component.onCompleted: enter.start()
                    ParallelAnimation {
                        id: enter
                        NumberAnimation { target: shift; property: "x"; to: 0; duration: 340; easing.type: Easing.OutCubic }
                        NumberAnimation { target: card; property: "opacity"; to: 1; duration: 220 }
                        NumberAnimation { target: card; property: "scale"; to: 1; duration: 340; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                    }

                    HoverHandler { id: hover }

                    Glass {
                        anchors.fill: parent
                        radius: Theme.popupR
                        color: Theme.panel
                        borderColor: slot.entry.critical ? "#66FF8080" : card.hovered ? Theme.borderHover : Theme.border
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const n = slot.entry.n
                            const def = n ? n.actions.find(a => a.identifier === "default") : null
                            if (def)
                                def.invoke()
                            else
                                Ui.toggle("notifs")
                            slot.leave()
                        }
                    }

                    NotificationCard {
                        id: content
                        x: 14
                        y: 14
                        width: parent.width - 28
                        notif: slot.entry
                        critical: slot.entry.critical
                        time: "agora"
                        actions: slot.entry.n ? slot.entry.n.actions.filter(a => a.identifier !== "default") : []
                        onDismiss: {
                            if (slot.entry.n)
                                slot.entry.n.dismiss()
                            slot.leave()
                        }
                        onInvoke: a => { a.invoke(); slot.leave() }
                    }

                    // remaining lifetime, hairline along the bottom
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 1
                        x: Theme.popupR
                        height: 2
                        radius: 1
                        width: (parent.width - Theme.popupR * 2) * slot.life
                        color: slot.entry.critical ? Theme.red : Theme.peach
                        opacity: 0.55
                    }
                }
            }
        }
    }
}
