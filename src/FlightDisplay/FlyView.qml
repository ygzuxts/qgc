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

import QGroundControl
import QGroundControl.Controllers
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QGroundControl.Vehicle

// 3D Viewer modules
import Viewer3D

Item {
    id: _root

    property var  _flyViewSettings: QGroundControl.settingsManager.flyViewSettings
    property bool _useCustomFlyView: _flyViewSettings.useCustomFlyView.rawValue

    // These should only be used by MainRootWindow
    property var planController:    _planController
    property var guidedController:  _guidedController

    // Properties of UTM adapter
    property bool utmspSendActTrigger: false

    PlanMasterController {
        id:                     _planController
        flyView:                true
        Component.onCompleted:  start()
    }

    property bool   _mainWindowIsMap:       mapControl.pipState.state === mapControl.pipState.fullState
    property bool   _isFullWindowItemDark:  _mainWindowIsMap ? mapControl.isSatelliteMap : true
    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property var    _missionController:     _planController.missionController
    property var    _geoFenceController:    _planController.geoFenceController
    property var    _rallyPointController:  _planController.rallyPointController
    property real   _margins:               ScreenTools.defaultFontPixelWidth / 2
    property var    _guidedController:      guidedActionsController
    property var    _guidedValueSlider:     guidedValueSlider
    property var    _widgetLayer:           _useCustomFlyView ? customOverlay : widgetLayer
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property rect   _centerViewport:        Qt.rect(0, 0, width, height)
    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 30
    property var    _mapControl:            mapControl

    property real   _fullItemZorder:    0
    property real   _pipItemZorder:     QGroundControl.zOrderWidgets

    function _calcCenterViewPort() {
        var newToolInset = Qt.rect(0, 0, width, height)
        toolstrip.adjustToolInset(newToolInset)
    }

    function dropMainStatusIndicatorTool() {
        toolbar.dropMainStatusIndicatorTool();
    }

    function setUseCustomFlyView(enabled) {
        _flyViewSettings.useCustomFlyView.rawValue = enabled
    }

    QGCToolInsets {
        id:                     _toolInsets
        leftEdgeBottomInset:    _pipView.leftEdgeBottomInset
        bottomEdgeLeftInset:    _pipView.bottomEdgeLeftInset
    }

    FlyViewToolBar {
        id:         toolbar
        visible:    !_useCustomFlyView && !QGroundControl.videoManager.fullScreen
    }

    Item {
        id:                 mapHolder
        // Custom mode uses a full-window map with its own transparent top bar.
        // Stock mode must leave room for the original QGC toolbar; otherwise the
        // original HUD/widgets overlap the toolbar after switching back.
        anchors.top:        _useCustomFlyView ? parent.top : toolbar.bottom
        anchors.bottom:     parent.bottom
        anchors.left:       parent.left
        anchors.right:      parent.right

        FlyViewMap {
            id:                     mapControl
            planMasterController:   _planController
            rightPanelWidth:        ScreenTools.defaultFontPixelHeight * 9
            pipView:                _pipView
            pipMode:                !_mainWindowIsMap
            toolInsets:             _widgetLayer.totalToolInsets
            mapName:                "FlightDisplayView"
            enabled:                !viewer3DWindow.isOpen
            visible:                true
            customFlyViewEnabled:   _useCustomFlyView
        }

        FlyViewVideo {
            id:         videoControl
            pipView:    _pipView
        }

        PipView {
            id:                     _pipView
            anchors.left:           parent.left
            anchors.bottom:         parent.bottom
            anchors.margins:        _toolsMargin
            item1IsFullSettingsKey: "MainFlyWindowIsMap"
            item1:                  mapControl
            item2:                  QGroundControl.videoManager.hasVideo ? videoControl : null
            show:                   !_useCustomFlyView && QGroundControl.videoManager.hasVideo && !QGroundControl.videoManager.fullScreen &&
                                        (videoControl.pipState.state === videoControl.pipState.pipState || mapControl.pipState.state === mapControl.pipState.pipState)
            z:                      QGroundControl.zOrderWidgets

            property real leftEdgeBottomInset: visible ? width + anchors.margins : 0
            property real bottomEdgeLeftInset: visible ? height + anchors.margins : 0
        }

        FlyViewWidgetLayer {
            id:                     widgetLayer
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
            anchors.left:           parent.left
            anchors.right:          guidedValueSlider.visible ? guidedValueSlider.left : parent.right
            z:                      _fullItemZorder + 2
            parentToolInsets:       _toolInsets
            mapControl:             _mapControl
            visible:                !_useCustomFlyView && !QGroundControl.videoManager.fullScreen
            utmspActTrigger:        utmspSendActTrigger
            isViewer3DOpen:         viewer3DWindow.isOpen
        }

        FlyViewCustomLayer {
            id:                 customOverlay
            anchors.fill:       parent
            z:                  _fullItemZorder + 2
            parentToolInsets:   widgetLayer.totalToolInsets
            mapControl:         _mapControl
            activeVehicle:      _activeVehicle
            missionController:  _missionController
            guidedController:   _guidedController
            customFlyViewEnabled: _useCustomFlyView
            setCustomFlyViewEnabled: function(enabled) { _root.setUseCustomFlyView(enabled) }
            visible:            _useCustomFlyView && !QGroundControl.videoManager.fullScreen
        }

        // Development tool for visualizing the insets for a paticular layer, show if needed
        FlyViewInsetViewer {
            id:                     widgetLayerInsetViewer
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
            anchors.left:           parent.left
            anchors.right:          guidedValueSlider.visible ? guidedValueSlider.left : parent.right
            z:                      _widgetLayer.z + 1
            insetsToView:           _widgetLayer.totalToolInsets
            visible:                false
        }

        GuidedActionsController {
            id:                 guidedActionsController
            missionController:  _missionController
            guidedValueSlider:     _guidedValueSlider
        }

        //-- Guided value slider (e.g. altitude)
        GuidedValueSlider {
            id:                 guidedValueSlider
            anchors.right:      parent.right
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            z:                  QGroundControl.zOrderTopMost
            visible:            false
        }

        Viewer3D{
            id:                     viewer3DWindow
            anchors.fill:           parent
        }
    }

    Item {
        id: nativeModeSwitchPanel
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        z: QGroundControl.zOrderTopMost + 10
        visible: !_useCustomFlyView && !QGroundControl.videoManager.fullScreen && _flyViewSettings.showViewSwitchBar.rawValue

        readonly property real panelWidth:    ScreenTools.defaultFontPixelWidth * 22
        readonly property real handleHeight:  ScreenTools.defaultFontPixelHeight * 1.6
        readonly property real trayHeight:    ScreenTools.defaultFontPixelHeight * 4.2
        readonly property real radius:        ScreenTools.defaultFontPixelWidth * 0.7

        width:  panelWidth
        height: handleHeight + (expanded ? trayHeight : 0)
        property bool expanded: false

        Behavior on height {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.top:    parent.top
            height:         nativeModeSwitchPanel.expanded ? nativeModeSwitchPanel.trayHeight : 0
            radius:         nativeModeSwitchPanel.radius
            color:          Qt.rgba(0.03, 0.05, 0.10, 0.88)
            border.width:   1
            border.color:   Qt.rgba(1, 1, 1, 0.13)
            clip:           true
            opacity:        nativeModeSwitchPanel.expanded ? 1 : 0

            Behavior on height  { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

            Column {
                anchors.fill:        parent
                anchors.margins:     ScreenTools.defaultFontPixelWidth * 0.9
                spacing:             ScreenTools.defaultFontPixelHeight * 0.25

                QGCLabel {
                    width:          parent.width
                    text:           qsTr("当前：原版界面")
                    font.pointSize: ScreenTools.smallFontPointSize
                    color:          Qt.rgba(1, 1, 1, 0.42)
                    horizontalAlignment: Text.AlignHCenter
                }

                QGCButton {
                    width:   parent.width
                    height:  ScreenTools.defaultFontPixelHeight * 2.0
                    text:    qsTr("切换到自定义界面")
                    enabled: nativeModeSwitchPanel.expanded
                    onClicked: {
                        nativeModeSwitchPanel.expanded = false
                        _root.setUseCustomFlyView(true)
                    }
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
            border.width:   1
            border.color:   Qt.rgba(1, 1, 1, 0.13)

            Row {
                anchors.centerIn: parent
                spacing:          ScreenTools.defaultFontPixelWidth * 0.5

                QGCLabel {
                    text:           "▲"
                    color:          Qt.rgba(1, 1, 1, 0.6)
                    font.pointSize: ScreenTools.smallFontPointSize * 0.85
                    rotation:       nativeModeSwitchPanel.expanded ? 180 : 0
                    Behavior on rotation {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
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
                onClicked: nativeModeSwitchPanel.expanded = !nativeModeSwitchPanel.expanded
            }
        }
    }

}
