import QtQuick

import QGroundControl
import QGroundControl.FlightDisplay

Item {
    property var parentToolInsets
    property var totalToolInsets: parentToolInsets
    property var mapControl

    FlightConsole {
        anchors.fill: parent
        z: 10000

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            preventStealing: true
            z: 10001
        }
    }
}
