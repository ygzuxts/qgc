import QtQuick
import QtQuick.Controls

import QGroundControl

Rectangle {
    id: panelRoot

    property var state: null
    property var theme: null
    readonly property bool darkMode: theme ? theme.darkMode : false
    readonly property color panelColor: darkMode ? "#151b24" : "#ffffff"
    readonly property color primaryText: theme ? theme.text : "#1a1d23"
    readonly property color secondaryText: theme ? theme.text2 : "#5a6272"
    readonly property color itemColor: darkMode ? "#202936" : "#f5f6f8"
    readonly property color accentColor: theme ? theme.blue : "#2563eb"
    readonly property color selectedColor: darkMode ? Qt.tint(panelColor, theme ? theme.blueL : "#382563eb") : (theme ? theme.blueL : "#e8effc")
    readonly property color hoverColor: darkMode ? "#2b3747" : "#edf1f7"
    property bool opened: visible
    property var vehicle: QGroundControl.multiVehicleManager.activeVehicle
    property var modeList: vehicle && vehicle.flightModes ? vehicle.flightModes : []
    readonly property var preferredModeOrder: [
        "Manual",
        "Stabilized",
        "Acro",
        "Rattitude",
        "Altitude",
        "Offboard",
        "Position",
        "Hold",
        "Mission",
        "Return",
        "Precision Landing",
        "Land",
        "Takeoff",
        "VTOL Takeoff",
        "Safe Recovery",
        "Position Slow",
        "Altitude Cruise",
        "Follow Target"
    ]
    readonly property var sortedModeList: _sortedModes()
    signal closeRequested()
    readonly property real panelPadding: 10
    readonly property real maxPanelHeight: parent ? Math.max(140, parent.height - y - panelPadding) : implicitHeight
    readonly property real staticContentHeight: titleText.implicitHeight
                                               + statusText.implicitHeight
                                               + modeCountText.implicitHeight
                                               + divider.height
                                               + panelColumn.spacing * 3
    readonly property real listViewportHeight: Math.min(modeListColumn.implicitHeight,
                                                        Math.max(0, maxPanelHeight - staticContentHeight - (panelPadding * 2)))

    width: 218
    height: Math.min(maxPanelHeight, implicitHeight)
    radius: 8
    color: panelColor
    border.width: 1
    border.color: darkMode ? "#3b485c" : "#8fb3f5"

    function modeDisplayName(modeName) {
        var normalizedModeName = modeName ? String(modeName).trim() : "--"
        switch (normalizedModeName) {
        case "手动":
        case "Manual": return qsTr("Manual")
        case "自稳":
        case "Stabilized": return qsTr("Stabilized")
        case "特技":
        case "Acro": return qsTr("Acro")
        case "半自稳":
        case "Rattitude": return qsTr("Rattitude")
        case "定高":
        case "Altitude": return qsTr("Altitude Hold")
        case "外部控制":
        case "Offboard": return qsTr("Offboard")
        case "定点":
        case "Position": return qsTr("Position")
        case "悬停":
        case "Hold": return qsTr("Hold")
        case "任务":
        case "Mission": return qsTr("Mission")
        case "返航":
        case "Return": return qsTr("Return")
        case "降落":
        case "Land": return qsTr("Land")
        case "精准降落":
        case "Precision Land":
        case "Precision Landing": return qsTr("Precision Land")
        case "起飞":
        case "Takeoff": return qsTr("Takeoff")
        case "VTOL Takeoff": return qsTr("VTOL Takeoff")
        case "Safe Recovery": return qsTr("Safe Recovery")
        case "Position Slow": return qsTr("Slow Position")
        case "Altitude Cruise": return qsTr("Altitude Cruise")
        case "Follow Target": return qsTr("Follow Target")
        default: return normalizedModeName && normalizedModeName !== "--" ? normalizedModeName : "--"
        }
    }

    function _modeKey(modeName) {
        return modeName ? String(modeName).trim() : ""
    }

    function _sortedModes() {
        var available = []
        if (modeList && modeList.length !== undefined) {
            for (var i = 0; i < modeList.length; i++) {
                var item = _modeKey(modeList[i])
                if (item !== "" && available.indexOf(item) < 0) {
                    available.push(item)
                }
            }
        }
        var ordered = []
        for (var j = 0; j < preferredModeOrder.length; j++) {
            var preferred = preferredModeOrder[j]
            var idx = available.indexOf(preferred)
            if (idx >= 0) {
                ordered.push(preferred)
                available.splice(idx, 1)
            }
        }
        return ordered.concat(available)
    }

    function statusDisplayName(statusName) {
        switch (statusName) {
        case "Ready": return qsTr("Ready")
        case "Not Ready": return qsTr("Not Ready")
        case "Flying": return qsTr("Flying")
        case "Landing": return qsTr("Landing")
        case "Armed": return qsTr("Armed")
        case "Comms Lost": return qsTr("Communication Lost")
        case "Disconnected": return qsTr("Disconnected")
        default: return statusName && statusName.length > 0 ? statusName : qsTr("Disconnected")
        }
    }

    function _currentMode() {
        return vehicle && vehicle.flightMode ? _modeKey(vehicle.flightMode) : "--"
    }

    function _hasModes() {
        return !!(vehicle && panelRoot.sortedModeList && panelRoot.sortedModeList.length > 0)
    }

    implicitHeight: panelColumn.implicitHeight + (panelPadding * 2)

    MouseArea {
        anchors.fill: parent
        onPressed: mouse.accepted = true
    }

    Column {
        id: panelColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: panelPadding
        spacing: 8

        Text {
            id: titleText
            text: qsTr("Flight Mode ")
            font.pixelSize: 18
            font.weight: Font.Bold
            color: panelRoot.primaryText
        }

        Text {
            id: statusText
            text: panelRoot.statusDisplayName(panelRoot.state ? panelRoot.state.mainStatusText : qsTr("Disconnected")) + qsTr(" · Current ") + panelRoot.modeDisplayName(panelRoot._currentMode())
            font.pixelSize: 12
            color: panelRoot.secondaryText
        }

        Text {
            id: modeCountText
            text: qsTr("Available modes: ") + (vehicle && panelRoot.sortedModeList ? panelRoot.sortedModeList.length : 0)
            font.pixelSize: 12
            color: panelRoot.secondaryText
        }

        Rectangle {
            id: divider
            width: parent.width
            height: 1
            color: panelRoot.darkMode ? "#344154" : "#d8e2ef"
        }

        Flickable {
            width: parent.width
            height: panelRoot.listViewportHeight
            visible: panelRoot.opened && vehicle !== null && panelRoot._hasModes()
            clip: true
            contentWidth: width
            contentHeight: modeListColumn.implicitHeight
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {
                policy: contentHeight > parent.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
            }

            Column {
                id: modeListColumn
                width: parent.width
                spacing: 6

                Repeater {
                    model: panelRoot.sortedModeList.length

                    delegate: Rectangle {
                        width: parent.width
                        height: 42
                        property string modeName: panelRoot.sortedModeList[index] ? panelRoot.sortedModeList[index] : ""
                        readonly property bool currentMode: panelRoot._currentMode() === modeName
                        radius: 7
                        color: currentMode ? panelRoot.selectedColor
                                           : (_modeMouse.containsMouse ? panelRoot.hoverColor : panelRoot.itemColor)
                        border.width: currentMode ? 1 : 0
                        border.color: panelRoot.accentColor

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 5
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            height: 18
                            radius: 1.5
                            visible: parent.currentMode
                            color: panelRoot.accentColor
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            text: panelRoot.modeDisplayName(modeName)
                            font.pixelSize: 13
                            font.weight: panelRoot._currentMode() === modeName ? Font.Bold : Font.Normal
                            color: panelRoot.primaryText
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: _modeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (vehicle && modeName !== "") {
                                    vehicle.flightMode = modeName
                                }
                                panelRoot.closeRequested()
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 44
            radius: 8
            visible: panelRoot.opened && (vehicle === null || !panelRoot._hasModes())
            color: panelRoot.itemColor

            Text {
                anchors.centerIn: parent
                text: vehicle === null ? qsTr("Disconnected; no modes available") : qsTr("No modes available")
                font.pixelSize: 12
                color: panelRoot.secondaryText
            }
        }
    }
}
