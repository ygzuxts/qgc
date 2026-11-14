import QtQuick

import QGroundControl

Item {
    id: root

    property var state: null
    property var theme: null
    property bool panelVisible: false
    readonly property var activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    readonly property bool communicationLost: !!(activeVehicle && activeVehicle.communicationLost)
    readonly property bool healthAndArmingChecksSupported: !!(activeVehicle && activeVehicle.healthAndArmingCheckReport && activeVehicle.healthAndArmingCheckReport.supported)
    readonly property string statusText: {
        if (!activeVehicle) {
            return qsTr("Disconnected")
        }
        if (communicationLost) {
            return qsTr("Connection Lost")
        }
        if (activeVehicle.armed) {
            if (activeVehicle.flying) {
                return qsTr("Flying")
            }
            if (activeVehicle.landing) {
                return qsTr("Landing")
            }
            return qsTr("Armed")
        }
        if (healthAndArmingChecksSupported) {
            return activeVehicle.healthAndArmingCheckReport.canArm ? qsTr("Ready to Fly") : qsTr("Not Ready")
        }
        if (activeVehicle.readyToFlyAvailable) {
            return activeVehicle.readyToFly ? qsTr("Ready to Fly") : qsTr("Not Ready")
        }
        return activeVehicle.allSensorsHealthy && activeVehicle.autopilotPlugin && activeVehicle.autopilotPlugin.setupComplete ? qsTr("Ready to Fly") : qsTr("Not Ready")
    }
    readonly property string statusTone: {
        if (!activeVehicle) {
            return "gray"
        }
        if (communicationLost) {
            return "red"
        }
        if (activeVehicle.armed) {
            if (healthAndArmingChecksSupported && !activeVehicle.healthAndArmingCheckReport.canArm) {
                return "red"
            }
            return healthAndArmingChecksSupported && activeVehicle.healthAndArmingCheckReport.hasWarningsOrErrors ? "amber" : "green"
        }
        if (healthAndArmingChecksSupported) {
            if (!activeVehicle.healthAndArmingCheckReport.canArm) {
                return "red"
            }
            return activeVehicle.healthAndArmingCheckReport.hasWarningsOrErrors ? "amber" : "green"
        }
        if (activeVehicle.readyToFlyAvailable) {
            return activeVehicle.readyToFly ? "green" : "amber"
        }
        return activeVehicle.allSensorsHealthy && activeVehicle.autopilotPlugin && activeVehicle.autopilotPlugin.setupComplete ? "green" : "amber"
    }
    signal clicked()

    implicitWidth: buttonBg.implicitWidth
    implicitHeight: buttonBg.height

    function _toneBackground() {
        if (!theme) {
            return "#f3f4f6"
        }
        switch (root.statusTone) {
        case "green":
            return theme.greenL
        case "amber":
            return theme.amberL
        case "red":
            return theme.redL
        default:
            return theme.surface2
        }
    }

    function _toneForeground() {
        if (!theme) {
            return "#5a6272"
        }
        switch (root.statusTone) {
        case "green":
            return theme.green
        case "amber":
            return theme.amber
        case "red":
            return theme.red
        default:
            return theme.text3
        }
    }

    Rectangle {
        id: buttonBg
        height: 32
        radius: 16
        color: mouseArea.containsMouse || root.panelVisible
               ? (theme ? theme.surface3 : "#eef3fb")
               : (theme ? theme.surface : "#ffffff")
        border.width: 1
        border.color: root.panelVisible
                      ? (theme ? theme.blueBorder : "#8080B3")
                      : (theme ? theme.border : "#d7dde6")
        implicitWidth: statusBadge.width + contentRow.implicitWidth + 24
        width: implicitWidth

        Row {
            id: contentRow
            anchors.left: statusBadge.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Rectangle {
                width: 1
                height: 14
                anchors.verticalCenter: parent.verticalCenter
                color: theme ? theme.border : "#d7dde6"
            }

            Row {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: modeText
                    anchors.verticalCenter: parent.verticalCenter
                    text: activeVehicle && activeVehicle.flightMode ? activeVehicle.flightMode : "--"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: theme ? theme.text : "#1a1d23"
                }

                Text {
                    id: caretText
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.panelVisible ? "▼" : "▲"
                    font.pixelSize: 9
                    color: root.panelVisible
                           ? (theme ? theme.blue : "#000066")
                           : (theme ? theme.text3 : "#9aa3b2")
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 1
            anchors.verticalCenter: parent.verticalCenter
            width: statusBadge.width + 2
            height: parent.height - 2
            radius: 15
            color: Qt.rgba(1, 1, 1, 0.24)
            opacity: 0.55
        }

        Rectangle {
            id: statusBadge
            anchors.left: parent.left
            anchors.leftMargin: 1
            anchors.verticalCenter: parent.verticalCenter
            width: statusRow.implicitWidth + 14
            height: parent.height - 2
            radius: 15
            color: root._toneBackground()

            Row {
                id: statusRow
                anchors.centerIn: parent
                spacing: 6

                Rectangle {
                    width: 7
                    height: 7
                    radius: 3.5
                    anchors.verticalCenter: parent.verticalCenter
                    color: root._toneForeground()
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.statusText
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: root._toneForeground()
                }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }
}
