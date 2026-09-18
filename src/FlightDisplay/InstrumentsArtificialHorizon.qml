import QtQuick

Canvas {
    id: root

    property double roll: 0
    property double pitch: 0
    property double pitchScale: 30

    implicitWidth: 200
    implicitHeight: 200

    onPaint: {
        var ctx = getContext("2d")
        ctx.save()
        ctx.clearRect(0, 0, width, height)

        var ovlpitch = Math.max(-90, Math.min(90, pitch))
        var w2 = width / 2
        var h2 = height / 2
        var radius = Math.min(w2, h2) - 3
        var skyColor = "#287BE8"
        var groundColor = "#8A531F"
        var h = -ovlpitch / pitchScale * h2

        ctx.translate(w2, h2)

        ctx.beginPath()
        ctx.arc(0, 0, radius, 0, 2 * Math.PI)
        ctx.clip()

        ctx.rotate(roll * Math.PI / 180)

        ctx.fillStyle = skyColor
        ctx.fillRect(-radius * 2, -radius * 2, radius * 4, radius * 4)

        ctx.fillStyle = groundColor
        ctx.fillRect(-radius * 2, -h, radius * 4, radius * 3)

        ctx.beginPath()
        ctx.moveTo(-radius * 2, -h)
        ctx.lineTo(radius * 2, -h)
        ctx.strokeStyle = "white"
        ctx.lineWidth = Math.max(2, width * 0.008)
        ctx.stroke()

        ctx.strokeStyle = "white"
        ctx.fillStyle = "white"
        ctx.lineWidth = 1
        ctx.font = Math.max(9, Math.round(width * 0.036)) + "px sans-serif"
        drawPitchMarks(ctx, h2 / pitchScale, radius, ovlpitch)

        ctx.restore()

        drawFixedReference(ctx, w2, h2, radius)
    }

    function drawPitchMarks(ctx, pxPerDegree, radius, ovlpitch) {
        for (var p = -90; p <= 90; p += 5) {
            if (p === 0) {
                continue
            }

            var y = (ovlpitch - p) * pxPerDegree
            if (y < -radius * 0.92 || y > radius * 0.92) {
                continue
            }

            ctx.beginPath()
            var major = Math.abs(p % 10) < 0.001
            var markWidth = major ? radius * 0.24 : radius * 0.13
            ctx.moveTo(-markWidth, y)
            ctx.lineTo(markWidth, y)
            ctx.stroke()

            if (major) {
                var label = Math.abs(p).toString()
                ctx.fillText(label, markWidth + 7, y + 4)
                ctx.save()
                ctx.scale(-1, 1)
                ctx.fillText(label, markWidth + 7, y + 4)
                ctx.restore()
            }
        }
    }

    function drawFixedReference(ctx, w2, h2, radius) {
        ctx.save()
        ctx.translate(w2, h2)

        ctx.beginPath()
        ctx.arc(0, 0, radius + 1, 0, 2 * Math.PI)
        ctx.lineWidth = Math.max(5, width * 0.035)
        ctx.strokeStyle = "#050505"
        ctx.stroke()

        ctx.beginPath()
        ctx.arc(0, 0, radius - 2, 0, 2 * Math.PI)
        ctx.lineWidth = Math.max(2, width * 0.012)
        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.28)
        ctx.stroke()

        ctx.strokeStyle = "#FFD600"
        ctx.lineWidth = Math.max(3, width * 0.014)
        ctx.lineCap = "round"
        ctx.beginPath()
        ctx.moveTo(-radius * 0.55, 0)
        ctx.lineTo(-radius * 0.16, 0)
        ctx.moveTo(radius * 0.16, 0)
        ctx.lineTo(radius * 0.55, 0)
        ctx.stroke()

        ctx.beginPath()
        ctx.arc(0, 0, radius * 0.09, 0, Math.PI)
        ctx.stroke()

        ctx.strokeStyle = "white"
        ctx.lineWidth = Math.max(2, width * 0.01)
        ctx.beginPath()
        ctx.moveTo(0, radius * 0.26)
        ctx.lineTo(0, radius * 0.52)
        ctx.stroke()

        ctx.restore()
    }

    onRollChanged: root.requestPaint()
    onPitchChanged: root.requestPaint()
    onPitchScaleChanged: root.requestPaint()
    onWidthChanged: root.requestPaint()
    onHeightChanged: root.requestPaint()
}
