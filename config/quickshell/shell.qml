//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import "bar"
import "popups"

// Vesper Islands. Everything lives on the primary display.
ShellRoot {
    id: shell

    readonly property var screen: Quickshell.screens.find(s => s.name === "DP-2") ?? Quickshell.screens[0]

    Bar { screen: shell.screen }

    VolumeCenter { screen: shell.screen }
    NetworkPopup { screen: shell.screen }
    NotificationCenter { screen: shell.screen }
    CalendarPopup { screen: shell.screen }
    WeatherPopup { screen: shell.screen }
    PlayerPopup { screen: shell.screen }
    SysMonitor { screen: shell.screen }
    Overview { screen: shell.screen }
    SharePicker { screen: shell.screen }
    Toasts { screen: shell.screen }

    // services that should start with the shell, not on first use
    Component.onCompleted: [Notifs.count, Weather.ready, Stats.cpu]

    IpcHandler {
        target: "shell"

        function toggleVolume(): void { Ui.toggleTab("volume", "output") }
        function toggleVolumeInput(): void { Ui.toggleTab("volume", "input") }
        function toggleNetwork(): void { Ui.toggleTab("network", "wifi") }
        function toggleBluetooth(): void { Ui.toggleTab("network", "bluetooth") }
        function toggleCalendar(): void { Ui.toggle("calendar") }
        function showCalendar(): void { Ui.popup = "calendar" }
        function hideCalendar(): void { Ui.close("calendar") }
        function toggleWeather(): void { Ui.toggle("weather") }
        function toggleOverview(): void { Ui.toggle("overview") }
        function togglePlayer(): void { Ui.toggle("player") }
        function toggleSysmon(): void { Ui.toggle("sysmon") }
        function closeAll(): void { Ui.close() }
        function state(): string { return JSON.stringify({ popup: Ui.popup, volumeTab: Ui.volumeTab, networkTab: Ui.networkTab, wsHovered: Ui.wsHovered }) }
    }

    IpcHandler {
        target: "notifications"

        function toggleCenter(): void { Ui.toggle("notifs") }
        function showCenter(): void { Ui.popup = "notifs" }
        function hideCenter(): void { Ui.close("notifs") }
        function toggleDnd(): void { Notifs.dnd = !Notifs.dnd }
        function clear(): void { Notifs.clearAnimated() }
        function trackedCount(): int { return Notifs.count }
        function popupCount(): int { return Notifs.toasts.length }
        function dndState(): bool { return Notifs.dnd }
    }
}
