pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

// BlueZ via Quickshell.Bluetooth.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: !!adapter
    readonly property bool enabled: !!adapter && adapter.enabled
    readonly property bool discovering: !!adapter && adapter.discovering

    readonly property var devices: adapter ? adapter.devices.values : []
    readonly property var paired: devices.filter(d => d.paired || d.bonded)
        .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
    // unnamed beacons (name == address) are noise
    readonly property var nearby: devices.filter(d => !d.paired && !d.bonded && d.deviceName && d.deviceName !== d.address)
    readonly property var connected: paired.filter(d => d.connected)

    readonly property string icon: !enabled ? "bluetooth-off"
        : connected.length > 0 ? "bluetooth-connected"
        : discovering ? "bluetooth-searching" : "bluetooth"

    function setEnabled(on) {
        if (adapter)
            adapter.enabled = on
    }

    function setDiscovering(on) {
        if (adapter && adapter.enabled)
            adapter.discovering = on
    }

    function deviceIcon(d) {
        const i = d.icon || ""
        return i.includes("headset") || i.includes("headphone") || i.includes("audio") ? "headphones"
            : i.includes("keyboard") ? "keyboard"
            : i.includes("mouse") ? "mouse"
            : i.includes("gaming") || i.includes("joystick") ? "gamepad-2"
            : i.includes("phone") ? "smartphone"
            : i.includes("computer") ? "laptop"
            : i.includes("display") || i.includes("video") ? "monitor"
            : "bluetooth"
    }

    function toggle(d) {
        if (d.connected) {
            d.disconnect()
        } else if (d.paired || d.bonded) {
            d.connect()
        } else {
            d.trusted = true
            d.pair()
        }
    }

    // a freshly paired device connects on its own
    Instantiator {
        model: root.devices
        delegate: Connections {
            required property var modelData
            target: modelData
            function onPairedChanged() {
                if (modelData.paired && !modelData.connected)
                    modelData.connect()
            }
        }
    }
}
