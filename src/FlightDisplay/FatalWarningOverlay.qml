import QtQuick 2.15

import QGroundControl.FlightDisplay

Rectangle {
    id: root

    property bool compactLandscape: false
    property real primaryMetricSize: 80
    property color overlayColor: Qt.rgba(0.18, 0.0, 0.0, 0.90)

    visible: false
    color: overlayColor

    MouseArea {
        anchors.fill: parent
    }

    Column {
        anchors.fill: parent
        anchors.leftMargin: root.compactLandscape ? 24 : 36
        anchors.rightMargin: root.compactLandscape ? 24 : 36
        anchors.topMargin: root.compactLandscape ? 18 : 26
        anchors.bottomMargin: root.compactLandscape ? 18 : 24
        spacing: root.compactLandscape ? 8 : 14

        Text {
            width: parent.width
            text: "姿态超限"
            color: "#FFFFFF"
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.family: FlightPalette.cockpitFont
            font.pixelSize: root.compactLandscape ? 26 : 34
            font.bold: true
        }

        Item {
            width: parent.width
            height: Math.max(180, parent.height - fatalTitleReserve.height - fatalFooter.height - parent.spacing * 2)

            Row {
                anchors.fill: parent
                spacing: root.compactLandscape ? 18 : 28

                Column {
                    width: Math.max(150, parent.width * 0.25)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.compactLandscape ? 12 : 18

                    CriticalMetric {
                        label: "速度 km/h"
                        value: FlightTelemetryModel.airspeed.toFixed(0)
                        accent: "#FFFFFF"
                        compactLandscape: root.compactLandscape
                        primaryMetricSize: root.primaryMetricSize
                    }

                    CriticalMetric {
                        label: "垂直速度 m/s"
                        value: (FlightTelemetryModel.vspeed >= 0 ? "↑ +" : "↓ ") + FlightTelemetryModel.vspeed.toFixed(1)
                        accent: FlightTelemetryModel.vspeed >= 0 ? "#FFFFFF" : "#FFD7A0"
                        compactLandscape: root.compactLandscape
                        primaryMetricSize: root.primaryMetricSize
                    }
                }

                Item {
                    width: Math.min(parent.width * 0.38, parent.height * 0.95)
                    height: width
                    anchors.verticalCenter: parent.verticalCenter

                    InstrumentsArtificialHorizon {
                        anchors.fill: parent
                        roll: FlightTelemetryModel.roll
                        pitch: FlightTelemetryModel.pitch
                        pitchScale: 90
                    }
                }

                Column {
                    width: Math.max(170, parent.width * 0.26)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.compactLandscape ? 10 : 16

                    CriticalMetric {
                        label: "高度 m"
                        value: FlightTelemetryModel.altitude.toFixed(0)
                        accent: "#FFFFFF"
                        compactLandscape: root.compactLandscape
                        primaryMetricSize: root.primaryMetricSize
                    }

                    AttitudeMetric {
                        compactLandscape: root.compactLandscape
                    }
                }
            }
        }

        Text {
            id: fatalFooter
            width: parent.width
            text: "请检查飞行姿态"
            color: Qt.rgba(1, 1, 1, 0.86)
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.family: FlightPalette.cockpitFont
            font.pixelSize: root.compactLandscape ? 13 : 15
            font.bold: true
        }

        Item {
            id: fatalTitleReserve
            visible: false
            width: 1
            height: root.compactLandscape ? 32 : 42
        }
    }

    component CriticalMetric: Column {
        property string label: ""
        property string value: ""
        property color accent: "#FFFFFF"
        property bool compactValue: false
        property bool compactLandscape: false
        property real primaryMetricSize: 80

        width: parent ? parent.width : 160
        spacing: compactLandscape ? 4 : 6

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            text: value
            color: accent
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.family: FlightPalette.cockpitFont
            font.pixelSize: compactValue ? (compactLandscape ? 20 : 26)
                                         : Math.round(primaryMetricSize * 0.92)
            font.bold: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            text: label
            color: Qt.rgba(1, 1, 1, 0.76)
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.family: FlightPalette.cockpitFont
            font.pixelSize: compactLandscape ? 13 : 15
            font.bold: true
        }
    }

    component AttitudeMetric: Column {
        property bool compactLandscape: false

        width: parent ? parent.width : 170
        spacing: compactLandscape ? 4 : 6

        Text {
            width: parent.width
            text: "横滚 " + FlightTelemetryModel.roll.toFixed(0) + "°"
            color: "#FFD7A0"
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideNone
            font.family: FlightPalette.cockpitFont
            font.pixelSize: compactLandscape ? 23 : 28
            font.bold: true
        }

        Text {
            width: parent.width
            text: "俯仰 " + FlightTelemetryModel.pitch.toFixed(0) + "°"
            color: "#FFD7A0"
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideNone
            font.family: FlightPalette.cockpitFont
            font.pixelSize: compactLandscape ? 23 : 28
            font.bold: true
        }

        Text {
            width: parent.width
            text: "姿态角"
            color: Qt.rgba(1, 1, 1, 0.76)
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.family: FlightPalette.cockpitFont
            font.pixelSize: compactLandscape ? 13 : 15
            font.bold: true
        }
    }
}
