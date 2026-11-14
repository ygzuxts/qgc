/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QtLocation
import QtPositioning
import QtQuick.Window
import QtQml.Models
import QtCore

import QGroundControl
import QGroundControl.Controllers
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QGroundControl.Vehicle

// To implement a custom overlay copy this code to your own control in your custom code source. Then override the
// FlyViewCustomLayer.qml resource with your own qml. See the custom example and documentation for details.
Item {
    id: _root

    property var parentToolInsets               // These insets tell you what screen real estate is available for positioning the controls in your overlay
    property var totalToolInsets:   _toolInsets // These are the insets for your custom overlay additions
    property var mapControl
    property var activeVehicle
    property var missionController
    property var guidedController
    property var _flyViewSettings: QGroundControl.settingsManager.flyViewSettings
    property bool customFlyViewEnabled: false
    property var setCustomFlyViewEnabled
    readonly property bool wantsMapVisible: customFlyViewEnabled
    readonly property bool wantsMapInteractive: workspaceVisible && mapViewportHover.hovered
    property bool nativeSwitchPanelExpanded: false
    property bool flightModePanelVisible: false
    property int currentTab: 0
    property bool customPlanShellVisible: false
    property string customPlanFilePath: ""
    property string openToolPage: ""
    readonly property real informationBarHeight: topBar.height
    property real rightW: Math.max(minRightW, Math.min(maxRightW, width * 0.22))
    property real hudH: Math.max(minHudH, Math.min(maxHudH, height * (ScreenTools.isMobileLayout ? 0.44 : 0.52)))
    property bool showRightPanel: _panelSettings.showRightPanel
    property real sidePanelOpacity: _panelSettings.sidePanelOpacity
    property bool showHudExpandBar: _panelSettings.showHudExpandBar
    property real infoBarOpacity: _panelSettings.infoBarOpacity
    property bool showBottomActionBar: _panelSettings.showBottomActionBar
    property bool showViewSwitchBar: _flyViewSettings.showViewSwitchBar.rawValue
    readonly property var uiTheme: theme
    readonly property var uiState: flightViewState
    readonly property bool workspaceVisible: customFlyViewEnabled && !customPlanShellVisible && openToolPage === ""
    readonly property bool bottomBarVisible: workspaceVisible && showBottomActionBar
    readonly property real effectiveRightW: workspaceVisible && showRightPanel ? rightW : 0
    readonly property real minRightW: Math.min(width * 0.42, 280 * theme.uiScale)
    readonly property real maxRightW: width * 0.46
    readonly property real qgcAndroidInstrumentSize: Math.min(ScreenTools.defaultFontPixelHeight * 6.38, height * 0.253, width * 0.132)
    readonly property real minHudH: Math.round(ScreenTools.isMobileLayout ? qgcAndroidInstrumentSize * 2.1 + 8 * theme.uiScale : height * 0.45)
    readonly property real maxHudH: Math.round(Math.max(height * (ScreenTools.isMobileLayout ? 0.50 : 0.58), ScreenTools.isMobileLayout ? minHudH : 0))
    readonly property real bottomBarH: theme.bottomBarH
    // Mobile instruments use the actual map viewport dimensions in FlyViewHUD.
    readonly property real sharedHudInstrumentSize: ScreenTools.isMobileLayout ? 0
                                                    : Math.max(96, Math.min(172, Math.min(width * 0.16, (hudH - theme.spacingXl * 2 - Math.round(10 * theme.uiScale) - Math.round(35 * theme.uiScale)) / 2)))
    readonly property real sharedHudTelemetryWidth: Math.max(220, Math.min(Math.round(430 * theme.uiScale), width - theme.spacingXl - sharedHudInstrumentSize - Math.max(8, Math.round(18 * theme.uiScale)) - theme.spacingXl))

    function selectWorkspaceTab(index) {
        if (!mainWindow.allowViewSwitch() || !mainWindow.closeTool()) {
            return false
        }
        if (customPlanShellVisible && customPlanShellLoader.item && customPlanShellLoader.item.requestReturn) {
            customPlanShellLoader.item.requestReturn()
            return false
        }
        customPlanShellVisible = false
        flightModePanelVisible = false
        openToolPage = ""
        currentTab = index
        _panelSettings.showRightPanel = true
        return true
    }

    function openWaypointPlanPage(planFilePath) {
        _root.customPlanFilePath = typeof planFilePath === "string" ? planFilePath : ""
        _root.currentTab = 2
        _root.customPlanShellVisible = true
    }

    // since this file is a placeholder for the custom layer in a standard build, we will just pass through the parent insets
    QGCToolInsets {
        id:                     _toolInsets
        leftEdgeTopInset:       parentToolInsets.leftEdgeTopInset
        leftEdgeCenterInset:    parentToolInsets.leftEdgeCenterInset
        leftEdgeBottomInset:    parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      parentToolInsets.rightEdgeTopInset
        rightEdgeCenterInset:   parentToolInsets.rightEdgeCenterInset
        rightEdgeBottomInset:   parentToolInsets.rightEdgeBottomInset
        topEdgeLeftInset:       parentToolInsets.topEdgeLeftInset
        topEdgeCenterInset:     parentToolInsets.topEdgeCenterInset
        topEdgeRightInset:      parentToolInsets.topEdgeRightInset
        bottomEdgeLeftInset:    parentToolInsets.bottomEdgeLeftInset
        bottomEdgeCenterInset:  parentToolInsets.bottomEdgeCenterInset
        bottomEdgeRightInset:   parentToolInsets.bottomEdgeRightInset
    }

    Settings {
        id: _panelSettings
        category: "CustomFlyView"
        property bool showRightPanel: true
        property real sidePanelOpacity: 0.92
        property bool showHudExpandBar: true
        property real infoBarOpacity: 0.82
        property bool showBottomActionBar: true
    }

    FlyViewTheme {
        id: theme
        viewportWidth: _root.width
        viewportHeight: _root.height
        darkMode: QGroundControl.settingsManager.appSettings.indoorPalette.rawValue === 1
    }

    FlyViewState {
        id: flightViewState
        activeVehicle: _root.activeVehicle
        missionController: _root.missionController
        guidedController: _root.guidedController
        customFlyViewEnabled: _root.customFlyViewEnabled
        setCustomFlyViewEnabled: _root.setCustomFlyViewEnabled
        sidePanelOpacity: _root.sidePanelOpacity
        setSidePanelOpacity: function(value) {
            _panelSettings.sidePanelOpacity = Math.max(0, Math.min(1, Number(value)))
        }
        showHudExpandBar: _root.showHudExpandBar
        setShowHudExpandBar: function(visible) { _panelSettings.showHudExpandBar = !!visible }
        infoBarOpacity: _root.infoBarOpacity
        setInfoBarOpacity: function(value) {
            _panelSettings.infoBarOpacity = Math.max(0, Math.min(1, Number(value)))
        }
        showBottomActionBar: _root.showBottomActionBar
        setShowBottomActionBar: function(visible) { _panelSettings.showBottomActionBar = !!visible }
    }

    FlyViewTopBar {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        state: _root.uiState
        theme: theme
        currentTab: _root.currentTab
        flightModePanelVisible: _root.flightModePanelVisible
        visible: _root.customFlyViewEnabled
        z: 120
        onFlightModeButtonClicked: _root.flightModePanelVisible = !_root.flightModePanelVisible
        onFlightModePanelCloseRequested: _root.flightModePanelVisible = false
        onAnalyzeToolsRequested: {
            if (!mainWindow.allowViewSwitch() || !mainWindow.closeTool()) {
                return
            }
            _root.flightModePanelVisible = false
            _root.openToolPage = "analyze"
        }
        onSettingsRequested: _root.selectWorkspaceTab(3)
        onPageSwitchRequested: _root.selectWorkspaceTab(0)
    }

    Item {
        id: centerArea
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.rightMargin: _root.effectiveRightW
        anchors.bottom: _root.bottomBarVisible ? bottomBar.top : parent.bottom
        visible: _root.customFlyViewEnabled

        Item {
            id: qgcMapViewport
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            HoverHandler {
                id: mapViewportHover
            }
        }

    }

    FlightModePanel {
        id: flightModePanel
        x: topBar.flightModePanelX
        y: topBar.flightModePanelY
        state: _root.uiState
        theme: theme
        visible: _root.customFlyViewEnabled && _root.flightModePanelVisible
        z: 90
        onCloseRequested: _root.flightModePanelVisible = false
    }

    FlyViewRightPanel {
        id: rightPanel
        anchors.top: topBar.bottom
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: _root.effectiveRightW
        state: _root.uiState
        theme: theme
        clip: true
        currentTab: _root.currentTab
        visible: width > 0
        backgroundOpacity: _root.sidePanelOpacity
        openCustomPlanShell: _root.openWaypointPlanPage
        onTabRequested: index => _root.selectWorkspaceTab(index)
        onAdvancedSettingsRequested: {
            if (mainWindow.allowViewSwitch()) {
                _root.openToolPage = "settings"
            }
        }
    }

    Rectangle {
        id: rightPanelCollapseHandle
        readonly property real handleW: Math.max(20, Math.round(theme.baseWidth * 2.4))
        readonly property real handleH: Math.max(42, Math.round(theme.baseFont * 3.1))

        width: handleW
        height: handleH
        radius: Math.round(width / 2)
        color: theme.darkMode ? Qt.rgba(0, 0, 0, 0.72) : Qt.rgba(1, 1, 1, 0.90)
        border.color: theme.darkMode ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(0, 0, 0, 0.14)
        border.width: 1
        visible: _root.workspaceVisible
        z: 35
        anchors.top: topBar.bottom
        anchors.topMargin: rightPanel.tabHeight + theme.spacingSm
        anchors.right: parent.right
        anchors.rightMargin: _root.showRightPanel ? Math.max(0, _root.rightW - width / 2) : 0

        Text {
            anchors.centerIn: parent
            text: _root.showRightPanel ? "›" : "‹"
            color: theme.darkMode ? "#ffffff" : "#111827"
            font.pixelSize: Math.round(theme.fontLg * 1.15)
            font.weight: Font.Bold
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: _panelSettings.showRightPanel = !_panelSettings.showRightPanel
        }
    }

    FlyViewBottomBar {
        id: bottomBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.rightMargin: _root.effectiveRightW
        height: _root.bottomBarH
        state: _root.uiState
        theme: theme
        visible: _root.bottomBarVisible
        onFailoverRequested: failoverDialog.visible = true
        onMissionCheckRequested: {
            if (_root.selectWorkspaceTab(1)) {
                rightPanel.openMissionCheck()
            }
        }
    }

    Loader {
        id: customPlanShellLoader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        active: _root.customFlyViewEnabled && _root.customPlanShellVisible
        asynchronous: true
        visible: _root.customFlyViewEnabled && _root.customPlanShellVisible
        z: 110

        sourceComponent: Component {
            WaypointPlanPage {
                state: _root.uiState
                theme: _root.uiTheme
                initialPlanFile: _root.customPlanFilePath
                missionController: _root.missionController
                hudInstrumentSize: _root.sharedHudInstrumentSize
                hudTelemetryWidth: _root.sharedHudTelemetryWidth
                hudHeight: _root.hudH
                topInset: topBar.height
                onCloseRequested: {
                    _root.currentTab = 2
                    _root.customPlanShellVisible = false
                }
            }
        }
    }

    Loader {
        id: toolPageLoader
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        active: _root.customFlyViewEnabled && _root.openToolPage !== ""
        asynchronous: true
        visible: active
        z: 110

        sourceComponent: Component {
            PageSettings {
                state: _root.uiState
                theme: _root.uiTheme
                analyzeMode: _root.openToolPage === "analyze"
                onCloseRequested: _root.openToolPage = ""
            }
        }
    }

    Item {
        id: nativeModeSwitchPanel
        anchors.left: parent.left
        anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 0.6
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        z: 30
        visible: !_root.customFlyViewEnabled && _root.showViewSwitchBar

        readonly property real panelWidth:    ScreenTools.defaultFontPixelWidth * 22
        readonly property real handleHeight:  ScreenTools.defaultFontPixelHeight * 1.6
        readonly property real trayHeight:    ScreenTools.defaultFontPixelHeight * 4.2
        readonly property real radius:        ScreenTools.defaultFontPixelWidth * 0.7

        width:  panelWidth
        height: handleHeight + (nativeModeSwitchPanel.expanded ? trayHeight : 0)

        property bool expanded: _root.nativeSwitchPanelExpanded

        Behavior on height {
            NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.top:    parent.top
            height:         nativeModeSwitchPanel.expanded ? nativeModeSwitchPanel.trayHeight : 0
            radius:         nativeModeSwitchPanel.radius
            color:          Qt.rgba(0.03, 0.05, 0.10, 0.88)
            border.width:   0.5
            border.color:   Qt.rgba(1, 1, 1, 0.13)
            clip:           true
            opacity:        nativeModeSwitchPanel.expanded ? 1 : 0

            Behavior on height  { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.left:   parent.left
                anchors.right:  parent.right
                anchors.bottom: parent.bottom
                height:         nativeModeSwitchPanel.radius
                color:          parent.color
            }

            Column {
                anchors.fill:        parent
                anchors.margins:     ScreenTools.defaultFontPixelWidth * 0.9
                spacing:             ScreenTools.defaultFontPixelHeight * 0.25

                QGCLabel {
                    width:          parent.width
                    text:           _root.customFlyViewEnabled ? qsTr("当前：自定义界面") : qsTr("当前：原版界面")
                    font.pointSize: ScreenTools.smallFontPointSize
                    color:          Qt.rgba(1, 1, 1, 0.38)
                    horizontalAlignment: Text.AlignHCenter
                }

                QGCButton {
                    width:   parent.width
                    height:  ScreenTools.defaultFontPixelHeight * 2.0
                    text:    _root.customFlyViewEnabled ? qsTr("切换到原版界面") : qsTr("切换到自定义界面")
                    enabled: nativeModeSwitchPanel.expanded
                    onClicked: _root.setCustomFlyViewEnabled(!_root.customFlyViewEnabled)
                }
            }
        }

        Rectangle {
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.bottom: parent.bottom
            height:         nativeModeSwitchPanel.handleHeight
            radius:         nativeModeSwitchPanel.radius
            color:          handleMouseArea.containsMouse
                            ? Qt.rgba(0.12, 0.18, 0.32, 0.92)
                            : Qt.rgba(0.03, 0.05, 0.10, 0.88)
            border.width:   0.5
            border.color:   Qt.rgba(1, 1, 1, 0.13)

            Behavior on color { ColorAnimation { duration: 140 } }

            Rectangle {
                anchors.left:   parent.left
                anchors.right:  parent.right
                anchors.top:    parent.top
                height:         nativeModeSwitchPanel.radius
                color:          parent.color
                visible:        nativeModeSwitchPanel.expanded
            }

            Rectangle {
                anchors.left:   parent.left
                anchors.right:  parent.right
                anchors.top:    parent.top
                height:         1
                color:          Qt.rgba(0.03, 0.05, 0.10, 0.88)
                visible:        nativeModeSwitchPanel.expanded
            }

            Row {
                anchors.centerIn: parent
                spacing:          ScreenTools.defaultFontPixelWidth * 0.5

                QGCLabel {
                    text:           "▲"
                    color:          Qt.rgba(1, 1, 1, 0.6)
                    font.pointSize: ScreenTools.smallFontPointSize * 0.85
                    rotation:       nativeModeSwitchPanel.expanded ? 180 : 0
                    Behavior on rotation {
                        NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
                    }
                }

                QGCLabel {
                    text:           qsTr("视图切换")
                    color:          Qt.rgba(1, 1, 1, 0.78)
                    font.pointSize: ScreenTools.smallFontPointSize
                }
            }

            QGCMouseArea {
                id:           handleMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: _root.nativeSwitchPanelExpanded = !_root.nativeSwitchPanelExpanded
            }
        }
    }

    FailoverDialog {
        id: failoverDialog
        fromBoardId: 1
        toBoardId: 2
        theme: theme
    }
}
