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
    readonly property bool wantsMapInteractive: customFlyViewEnabled && mapViewportHover.hovered
    property bool nativeSwitchPanelExpanded: false
    property bool flightModePanelVisible: false
    // 0: 起飞/起降页，1: 任务列表页。打开地面站默认进入任务列表页。
    property int currentTab: 1
    property bool customPlanShellVisible: false
    property bool settingsPageVisible: false
    property real leftW: Math.max(minLeftW, Math.min(maxLeftW, theme.leftPanelW))
    property real rightW: Math.max(minRightW, Math.min(maxRightW, theme.rightPanelW))
    property real hudH: Math.max(minHudH, Math.min(maxHudH, height * (ScreenTools.isMobile ? 0.44 : 0.52)))
    property bool hudCollapsed: false
    property bool showLeftPanel: _panelSettings.showLeftPanel
    property bool showRightPanel: _panelSettings.showRightPanel
    property real sidePanelOpacity: _panelSettings.sidePanelOpacity
    property bool showHudExpandBar: _panelSettings.showHudExpandBar
    property real infoBarOpacity: _panelSettings.infoBarOpacity
    property bool showBottomActionBar: _panelSettings.showBottomActionBar
    property bool showViewSwitchBar: _flyViewSettings.showViewSwitchBar.rawValue
    readonly property var uiTheme: theme
    readonly property bool taskListPageActive: currentTab === 1 && !customPlanShellVisible
    readonly property bool takeoffPageActive: currentTab === 0 && !customPlanShellVisible
    readonly property bool bottomBarVisible: false
    readonly property real effectiveLeftW: taskListPageActive && showLeftPanel ? leftW : 0
    readonly property real effectiveRightW: takeoffPageActive && showRightPanel ? rightW : 0
    readonly property real minLeftW: width * (ScreenTools.isMobile ? 0.17 : 0.104)
    readonly property real maxLeftW: width * (ScreenTools.isMobile ? 0.34 : 0.208)
    readonly property real minRightW: width * (ScreenTools.isMobile ? 0.18 : 0.115)
    readonly property real maxRightW: width * (ScreenTools.isMobile ? 0.34 : 0.219)
    readonly property real qgcAndroidInstrumentSize: ScreenTools.defaultFontPixelHeight * 6.4
    readonly property real minHudH: Math.round(Math.max(height * (ScreenTools.isMobile ? 0.38 : 0.45), ScreenTools.isMobile ? qgcAndroidInstrumentSize * 2 + theme.spacingXl * 2 + Math.round(10 * theme.uiScale) : 0))
    readonly property real maxHudH: Math.round(Math.max(height * (ScreenTools.isMobile ? 0.50 : 0.58), ScreenTools.isMobile ? minHudH : 0))
    readonly property real bottomBarH: theme.bottomBarH
    readonly property real sharedHudInstrumentSize: ScreenTools.isMobile
                                                    ? Math.max(qgcAndroidInstrumentSize * 0.92, Math.min(qgcAndroidInstrumentSize, Math.min(width * 0.16, (hudH - theme.spacingXl * 2 - Math.round(10 * theme.uiScale) - Math.round(35 * theme.uiScale)) / 2)))
                                                    : Math.max(96, Math.min(172, Math.min(width * 0.16, (hudH - theme.spacingXl * 2 - Math.round(10 * theme.uiScale) - Math.round(35 * theme.uiScale)) / 2)))
    readonly property real sharedHudTelemetryWidth: Math.max(220, Math.min(Math.round(430 * theme.uiScale), width - theme.spacingXl - sharedHudInstrumentSize - Math.max(8, Math.round(18 * theme.uiScale)) - theme.spacingXl))

    Component.onCompleted: {
        _root.currentTab = 1
        _panelSettings.showLeftPanel = true
    }

    function openWaypointPlanPage() {
        _root.currentTab = 1
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
        property bool showLeftPanel: true
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
    }

    FlyViewState {
        id: state
        activeVehicle: _root.activeVehicle
        missionController: _root.missionController
        guidedController: _root.guidedController
        customFlyViewEnabled: _root.customFlyViewEnabled
        setCustomFlyViewEnabled: _root.setCustomFlyViewEnabled
        showLeftPanel: _root.showLeftPanel
        setShowLeftPanel: function(visible) { _panelSettings.showLeftPanel = !!visible }
        sidePanelOpacity: _root.sidePanelOpacity
        setSidePanelOpacity: function(value) {
            _panelSettings.sidePanelOpacity = Math.max(0, Math.min(1, Number(value)))
        }
        showHudExpandBar: _root.showHudExpandBar
        setShowHudExpandBar: function(visible) {
            _panelSettings.showHudExpandBar = !!visible
            if (!visible) {
                _root.hudCollapsed = true
            }
        }
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
        state: state
        theme: theme
        currentTab: _root.currentTab
        flightModePanelVisible: _root.flightModePanelVisible
        visible: _root.customFlyViewEnabled
        z: 120
        onFlightModeButtonClicked: _root.flightModePanelVisible = !_root.flightModePanelVisible
        onSettingsRequested: {
            _root.flightModePanelVisible = false
            _root.settingsPageVisible = true
        }
        onPageSwitchRequested: {
            if (_root.settingsPageVisible) {
                _root.settingsPageVisible = false
                return
            }
            if (_root.customPlanShellVisible && customPlanShellLoader.item && customPlanShellLoader.item.requestReturn) {
                customPlanShellLoader.item.requestReturn()
                return
            }
            _root.currentTab = _root.taskListPageActive ? 0 : 1
            if (_root.currentTab === 1) {
                _panelSettings.showLeftPanel = true
            } else if (_root.currentTab === 0) {
                _panelSettings.showRightPanel = true
            }
        }
    }

    FlyViewLeftPanel {
        id: leftPanel
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: _root.effectiveLeftW
        visible: _root.customFlyViewEnabled && _root.taskListPageActive && _root.showLeftPanel
        state: state
        theme: theme
        clip: true
        backgroundOpacity: _root.sidePanelOpacity
        openCustomPlanShell: function() { _root.openWaypointPlanPage() }
        onTakeoffPageRequested: {
            _root.currentTab = 0
            _panelSettings.showRightPanel = true
        }
    }

    Rectangle {
        id: leftPanelCollapseHandle
        readonly property real handleW: Math.max(20, Math.round(theme.baseWidth * 2.4))
        readonly property real handleH: Math.max(42, Math.round(theme.baseFont * 3.1))

        width: handleW
        height: handleH
        radius: Math.round(width / 2)
        color: theme.darkMode ? Qt.rgba(0, 0, 0, 0.72) : Qt.rgba(1, 1, 1, 0.90)
        border.color: theme.darkMode ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(0, 0, 0, 0.14)
        border.width: 1
        visible: _root.customFlyViewEnabled && _root.taskListPageActive
        z: 35
        anchors.top: topBar.bottom
        anchors.topMargin: theme.spacingLg
        anchors.left: parent.left
        anchors.leftMargin: _root.showLeftPanel ? Math.max(0, _root.leftW - width / 2) : 0

        Text {
            anchors.centerIn: parent
            text: _root.showLeftPanel ? "‹" : "›"
            color: theme.darkMode ? "#ffffff" : "#111827"
            font.pixelSize: Math.round(theme.fontLg * 1.15)
            font.weight: Font.Bold
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: _panelSettings.showLeftPanel = !_panelSettings.showLeftPanel
        }
    }

    Item {
        id: centerArea
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.leftMargin: _root.effectiveLeftW
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

        Rectangle {
            id: hudTopBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: hudArea.top
            height: theme.sectionH
            color: theme.surface
            z: 5
            visible: false

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: theme.border
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: theme.border
            }

            Text {
                anchors.centerIn: parent
                text: "姿态 · 遥测"
                font.pixelSize: theme.fontSm
                font.weight: Font.Medium
                color: theme.text3
            }

            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: 88
                cursorShape: _root.hudCollapsed ? Qt.ArrowCursor : Qt.SizeVerCursor
                hoverEnabled: true

                property int _sy: 0
                property int _sh: 0

                onPressed: {
                    _sy = mouseY
                    _sh = _root.hudH
                }
                onMouseYChanged: {
                    if (pressed && !_root.hudCollapsed) {
                        var newH = _sh - (mouseY - _sy)
                        _root.hudH = Math.max(_root.minHudH, Math.min(_root.maxHudH, newH))
                    }
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: theme.spacingSm
                anchors.verticalCenter: parent.verticalCenter
                width: theme.baseWidth * 9.5
                height: theme.controlHSm
                radius: theme.radiusLg
                color: _colBtn.containsMouse ? theme.blue : theme.surface3
                border.color: _colBtn.containsMouse ? theme.blueBorder : theme.blueBorder
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: theme.spacingSm

                    Text {
                        text: _root.hudCollapsed ? "▲" : "▼"
                        font.pixelSize: theme.fontXs
                        font.weight: Font.Bold
                        color: _colBtn.containsMouse ? theme.textOnBlue : theme.blue
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: _root.hudCollapsed ? "展开" : "收起"
                        font.pixelSize: theme.fontMd
                        font.weight: Font.DemiBold
                        color: _colBtn.containsMouse ? theme.textOnBlue : theme.blue
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: _colBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: _root.hudCollapsed = !_root.hudCollapsed
                }
            }
        }

        FlyViewHUD {
            id: hudArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: _root.takeoffPageActive && !_root.hudCollapsed ? _root.hudH : 0
            visible: _root.takeoffPageActive && !_root.hudCollapsed
            clip: false
            z: 8
            state: state
            theme: theme
            instrumentSizeOverride: _root.sharedHudInstrumentSize
            telemetryWidthOverride: _root.sharedHudTelemetryWidth
        }
    }

    FlightModePanel {
        id: flightModePanel
        x: topBar.flightModePanelX
        y: topBar.flightModePanelY
        state: state
        theme: theme
        visible: _root.customFlyViewEnabled && _root.flightModePanelVisible
        z: 90
        onCloseRequested: _root.flightModePanelVisible = false
    }

    FlyViewRightPanel {
        id: rightPanel
        anchors.top: topBar.bottom
        anchors.right: parent.right
        anchors.bottom: _root.bottomBarVisible ? bottomBar.top : parent.bottom
        width: _root.effectiveRightW
        state: state
        theme: theme
        clip: true
        currentTab: _root.currentTab
        visible: _root.customFlyViewEnabled && _root.takeoffPageActive && _root.showRightPanel
        backgroundOpacity: _root.sidePanelOpacity
        openCustomPlanShell: function() { _root.customPlanShellVisible = true }
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
        visible: _root.customFlyViewEnabled && _root.takeoffPageActive
        z: 35
        anchors.top: topBar.bottom
        anchors.topMargin: theme.spacingLg
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
        height: _root.bottomBarH
        state: state
        theme: theme
        visible: _root.bottomBarVisible
        onFailoverRequested: failoverDialog.visible = true
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
                state: state
                theme: theme
                missionController: _root.missionController
                hudInstrumentSize: _root.sharedHudInstrumentSize
                hudTelemetryWidth: _root.sharedHudTelemetryWidth
                hudHeight: _root.hudH
                topInset: topBar.height
                onCloseRequested: {
                    _root.currentTab = 1
                    _root.customPlanShellVisible = false
                }
            }
        }
    }

    Loader {
        id: settingsPageLoader
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        active: _root.customFlyViewEnabled && _root.settingsPageVisible
        asynchronous: true
        visible: active
        z: 110

        sourceComponent: Component {
            PageSettings {
                state: state
                theme: _root.uiTheme
                onCloseRequested: _root.settingsPageVisible = false
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
