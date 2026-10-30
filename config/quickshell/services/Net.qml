pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// NetworkManager via Quickshell.Networking, plus the primary route's IP.
Singleton {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.nmManaged) ?? null

    readonly property var networks: wifi ? wifi.networks.values : []
    readonly property var active: networks.find(n => n.connected) ?? null
    // connected first, then saved, then by signal
    readonly property var sorted: networks.slice().sort((a, b) =>
        (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength))

    readonly property bool wiredUp: !!wired && wired.connected
    readonly property bool online: ip !== ""
    readonly property int strength: active ? Math.round(active.signalStrength * 100) : 0
    // the chip follows whatever carries the default route, not just "a cable is up"
    readonly property bool viaWifi: iface.startsWith("wl")
    readonly property string icon: !online ? "wifi-off"
        : !viaWifi ? "ethernet-port"
        : strength > 66 ? "wifi" : strength > 33 ? "wifi-high" : "wifi-low"

    property string ip: ""
    property string iface: ""

    // scan only while someone is looking at the list
    property bool scanning: false
    Binding {
        when: !!root.wifi
        target: root.wifi
        property: "scannerEnabled"
        value: root.scanning
    }

    function signalIcon(n) {
        const s = n.signalStrength
        return s > 0.66 ? "wifi" : s > 0.33 ? "wifi-high" : "wifi-low"
    }

    function secured(n) {
        return n.security !== undefined && n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe
    }

    // NetworkDevice exposes no IP: the source address comes from the route
    Process {
        id: route
        command: ["ip", "-4", "-o", "route", "get", "1.1.1.1"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.ip = (text.match(/\bsrc\s+(\S+)/) || [])[1] || ""
                root.iface = (text.match(/\bdev\s+(\S+)/) || [])[1] || ""
            }
        }
        onExited: code => { if (code !== 0) { root.ip = ""; root.iface = "" } }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: route.running = true
    }

    // re-probe right away when connectivity changes
    Connections {
        target: Networking
        function onConnectivityChanged() { route.running = true }
    }
}
