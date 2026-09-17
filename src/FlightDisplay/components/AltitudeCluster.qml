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
        value: Math.abs(FlightTelemetryModel.displayAltitude)
        maximumValue: 120
        valueText: flightState.dataSuppressed ? "--" : FlightTelemetryModel.displayAltitude.toFixed(0)
        label: "高度"
        unit: "m"
        progressColor: flightState.limitedMetricColor(FlightTelemetryModel.displayAltitude, 120, FlightPalette.amber)
        trackColor: FlightPalette.lightMode ? "#D8DEE6" : "#263241"
        textColor: FlightPalette.amber
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
        text: flightState.dataSuppressed ? "--" : (FlightTelemetryModel.activeVehicle ? FlightTelemetryModel.displayAltitudeAMSL.toFixed(0) : "--")
        color: FlightPalette.amber
        font.pixelSize: Math.round(root.sideGaugeSize * 0.20)
        font.bold: true
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "海拔 m"
        color: FlightPalette.textLo
        font.pixelSize: Math.round(root.sideGaugeSize * 0.065)
    }
}
