import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl.Controls
import QGroundControl
import QGroundControl.Palette
import MAVLink
import QGroundControl.FlightDisplay

RowLayout {
    id: root

    QGCPalette { id: batteryPalette; colorGroupEnabled: true }

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
        Layout.preferredWidth: compactLandscape ? 72 : 84
        Layout.preferredHeight: compactLandscape ? 28 : 32

        QGCColoredImage {
            id: batteryIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: root.compactLandscape ? 26 : 30
            height: width
            sourceSize.width: width
            fillMode: Image.PreserveAspectFit

            readonly property var battery: FlightTelemetryModel.batteryFactGroup
            readonly property int chargeState: root.flightState.batteryReadingValid && battery
                                              ? battery.chargeState.rawValue : MAVLink.MAV_BATTERY_CHARGE_STATE_UNDEFINED
            readonly property var settings: QGroundControl.settingsManager.batteryIndicatorSettings
            readonly property real percentage: FlightTelemetryModel.displayBattery
            readonly property int level: {
                switch (chargeState) {
                case MAVLink.MAV_BATTERY_CHARGE_STATE_OK:
                    return percentage > settings.threshold1.rawValue ? 0
                         : percentage > settings.threshold2.rawValue ? 1 : 2
                case MAVLink.MAV_BATTERY_CHARGE_STATE_LOW:
                    return 3
                case MAVLink.MAV_BATTERY_CHARGE_STATE_CRITICAL:
                    return 4
                case MAVLink.MAV_BATTERY_CHARGE_STATE_EMERGENCY:
                case MAVLink.MAV_BATTERY_CHARGE_STATE_FAILED:
                case MAVLink.MAV_BATTERY_CHARGE_STATE_UNHEALTHY:
                    return 5
                default:
                    return 6
                }
            }
            source: ["/qmlimages/BatteryGreen.svg", "/qmlimages/BatteryYellowGreen.svg",
                     "/qmlimages/BatteryYellow.svg", "/qmlimages/BatteryOrange.svg",
                     "/qmlimages/BatteryCritical.svg", "/qmlimages/BatteryEMERGENCY.svg",
                     "/qmlimages/Battery.svg"][level]
            color: [batteryPalette.colorGreen, batteryPalette.colorYellowGreen,
                    batteryPalette.colorYellow, batteryPalette.colorOrange,
                    batteryPalette.colorRed, batteryPalette.colorRed,
                    FlightPalette.textHi][level]
        }
        Text {
            anchors.left: batteryIcon.right
            anchors.leftMargin: 3
            anchors.verticalCenter: parent.verticalCenter
            text: root.flightState.batteryReadingValid ? (Math.round(FlightTelemetryModel.displayBattery) + "%") : "--%"
            color: FlightPalette.textHi
            font.family: FlightPalette.cockpitFont
            font.pixelSize: compactLandscape ? 13 : 15
            font.bold: false
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
