import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.FlightMap

Rectangle {
    id: root

    required property var state
    required property var theme
    property int currentTab: 0
    property var openCustomPlanShell: null
    property real backgroundOpacity: 1.0
    readonly property real tabHeight: Math.max(40, theme.tabBarH)
    readonly property bool connected: state.vehicleConnected
    readonly property string unavailable: "—"

    signal tabRequested(int index)
    signal advancedSettingsRequested()

    function openMissionCheck() {
        if (takeoffLoader.item && takeoffLoader.item.takeoffPage.missionStartEnabled()) {
            takeoffLoader.item.takeoffPage.openStartMissionCheck()
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

    color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, Math.max(0.94, backgroundOpacity))

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

    component DockButton: Button {
        id: control
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        Layout.preferredHeight: root.tabHeight
        font.pixelSize: root.theme.fontSm
        padding: 4

        contentItem: Text {
            text: control.text
            font: control.font
            color: control.enabled ? root.theme.text : root.theme.text3
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            color: control.down || control.checked ? root.theme.surface3
                   : control.hovered || control.visualFocus ? root.theme.surface2 : "transparent"

            Rectangle {
                visible: control.checked || control.visualFocus
                anchors.bottom: parent.bottom
                width: parent.width
                height: 2
                color: root.theme.blue
            }
        }
    }

    component DisplaySwitch: Switch {
        Layout.fillWidth: true
        palette.windowText: root.theme.text
        palette.text: root.theme.text
        palette.buttonText: root.theme.text
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
            Layout.preferredHeight: Math.max(32, root.theme.controlHMd)
            text: section.title
            checkable: true
            checked: section.expanded
            onToggled: section.expanded = checked

            contentItem: RowLayout {
                Text {
                    Layout.fillWidth: true
                    text: section.title
                    color: root.theme.text
                    font.pixelSize: root.theme.fontMd
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    text: section.expanded ? "▾" : "›"
                    color: root.theme.text2
                    font.pixelSize: root.theme.fontLg
                }
            }

            background: Rectangle {
                color: header.hovered || header.visualFocus ? root.theme.surface3 : root.theme.surface2
                radius: 3
            }
        }

        ColumnLayout {
            id: content
            visible: section.expanded
            Layout.fillWidth: true
            Layout.margins: root.theme.spacingSm
            spacing: root.theme.spacingXs
        }
    }

    component Readout: RowLayout {
        id: readout
        property string label
        property string value
        Layout.fillWidth: true
        Layout.minimumHeight: root.theme.controlHSm

        Text {
            Layout.fillWidth: true
            text: readout.label
            color: root.theme.text2
            font.pixelSize: root.theme.fontSm
            wrapMode: Text.WordWrap
        }
        Text {
            Layout.maximumWidth: readout.width * 0.55
            text: readout.value
            color: root.theme.text
            font.pixelSize: root.theme.fontSm
            font.weight: Font.DemiBold
            elide: Text.ElideRight
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
                model: [qsTr("Flight"), qsTr("Takeoff"), qsTr("Mission"), qsTr("Settings")]
                delegate: DockButton {
                    required property int index
                    required property string modelData
                    Layout.preferredWidth: 1
                    text: modelData
                    checked: index === root.currentTab
                    onClicked: root.tabRequested(index)
                    ToolTip.visible: hovered && contentItem.truncated
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
                    spacing: root.theme.spacingSm

                    Readout {
                        label: qsTr("Vehicle")
                        value: root.connected ? qsTr("Vehicle %1").arg(root.state.activeVehicle.id)
                               : root.state.communicationLost ? qsTr("Connection lost") : qsTr("Disconnected")
                    }

                    Section {
                        title: qsTr("Flight Parameters")
                        expanded: true
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
                        title: qsTr("Flight Instruments")
                        visible: root.state.showHudExpandBar
                        expanded: true

                        QGCAttitudeWidget {
                            Layout.alignment: Qt.AlignHCenter
                            visible: root.connected
                            size: Math.max(1, Math.min(180 * root.theme.uiScale, root.width * 0.65))
                            vehicle: root.connected ? root.state.activeVehicle : null
                            showPitch: true
                            showHeading: true
                        }

                        Label {
                            visible: !root.connected
                            text: qsTr("No live attitude data")
                            color: root.theme.text2
                        }
                    }

                    DockButton {
                        text: qsTr("Vehicle Configuration")
                        onClicked: mainWindow.showVehicleConfig()
                    }
                }
            }

            Loader {
                id: takeoffLoader
                active: root.currentTab === 1
                sourceComponent: ScrollView {
                    property alias takeoffPage: takeoffPage
                    contentWidth: availableWidth
                    clip: true

                    PageTakeoff {
                        id: takeoffPage
                        width: parent.width
                        height: implicitHeight
                        state: root.state
                        theme: root.theme
                    }
                }
            }

            Loader {
                active: root.currentTab === 2
                sourceComponent: PageMission {
                    state: root.state
                    theme: root.theme
                    openCustomPlanShell: root.openCustomPlanShell
                    onTakeoffPageRequested: root.tabRequested(1)
                }
            }

            ScrollView {
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    width: Math.max(0, parent.width - root.theme.spacingSm * 2)
                    x: root.theme.spacingSm
                    spacing: root.theme.spacingSm

                    Section {
                        title: qsTr("Display")
                        expanded: true

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
