import QtQuick
import Quickshell.Networking
import qs.common
import qs.components
import qs.services

// Conexões: Wi-Fi + cable, and Bluetooth. Under the right island.
Popup {
    id: root

    readonly property bool bt: Ui.networkTab === "bluetooth"

    open: Ui.popup === "network"
    onDismissed: Ui.close("network")
    ns: "quickshell-network"
    cardWidth: 352
    spacing: 12

    // scan Wi-Fi / discover BT only while the matching tab is visible
    Binding { target: Net; property: "scanning"; value: root.open && !root.bt && Networking.wifiEnabled }
    onOpenChanged: if (!open) Bt.setDiscovering(false)

    Segmented {
        model: [{ key: "wifi", label: "Wi-Fi", icon: "wifi" }, { key: "bluetooth", label: "Bluetooth", icon: "bluetooth" }]
        current: Ui.networkTab
        onSelected: key => Ui.networkTab = key
    }

    // ── Wi-Fi tab ──────────────────────────────────────────────────────
    Column {
        visible: !root.bt
        width: parent.width
        spacing: 12

        // power row
        Item {
            width: parent.width
            height: 34

            Rectangle {
                id: wifiTile
                width: 34
                height: 34
                radius: 9
                color: Theme.well
                Icon {
                    anchors.centerIn: parent
                    size: 16
                    name: Networking.wifiEnabled ? (Net.active ? Net.signalIcon(Net.active) : "wifi") : "wifi-off"
                    color: Networking.wifiEnabled ? Theme.peach : Theme.dim
                }
            }

            Column {
                anchors.left: wifiTile.right
                anchors.leftMargin: 12
                anchors.right: wifiSwitch.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    text: Net.active ? Net.active.name : "Wi-Fi"
                    color: Theme.text
                    font.pixelSize: Theme.fsMd
                    font.weight: Font.DemiBold
                }
                Label {
                    text: !Networking.wifiHardwareEnabled ? "Bloqueado por hardware"
                        : !Networking.wifiEnabled ? "Desligado"
                        : Net.active ? "Sinal " + Net.strength + "%  ·  " + Net.ip
                        : "Sem conexão"
                    color: Theme.muted
                    font.pixelSize: Theme.fsXs
                }
            }

            Toggle {
                id: wifiSwitch
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                checked: Networking.wifiEnabled
                onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
            }
        }

        // cable
        Rectangle {
            visible: !!Net.wired
            width: parent.width
            height: 40
            radius: 10
            color: Theme.well

            Icon {
                id: cableIcon
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                size: 14
                name: "ethernet-port"
                color: Net.wiredUp ? Theme.peach : Theme.muted
            }
            Column {
                anchors.left: cableIcon.right
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                Label {
                    text: "Cabo" + (Net.wired ? "  ·  " + Net.wired.name : "")
                    color: Net.wiredUp ? Theme.text : Theme.soft
                    font.weight: Font.DemiBold
                }
                Label {
                    text: !Net.wired ? ""
                        : !Net.wired.hasLink ? "Sem cabo conectado"
                        : Net.wired.connected ? "Conectado · " + Net.wired.linkSpeed + " Mb/s"
                        : "Desativado"
                    color: Theme.muted
                    font.pixelSize: Theme.fsXs
                }
            }
            Toggle {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                checked: Net.wiredUp
                busy: !!Net.wired && Net.wired.network && Net.wired.network.stateChanging
                onToggled: {
                    if (Net.wired.connected) Net.wired.disconnect()
                    else if (Net.wired.network) Net.wired.network.connect()
                }
            }
        }

        // networks
        Column {
            visible: Networking.wifiEnabled
            width: parent.width
            spacing: 2

            Item {
                width: parent.width
                height: 16
                Caps { anchors.verticalCenter: parent.verticalCenter; text: "Redes"; leftPadding: 2 }
                Icon {
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    name: "refresh-cw"
                    size: 11
                    color: Theme.dim
                    RotationAnimation on rotation {
                        running: Net.scanning
                        from: 0; to: 360
                        duration: 1600
                        loops: Animation.Infinite
                    }
                }
            }

            Flickable {
                width: parent.width
                height: Math.min(list.implicitHeight, 300)
                contentHeight: list.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: list
                    width: parent.width
                    spacing: 2
                    Repeater {
                        model: Net.sorted.filter(n => n.name !== "")
                        delegate: WifiRow {
                            required property var modelData
                            network: modelData
                        }
                    }
                }
            }

            Label {
                visible: Net.sorted.length === 0
                leftPadding: 2
                topPadding: 4
                text: "Procurando redes…"
                color: Theme.muted
            }
        }
    }

    // ── Bluetooth tab ──────────────────────────────────────────────────
    Column {
        visible: root.bt
        width: parent.width
        spacing: 12

        Item {
            width: parent.width
            height: 34

            Rectangle {
                id: btTile
                width: 34
                height: 34
                radius: 9
                color: Theme.well
                Icon {
                    anchors.centerIn: parent
                    size: 16
                    name: Bt.icon
                    color: Bt.enabled ? Theme.peach : Theme.dim
                }
            }

            Column {
                anchors.left: btTile.right
                anchors.leftMargin: 12
                anchors.right: btControls.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    text: Bt.available ? (Bt.adapter.name || "Bluetooth") : "Bluetooth"
                    color: Theme.text
                    font.pixelSize: Theme.fsMd
                    font.weight: Font.DemiBold
                }
                Label {
                    text: !Bt.available ? "Nenhum adaptador"
                        : !Bt.enabled ? "Desligado"
                        : Bt.connected.length > 0 ? Bt.connected.length + (Bt.connected.length > 1 ? " conectados" : " conectado")
                        : "Ligado"
                    color: Theme.muted
                    font.pixelSize: Theme.fsXs
                }
            }

            Row {
                id: btControls
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Button {
                    visible: Bt.enabled
                    anchors.verticalCenter: parent.verticalCenter
                    icon: Bt.discovering ? "loader-circle" : "bluetooth-searching"
                    text: Bt.discovering ? "Parar" : "Procurar"
                    onClicked: Bt.setDiscovering(!Bt.discovering)
                }
                Toggle {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: Bt.enabled
                    onToggled: Bt.setEnabled(!Bt.enabled)
                }
            }
        }

        Column {
            visible: Bt.enabled
            width: parent.width
            spacing: 2

            Caps { text: "Pareados"; leftPadding: 2; bottomPadding: 4 }
            Repeater {
                model: Bt.paired
                delegate: BtRow {
                    required property var modelData
                    device: modelData
                }
            }
            Label {
                visible: Bt.paired.length === 0
                leftPadding: 2
                text: "Nenhum dispositivo pareado"
                color: Theme.muted
            }
        }

        Column {
            visible: Bt.enabled && (Bt.discovering || Bt.nearby.length > 0)
            width: parent.width
            spacing: 2

            Caps { text: "Disponíveis"; leftPadding: 2; bottomPadding: 4 }
            Repeater {
                model: Bt.nearby
                delegate: BtRow {
                    required property var modelData
                    device: modelData
                }
            }
            Label {
                visible: Bt.nearby.length === 0
                leftPadding: 2
                text: "Procurando dispositivos…"
                color: Theme.muted
            }
        }
    }
}
