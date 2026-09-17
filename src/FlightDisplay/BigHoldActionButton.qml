import QtQuick 2.15

Rectangle {
    id: root

    signal holdTriggered()

    property string text: ""
    property string hint: ""
    property color accent: "#2977EF"
    property bool enabledState: false
    property real holdProgress: 0
    property int holdDuration: 900
    property real containerWidth: 0
    property bool lightMode: true
    property color buttonIdle: "#F1F5F9"
    property color panelBorder: "#CBD5E1"
    property color textLo: "#64748B"

    width: Math.min(190, Math.max(150, containerWidth * 0.18))
    height: width
    radius: width / 2
    color: enabledState ? Qt.rgba(accent.r, accent.g, accent.b, lightMode ? 0.12 : 0.18) : buttonIdle
    border.color: enabledState ? accent : panelBorder
    border.width: 2
    opacity: enabledState ? 1.0 : 0.55

    Canvas {
        id: holdProgressRing
        anchors.fill: parent
        anchors.margins: 7
        visible: root.enabledState

        onPaint: {
            var ctx = getContext("2d")
            var w = width
            var h = height
            var cx = w / 2
            var cy = h / 2
            var radius = Math.min(w, h) / 2 - 5
            var start = -Math.PI / 2
            var end = start + Math.PI * 2 * root.holdProgress

            ctx.clearRect(0, 0, w, h)
            ctx.lineCap = "round"
            ctx.lineWidth = 5
            ctx.strokeStyle = root.lightMode ? Qt.rgba(0.4, 0.48, 0.58, 0.22) : Qt.rgba(1, 1, 1, 0.18)
            ctx.beginPath()
            ctx.arc(cx, cy, radius, 0, Math.PI * 2)
            ctx.stroke()

            if (root.holdProgress > 0) {
                ctx.strokeStyle = root.accent
                ctx.beginPath()
                ctx.arc(cx, cy, radius, start, end)
                ctx.stroke()
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.text
            color: root.enabledState ? root.accent : root.textLo
            font.pixelSize: 34
            font.bold: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.hint
            color: root.textLo
            font.pixelSize: 13
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabledState
        onPressed: {
            root.holdProgress = 0
            holdProgressRing.requestPaint()
            holdTimer.restart()
        }
        onReleased: {
            holdTimer.stop()
            root.holdProgress = 0
            holdProgressRing.requestPaint()
        }
        onCanceled: {
            holdTimer.stop()
            root.holdProgress = 0
            holdProgressRing.requestPaint()
        }
    }

    Timer {
        id: holdTimer
        interval: 16
        repeat: true

        property int elapsedMs: 0

        onRunningChanged: {
            if (running) {
                elapsedMs = 0
            }
        }

        onTriggered: {
            elapsedMs += interval
            root.holdProgress = Math.min(1, elapsedMs / root.holdDuration)
            holdProgressRing.requestPaint()

            if (root.holdProgress >= 1) {
                stop()
                root.holdTriggered()
                root.holdProgress = 0
                holdProgressRing.requestPaint()
            }
        }
    }
}
