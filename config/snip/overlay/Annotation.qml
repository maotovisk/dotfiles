import QtQuick
import QtQuick.Shapes
import qs.common
import qs.state

// One annotation, drawn in global coordinates (the parent layer is offset).
Item {
    id: root

    property var a: null
    property bool editing: false

    readonly property string kind: a ? a.kind : ""
    readonly property color ink: a ? a.color : "transparent"
    readonly property color contrast: (ink.r * 0.299 + ink.g * 0.587 + ink.b * 0.114) > 0.6 ? "#141414" : "#FFFFFF"

    Loader {
        active: root.a !== null
        sourceComponent: {
            switch (root.kind) {
            case "pen": case "highlight": return stroke
            case "line": case "arrow": return line
            case "rect": return rectangle
            case "ellipse": return ellipse
            case "text": return text
            case "counter": return counter
            case "pixelate": return pixelate
            }
            return null
        }
    }

    Component {
        id: stroke
        Shape {
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                readonly property bool hl: root.kind === "highlight"
                strokeColor: hl ? Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.38) : root.ink
                strokeWidth: hl ? root.a.stroke * 4 + 8 : root.a.stroke
                fillColor: "transparent"
                capStyle: hl ? ShapePath.SquareCap : ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                PathPolyline { path: root.a.points.map(p => Qt.point(p.x, p.y)) }
            }
        }
    }

    Component {
        id: line
        Shape {
            id: ln
            preferredRendererType: Shape.CurveRenderer
            readonly property real w: root.a.stroke
            readonly property real len: Math.hypot(root.a.x1 - root.a.x0, root.a.y1 - root.a.y0)
            readonly property real ux: len ? (root.a.x1 - root.a.x0) / len : 0
            readonly property real uy: len ? (root.a.y1 - root.a.y0) / len : 0
            readonly property bool arrow: root.kind === "arrow"
            readonly property real head: Math.min(len, w * 3.5 + 10)
            readonly property real half: head * 0.55
            // stop the shaft inside the head so the round cap never pokes through
            readonly property real cut: arrow ? head * 0.7 : 0
            readonly property real bx: root.a.x1 - ux * head
            readonly property real by: root.a.y1 - uy * head

            ShapePath {
                strokeColor: root.ink
                strokeWidth: ln.w
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathPolyline {
                    path: [Qt.point(root.a.x0, root.a.y0),
                           Qt.point(root.a.x1 - ln.ux * ln.cut, root.a.y1 - ln.uy * ln.cut)]
                }
            }
            ShapePath {
                strokeColor: ln.arrow ? root.ink : "transparent"
                strokeWidth: ln.arrow ? Math.max(1, ln.w / 2) : 0
                fillColor: ln.arrow ? root.ink : "transparent"
                joinStyle: ShapePath.RoundJoin
                PathPolyline {
                    path: [Qt.point(root.a.x1, root.a.y1),
                           Qt.point(ln.bx - ln.uy * ln.half, ln.by + ln.ux * ln.half),
                           Qt.point(ln.bx + ln.uy * ln.half, ln.by - ln.ux * ln.half),
                           Qt.point(root.a.x1, root.a.y1)]
                }
            }
        }
    }

    Component {
        id: rectangle
        Shape {
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: root.ink
                strokeWidth: root.a.stroke
                fillColor: "transparent"
                joinStyle: ShapePath.RoundJoin
                PathRectangle {
                    x: Math.min(root.a.x0, root.a.x1)
                    y: Math.min(root.a.y0, root.a.y1)
                    width: Math.abs(root.a.x1 - root.a.x0)
                    height: Math.abs(root.a.y1 - root.a.y0)
                    radius: 3
                }
            }
        }
    }

    Component {
        id: ellipse
        Shape {
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: root.ink
                strokeWidth: root.a.stroke
                fillColor: "transparent"
                PathAngleArc {
                    moveToStart: true
                    centerX: (root.a.x0 + root.a.x1) / 2
                    centerY: (root.a.y0 + root.a.y1) / 2
                    radiusX: Math.abs(root.a.x1 - root.a.x0) / 2
                    radiusY: Math.abs(root.a.y1 - root.a.y0) / 2
                    startAngle: 0
                    sweepAngle: 360
                }
            }
        }
    }

    Component {
        id: text
        Item {
            readonly property int px: [16, 24, 36][root.a.size]
            x: root.a.x
            y: root.a.y - px * 0.65

            Text {
                id: label
                text: root.a.text
                color: root.ink
                font.family: Theme.font
                font.pixelSize: parent.px
                font.weight: Font.DemiBold
                style: Text.Outline
                styleColor: Qt.rgba(root.contrast.r, root.contrast.g, root.contrast.b, 0.55)
                textFormat: Text.PlainText
            }

            // invisible twin that knows where the caret goes
            TextEdit {
                id: measure
                visible: false
                text: root.a.text
                font: label.font
                textFormat: TextEdit.PlainText
            }

            Rectangle {
                id: caret
                visible: root.editing
                readonly property rect r: measure.positionToRectangle(measure.length)
                x: r.x + 1
                y: r.y
                width: Math.max(2, parent.px / 12)
                height: r.height || parent.px * 1.2
                color: root.ink
                border.width: 1
                border.color: Qt.rgba(root.contrast.r, root.contrast.g, root.contrast.b, 0.5)
                SequentialAnimation on opacity {
                    running: caret.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 1; duration: 0 }
                    PauseAnimation { duration: 530 }
                    NumberAnimation { to: 0; duration: 0 }
                    PauseAnimation { duration: 530 }
                }
            }
        }
    }

    Component {
        id: counter
        Rectangle {
            readonly property int r: [11, 15, 20][root.a.size]
            x: root.a.x - r
            y: root.a.y - r
            width: r * 2
            height: r * 2
            radius: r
            color: root.ink
            border.width: 2
            border.color: Qt.rgba(root.contrast.r, root.contrast.g, root.contrast.b, 0.85)
            antialiasing: true

            Text {
                anchors.centerIn: parent
                text: root.a.n
                color: root.contrast
                font.family: Theme.font
                font.pixelSize: parent.r * 1.15
                font.weight: Font.Bold
            }
        }
    }

    Component {
        id: pixelate
        Backdrop {
            readonly property int block: [8, 14, 22][root.a.size]
            x: Math.round(Math.min(root.a.x0, root.a.x1))
            y: Math.round(Math.min(root.a.y0, root.a.y1))
            region: Qt.rect(x, y, Math.max(1, Math.round(Math.abs(root.a.x1 - root.a.x0))),
                                  Math.max(1, Math.round(Math.abs(root.a.y1 - root.a.y0))))
            smoothed: true
            // render into a tiny texture, show it unfiltered: real blocks, no shader
            layer.enabled: true
            layer.smooth: false
            layer.textureSize: Qt.size(Math.max(1, Math.ceil(width / block)), Math.max(1, Math.ceil(height / block)))
        }
    }
}
