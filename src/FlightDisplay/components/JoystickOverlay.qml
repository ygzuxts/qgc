import QtQuick 2.15

import QGroundControl
import QGroundControl.FlightDisplay

Rectangle {
    id: root

    property bool joystickEnabled: false
    signal joystickEnabledChangedByUser(bool enabled)
    signal closeRequested()

    color: FlightPalette.lightMode ? Qt.rgba(0.93, 0.96, 0.99, 0.90) : Qt.rgba(0.03, 0.05, 0.08, 0.90)

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
            text: "模拟摇杆"
            color: FlightPalette.textHi
            font.pixelSize: 18
            font.bold: true
        }

        Rectangle {
            width: 92
            height: 34
            radius: 17
            color: root.joystickEnabled ? FlightPalette.takeoffReady : FlightPalette.buttonIdle
            border.color: root.joystickEnabled ? FlightPalette.cyan : FlightPalette.panelBorder

            Rectangle {
                width: 28
                height: 28
                radius: 14
                anchors.verticalCenter: parent.verticalCenter
                x: root.joystickEnabled ? parent.width - width - 3 : 3
                color: root.joystickEnabled ? FlightPalette.cyan : FlightPalette.textLo

                Behavior on x { NumberAnimation { duration: 120 } }
            }

            Text {
                anchors.centerIn: parent
                text: root.joystickEnabled ? "已激活" : "关闭"
                color: FlightPalette.textHi
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
