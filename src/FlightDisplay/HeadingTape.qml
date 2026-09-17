import QtQuick 2.15

Item {
    id: root

    property real heading: 0
    property bool active: false
    property bool compactLandscape: false
    property color textHi: "#142033"
    property color textLo: "#64748B"
    property color accent: "#2977EF"
    property color tickColor: "#8EA0B6"
    property real scaleFactor: 1.0

    width: (compactLandscape ? 172 : 210) * scaleFactor
    height: (compactLandscape ? 84 : 94) * scaleFactor
    clip: true

    function normalize(value) {
        var result = value % 360
        return result < 0 ? result + 360 : result
    }

    function signedDelta(value, center) {
        var delta = normalize(value) - normalize(center)
        if (delta > 180) {
            delta -= 360
        } else if (delta < -180) {
            delta += 360
        }
        return delta
    }

    function tickLabel(value) {
        return ("000" + Math.round(normalize(value))).slice(-3)
    }

    Canvas {
        id: tapeCanvas
        anchors.left: parent.left
        anchors.right: parent.right
        y: (compactLandscape ? 8 : 9) * root.scaleFactor
        height: (compactLandscape ? 38 : 43) * root.scaleFactor

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var centerX = width / 2
            var baselineY = (root.compactLandscape ? 10 : 11) * root.scaleFactor
            var labelY = (root.compactLandscape ? 30 : 34) * root.scaleFactor
            var pixelsPerDegree = (root.compactLandscape ? 2.9 : 3.35) * root.scaleFactor
            var centerHeading = root.active ? root.heading : 0
            var visibleDegrees = Math.ceil(width / pixelsPerDegree / 2) + 10
            var startTick = Math.floor((centerHeading - visibleDegrees) / 5) * 5
            var endTick = Math.ceil((centerHeading + visibleDegrees) / 5) * 5
            var edgePadding = (root.compactLandscape ? 18 : 22) * root.scaleFactor

            ctx.lineCap = "butt"
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"

            ctx.strokeStyle = root.tickColor
            ctx.globalAlpha = 0.28
            ctx.lineWidth = 1
            ctx.beginPath()
            ctx.moveTo(edgePadding, baselineY)
            ctx.lineTo(width - edgePadding, baselineY)
            ctx.stroke()

            for (var headingValue = startTick; headingValue <= endTick; headingValue += 5) {
                var x = centerX + root.signedDelta(headingValue, centerHeading) * pixelsPerDegree
                if (x < edgePadding || x > width - edgePadding) {
                    continue
                }

                var normalizedHeading = Math.round(root.normalize(headingValue))
                var isMajor = normalizedHeading % 10 === 0
                var hasLabel = isMajor
                var tickTop = baselineY - (isMajor ? (root.compactLandscape ? 8 : 9) : (root.compactLandscape ? 4 : 5)) * root.scaleFactor
                var tickBottom = baselineY + (isMajor ? 7 : 4) * root.scaleFactor

                ctx.strokeStyle = root.tickColor
                ctx.globalAlpha = isMajor ? 0.72 : 0.38
                ctx.lineWidth = 1
                ctx.beginPath()
                ctx.moveTo(Math.round(x) + 0.5, tickTop)
                ctx.lineTo(Math.round(x) + 0.5, tickBottom)
                ctx.stroke()

                if (hasLabel && Math.abs(root.signedDelta(headingValue, centerHeading)) >= 8 &&
                        x >= edgePadding + 14 * root.scaleFactor && x <= width - edgePadding - 14 * root.scaleFactor) {
                    ctx.globalAlpha = 1
                    ctx.fillStyle = root.textLo
                    ctx.font = Math.round((root.compactLandscape ? 9 : 10) * root.scaleFactor) + "px sans-serif"
                    ctx.fillText(root.tickLabel(headingValue), x, labelY)
                }
            }

            ctx.globalAlpha = 1
        }
    }

    Rectangle {
        id: headingChip
        anchors.horizontalCenter: parent.horizontalCenter
        y: (compactLandscape ? 44 : 50) * root.scaleFactor
        width: (compactLandscape ? 44 : 50) * root.scaleFactor
        height: (compactLandscape ? 20 : 22) * root.scaleFactor
        radius: 5 * root.scaleFactor
        color: accent

        Text {
            anchors.centerIn: parent
            text: root.active ? root.tickLabel(root.heading) : "---"
            color: "#FFFFFF"
            font.pixelSize: Math.round((root.compactLandscape ? 12 : 14) * root.scaleFactor)
            font.bold: true
        }
    }

    Canvas {
        id: pointerCanvas
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        width: (compactLandscape ? 9 : 10) * root.scaleFactor
        height: (compactLandscape ? 12 : 14) * root.scaleFactor

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = root.accent
            ctx.beginPath()
            ctx.moveTo(width / 2, height)
            ctx.lineTo(0, 0)
            ctx.lineTo(width, 0)
            ctx.closePath()
            ctx.fill()
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: headingChip.bottom
        anchors.topMargin: (compactLandscape ? 5 : 6) * root.scaleFactor
        text: "航向"
        color: textHi
        font.pixelSize: Math.round((compactLandscape ? 11 : 12) * root.scaleFactor)
        font.bold: true
    }

    onHeadingChanged: tapeCanvas.requestPaint()
    onActiveChanged: tapeCanvas.requestPaint()
    onCompactLandscapeChanged: tapeCanvas.requestPaint()
    onScaleFactorChanged: tapeCanvas.requestPaint()
    onAccentChanged: pointerCanvas.requestPaint()
}
