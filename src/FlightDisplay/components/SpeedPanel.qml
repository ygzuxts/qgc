import QtQuick 2.15

import QGroundControl.FlightDisplay

Column {
    id: root

    property bool compactLandscape: false
    property int sideGaugeSize: 260
    property var flightState
    readonly property bool showingSpeed: FlightTelemetryModel.displayAirspeed >= 0.05

    width: Math.max(sideGaugeSize + 36, parent ? parent.width * 0.22 : sideGaugeSize + 36)
    spacing: compactLandscape ? 6 : 8
    opacity: flightState.dataSuppressed ? 0.48 : 1.0

    Behavior on opacity { NumberAnimation { duration: 260 } }

    QfiAirspeedIndicator {
        anchors.horizontalCenter: parent.horizontalCenter
        radius: root.sideGaugeSize / 2
        airspeed: Math.max(0, FlightTelemetryModel.displayAirspeed)
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.round(root.sideGaugeSize * 0.54)
        height: Math.round(root.sideGaugeSize * 0.16)
        radius: 3
        color: FlightPalette.lcdBg
        border.color: FlightPalette.lcdBorder
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: flightState.dataSuppressed ? "--"
                  : root.showingSpeed ? FlightTelemetryModel.displayAirspeed.toFixed(1)
                  : ((FlightTelemetryModel.displayVspeed >= 0 ? "↑ +" : "↓ ") + FlightTelemetryModel.displayVspeed.toFixed(1))
            color: FlightPalette.lcdText
            font.family: FlightPalette.cockpitFont
            font.pixelSize: Math.round(root.sideGaugeSize * 0.105)
            font.bold: true
            style: Text.Raised
            styleColor: FlightPalette.lcdGlow
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "速度 m/s"
        color: FlightPalette.textLo
        font.family: FlightPalette.cockpitFont
        font.pixelSize: Math.round(root.sideGaugeSize * 0.052)
    }

}
