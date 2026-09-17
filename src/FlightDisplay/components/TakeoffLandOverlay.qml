import QtQuick 2.15

import QGroundControl.FlightDisplay

Rectangle {
    id: root

    property real containerWidth: width
    signal closeRequested()

    color: FlightPalette.lightMode ? Qt.rgba(0.93, 0.96, 0.99, 0.96) : Qt.rgba(0.03, 0.05, 0.08, 0.96)

    MouseArea { anchors.fill: parent }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 22
        anchors.topMargin: 22
        width: 42
        height: 42
        radius: 21
        color: FlightPalette.buttonIdle
        border.color: FlightPalette.panelBorder

        Text {
            anchors.centerIn: parent
            text: "×"
            color: FlightPalette.textHi
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
            text: "长按执行"
            color: FlightPalette.textLo
            font.pixelSize: 16
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 44

            BigHoldActionButton {
                text: "起飞"
                hint: FlightTelemetryModel.guidedController && FlightTelemetryModel.guidedController.showTakeoff ? "长按启动起飞" : "LOCKED"
                accent: FlightPalette.cyan
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
                text: "降落"
                hint: FlightTelemetryModel.guidedController && FlightTelemetryModel.guidedController.showLand ? "长按启动降落" : "LOCKED"
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
