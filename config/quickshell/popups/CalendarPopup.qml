import QtQuick
import qs.common
import qs.components
import qs.services

// Month grid under the center island. Monday-first, today in a peach bubble.
Popup {
    id: root

    property int offset: 0                   // months away from the current one
    readonly property date today: Time.now
    readonly property date month: new Date(today.getFullYear(), today.getMonth() + offset, 1)

    // 42 cells starting on the Monday on/before the 1st
    readonly property var cells: {
        const lead = (month.getDay() + 6) % 7
        const out = []
        for (let i = 0; i < 42; i++) {
            const d = new Date(month.getFullYear(), month.getMonth(), 1 - lead + i)
            out.push({
                day: d.getDate(),
                inMonth: d.getMonth() === month.getMonth(),
                today: d.toDateString() === today.toDateString(),
                weekend: d.getDay() === 0 || d.getDay() === 6
            })
        }
        return out
    }

    open: Ui.popup === "calendar"
    onOpenChanged: if (open) offset = 0
    onDismissed: Ui.close("calendar")
    ns: "quickshell-calendar"
    align: "center"
    cardWidth: 258
    spacing: 10

    // ── header ─────────────────────────────────────────────────────────
    Item {
        width: parent.width
        height: 24

        Row {
            anchors.verticalCenter: parent.verticalCenter
            leftPadding: 2
            spacing: 6

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: Time.monthsLong[root.month.getMonth()]
                color: Theme.text
                font.pixelSize: Theme.fsMd
                font.weight: Font.DemiBold
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: root.month.getFullYear()
                color: Theme.muted
                font.pixelSize: Theme.fsMd
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Chip {
                visible: root.offset !== 0
                pad: 6
                text: "Hoje"
                textColor: Theme.peach
                onClicked: root.offset = 0
            }
            Chip { pad: 4; icon: "chevron-left"; onClicked: root.offset-- }
            Chip { pad: 4; icon: "chevron-right"; onClicked: root.offset++ }
        }
    }

    // ── weekday initials ───────────────────────────────────────────────
    Row {
        width: parent.width
        Repeater {
            model: ["S", "T", "Q", "Q", "S", "S", "D"]
            delegate: Caps {
                required property string modelData
                required property int index
                width: parent.width / 7
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: index >= 5 ? Theme.dim : Theme.muted
            }
        }
    }

    // ── grid ───────────────────────────────────────────────────────────
    Column {
        width: parent.width
        spacing: 2

        Repeater {
            model: 6

            delegate: Item {
                id: week
                required property int index
                width: parent.width
                height: 28

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: weekHover.hovered ? Theme.well : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                }
                HoverHandler { id: weekHover }

                Row {
                    anchors.fill: parent

                    Repeater {
                        model: 7

                        delegate: Item {
                            required property int index
                            readonly property var cell: root.cells[week.index * 7 + index]
                            width: parent.width / 7
                            height: parent.height

                            Rectangle {
                                anchors.centerIn: parent
                                width: 24
                                height: 24
                                radius: 12
                                color: Theme.peach
                                visible: cell.today
                            }

                            Label {
                                anchors.centerIn: parent
                                text: cell.day
                                font.weight: cell.today ? Font.Bold : Font.Medium
                                color: cell.today ? Theme.onAccent
                                     : !cell.inMonth ? "#3A3A3A"
                                     : cell.weekend ? Theme.muted : Theme.soft
                            }
                        }
                    }
                }
            }
        }
    }

    WheelHandler {
        onWheel: e => root.offset += e.angleDelta.y > 0 ? -1 : 1
    }
}
