import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

Rectangle {
    id: root

    required property var state
    required property var theme
    property int currentTab: 0
    property var openCustomPlanShell: null
    property real backgroundOpacity: 1.0
    readonly property real tabHeight: 50
    readonly property var safety: safetyLoader.item
    readonly property var missionItems: state.missionController ? state.missionController.visualItems : null
    property int missionTab: 0

    function missionItem(kind, count) {
        for (let i = 1; missionItems && i < count; ++i) {
            const item = missionItems.get(i)
            if ((kind === "takeoff" && item.launchCoordinate !== undefined) ||
                    (kind === "landing" && item.landingDistance !== undefined) ||
                    (kind === "survey" && item.gridAngle !== undefined)) {
                return item
            }
        }
        return null
    }

    function coordinateValue(coordinate, latitude) {
        return coordinate && coordinate.isValid
                ? (latitude ? coordinate.latitude : coordinate.longitude).toFixed(6) : unavailable
    }

    function plannedValue(fact) {
        return fact ? fact.valueString + (fact.units ? " " + fact.units : "") : unavailable
    }

    readonly property var takeoffItem: missionItem("takeoff", missionItems ? missionItems.count : 0)
    readonly property var landingItem: missionItem("landing", missionItems ? missionItems.count : 0)
    readonly property var surveyItem: missionItem("survey", missionItems ? missionItems.count : 0)
    readonly property bool connected: state.vehicleConnected
    readonly property string unavailable: "—"

    signal tabRequested(int index)
    signal advancedSettingsRequested()
    signal waypointEditorRequested()

    function openMissionCheck() {
        if (takeoffLoader.item && takeoffLoader.item.missionStartEnabled()) {
            takeoffLoader.item.openStartMissionCheck()
        }
    }

    function reading(value) {
        if (!connected || value === undefined || value === null || value === "" ||
                value === "--" || value === "--:--") {
            return unavailable
        }
        return value
    }

    function vehicleReading(fact) {
        return connected && fact && Number.isFinite(Number(fact.rawValue))
                ? fact.valueString + (fact.units ? " " + fact.units : "")
                : unavailable
    }

    color: "#092a4b"

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onWheel: wheel => wheel.accepted = true
    }

    Rectangle {
        width: 1
        height: parent.height
        color: root.theme.border
    }

    readonly property color panelText: "#ffffff"
    readonly property color secondaryText: "#c1d7eb"
    readonly property var tabIcons: ["PaperPlane.svg", "MapCenter.svg", "Plan.svg", "MapAddMission.svg", "Gears.svg"]

    component DockButton: Button {
        id: control
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        Layout.preferredHeight: root.tabHeight
        font.pixelSize: 12
        padding: 4

        contentItem: Text {
            text: control.text
            font: control.font
            color: control.enabled ? root.panelText : root.secondaryText
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            color: control.down || control.checked ? "#20517e"
                   : control.hovered || control.visualFocus ? "#1a4471" : "transparent"

            Rectangle {
                visible: control.visualFocus
                anchors.bottom: parent.bottom
                width: parent.width
                height: 2
                color: root.theme.blue
            }
        }
    }

    component DisplaySwitch: Switch {
        Layout.fillWidth: true
        palette.windowText: root.panelText
        palette.text: root.panelText
        palette.buttonText: root.panelText
    }

    component Section: ColumnLayout {
        id: section
        property string title
        property bool expanded: false
        default property alias rows: content.data
        Layout.fillWidth: true
        spacing: 0

        Button {
            id: header
            Layout.fillWidth: true
            Layout.preferredHeight: 25
            text: section.title
            checkable: true
            checked: section.expanded
            onToggled: section.expanded = checked

            contentItem: RowLayout {
                Text {
                    Layout.fillWidth: true
                    text: section.title
                    color: root.panelText
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    text: section.expanded ? "▾" : "›"
                    color: root.secondaryText
                    font.pixelSize: 12
                }
            }

            background: Rectangle {
                color: header.hovered || header.visualFocus ? "#20517e" : "#1a4471"
                radius: 3
            }
        }

        ColumnLayout {
            id: content
            visible: section.expanded
            Layout.fillWidth: true
            Layout.margins: 5
            spacing: root.theme.spacingXs
        }
    }

    component Readout: RowLayout {
        id: readout
        property string label
        property string value
        Layout.fillWidth: true
        Layout.minimumHeight: 23

        Text {
            Layout.fillWidth: true
            text: readout.label
            color: root.secondaryText
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }
        Text {
            Layout.maximumWidth: readout.width * 0.55
            text: readout.value
            color: root.panelText
            font.pixelSize: 12
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
    }

    Loader {
        id: safetyLoader
        active: root.currentTab === 4
        visible: false
        sourceComponent: PageTakeoff {
            safetyOnly: true
            state: root.state
            theme: root.theme
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 1
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            spacing: 1
            Repeater {
                model: [qsTr("Flight"), qsTr("Takeoff"), qsTr("Mission"), qsTr("Waypoints"), qsTr("Settings")]
                delegate: DockButton {
                    required property int index
                    required property string modelData
                    Layout.preferredWidth: 1
                    text: modelData
                    checked: index === root.currentTab
                    contentItem: Column {
                        spacing: 1
                        QGCColoredImage {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 23
                            height: 23
                            source: "qrc:/qmlimages/" + root.tabIcons[index]
                            color: root.panelText
                            fillMode: Image.PreserveAspectFit
                        }
                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            color: root.panelText
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }
                    onClicked: root.tabRequested(index)
                    ToolTip.visible: hovered
                    ToolTip.text: text
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: root.theme.border
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.currentTab

            ScrollView {
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    width: Math.max(0, parent.width - root.theme.spacingSm * 2)
                    x: root.theme.spacingSm
                    spacing: 2

                    Section {
                        title: qsTr("Mission Information Preview")
                        Readout { label: qsTr("Mission"); value: root.connected ? root.state.currentWP + "/" + root.state.totalWP : root.unavailable }
                        DockButton { text: qsTr("Waypoints"); onClicked: root.tabRequested(3) }
                    }

                    Section {
                        title: qsTr("Flight Parameters")
                        RowLayout {
                            Layout.fillWidth: true
                            Repeater {
                                model: [
                                    [qsTr("Battery"), root.reading(root.state.batteryPercentText)],
                                    [qsTr("Link"), root.connected && Number.isFinite(root.state.mavlinkLossPercent)
                                        ? Math.round(100 - root.state.mavlinkLossPercent) + "%" : root.unavailable],
                                    [qsTr("GPS"), root.reading(root.state.gpsSatellitesText)]
                                ]
                                Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 58
                                    color: "#143b65"
                                    border.color: "#204c7b"
                                    radius: 5
                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[0]; color: root.secondaryText; font.pixelSize: 11 }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[1]; color: root.panelText; font.pixelSize: 14 }
                                    }
                                }
                            }
                        }
                        Readout { label: qsTr("Flight Mode"); value: root.reading(root.state.flightModeDisplayText) }
                        Readout { label: qsTr("Arming Status"); value: root.reading(root.state.armStateText) }
                        Readout { label: qsTr("Battery"); value: root.reading(root.state.batteryText) }
                        Readout { label: qsTr("GPS"); value: root.reading(root.state.gpsLockText) }
                        Readout { label: qsTr("Satellites"); value: root.reading(root.state.gpsSatellitesText) }
                        Readout { label: qsTr("Ground Speed"); value: root.connected ? root.vehicleReading(root.state.activeVehicle.groundSpeed) : root.unavailable }
                        Readout { label: qsTr("Relative Altitude"); value: root.connected ? root.vehicleReading(root.state.activeVehicle.altitudeRelative) : root.unavailable }
                        Readout { label: qsTr("Flight Time"); value: root.reading(root.state.flightTime) }
                    }

                    Section {
                        title: qsTr("Flight Status and Instruments")
                        visible: root.state.showHudExpandBar
                        expanded: true

                        Text {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: root.connected ? qsTr("Vehicle %1").arg(root.state.activeVehicle.id)
                                  : root.state.communicationLost ? qsTr("Connection lost") : qsTr("Disconnected")
                            color: root.panelText
                            font.pixelSize: 12
                        }

                        AttitudeHUD {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 245
                            theme: root.theme
                            connected: root.connected
                            pitch: root.state.pitch
                            roll: root.state.roll
                            heading: root.state.heading
                            airspeed: root.state.airSpeed
                            altitude: root.state.altitude
                        }
                    }

                    DockButton {
                        text: qsTr("Vehicle Configuration")
                        onClicked: mainWindow.showVehicleConfig()
                    }
                }
            }

            ScrollView {
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    width: Math.max(0, parent.width - 16)
                    x: 8
                    spacing: 5

                    Section {
                        title: qsTr("Takeoff Setup")
                        expanded: true
                        Readout { label: qsTr("Altitude"); value: root.plannedValue(root.takeoffItem ? root.takeoffItem.altitude : null) }
                        Readout { label: qsTr("Longitude"); value: root.coordinateValue(root.takeoffItem ? root.takeoffItem.coordinate : null, false) }
                        Readout { label: qsTr("Latitude"); value: root.coordinateValue(root.takeoffItem ? root.takeoffItem.coordinate : null, true) }
                    }

                    Section {
                        title: qsTr("Landing Setup")
                        expanded: true
                        Readout { label: qsTr("Longitude"); value: root.coordinateValue(root.landingItem ? root.landingItem.landingCoordinate : null, false) }
                        Readout { label: qsTr("Latitude"); value: root.coordinateValue(root.landingItem ? root.landingItem.landingCoordinate : null, true) }
                        Readout { label: qsTr("Approach Altitude"); value: root.plannedValue(root.landingItem ? root.landingItem.finalApproachAltitude : null) }
                        Readout { label: qsTr("Loiter Radius"); value: root.plannedValue(root.landingItem ? root.landingItem.loiterRadius : null) }
                        Readout { label: qsTr("Landing Distance"); value: root.plannedValue(root.landingItem ? root.landingItem.landingDistance : null) }
                        Readout { label: qsTr("Approach Speed"); value: root.plannedValue(root.landingItem ? root.landingItem.finalApproachSpeed : null) }
                    }

                    DockButton {
                        text: qsTr("Open Waypoint Editor")
                        onClicked: root.waypointEditorRequested()
                    }

                    Section {
                        id: liveControls
                        title: qsTr("Vehicle Controls")

                        Loader {
                            id: takeoffLoader
                            Layout.fillWidth: true
                            active: root.currentTab === 1
                            visible: liveControls.expanded
                            sourceComponent: PageTakeoff {
                                state: root.state
                                theme: root.theme
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Repeater {
                        model: [qsTr("Survey"), qsTr("Route"), qsTr("Inspection")]

                        DockButton {
                            required property int index
                            required property string modelData
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 34
                            text: modelData
                            checked: root.missionTab === index
                            onClicked: root.missionTab = index
                        }
                    }
                }

                Section {
                    visible: root.missionTab === 0
                    title: qsTr("Survey Parameters")
                    expanded: true
                    Readout { label: qsTr("Camera"); value: root.surveyItem ? (root.surveyItem.cameraCalc.cameraModel || root.unavailable) : root.unavailable }
                    Readout { label: qsTr("Grid Angle"); value: root.plannedValue(root.surveyItem ? root.surveyItem.gridAngle : null) }
                    Readout { label: qsTr("Turnaround Distance"); value: root.plannedValue(root.surveyItem ? root.surveyItem.turnAroundDistance : null) }
                    Readout { label: qsTr("Camera Shots"); value: root.surveyItem ? String(root.surveyItem.cameraShots) : root.unavailable }
                }

                DockButton {
                    text: qsTr("Open Waypoint Editor")
                    onClicked: root.waypointEditorRequested()
                }

                PageMission {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    state: root.state
                    theme: root.theme
                    openCustomPlanShell: root.openCustomPlanShell
                    onTakeoffPageRequested: root.tabRequested(1)
                }
            }

            ColumnLayout {
                spacing: 2
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    Repeater {
                        model: [qsTr("Waypoints"), qsTr("Altitude"), qsTr("Loiter Radius"), qsTr("Direction"), qsTr("Camera")]

                        Text {
                            required property string modelData
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            font.pixelSize: 12
                            color: root.panelText
                            elide: Text.ElideRight
                        }
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.missionItems

                    delegate: RowLayout {
                        id: waypointRow
                        required property var object
                        width: ListView.view.width
                        height: visible ? 25 : 0
                        visible: object.specifiesCoordinate && object.sequenceNumber > 0

                        Repeater {
                            model: [
                                String(waypointRow.object.sequenceNumber),
                                root.plannedValue(waypointRow.object.altitude),
                                typeof waypointRow.object.loiterRadius === "number" && waypointRow.object.isLoiterItem
                                    ? Math.abs(waypointRow.object.loiterRadius).toFixed(0) : root.unavailable,
                                root.unavailable,
                                root.unavailable
                            ]

                            Text {
                                required property string modelData
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                text: modelData
                                color: root.panelText
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                font.pixelSize: 12
                            }
                        }
                    }
                }

                DockButton {
                    text: qsTr("Open Waypoint Editor")
                    onClicked: root.waypointEditorRequested()
                }
            }

            ScrollView {
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    width: Math.max(0, parent.width - root.theme.spacingSm * 2)
                    x: root.theme.spacingSm
                    spacing: 2

                    Section {
                        title: qsTr("Safety Settings")
                        expanded: true
                        Repeater {
                            model: 4
                            delegate: RowLayout {
                                id: safetyRow
                                required property int index
                                readonly property var fact: root.safety ? root.safety.safetyFact(index) : null
                                Layout.fillWidth: true
                                visible: !!fact

                                Text {
                                    Layout.fillWidth: true
                                    text: root.safety ? root.safety.safetyLabel(index) : ""
                                    color: root.panelText
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }

                                FactTextField {
                                    Layout.preferredWidth: 100
                                    fact: safetyRow.fact
                                    enabled: root.connected && !root.state.armed
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: !root.safety || !root.safety.parametersReady
                            text: qsTr("Parameters not ready")
                            color: root.secondaryText
                            font.pixelSize: 12
                        }
                    }

                    Section {
                        title: qsTr("Video")
                        DockButton {
                            text: qsTr("Video Settings")
                            onClicked: mainWindow.showSettingsTool(qsTranslate("SettingsPagesModel", "Video"))
                        }
                    }

                    Section {
                        title: qsTr("Sensors and Calibration")
                        DockButton {
                            text: qsTr("Vehicle Configuration")
                            onClicked: mainWindow.showVehicleConfig()
                        }
                    }

                    Section {
                        title: qsTr("Display")

                        DockButton {
                            text: root.theme.darkMode ? qsTr("Light Theme") : qsTr("Dark Theme")
                            onClicked: {
                                QGroundControl.settingsManager.appSettings.indoorPalette.rawValue = root.theme.darkMode ? 0 : 1
                            }
                        }

                        DisplaySwitch {
                            text: qsTr("Bottom Action Bar")
                            checked: root.state.showBottomActionBar
                            onToggled: root.state.setShowBottomActionBar(checked)
                        }

                        DisplaySwitch {
                            text: qsTr("Flight Instruments")
                            checked: root.state.showHudExpandBar
                            onToggled: root.state.setShowHudExpandBar(checked)
                        }
                    }

                    Section {
                        title: qsTr("Fly View")

                        FactCheckBoxSlider {
                            Layout.fillWidth: true
                            text: qsTr("Keep Map Centered on Vehicle")
                            fact: QGroundControl.settingsManager.flyViewSettings.keepMapCenteredOnVehicle
                            visible: fact.visible
                        }
                    }

                    Section {
                        title: qsTr("Connections")

                        DockButton {
                            text: qsTr("Comm Links")
                            onClicked: mainWindow.showSettingsTool(qsTranslate("SettingsPagesModel", "Comm Links"))
                        }
                    }

                    Section {
                        title: qsTr("Vehicle Configuration")

                        DockButton {
                            text: qsTr("Summary")
                            onClicked: mainWindow.showVehicleConfig()
                        }
                    }

                    DockButton {
                        text: qsTr("Application Settings")
                        onClicked: root.advancedSettingsRequested()
                    }
                }
            }
        }
    }
}
