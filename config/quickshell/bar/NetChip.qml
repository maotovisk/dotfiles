import QtQuick
import Quickshell
import qs.common
import qs.components
import qs.services

// Icon only; hovering slides the IP out. L: Conexões popout, R: nm editor.
Chip {
    id: root

    icon: Net.icon
    iconColor: Net.online ? Theme.muted : Theme.red
    clip: true

    highlighted: Ui.popup === "network" && Ui.networkTab === "wifi"
    onClicked: m => m.button === Qt.RightButton
        ? Quickshell.execDetached(["nm-connection-editor"]) : Ui.toggleTab("network", "wifi")

    Item {
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.chipH
        width: root.hovered ? ip.implicitWidth : -5        // -5 eats the row spacing when hidden
        clip: true
        Behavior on width { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }

        Label {
            id: ip
            anchors.verticalCenter: parent.verticalCenter
            text: Net.online ? Net.ip : "offline"
            color: Net.online ? Theme.soft : Theme.red
            font.weight: Font.DemiBold
            opacity: root.hovered ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.med } }
        }
    }
}
