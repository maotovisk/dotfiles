import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.common
import qs.components
import qs.services

// Player card under the center island: blurred art backdrop, art + track,
// seek bar, transport, volume and a player switcher.
Popup {
    id: root

    readonly property var p: Media.player
    readonly property string art: p ? (p.trackArtUrl || "") : ""

    open: Ui.popup === "player"
    onDismissed: Ui.close("player")
    ns: "quickshell-player"
    align: "center"
    cardWidth: 360
    spacing: 14

    Binding { target: Media; property: "ticking"; value: root.open }

    // ── backdrop: the cover, blurred and dimmed ────────────────────────
    backdrop: [
        Image {
            id: backArt
            anchors.fill: parent
            source: root.art
            sourceSize: Qt.size(160, 160)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        },
        MultiEffect {
            anchors.fill: parent
            source: backArt
            blurEnabled: true
            blur: 1
            blurMax: 64
            saturation: 0.15
            opacity: backArt.status === Image.Ready ? 0.7 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.slow } }
        },
        // keep text legible over bright covers
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: "#600E0E0E" }
                GradientStop { position: 1; color: "#D90E0E0E" }
            }
        }
    ]

    // ── art + track ────────────────────────────────────────────────────
    Item {
        width: parent.width
        height: 84

        ClippingRectangle {
            id: cover
            width: 84
            height: 84
            radius: 12
            color: Theme.well

            Image {
                id: coverImg
                anchors.fill: parent
                source: root.art
                sourceSize: Qt.size(168, 168)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.slow } }
            }
            Icon {
                anchors.centerIn: parent
                visible: coverImg.status !== Image.Ready
                name: "disc-3"
                size: 28
                color: Theme.dim
            }
        }

        // hairline over the cover so light art keeps its edge
        Rectangle {
            anchors.fill: cover
            radius: 12
            color: "transparent"
            border.width: 1
            border.color: Theme.border
        }

        Column {
            anchors.left: cover.right
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Row {
                spacing: 5
                bottomPadding: 3
                IconImage {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: 11
                    source: Media.appIcon(root.p)
                    visible: source != ""
                }
                Caps {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.p ? root.p.identity : ""
                }
            }
            Label {
                width: parent.width
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                text: root.p ? root.p.trackTitle || "Nada tocando" : "Nada tocando"
                color: Theme.text
                font.pixelSize: Theme.fsLg
                font.weight: Font.DemiBold
                lineHeight: 1.05
            }
            Label {
                width: parent.width
                elide: Text.ElideRight
                visible: text !== ""
                text: root.p ? root.p.trackArtist || "" : ""
                color: Theme.soft
            }
            Label {
                width: parent.width
                elide: Text.ElideRight
                visible: text !== ""
                text: root.p ? root.p.trackAlbum || "" : ""
                color: Theme.muted
                font.pixelSize: Theme.fsXs
            }
        }
    }

    // ── progress ───────────────────────────────────────────────────────
    Column {
        width: parent.width
        spacing: 4

        Slider {
            visible: Media.timed
            width: parent.width
            value: Media.progress
            fill: Theme.text
            onMoved: v => Media.seek(v)
            enabled: !!root.p && root.p.canSeek
        }

        // streams without a length: a quiet moving line instead of a fake bar
        Item {
            visible: !Media.timed
            width: parent.width
            height: 16
            clip: true

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 3
                radius: 1.5
                color: "#16FFFFFF"
            }
            Rectangle {
                id: runner
                anchors.verticalCenter: parent.verticalCenter
                width: 64
                height: 3
                radius: 1.5
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 0.5; color: Media.playing ? Theme.peach : Theme.dim }
                    GradientStop { position: 1; color: "transparent" }
                }
                NumberAnimation on x {
                    running: root.open && Media.playing && !Media.timed
                    from: -64
                    to: runner.parent.width
                    duration: 1800
                    loops: Animation.Infinite
                    easing.type: Easing.InOutSine
                }
            }
        }

        Item {
            width: parent.width
            height: 12
            Label {
                text: Media.timed ? Media.clock(root.p.position) : (Media.playing ? "Ao vivo" : "Pausado")
                color: Theme.muted
                font.pixelSize: Theme.fsXs
                font.weight: Font.DemiBold
            }
            Label {
                anchors.right: parent.right
                visible: Media.timed
                text: Media.timed ? "-" + Media.clock(root.p.length - root.p.position) : ""
                color: Theme.muted
                font.pixelSize: Theme.fsXs
                font.weight: Font.DemiBold
            }
        }
    }

    // ── transport ──────────────────────────────────────────────────────
    Item {
        width: parent.width
        height: 44

        Row {
            anchors.centerIn: parent
            spacing: 14

            Transport {
                icon: "shuffle"
                visible: !!root.p && root.p.shuffleSupported
                on: !!root.p && root.p.shuffle
                onActivated: root.p.shuffle = !root.p.shuffle
            }
            Transport {
                icon: "skip-back"
                size: 17
                enabled: !!root.p && root.p.canGoPrevious
                onActivated: root.p.previous()
            }

            // play / pause
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                height: 44
                radius: 22
                color: playMouse.pressed ? "#F0B98A" : playMouse.containsMouse ? "#FFD4AE" : Theme.peach
                scale: playMouse.pressed ? 0.94 : 1
                Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: Theme.fast } }

                Icon {
                    anchors.centerIn: parent
                    // play's optical centre sits left of its box
                    anchors.horizontalCenterOffset: Media.playing ? 0 : 1
                    name: Media.playing ? "pause" : "play"
                    size: 18
                    color: Theme.onAccent
                }
                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.p) root.p.togglePlaying()
                }
            }

            Transport {
                icon: "skip-forward"
                size: 17
                enabled: !!root.p && root.p.canGoNext
                onActivated: root.p.next()
            }
            Transport {
                icon: root.p && root.p.loopState === MprisLoopState.Track ? "repeat-1" : "repeat"
                visible: !!root.p && root.p.loopSupported
                on: !!root.p && root.p.loopState !== MprisLoopState.None
                onActivated: Media.cycleLoop()
            }
        }
    }

    // ── volume ─────────────────────────────────────────────────────────
    Row {
        visible: !!root.p && root.p.volumeSupported
        width: parent.width
        spacing: 10

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.p ? Audio.speakerIcon(Math.round(root.p.volume * 100), false) : "volume-2"
            size: 14
            color: Theme.muted
        }
        Slider {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 14 - pct.width - 2 * parent.spacing
            value: root.p ? root.p.volume : 0
            onMoved: v => root.p.volume = v
        }
        Label {
            id: pct
            anchors.verticalCenter: parent.verticalCenter
            text: root.p ? Math.round(root.p.volume * 100) + "%" : ""
            color: Theme.soft
            font.pixelSize: Theme.fsXs
            font.weight: Font.DemiBold
        }
    }

    // ── players ────────────────────────────────────────────────────────
    Flow {
        visible: Media.players.length > 1
        width: parent.width
        spacing: 6

        Repeater {
            model: Media.players
            delegate: Button {
                required property var modelData
                text: modelData.identity
                icon: modelData.isPlaying ? "audio-lines" : "music"
                tone: modelData === root.p ? "accent" : ""
                onClicked: Media.pinned = modelData
            }
        }
    }

    component Transport: Item {
        id: t
        property string icon: ""
        property int size: 15
        property bool on: false
        signal activated()

        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        width: 32
        height: 32
        opacity: enabled ? 1 : 0.35

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: tMouse.pressed ? Theme.press : tMouse.containsMouse ? Theme.hover : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }
        Icon {
            anchors.centerIn: parent
            name: t.icon
            size: t.size
            color: t.on ? Theme.peach : Theme.soft
        }
        // active-mode dot under shuffle / repeat
        Rectangle {
            visible: t.on
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            width: 3
            height: 3
            radius: 1.5
            color: Theme.peach
        }
        MouseArea {
            id: tMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: t.activated()
        }
    }
}
