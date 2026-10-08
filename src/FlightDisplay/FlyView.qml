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

    // These should only be used by MainRootWindow
    property var planController:    _planController
    property var guidedController:  _guidedController
    property bool originalQgcMode:  false

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
    property var    _widgetLayer:           widgetLayer
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

    QGCToolInsets {
        id:                     _toolInsets
        leftEdgeBottomInset:    _pipView.leftEdgeBottomInset
        bottomEdgeLeftInset:    _pipView.bottomEdgeLeftInset
    }

    FlyViewToolBar {
        id:         toolbar
        visible:    _root.originalQgcMode
        z:          QGroundControl.zOrderTopMost
    }

    Item {
        id:                 mapHolder
        anchors.top:        _root.originalQgcMode ? toolbar.bottom : parent.top
        anchors.bottom:     parent.bottom
        anchors.left:       parent.left
        anchors.right:      parent.right

        FlyViewMap {
            id:                     mapControl
            planMasterController:   _planController
            rightPanelWidth:        ScreenTools.defaultFontPixelHeight * 9
            pipView:                _pipView
            pipMode:                !_mainWindowIsMap
            toolInsets:             _root.originalQgcMode ? widgetLayer.totalToolInsets : customOverlay.totalToolInsets
            mapName:                "FlightDisplayView"
            enabled:                !viewer3DWindow.isOpen
        }

        FlyViewVideo {
            id:         videoControl
            pipView:    _pipView
            visible:    false
        }

        PipView {
            id:                     _pipView
            anchors.left:           parent.left
            anchors.bottom:         parent.bottom
            anchors.margins:        _toolsMargin
            item1IsFullSettingsKey: "MainFlyWindowIsMap"
            item1:                  mapControl
            item2:                  QGroundControl.videoManager.hasVideo ? videoControl : null
            show:                   QGroundControl.videoManager.hasVideo && !QGroundControl.videoManager.fullScreen &&
                                        (videoControl.pipState.state === videoControl.pipState.pipState || mapControl.pipState.state === mapControl.pipState.pipState)
            z:                      QGroundControl.zOrderWidgets
            visible:                _root.originalQgcMode

            property real leftEdgeBottomInset: visible ? width + anchors.margins : 0
            property real bottomEdgeLeftInset: visible ? height + anchors.margins : 0
        }

        FlyViewWidgetLayer {
            id:                     widgetLayer
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
            anchors.left:           parent.left
            anchors.right:          guidedValueSlider.visible ? guidedValueSlider.left : parent.right
            z:                      _fullItemZorder + 2 // we need to add one extra layer for map 3d viewer (normally was 1)
            parentToolInsets:       _toolInsets
            mapControl:             _mapControl
            utmspActTrigger:        utmspSendActTrigger
            isViewer3DOpen:         viewer3DWindow.isOpen
            visible:                _root.originalQgcMode
        }

        FlyViewCustomLayer {
            id:                 customOverlay
            anchors.fill:       widgetLayer
            z:                  _fullItemZorder + 2
            parentToolInsets:   widgetLayer.totalToolInsets
            mapControl:         _mapControl
            visible:            !QGroundControl.videoManager.fullScreen && !_root.originalQgcMode
            onOriginalQgcModeRequested: _root.originalQgcMode = true
        }

        // Development tool for visualizing the insets for a paticular layer, show if needed
        FlyViewInsetViewer {
            id:                     widgetLayerInsetViewer
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
            anchors.left:           parent.left
            anchors.right:          guidedValueSlider.visible ? guidedValueSlider.left : parent.right
            z:                      widgetLayer.z + 1
            insetsToView:           widgetLayer.totalToolInsets
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
            visible:                false
        }
    }

    Item {
        id:                 originalModeReturnRail
        anchors.right:      parent.right
        anchors.verticalCenter: parent.verticalCenter
        width:              expanded ? ScreenTools.defaultFontPixelWidth * 14 : ScreenTools.defaultFontPixelHeight * 2.2
        height:             ScreenTools.defaultFontPixelHeight * 7
        visible:            _root.originalQgcMode
        z:                  QGroundControl.zOrderTopMost + 1

        property bool expanded: false

        Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill:   parent
            color:          Qt.rgba(0, 0, 0, 0.72)
            radius:         ScreenTools.defaultFontPixelWidth * 0.75
            border.color:   Qt.rgba(1, 1, 1, 0.18)
        }

        Text {
            anchors.centerIn: parent
            visible:          !originalModeReturnRail.expanded
            text:             "<"
            color:            "white"
            font.pixelSize:   ScreenTools.defaultFontPixelHeight * 1.25
            font.bold:        true
        }

        Column {
            anchors.fill:       parent
            anchors.margins:    ScreenTools.defaultFontPixelWidth
            visible:            originalModeReturnRail.expanded
            spacing:            ScreenTools.defaultFontPixelHeight * 0.45

            Text {
                width:          parent.width
                text:           "界面"
                color:          Qt.rgba(1, 1, 1, 0.72)
                font.pixelSize: ScreenTools.smallFontPixelHeight
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                width:          parent.width
                height:         ScreenTools.defaultFontPixelHeight * 2.6
                radius:         ScreenTools.defaultFontPixelWidth * 0.5
                color:          dashboardMouse.pressed ? Qt.rgba(1, 1, 1, 0.26) : Qt.rgba(1, 1, 1, 0.14)
                border.color:   Qt.rgba(1, 1, 1, 0.22)

                Text {
                    anchors.centerIn: parent
                    text:             "仪表盘"
                    color:            "white"
                    font.pixelSize:   ScreenTools.defaultFontPixelHeight * 0.85
                    font.bold:        true
                }

                MouseArea {
                    id:             dashboardMouse
                    anchors.fill:   parent
                    onClicked: {
                        originalModeReturnRail.expanded = false
                        _root.originalQgcMode = false
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled:      !originalModeReturnRail.expanded
            onClicked:    originalModeReturnRail.expanded = true
        }
    }
}
