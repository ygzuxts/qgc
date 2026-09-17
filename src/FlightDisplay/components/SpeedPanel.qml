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

    CircularMetricGauge {
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.sideGaugeSize
        height: width
        value: Math.abs(FlightTelemetryModel.displayAirspeed)
        maximumValue: 160
        valueText: flightState.dataSuppressed ? "--" : FlightTelemetryModel.displayAirspeed.toFixed(0)
        label: "速度"
        unit: "km/h"
        progressColor: flightState.limitedMetricColor(FlightTelemetryModel.displayAirspeed, 160, FlightPalette.cyan)
        trackColor: FlightPalette.lightMode ? "#D8DEE6" : "#263241"
        textColor: FlightPalette.cyan
        labelColor: FlightPalette.textLo
        lineWidth: Math.max(12, Math.round(root.sideGaugeSize * 0.055))
        valueFontSize: Math.round(root.sideGaugeSize * 0.30)
        labelFontSize: Math.round(root.sideGaugeSize * 0.075)
        minimumVisibleProgress: 0
        compact: root.compactLandscape
        closedRing: true
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: flightState.dataSuppressed ? "--" : ((FlightTelemetryModel.displayVspeed >= 0 ? "↑ +" : "↓ ") + FlightTelemetryModel.displayVspeed.toFixed(1))
        color: FlightPalette.cyan
        font.pixelSize: Math.round(root.sideGaugeSize * 0.20)
        font.bold: true
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "垂直速度 m/s"
        color: FlightPalette.textLo
        font.pixelSize: Math.round(root.sideGaugeSize * 0.065)
    }
}
