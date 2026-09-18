import QtQuick 2.15

import QGroundControl.FlightDisplay

Item {
    id: root

    property real heading: 0
    property bool active: false
    property bool compactLandscape: false
    property color textHi: "#E6E2D8"
    property color textLo: "#9B9A94"
    property color accent: "#E6E2D8"
    property color tickColor: "#9B9A94"
    property real scaleFactor: 1.0

    width: (compactLandscape ? 124 : 148) * scaleFactor
    height: width + (compactLandscape ? 26 : 30) * scaleFactor

    function normalize(value) {
        var result = value % 360
        return result < 0 ? result + 360 : result
    }

    function cardLabel(value) {
        var v = Math.round(normalize(value))
        if (v === 0) return "N"
        if (v === 90) return "E"
        if (v === 180) return "S"
        if (v === 270) return "W"
        return ""
    }

    Rectangle {
        id: bezel
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: width
        radius: width / 2
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#525254" }
            GradientStop { position: 0.42; color: "#151516" }
            GradientStop { position: 1.0; color: "#050506" }
        }
        border.color: Qt.rgba(1, 1, 1, 0.22)
        border.width: Math.max(1, Math.round(2 * root.scaleFactor))

        Canvas {
            id: compassCanvas
            anchors.fill: parent
            anchors.margins: Math.round(8 * root.scaleFactor)
            rotation: -(root.active ? root.heading : 0)

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var cx = width / 2
                var cy = height / 2
                var r = Math.min(width, height) / 2
                var outer = r * 0.92
                var inner = r * 0.70
                var currentHeading = root.active ? root.heading : 0

                ctx.save()
                ctx.translate(cx, cy)

                ctx.beginPath()
                ctx.arc(0, 0, outer, 0, Math.PI * 2)
                ctx.fillStyle = "#080809"
                ctx.fill()
                ctx.strokeStyle = "rgba(255,255,255,0.20)"
                ctx.lineWidth = Math.max(1, r * 0.018)
                ctx.stroke()

                ctx.textAlign = "center"
                ctx.textBaseline = "middle"
                ctx.lineCap = "butt"

                for (var deg = 0; deg < 360; deg += 5) {
                    var rad = (deg - 90) * Math.PI / 180
                    var major = deg % 30 === 0
                    var cardinal = deg % 90 === 0
                    var tickOuter = outer * 0.95
                    var tickInner = major ? outer * 0.78 : outer * 0.86
                    var x1 = Math.cos(rad) * tickInner
                    var y1 = Math.sin(rad) * tickInner
                    var x2 = Math.cos(rad) * tickOuter
                    var y2 = Math.sin(rad) * tickOuter

                    ctx.strokeStyle = cardinal ? "#E6E2D8" : "rgba(230,226,216,0.72)"
                    ctx.lineWidth = cardinal ? Math.max(1.6, r * 0.030) : (major ? Math.max(1.2, r * 0.022) : 1)
                    ctx.beginPath()
                    ctx.moveTo(x1, y1)
                    ctx.lineTo(x2, y2)
                    ctx.stroke()

                    if (major) {
                        var label = root.cardLabel(deg)
                        var labelRadius = cardinal ? inner * 0.82 : inner * 0.92
                        ctx.save()
                        ctx.translate(Math.cos(rad) * labelRadius, Math.sin(rad) * labelRadius)
                        ctx.rotate(currentHeading * Math.PI / 180)
                        ctx.fillStyle = cardinal ? "#E6E2D8" : "#9B9A94"
                        ctx.font = "bold " + Math.round((cardinal ? 15 : 9) * root.scaleFactor) + "px Consolas"
                        ctx.fillText(label !== "" ? label : ("0" + (deg / 10)).slice(-2), 0, 0)
                        ctx.restore()
                    }
                }

                ctx.beginPath()
                ctx.arc(0, 0, r * 0.055, 0, Math.PI * 2)
                ctx.fillStyle = "#D8D5CA"
                ctx.fill()
                ctx.restore()
            }
        }

        Canvas {
            id: lubberLine
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(5 * root.scaleFactor)
            width: Math.round(18 * root.scaleFactor)
            height: Math.round(26 * root.scaleFactor)

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = "#E6E2D8"
                ctx.strokeStyle = "#080809"
                ctx.lineWidth = 1
                ctx.beginPath()
                ctx.moveTo(width / 2, height)
                ctx.lineTo(0, 0)
                ctx.lineTo(width, 0)
                ctx.closePath()
                ctx.fill()
                ctx.stroke()
            }
        }
    }

    Rectangle {
        anchors.top: bezel.bottom
        anchors.topMargin: Math.round(2 * root.scaleFactor)
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.round((compactLandscape ? 86 : 104) * root.scaleFactor)
        height: Math.round((compactLandscape ? 24 : 28) * root.scaleFactor)
        radius: 3
        color: FlightPalette.lcdBg
        border.color: FlightPalette.lcdBorder
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: root.active ? ("航向 " + ("000" + Math.round(root.normalize(root.heading))).slice(-3) + "°") : "航向 ---"
            color: FlightPalette.lcdText
            font.family: FlightPalette.cockpitFont
            font.pixelSize: Math.round((compactLandscape ? 13 : 16) * root.scaleFactor)
            font.bold: true
            style: Text.Raised
            styleColor: FlightPalette.lcdGlow
        }
    }

    onHeadingChanged: compassCanvas.requestPaint()
    onActiveChanged: compassCanvas.requestPaint()
    onScaleFactorChanged: {
        compassCanvas.requestPaint()
        lubberLine.requestPaint()
    }
}
