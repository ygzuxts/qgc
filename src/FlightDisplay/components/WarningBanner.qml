import QtQuick 2.15

import QGroundControl.Controls
import QGroundControl.FlightDisplay

Rectangle {
    id: root

    property bool compactLandscape: false
    property var flightState

    visible: (flightState.connectionLossConfirmed || flightState.lowBatteryWarning) && !flightState.fatalAttitudeWarning
    width: Math.min(parent ? parent.width * 0.36 : 260, warningText.implicitWidth + (compactLandscape ? 56 : 54))
    height: compactLandscape ? 34 : 30
    radius: 3
    color: FlightPalette.warningBg
    border.color: FlightPalette.statusYellow
    border.width: 1

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        spacing: 8

        QGCColoredImage {
            anchors.verticalCenter: parent.verticalCenter
            width: compactLandscape ? 20 : 18
            height: width
            source: "/qmlimages/warning.svg"
            fillMode: Image.PreserveAspectFit
            color: FlightPalette.statusYellow
        }

        Text {
            id: warningText
            anchors.verticalCenter: parent.verticalCenter
            width: root.width - (compactLandscape ? 58 : 52)
            text: flightState.connectionLossConfirmed ? "LINK LOST"
                  : (compactLandscape ? ("BAT LOW " + flightState.batteryText())
                                       : ("BAT LOW " + flightState.batteryText() + "  RETURN ADVISED"))
            color: FlightPalette.statusYellow
            elide: Text.ElideRight
            font.family: FlightPalette.cockpitFont
            font.pixelSize: compactLandscape ? 14 : 13
            font.bold: true
        }
    }
}
