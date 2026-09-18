import QtQuick 2.15

import QGroundControl.FlightDisplay

Rectangle {
    id: root

    property real containerWidth: width
    signal closeRequested()

    color: Qt.rgba(0.02, 0.02, 0.022, 0.96)

    MouseArea { anchors.fill: parent }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 22
        anchors.topMargin: 22
        width: 42
        height: 42
        radius: 21
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#3A3A3C" }
            GradientStop { position: 1.0; color: "#09090A" }
        }
        border.color: FlightPalette.panelBorder

        Text {
            anchors.centerIn: parent
            text: "×"
            color: FlightPalette.textHi
            font.family: FlightPalette.cockpitFont
            font.pixelSize: 24
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeRequested()
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 28

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "HOLD TO ACTUATE"
            color: FlightPalette.textLo
            font.family: FlightPalette.cockpitFont
            font.pixelSize: 16
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 44

            BigHoldActionButton {
                text: "TAKEOFF"
                hint: FlightTelemetryModel.guidedController && FlightTelemetryModel.guidedController.showTakeoff ? "HOLD" : "LOCKED"
                accent: FlightPalette.statusGreen
                enabledState: FlightTelemetryModel.guidedController && FlightTelemetryModel.guidedController.showTakeoff
                containerWidth: root.containerWidth
                lightMode: FlightPalette.lightMode
                buttonIdle: FlightPalette.buttonIdle
                panelBorder: FlightPalette.panelBorder
                textLo: FlightPalette.textLo
                onHoldTriggered: {
                    FlightTelemetryModel.directTakeoff()
                    root.closeRequested()
                }
            }

            BigHoldActionButton {
                text: "LAND"
                hint: FlightTelemetryModel.guidedController && FlightTelemetryModel.guidedController.showLand ? "HOLD" : "LOCKED"
                accent: FlightPalette.red
                enabledState: FlightTelemetryModel.guidedController && FlightTelemetryModel.guidedController.showLand
                containerWidth: root.containerWidth
                lightMode: FlightPalette.lightMode
                buttonIdle: FlightPalette.buttonIdle
                panelBorder: FlightPalette.panelBorder
                textLo: FlightPalette.textLo
                onHoldTriggered: {
                    FlightTelemetryModel.guidedController.confirmAction(FlightTelemetryModel.guidedController.actionLand)
                    root.closeRequested()
                }
            }
        }
    }
}
