import QtQuick
import Quickshell.Networking
import qs.common
import qs.components
import qs.services

// One Wi-Fi network. Click: connect (saved/open), ask for a password
// (new secured), or reveal actions (connected). Expands in place.
Item {
    id: root

    required property var network
    property bool expanded: false
    property bool failed: false

    readonly property bool connected: network.connected
    readonly property bool busy: network.stateChanging || network.state === ConnectionState.Connecting
    readonly property bool needsPassword: Net.secured(network) && !network.known
    readonly property string status: busy ? "Conectando…"
        : failed ? "Falha ao conectar"
        : connected ? "Conectado · " + Net.ip
        : network.known ? "Salva" : ""

    width: parent ? parent.width : 0
    property real h: 34 + (expanded ? panel.implicitHeight + 6 : 0)
    Behavior on h { NumberAnimation { duration: Theme.med; easing.type: Easing.OutCubic } }
    height: Math.round(h)
    clip: true

    Connections {
        target: root.network
        function onConnectionFailed(reason) {
            root.failed = true
            if (root.needsPassword || reason === ConnectionFailReason.NoSecrets)
                root.expanded = true
        }
        function onConnectedChanged() {
            if (root.network.connected) {
                root.failed = false
                root.expanded = false
            }
        }
    }

    function activate() {
        failed = false
        if (connected || needsPassword) {
            expanded = !expanded
            if (expanded && needsPassword)
                Qt.callLater(() => field.focusInput())
        } else {
            network.connect()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: mouse.containsMouse || root.expanded ? Theme.hover : root.connected ? Theme.well : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    Item {
        id: head
        width: parent.width
        height: 34

        Icon {
            id: icon
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            size: 14
            name: Net.signalIcon(root.network)
            color: root.connected ? Theme.peach : Theme.muted
        }

        Column {
            anchors.left: icon.right
            anchors.leftMargin: 10
            anchors.right: trail.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Label {
                width: parent.width
                elide: Text.ElideRight
                text: root.network.name
                color: root.connected ? Theme.text : Theme.soft
                font.weight: root.connected ? Font.DemiBold : Font.Medium
            }
            Label {
                visible: root.status !== ""
                text: root.status
                color: root.failed ? Theme.red : root.busy ? Theme.peach : Theme.muted
                font.pixelSize: Theme.fsXs
            }
        }

        Row {
            id: trail
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Icon {
                visible: Net.secured(root.network)
                anchors.verticalCenter: parent.verticalCenter
                name: "lock"
                size: 11
                color: Theme.dim
            }
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.busy || root.connected
                name: root.busy ? "loader-circle" : "check"
                size: 13
                color: Theme.peach
                RotationAnimation on rotation {
                    running: root.busy
                    from: 0; to: 360
                    duration: 900
                    loops: Animation.Infinite
                }
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activate()
        }
    }

    // ── expanded panel ─────────────────────────────────────────────────
    Item {
        id: panel
        y: 34
        x: 10
        width: parent.width - 20
        implicitHeight: root.needsPassword && !root.connected ? 30 : 26
        opacity: root.expanded ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.med } }

        Row {
            visible: root.needsPassword && !root.connected
            width: parent.width
            spacing: 6

            Field {
                id: field
                width: parent.width - go.width - 6
                password: true
                error: root.failed
                placeholder: "Senha"
                onAccepted: go.clicked()
            }
            Button {
                id: go
                anchors.verticalCenter: parent.verticalCenter
                text: "Conectar"
                tone: "accent"
                onClicked: {
                    if (field.text === "")
                        return
                    root.failed = false
                    root.network.connectWithPsk(field.text)
                }
            }
        }

        Row {
            visible: !root.needsPassword || root.connected
            spacing: 6

            Button {
                visible: root.connected
                icon: "unlink"
                text: "Desconectar"
                onClicked: root.network.disconnect()
            }
            Button {
                visible: root.network.known
                icon: "trash-2"
                text: "Esquecer"
                tone: "danger"
                onClicked: {
                    root.expanded = false
                    root.network.forget()
                }
            }
        }
    }
}
