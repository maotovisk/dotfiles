import QtQuick
import qs.common
import qs.components
import qs.services

// 09:48 · Sex 30 Out — click for the calendar.
Chip {
    id: root

    highlighted: Ui.popup === "calendar"
    onClicked: Ui.toggle("calendar")

    Label {
        anchors.verticalCenter: parent.verticalCenter
        text: Time.time
        color: Theme.text
        font.pixelSize: Theme.fsLg
        font.weight: Font.DemiBold
        font.letterSpacing: 0.3
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: 3
        radius: 1.5
        color: Theme.dim
    }

    Label {
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        text: Time.date
        color: Theme.muted
    }
}
