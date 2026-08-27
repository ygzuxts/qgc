import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property var state: null
    property var theme: null
    property real backgroundOpacity: 1.0
    property var openCustomPlanShell: null
    signal takeoffPageRequested()

    readonly property color _baseBackgroundColor: theme ? theme.surface : "#ffffff"
    color: Qt.rgba(_baseBackgroundColor.r, _baseBackgroundColor.g, _baseBackgroundColor.b, backgroundOpacity)

    WheelHandler {
        target: null
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(event) {
            event.accepted = true
        }
    }

    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: root.theme ? root.theme.border : "#e4e8ed"
    }

    PageMission {
        anchors.fill: parent
        state: root.state
        theme: root.theme
        openCustomPlanShell: root.openCustomPlanShell
        onTakeoffPageRequested: root.takeoffPageRequested()
    }
}
