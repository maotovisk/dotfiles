import QtQuick
import qs.common
import qs.state

Rectangle {
    id: root

    property string tip: ""
    property Item tipItem: null

    implicitWidth: row.implicitWidth + 12
    implicitHeight: 42
    radius: 13
    color: Theme.panel
    border.width: 1
    border.color: Theme.border

    // outer dark ring so it separates from bright screenshots
    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        z: -1
        radius: parent.radius + 1
        color: "transparent"
        border.width: 1
        border.color: Theme.outline
    }

    // swallow clicks on the gaps so they never reach the canvas
    MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.AllButtons }

    function showTip(t, item) {
        if (t !== "") { tip = t; tipItem = item }
        else if (tipItem === item) tip = ""
    }

    component Sep: Rectangle {
        width: 1
        height: 18
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.divider
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: Snip.tools
            ToolButton {
                required property var modelData
                icon: modelData.icon
                tip: modelData.label
                active: Snip.tool === modelData.id
                onClicked: Snip.setTool(modelData.id)
                onHoverTip: (t, i) => root.showTip(t, i)
            }
        }

        Item { width: 6; height: 1 }
        Sep {}
        Item { width: 6; height: 1 }

        Repeater {
            model: Snip.palette
            Item {
                id: swatch
                required property var modelData
                required property int index
                width: 22
                height: 30
                readonly property bool current: Qt.colorEqual(Snip.color, modelData)

                Rectangle {
                    anchors.centerIn: parent
                    width: swatch.current ? 18 : sm.containsMouse ? 16 : 14
                    height: width
                    radius: width / 2
                    color: swatch.modelData
                    border.width: swatch.current ? 2 : 1
                    border.color: swatch.current ? Theme.text : "#40FFFFFF"
                    Behavior on width { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
                }
                MouseArea {
                    id: sm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Snip.color = swatch.modelData
                    onContainsMouseChanged: root.showTip(containsMouse ? "Colour (" + (swatch.index + 1) + ")" : "", swatch)
                }
            }
        }

        Item { width: 6; height: 1 }
        Sep {}
        Item { width: 4; height: 1 }

        Repeater {
            model: Snip.sizes
            Rectangle {
                id: sz
                required property var modelData
                required property int index
                width: 26
                height: 30
                radius: 8
                readonly property bool current: Snip.sizeIndex === index
                color: current ? Theme.peachSoft : szm.containsMouse ? Theme.hover : "transparent"
                Rectangle {
                    anchors.centerIn: parent
                    width: [4, 7, 11][sz.index]
                    height: width
                    radius: width / 2
                    color: sz.current ? Theme.peach : Theme.soft
                }
                MouseArea {
                    id: szm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Snip.sizeIndex = sz.index
                    onContainsMouseChanged: root.showTip(containsMouse ? ["Thin", "Medium", "Thick"][sz.index] + "  [ ]" : "", sz)
                }
            }
        }

        Item { width: 4; height: 1 }
        Sep {}
        Item { width: 4; height: 1 }

        ToolButton {
            icon: "undo"; tip: "Undo (Ctrl+Z)"
            enabledLook: Snip.items.length > 0 || Snip.editingText
            onClicked: Snip.undo()
            onHoverTip: (t, i) => root.showTip(t, i)
        }
        ToolButton {
            icon: "redo"; tip: "Redo (Ctrl+Shift+Z)"
            enabledLook: Snip.redoStack.length > 0
            onClicked: Snip.redo()
            onHoverTip: (t, i) => root.showTip(t, i)
        }

        Item { width: 4; height: 1 }
        Sep {}
        Item { width: 4; height: 1 }

        ToolButton {
            icon: "copy"; tip: "Copy image (Ctrl+C)"
            onClicked: Snip.accept("copy")
            onHoverTip: (t, i) => root.showTip(t, i)
        }
        ToolButton {
            icon: "download"; tip: "Save only (Ctrl+S)"
            onClicked: Snip.accept("save")
            onHoverTip: (t, i) => root.showTip(t, i)
        }
        Item { width: 2; height: 1 }
        ToolButton {
            icon: "upload"; label: "Upload"; tip: "Upload to s-ul (Enter)"
            primary: true
            onClicked: Snip.accept("upload")
            onHoverTip: (t, i) => root.showTip(t, i)
        }
        ToolButton {
            icon: "x"; tip: "Cancel (Esc)"
            onClicked: Snip.cancel()
            onHoverTip: (t, i) => root.showTip(t, i)
        }
    }

    Pill {
        visible: root.tip !== "" && root.tipItem !== null
        text: root.tip
        y: -height - 6
        x: {
            if (!root.tipItem) return 0
            const p = root.tipItem.mapToItem(root, root.tipItem.width / 2, 0)
            return Math.max(0, Math.min(root.width - width, p.x - width / 2))
        }
    }
}
