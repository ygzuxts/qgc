import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl.Controls
import QGroundControl.FlightDisplay

RowLayout {
    id: root

    property bool compactLandscape: false
    property var flightState
    signal themeToggleRequested()
    signal originalQgcModeRequested()
    readonly property bool telemetryAvailable: !flightState.dataSuppressed && FlightTelemetryModel.activeVehicle
    readonly property string gpsText: telemetryAvailable
                                      ? ("卫星 " + FlightTelemetryModel.displayGpsSat + "  精度 " + FlightTelemetryModel.displayGpsHdop.toFixed(1))
                                      : "卫星 --  精度 --"
    readonly property string clockText: Qt.formatTime(FlightTelemetryModel.localTime, "hh:mm")
    readonly property int statusModuleHeight: compactLandscape ? 54 : 68

    height: compactLandscape ? 58 : 78
    spacing: compactLandscape ? 12 : 18

    Item {
        Layout.preferredWidth: Math.max(68, futureInlineText.implicitWidth + 22)
        Layout.preferredHeight: compactLandscape ? 26 : 30
        Layout.alignment: Qt.AlignVCenter

        Rectangle {
            anchors.fill: parent
            radius: 6
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: FlightPalette.lightMode
                           ? (futureInlineMouse.pressed ? "#BDB9AE" : "#F1F0EA")
                           : (futureInlineMouse.pressed ? "#09090A" : "#2B2B2D")
                }
                GradientStop {
                    position: 1.0
                    color: FlightPalette.lightMode
                           ? (futureInlineMouse.pressed ? "#E0DDD4" : "#D4D1C7")
                           : (futureInlineMouse.pressed ? "#1C1C1E" : "#0B0B0C")
                }
            }
            border.color: FlightPalette.lightMode ? "#9E9B92" : Qt.rgba(1, 1, 1, 0.20)
        }

        Text {
            id: futureInlineText
            anchors.centerIn: parent
            text: "FUTURE"
            color: FlightPalette.textHi
            font.family: FlightPalette.cockpitFont
            font.pixelSize: compactLandscape ? 13 : 14
            font.bold: true
        }

        MouseArea {
            id: futureInlineMouse
            anchors.fill: parent
            pressAndHoldInterval: 550
            property int tapCount: 0

            Timer {
                id: futureInlineTapReset
                interval: 3000
                repeat: false
                onTriggered: futureInlineMouse.tapCount = 0
            }

            onClicked: {
                tapCount++
                futureInlineTapReset.restart()

                if (tapCount >= 3) {
                    futureInlineTapReset.stop()
                    tapCount = 0
                    root.originalQgcModeRequested()
                }
            }

            onPressAndHold: root.themeToggleRequested()
        }
    }

    Item {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: compactLandscape ? 160 : 214
        Layout.preferredHeight: root.statusModuleHeight

        Row {
            anchors.centerIn: parent
            spacing: compactLandscape ? 7 : 10

            QGCColoredImage {
                anchors.verticalCenter: parent.verticalCenter
                width: compactLandscape ? 32 : 42
                height: width
                source: "/qmlimages/Gps.svg"
                fillMode: Image.PreserveAspectFit
                color: FlightPalette.textHi
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.gpsText
                color: FlightPalette.textHi
                font.family: FlightPalette.cockpitFont
                font.pixelSize: compactLandscape ? 13 : 17
                font.bold: true
            }
        }
    }

    Item { Layout.fillWidth: true }

    Item {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: compactLandscape ? 92 : 118
        Layout.preferredHeight: compactLandscape ? 62 : 78

        Canvas {
            id: batteryGauge
            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d")
                var w = width
                var h = height
                var cx = w * 0.5
                var cy = h * 0.68
                var r = Math.min(w * 0.42, h * 0.56)
                var start = Math.PI
                var batteryValue = root.flightState.batteryReadingValid ? Math.max(0, Math.min(100, FlightTelemetryModel.displayBattery)) : 0
                var angle = start + (batteryValue / 100) * Math.PI

                ctx.clearRect(0, 0, w, h)

                var shell = ctx.createRadialGradient(cx, cy, r * 0.1, cx, cy, r * 1.22)
                shell.addColorStop(0, FlightPalette.lightMode ? "#F1EFE7" : "#424347")
                shell.addColorStop(0.55, FlightPalette.lightMode ? "#D7D3C8" : "#17181A")
                shell.addColorStop(1, FlightPalette.lightMode ? "#8C897F" : "#050506")
                ctx.fillStyle = shell
                ctx.beginPath()
                ctx.arc(cx, cy, r * 1.18, Math.PI, Math.PI * 2, false)
                ctx.lineTo(cx + r * 1.18, cy + r * 0.16)
                ctx.lineTo(cx - r * 1.18, cy + r * 0.16)
                ctx.closePath()
                ctx.fill()

                ctx.lineWidth = Math.max(2, w * 0.045)
                ctx.lineCap = "round"
                function arcSegment(a0, a1, color) {
                    ctx.strokeStyle = color
                    ctx.beginPath()
                    ctx.arc(cx, cy, r * 0.82, a0, a1)
                    ctx.stroke()
                }
                arcSegment(Math.PI, Math.PI * 1.28, FlightPalette.statusRed)
                arcSegment(Math.PI * 1.30, Math.PI * 1.58, FlightPalette.statusYellow)
                arcSegment(Math.PI * 1.60, Math.PI * 2.0, FlightPalette.statusGreen)

                ctx.strokeStyle = FlightPalette.textHi
                ctx.lineWidth = 1
                for (var i = 0; i <= 10; i++) {
                    var tickAngle = start + i / 10 * Math.PI
                    var x0 = cx + Math.cos(tickAngle) * r * 0.66
                    var y0 = cy + Math.sin(tickAngle) * r * 0.66
                    var x1 = cx + Math.cos(tickAngle) * r * 0.76
                    var y1 = cy + Math.sin(tickAngle) * r * 0.76
                    ctx.beginPath()
                    ctx.moveTo(x0, y0)
                    ctx.lineTo(x1, y1)
                    ctx.stroke()
                }

                ctx.strokeStyle = root.flightState.batteryReadingValid ? FlightPalette.textHi : FlightPalette.textLo
                ctx.lineWidth = Math.max(2, w * 0.035)
                ctx.beginPath()
                ctx.moveTo(cx, cy)
                ctx.lineTo(cx + Math.cos(angle) * r * 0.58, cy + Math.sin(angle) * r * 0.58)
                ctx.stroke()

                ctx.fillStyle = FlightPalette.lightMode ? "#3B3934" : "#0A0A0B"
                ctx.beginPath()
                ctx.arc(cx, cy, r * 0.11, 0, Math.PI * 2)
                ctx.fill()
                ctx.strokeStyle = FlightPalette.panelBorder
                ctx.stroke()
            }

            Connections {
                target: FlightTelemetryModel
                function onDisplayBatteryChanged() { batteryGauge.requestPaint() }
            }
            Connections {
                target: root.flightState
                function onBatteryReadingValidChanged() { batteryGauge.requestPaint() }
            }
            Connections {
                target: FlightPalette
                function onLightModeChanged() { batteryGauge.requestPaint() }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            text: root.flightState.batteryReadingValid ? ("电量 " + Math.round(FlightTelemetryModel.displayBattery) + "%") : "电量 --"
            color: FlightPalette.textHi
            font.family: FlightPalette.cockpitFont
            font.pixelSize: compactLandscape ? 12 : 15
            font.bold: true
        }
    }

    Rectangle {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: compactLandscape ? 58 : 68
        Layout.preferredHeight: compactLandscape ? 24 : 30
        radius: 3
        color: FlightPalette.lcdBg
        border.color: FlightPalette.lcdBorder
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: root.clockText
            color: FlightPalette.lcdText
            font.family: FlightPalette.cockpitFont
            font.pixelSize: compactLandscape ? 14 : 17
            font.bold: true
            style: Text.Raised
            styleColor: FlightPalette.lcdGlow
        }
    }
}
