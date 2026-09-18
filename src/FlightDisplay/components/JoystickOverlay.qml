import QtQuick 2.15

import QGroundControl
import QGroundControl.FlightDisplay

Rectangle {
    id: root

    property bool joystickEnabled: false
    signal joystickEnabledChangedByUser(bool enabled)
    signal closeRequested()

    color: Qt.rgba(0.02, 0.02, 0.025, 0.94)

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
            font.family: FlightPalette.cockpitFont
            font.pixelSize: 24
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.joystickEnabledChangedByUser(false)
                QGroundControl.settingsManager.appSettings.virtualJoystick.rawValue = false
                root.closeRequested()
            }
        }
    }

    Row {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 30
        spacing: 18

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "VIRTUAL STICK"
            color: FlightPalette.textHi
            font.family: FlightPalette.cockpitFont
            font.pixelSize: 18
            font.bold: true
        }

        Rectangle {
            width: 92
            height: 34
            radius: 4
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.joystickEnabled ? Qt.lighter(FlightPalette.takeoffReady, 1.16) : "#3C3D40" }
                GradientStop { position: 0.48; color: root.joystickEnabled ? FlightPalette.takeoffReady : FlightPalette.buttonIdle }
                GradientStop { position: 1.0; color: root.joystickEnabled ? Qt.darker(FlightPalette.takeoffReady, 1.35) : "#070809" }
            }
            border.color: root.joystickEnabled ? FlightPalette.statusGreen : FlightPalette.panelBorder

            Rectangle {
                width: 18
                height: 28
                radius: 3
                anchors.verticalCenter: parent.verticalCenter
                x: root.joystickEnabled ? parent.width - width - 6 : 6
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.joystickEnabled ? "#FFFFFF" : "#8B8780" }
                    GradientStop { position: 0.52; color: root.joystickEnabled ? FlightPalette.statusGreen : "#3E3F42" }
                    GradientStop { position: 1.0; color: "#08090A" }
                }
                border.color: "#F1EEE6"
                border.width: 1

                Behavior on x { NumberAnimation { duration: 120 } }
            }

            Text {
                anchors.centerIn: parent
                text: root.joystickEnabled ? "ACTIVE" : "OFF"
                color: FlightPalette.textHi
                font.family: FlightPalette.cockpitFont
                font.pixelSize: 12
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.joystickEnabledChangedByUser(!root.joystickEnabled)
                    QGroundControl.settingsManager.appSettings.virtualJoystick.rawValue = !root.joystickEnabled
                }
            }
        }
    }

    Loader {
        id: virtualJoystickLoader
        anchors.centerIn: parent
        width: Math.min(parent.width - 120, 560)
        height: Math.min(300, Math.max(220, parent.height * 0.48))
        source: "qrc:/qml/QGroundControl/FlightDisplay/VirtualJoystick.qml"
        active: root.visible && root.joystickEnabled
        visible: active

        property bool autoCenterThrottle: QGroundControl.settingsManager.appSettings.virtualJoystickAutoCenterThrottle.rawValue
        property bool leftHandedMode: QGroundControl.settingsManager.appSettings.virtualJoystickLeftHandedMode.rawValue
        property real rootWidth: root.width
        property var itemX: x

        onLoaded: {
            item.calibration = true
            item.uiTotalWidth = rootWidth
            item.uiRealX = itemX
            item.calibration = false
        }

        onRootWidthChanged: status === Loader.Ready ? item.uiTotalWidth = rootWidth : undefined
        onItemXChanged: status === Loader.Ready ? item.uiRealX = itemX : undefined
    }
}
