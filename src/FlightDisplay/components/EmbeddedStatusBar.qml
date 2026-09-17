import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl.Controls
import QGroundControl.FlightDisplay

RowLayout {
    id: root

    property bool compactLandscape: false
    property var flightState

    height: compactLandscape ? 38 : 46
    spacing: compactLandscape ? 8 : 10

    Item {
        Layout.preferredWidth: Math.max(68, futureInlineText.implicitWidth + 22)
        Layout.preferredHeight: compactLandscape ? 26 : 30
        Layout.alignment: Qt.AlignVCenter

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: futureInlineMouse.pressed ? Qt.rgba(FlightPalette.cyan.r, FlightPalette.cyan.g, FlightPalette.cyan.b, 0.16)
                                             : Qt.rgba(1, 1, 1, FlightPalette.lightMode ? 0.70 : 0.10)
            border.color: Qt.rgba(FlightPalette.cyan.r, FlightPalette.cyan.g, FlightPalette.cyan.b, 0.12)
        }

        Text {
            id: futureInlineText
            anchors.centerIn: parent
            text: "future"
            color: FlightPalette.cyan
            font.pixelSize: compactLandscape ? 13 : 14
            font.bold: true
        }

        MouseArea {
            id: futureInlineMouse
            anchors.fill: parent
        }
    }

    Item { Layout.fillWidth: true }

    Row {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: compactLandscape ? 50 : 58
        Layout.preferredHeight: compactLandscape ? 28 : 34
        spacing: 2

        QGCColoredImage {
            anchors.verticalCenter: parent.verticalCenter
            width: compactLandscape ? 20 : 23
            height: width
            source: "/qmlimages/Gps.svg"
            fillMode: Image.PreserveAspectFit
            color: FlightPalette.lightMode ? FlightPalette.textHi : Qt.rgba(1, 1, 1, 0.58)
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.flightState.dataSuppressed ? "--" : (FlightTelemetryModel.activeVehicle ? FlightTelemetryModel.displayGpsSat : "--")
                color: FlightPalette.textHi
                font.pixelSize: compactLandscape ? 11 : 13
                font.bold: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.flightState.dataSuppressed ? "--" : (FlightTelemetryModel.activeVehicle ? FlightTelemetryModel.displayGpsHdop.toFixed(1) : "--")
                color: FlightPalette.textLo
                font.pixelSize: compactLandscape ? 10 : 11
            }
        }
    }

    CircularMetricGauge {
        Layout.preferredWidth: compactLandscape ? 40 : 46
        Layout.preferredHeight: Layout.preferredWidth
        value: root.flightState.batteryReadingValid ? FlightTelemetryModel.displayBattery : 0
        maximumValue: 100
        valueText: root.flightState.batteryReadingValid ? Math.round(FlightTelemetryModel.displayBattery).toString() : "--"
        progressColor: root.flightState.batteryGaugeColor()
        trackColor: FlightPalette.lightMode ? "#D8DEE6" : "#263241"
        textColor: FlightPalette.textHi
        labelColor: FlightPalette.textLo
        lineWidth: compactLandscape ? 5 : 5.5
        valueFontSize: compactLandscape ? 12 : 14
        labelFontSize: 0
        contentVerticalOffset: -0.5
        compact: true
        closedRing: true
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: Qt.formatTime(FlightTelemetryModel.localTime, "hh:mm")
        color: FlightPalette.textLo
        font.pixelSize: compactLandscape ? 12 : 14
    }
}
