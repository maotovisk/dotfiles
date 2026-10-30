import QtQuick
import qs.common
import qs.components
import qs.services

// Now playing: tiny live equaliser + title.
// L: player popout, M: play/pause, R: next.
Chip {
    id: root

    visible: Media.hasTrack
    highlighted: Ui.popup === "player"

    onClicked: m => {
        if (m.button === Qt.RightButton) Media.player.next()
        else if (m.button === Qt.MiddleButton) Media.player.togglePlaying()
        else Ui.toggle("player")
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        height: 10
        spacing: 2

        Repeater {
            model: 3
            delegate: Rectangle {
                id: bar
                required property int index
                anchors.bottom: parent.bottom
                width: 2
                radius: 1
                color: Media.playing ? Theme.peach : Theme.dim
                height: 3

                SequentialAnimation on height {
                    running: Media.playing
                    loops: Animation.Infinite
                    onRunningChanged: if (!running) bar.height = 3
                    NumberAnimation { to: 10; duration: 260 + index * 90; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 3 + index; duration: 300 + index * 70; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    Label {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, 200)
        elide: Text.ElideRight
        text: Media.player ? Media.player.trackTitle + (Media.player.trackArtist ? "  ·  " + Media.player.trackArtist : "") : ""
        color: Media.playing ? Theme.soft : Theme.muted
    }
}
