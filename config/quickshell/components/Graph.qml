import QtQuick
import qs.common

// Smoothed area sparkline. `values` are 0..max (max <= 0 → auto-scale).
// The x-axis is a fixed window of `capacity` samples, filled from the right.
Canvas {
    id: root

    property var values: []
    property real max: 1
    property int capacity: 60
    property color color: Theme.peach
    property real fillOpacity: 0.22

    renderStrategy: Canvas.Cooperative
    onValuesChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const n = values.length
        if (n < 2)
            return

        const top = max > 0 ? max : Math.max(1, ...values) * 1.15
        const step = width / (capacity - 1)
        const x0 = width - (n - 1) * step
        const pts = values.map((v, i) => [x0 + i * step, height - 1 - Math.min(1, v / top) * (height - 3)])

        // midpoint-smoothed path
        function trace() {
            ctx.moveTo(pts[0][0], pts[0][1])
            for (let i = 1; i < n - 1; i++) {
                const mx = (pts[i][0] + pts[i + 1][0]) / 2
                const my = (pts[i][1] + pts[i + 1][1]) / 2
                ctx.quadraticCurveTo(pts[i][0], pts[i][1], mx, my)
            }
            ctx.lineTo(pts[n - 1][0], pts[n - 1][1])
        }

        const c = Qt.rgba(root.color.r, root.color.g, root.color.b, 1)
        const grad = ctx.createLinearGradient(0, 0, 0, height)
        grad.addColorStop(0, Qt.rgba(c.r, c.g, c.b, fillOpacity))
        grad.addColorStop(1, Qt.rgba(c.r, c.g, c.b, 0))

        ctx.beginPath()
        trace()
        ctx.lineTo(pts[n - 1][0], height)
        ctx.lineTo(pts[0][0], height)
        ctx.closePath()
        ctx.fillStyle = grad
        ctx.fill()

        ctx.beginPath()
        trace()
        ctx.lineWidth = 1.5
        ctx.lineJoin = "round"
        ctx.strokeStyle = c
        ctx.stroke()
    }
}
