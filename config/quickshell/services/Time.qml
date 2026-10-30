pragma Singleton

import QtQuick
import Quickshell

// Clock + Portuguese calendar names (no locale dependency).
Singleton {
    id: root

    readonly property var days: ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
    readonly property var months: ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"]
    readonly property var monthsLong: ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
        "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]

    readonly property date now: clock.date
    readonly property string time: Qt.formatTime(now, "hh:mm")
    readonly property string date: days[now.getDay()] + " " + now.getDate() + " " + months[now.getMonth()]

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
