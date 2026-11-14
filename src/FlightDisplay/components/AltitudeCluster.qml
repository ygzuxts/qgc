import QtQuick 2.15

import QGroundControl.FlightDisplay

Column {
    id: root

    property bool compactLandscape: false
    property int sideGaugeSize: 260
    property var flightState

    width: Math.max(sideGaugeSize + 36, parent ? parent.width * 0.22 : sideGaugeSize + 36)
    spacing: compactLandscape ? 6 : 8
    opacity: flightState.dataSuppressed ? 0.48 : 1.0

    Behavior on opacity { NumberAnimation { duration: 260 } }

    QfiAltimeter {
        anchors.horizontalCenter: parent.horizontalCenter
        radius: root.sideGaugeSize / 2
        altitude: flightState.dataSuppressed ? 0 : FlightTelemetryModel.displayAltitude
        pressure: 29.92
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.round(root.sideGaugeSize * 0.46)
        height: Math.round(root.sideGaugeSize * 0.14)
        radius: 3
        color: FlightPalette.lcdBg
        border.color: FlightPalette.lcdBorder
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: flightState.dataSuppressed ? "--" : (FlightTelemetryModel.activeVehicle ? FlightTelemetryModel.displayAltitudeAMSL.toFixed(0) : "--")
            color: FlightPalette.lcdText
            font.family: FlightPalette.cockpitFont
            font.pixelSize: Math.round(root.sideGaugeSize * 0.088)
            font.bold: true
            style: Text.Raised
            styleColor: FlightPalette.lcdGlow
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "海拔高度 m"
        color: FlightPalette.textLo
        font.family: FlightPalette.cockpitFont
        font.pixelSize: Math.round(root.sideGaugeSize * 0.050)
    }
}
