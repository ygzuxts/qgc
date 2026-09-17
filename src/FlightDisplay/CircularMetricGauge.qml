import QtQuick 2.15

Item {
    id: root

    property real value: 0
    property real minimumValue: 0
    property real maximumValue: 100
    property string valueText: Math.round(value).toString()
    property string label: ""
    property string unit: ""
    property color progressColor: "#2977EF"
    property color trackColor: "#DDD8C7"
    property color textColor: "#142033"
    property color labelColor: "#64748B"
    property real lineWidth: compact ? 8 : 10
    property real valueFontSize: compact ? 26 : 32
    property real labelFontSize: compact ? 10 : 11
    property real contentVerticalOffset: 0
    property real minimumVisibleProgress: 0
    property bool compact: false
    property bool closedRing: false

    width: compact ? 112 : 132
    height: width

    function clampedProgress() {
        var span = maximumValue - minimumValue
        if (span <= 0) {
            return 0
        }
        var progress = Math.max(0, Math.min(1, (value - minimumValue) / span))
        return progress > 0 || minimumVisibleProgress <= 0 ? progress : minimumVisibleProgress
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            var size = Math.min(width, height)
            var cx = width / 2
            var cy = height / 2
            var radius = size / 2 - root.lineWidth / 2 - 2
            var start = root.closedRing ? -Math.PI / 2 : Math.PI * 0.67
            var sweep = root.closedRing ? Math.PI * 2 : Math.PI * 1.66
            var end = start + sweep * root.clampedProgress()

            ctx.clearRect(0, 0, width, height)
            ctx.lineCap = "butt"
            ctx.lineWidth = root.lineWidth

            if (root.closedRing) {
                ctx.strokeStyle = root.trackColor
                ctx.beginPath()
                ctx.arc(cx, cy, radius, 0, Math.PI * 2)
                ctx.stroke()
            } else {
                ctx.strokeStyle = root.trackColor
                ctx.beginPath()
                ctx.arc(cx, cy, radius, start, start + sweep)
                ctx.stroke()
            }

            if (root.clampedProgress() >= 1 && root.closedRing) {
                ctx.strokeStyle = root.progressColor
                ctx.beginPath()
                ctx.arc(cx, cy, radius, 0, Math.PI * 2)
                ctx.stroke()
            } else if (root.clampedProgress() > 0) {
                ctx.strokeStyle = root.progressColor
                ctx.beginPath()
                ctx.arc(cx, cy, radius, start, end)
                ctx.stroke()
            }
        }
    }

    Column {
        z: 2
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.contentVerticalOffset
        spacing: compact ? 0 : 2

        Text {
            z: 2
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.valueText
            color: root.textColor
            font.pixelSize: root.valueFontSize
            font.bold: true
        }

        Text {
            z: 2
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.label.length > 0 || root.unit.length > 0
            text: root.label + (root.unit.length > 0 ? " " + root.unit : "")
            color: root.labelColor
            font.pixelSize: root.labelFontSize
        }
    }

    onValueChanged: canvas.requestPaint()
    onMinimumValueChanged: canvas.requestPaint()
    onMaximumValueChanged: canvas.requestPaint()
    onProgressColorChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()
    onLineWidthChanged: canvas.requestPaint()
    onCompactChanged: canvas.requestPaint()
    onClosedRingChanged: canvas.requestPaint()
}
