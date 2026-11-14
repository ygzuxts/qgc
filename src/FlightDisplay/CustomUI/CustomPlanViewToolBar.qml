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
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Controllers

Rectangle {
    id:     _root
    width:  parent.width
    height: ScreenTools.toolbarHeight
    color:  theme ? theme.surface : qgcPal.toolbarBackground

    property var    planMasterController
    property var    closeHandler
    property var    theme

    function _tr(text) {
        return qsTranslate("PlanViewToolBar", text)
    }

    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property real   _controllerProgressPct: planMasterController.missionController.progressPct
    
    QGCPalette { id: qgcPal }

    /// Bottom single pixel divider
    Rectangle {
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        height:         1
        color:          theme ? theme.border : "black"
    }

    RowLayout {
        id:                     viewButtonRow
        anchors.bottomMargin:   1
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        spacing:                ScreenTools.defaultFontPixelWidth / 2

        QGCLabel {
            font.pointSize: ScreenTools.largeFontPointSize
            text:           "<"
            color:          theme ? theme.blue : qgcPal.text
        }

        QGCLabel {
            text:           qsTr("Back to Flight")
            font.pointSize: ScreenTools.largeFontPointSize
            color:          theme ? theme.text2 : qgcPal.text
        }
    }

    QGCMouseArea {
        anchors.fill:   viewButtonRow
        onClicked: {
            if (closeHandler) {
                closeHandler()
            } else {
                mainWindow.showFlyView()
            }
        }
    }

    QGCFlickable {
        id:                     toolsFlickable
        //anchors.leftMargin:     ScreenTools.defaultFontPixelWidth * ScreenTools.largeFontPointRatio * 1.5
        anchors.left:           viewButtonRow.right
        anchors.bottomMargin:   1
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.right:          parent.right
        contentWidth:           toolIndicators.width
        flickableDirection:     Flickable.HorizontalFlick

        CustomPlanToolBarIndicators {
            id:                     toolIndicators
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
            planMasterController:   _root.planMasterController
            theme:                  _root.theme
        }
    }

    // Small mission download progress bar
    Rectangle {
        id:             progressBar
        anchors.left:   parent.left
        anchors.bottom: parent.bottom
        height:         4
        width:          _controllerProgressPct * parent.width
        color:          theme ? theme.blue : qgcPal.colorGreen
        visible:        false

        onVisibleChanged: {
            if (visible) {
                largeProgressBar._userHide = false
            }
        }
    }

    // Large mission download progress bar
    Rectangle {
        id:             largeProgressBar
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        anchors.right:  parent.right
        height:         parent.height
        color:          theme ? theme.surface2 : qgcPal.window
        visible:        _showLargeProgress

        property bool _userHide:                false
        property bool _showLargeProgress:       progressBar.visible && !_userHide && qgcPal.globalTheme === QGCPalette.Light

        Connections {
            target:                 QGroundControl.multiVehicleManager
            onActiveVehicleChanged: largeProgressBar._userHide = false
        }

        Rectangle {
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            width:          _controllerProgressPct * parent.width
            color:          theme ? theme.blue : qgcPal.colorGreen
        }

        QGCLabel {
            anchors.centerIn:   parent
            text:               _tr("Syncing Mission")
            font.pointSize:     ScreenTools.largeFontPointSize
            visible:            _controllerProgressPct !== 1
        }

        QGCLabel {
            anchors.centerIn:   parent
            text:               _tr("Done")
            font.pointSize:     ScreenTools.largeFontPointSize
            visible:            _controllerProgressPct === 1
        }

        QGCLabel {
            anchors.margins:    _margin
            anchors.right:      parent.right
            anchors.bottom:     parent.bottom
            text:               _tr("Click anywhere to hide")

            property real _margin: ScreenTools.defaultFontPixelWidth / 2
        }

        MouseArea {
            anchors.fill:   parent
            onClicked:      largeProgressBar._userHide = true
        }
    }
    // Progress bar
    Connections {
        target: planMasterController.missionController

        onProgressPctChanged: {
            if (_controllerProgressPct === 1) {
                if (_root.visible) {
                    resetProgressTimer.start()
                } else {
                    progressBar.visible = false
                }
            } else if (_controllerProgressPct > 0) {
                progressBar.visible = true
            }
        }
    }

    Timer {
        id:             resetProgressTimer
        interval:       3000
        onTriggered:    progressBar.visible = false
    }
}
