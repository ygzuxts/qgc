import QtQuick 2.15

import QGroundControl.FlightDisplay

Column {
    id: root

    property bool compactLandscape: false
    property int horizonSize: 260
    property real headingTapeScale: 1.0
    property var flightState
    readonly property int statusLightTopOffset: Math.round((compactLandscape ? 10 : 14) * headingTapeScale)

    spacing: compactLandscape ? 2 : 4
    opacity: flightState.dataSuppressed ? 0.58 : 1.0

    Behavior on opacity { NumberAnimation { duration: 260 } }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        height: Math.max(modeStatusLight.height + root.statusLightTopOffset, headingTape.height, armStatusLight.height + root.statusLightTopOffset)
        spacing: compactLandscape ? 10 : 16

        StatusLight {
            id: modeStatusLight
            anchors.top: parent.top
            anchors.topMargin: root.statusLightTopOffset
            label: FlightTelemetryModel.modePillText
            accent: FlightTelemetryModel.modePillColor
            textLo: FlightPalette.textLo
            compactLandscape: root.compactLandscape
            lightMode: FlightPalette.lightMode
        }

        Column {
            id: headingTape
            anchors.top: parent.top
            spacing: 0

            QfiHeadingIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                radius: Math.round((compactLandscape ? 48 : 60) * root.headingTapeScale)
                heading: FlightTelemetryModel.displayHeading
                opacity: FlightTelemetryModel.activeVehicle && !flightState.dataSuppressed ? 1.0 : 0.48
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.round((compactLandscape ? 92 : 112) * root.headingTapeScale)
                height: Math.round((compactLandscape ? 23 : 26) * root.headingTapeScale)
                radius: 3
                color: FlightPalette.lcdBg
                border.color: FlightPalette.lcdBorder
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: FlightTelemetryModel.activeVehicle && !flightState.dataSuppressed
                          ? ("航向 " + ("000" + Math.round(((FlightTelemetryModel.displayHeading % 360) + 360) % 360)).slice(-3))
                          : "航向 ---"
                    color: FlightPalette.lcdText
                    font.family: FlightPalette.cockpitFont
                    font.pixelSize: Math.round((compactLandscape ? 13 : 16) * root.headingTapeScale)
                    font.bold: true
                    style: Text.Raised
                    styleColor: FlightPalette.lcdGlow
                }
            }
        }

        StatusLight {
            id: armStatusLight
            anchors.top: parent.top
            anchors.topMargin: root.statusLightTopOffset
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

        QfiAttitudeIndicator {
            anchors.centerIn: parent
            radius: parent.width / 2
            roll: FlightTelemetryModel.displayRoll
            pitch: FlightTelemetryModel.displayPitch
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: compactLandscape ? 8 : 12

        Text {
            text: flightState.dataSuppressed ? "横滚 --" : ("横滚 " + Math.round(isFinite(FlightTelemetryModel.displayRoll) ? FlightTelemetryModel.displayRoll : 0) + "°")
            color: FlightPalette.textLo
            font.family: FlightPalette.cockpitFont
            font.pixelSize: Math.round(root.horizonSize * 0.068)
            font.bold: true
        }

        Text {
            text: flightState.dataSuppressed ? "俯仰 --" : ("俯仰 " + Math.round(isFinite(FlightTelemetryModel.displayPitch) ? FlightTelemetryModel.displayPitch : 0) + "°")
            color: FlightPalette.textLo
            font.family: FlightPalette.cockpitFont
            font.pixelSize: Math.round(root.horizonSize * 0.068)
            font.bold: true
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: compactLandscape ? 0 : 1

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "飞行时间"
            color: FlightPalette.textLo
            font.family: FlightPalette.cockpitFont
            font.pixelSize: Math.round(root.horizonSize * 0.054)
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.round(root.horizonSize * 0.34)
            height: Math.round(root.horizonSize * 0.14)
            radius: 3
            color: FlightPalette.lcdBg
            border.color: FlightPalette.lcdBorder
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: flightState.dataSuppressed ? "--:--" : (FlightTelemetryModel.activeVehicle ? FlightTelemetryModel.formatElapsed(FlightTelemetryModel.displayFlightTime) : "--:--")
                color: FlightPalette.lcdText
                font.family: FlightPalette.cockpitFont
                font.pixelSize: Math.round(root.horizonSize * 0.085)
                font.bold: true
                style: Text.Raised
                styleColor: FlightPalette.lcdGlow
            }
        }
    }
}
