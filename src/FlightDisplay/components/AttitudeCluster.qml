import QtQuick 2.15

import QGroundControl.FlightDisplay

Column {
    id: root

    property bool compactLandscape: false
    property int horizonSize: 260
    property real headingTapeScale: 1.0
    property var flightState

    spacing: compactLandscape ? 9 : 14
    opacity: flightState.dataSuppressed ? 0.58 : 1.0

    Behavior on opacity { NumberAnimation { duration: 260 } }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        height: Math.max(modeStatusLight.height, headingTape.height, armStatusLight.height)
        spacing: compactLandscape ? 14 : 24

        StatusLight {
            id: modeStatusLight
            anchors.top: parent.top
            label: FlightTelemetryModel.modePillText
            accent: FlightTelemetryModel.modePillColor
            textLo: FlightPalette.textLo
            compactLandscape: root.compactLandscape
            lightMode: FlightPalette.lightMode
        }

        HeadingTape {
            id: headingTape
            anchors.top: parent.top
            heading: FlightTelemetryModel.displayHeading
            active: FlightTelemetryModel.activeVehicle && !flightState.dataSuppressed
            compactLandscape: root.compactLandscape
            textHi: FlightPalette.textHi
            textLo: FlightPalette.textLo
            accent: FlightPalette.cyan
            tickColor: FlightPalette.statusOff
            scaleFactor: root.headingTapeScale
        }

        StatusLight {
            id: armStatusLight
            anchors.top: parent.top
            label: FlightTelemetryModel.armPillText
            accent: FlightTelemetryModel.armPillColor
            textLo: FlightPalette.textLo
            compactLandscape: root.compactLandscape
            lightMode: FlightPalette.lightMode
        }
    }

    Item {
        width: root.horizonSize
        height: width
        anchors.horizontalCenter: parent.horizontalCenter

        InstrumentsArtificialHorizon {
            anchors.fill: parent
            roll: FlightTelemetryModel.displayRoll
            pitch: FlightTelemetryModel.displayPitch
            pitchScale: 30
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: compactLandscape ? 12 : 18

        Text {
            text: flightState.dataSuppressed ? "横滚 --" : ("横滚 " + Math.round(isFinite(FlightTelemetryModel.displayRoll) ? FlightTelemetryModel.displayRoll : 0) + "°")
            color: FlightPalette.textLo
            font.pixelSize: Math.round(root.horizonSize * 0.068)
            font.bold: true
        }

        Text {
            text: flightState.dataSuppressed ? "俯仰 --" : ("俯仰 " + Math.round(isFinite(FlightTelemetryModel.displayPitch) ? FlightTelemetryModel.displayPitch : 0) + "°")
            color: FlightPalette.textLo
            font.pixelSize: Math.round(root.horizonSize * 0.068)
            font.bold: true
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: compactLandscape ? 1 : 3

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "飞行时间"
            color: FlightPalette.textLo
            font.pixelSize: Math.round(root.horizonSize * 0.054)
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: flightState.dataSuppressed ? "--:--" : (FlightTelemetryModel.activeVehicle ? FlightTelemetryModel.formatElapsed(FlightTelemetryModel.displayFlightTime) : "--:--")
            color: FlightPalette.textHi
            font.family: "Consolas"
            font.pixelSize: Math.round(root.horizonSize * 0.115)
            font.bold: true
        }
    }
}
