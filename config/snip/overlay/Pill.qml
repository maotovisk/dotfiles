import QtQuick
import qs.common

// Small glass label.
Rectangle {
    property alias text: label.text
    property alias textColor: label.color

    implicitWidth: label.implicitWidth + 16
    implicitHeight: 24
    radius: 7
    color: Theme.panel
    border.width: 1
    border.color: Theme.border

    Text {
        id: label
        anchors.centerIn: parent
        color: Theme.soft
        font.family: Theme.font
        font.pixelSize: Theme.fsSm
        font.weight: Font.Medium
        font.features: { "tnum": 1 }
    }
}
