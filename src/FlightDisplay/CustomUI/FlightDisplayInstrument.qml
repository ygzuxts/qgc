import QtQuick

import "Eadi" as Eadi

Rectangle {
    id: root

    required property var state

    implicitWidth: 310
    implicitHeight: width
    radius: width * 6 / 310
    color: "black"

    readonly property bool connected: !!state && state.vehicleConnected
    readonly property bool attitudeValid: valid(state.roll) && valid(state.pitch)
    readonly property bool headingValid: valid(state.heading)
    readonly property bool airspeedValid: valid(state.airSpeed) && state.airSpeed >= 0
    readonly property bool altitudeValid: valid(state.absoluteAltitude)
    readonly property bool climbRateValid: valid(state.climbRate)

    function valid(value) {
        return connected && Number.isFinite(value)
    }

    Eadi.ElectronicAttitudeDirectionIndicator {
        anchors.centerIn: parent
        scale: Math.min(parent.width, parent.height) / 310

        adi.roll: root.attitudeValid ? root.state.roll : 0
        adi.pitch: root.attitudeValid ? root.state.pitch : 0
        adi.dotHVisible: false
        adi.dotVVisible: false
        adi.fdVisible: false

        asi.airspeed: root.airspeedValid ? root.state.airSpeed : 0
        asi.readingValid: root.airspeedValid
        alt.altitude: root.altitudeValid ? root.state.absoluteAltitude : 0
        alt.readingValid: root.altitudeValid
        hsi.heading: root.headingValid ? (root.state.heading % 360 + 360) % 360 : 0
        hsi.readingValid: root.headingValid
        vsi.climbRate: root.climbRateValid ? Math.max(-6, Math.min(6, root.state.climbRate)) : 0
        vsi.readingValid: root.climbRateValid

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 15
            text: root.connected ? root.state.flightModeDisplayText : qsTr("Disconnected")
            color: "#9ce5aa"
            font.family: "Open Sans"
            font.pixelSize: 11
        }

        Text {
            x: 20
            y: 26
            text: "m/s"
            color: "white"
            font.family: "Open Sans"
            font.pixelSize: 9
        }

        Text {
            x: 229
            y: 26
            text: "m AMSL"
            color: "white"
            font.family: "Open Sans"
            font.pixelSize: 9
        }

        Text {
            x: 270
            y: 207
            width: 28
            horizontalAlignment: Text.AlignHCenter
            text: root.climbRateValid ? root.state.climbRate.toFixed(1) : "—"
            color: "white"
            font.family: "Open Sans"
            font.pixelSize: 9
        }

        Text {
            x: 270
            y: 220
            width: 28
            horizontalAlignment: Text.AlignHCenter
            text: "m/s"
            color: "white"
            font.family: "Open Sans"
            font.pixelSize: 8
        }

        Rectangle {
            anchors.centerIn: parent
            width: 110
            height: 22
            visible: !root.attitudeValid
            radius: 3
            color: "#cc000000"

            Text {
                anchors.centerIn: parent
                text: qsTr("No Attitude Data")
                color: "white"
                font.family: "Open Sans"
                font.pixelSize: 10
            }
        }
    }
}
