import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.Palette
import QGroundControl.UTMSP

// Toolbar for Plan View
Item {
    width: missionStats.width + _margins
    height: missionStats.implicitHeight + ScreenTools.defaultFontPixelHeight
    implicitHeight: height

    property var    planMasterController
    property var    theme
    readonly property color _sectionColor: theme ? theme.blue : "#3d6f99"
    readonly property color _labelColor: theme ? theme.text3 : "#64798f"
    readonly property color _valueColor: theme ? theme.text2 : "#1f2f3d"

    function _tr(text) {
        return qsTranslate("PlanToolBarIndicators", text)
    }

    property var    _planMasterController:      planMasterController
    property var    _currentMissionItem:        _planMasterController.missionController.currentPlanViewItem ///< Mission item to display status for

    property var    missionItems:               _controllerValid ? _planMasterController.missionController.visualItems : undefined
    property real   missionPlannedDistance:     _controllerValid ? _planMasterController.missionController.missionPlannedDistance : NaN
    property real   missionTime:                _controllerValid ? _planMasterController.missionController.missionTime : 0
    property real   missionMaxTelemetry:        _controllerValid ? _planMasterController.missionController.missionMaxTelemetry : NaN
    property bool   missionDirty:               _controllerValid ? _planMasterController.missionController.dirty : false

    property bool   _controllerValid:           _planMasterController !== undefined && _planMasterController !== null
    property bool   _controllerOffline:         _controllerValid ? _planMasterController.offline : true
    property var    _controllerDirty:           _controllerValid ? _planMasterController.dirty : false
    property var    _controllerSyncInProgress:  _controllerValid ? _planMasterController.syncInProgress : false

    property bool   _currentMissionItemValid:   _currentMissionItem && _currentMissionItem !== undefined && _currentMissionItem !== null
    property bool   _curreItemIsFlyThrough:     _currentMissionItemValid && _currentMissionItem.specifiesCoordinate && !_currentMissionItem.isStandaloneCoordinate
    property bool   _currentItemIsVTOLTakeoff:  _currentMissionItemValid && _currentMissionItem.command == 84
    property bool   _missionValid:              missionItems !== undefined

    property real   _dataFontSize:              ScreenTools.defaultFontPointSize
    property real   _largeValueWidth:           ScreenTools.defaultFontPixelWidth * 8
    property real   _mediumValueWidth:          ScreenTools.defaultFontPixelWidth * 4
    property real   _smallValueWidth:           ScreenTools.defaultFontPixelWidth * 3
    property real   _labelToValueSpacing:       ScreenTools.defaultFontPixelWidth
    property real   _rowSpacing:                ScreenTools.isMobileLayout ? 1 : 0
    property real   _distance:                  _currentMissionItemValid ? _currentMissionItem.distance : NaN
    property real   _altDifference:             _currentMissionItemValid ? _currentMissionItem.altDifference : NaN
    property real   _azimuth:                   _currentMissionItemValid ? _currentMissionItem.azimuth : NaN
    property real   _heading:                   _currentMissionItemValid ? _currentMissionItem.missionVehicleYaw : NaN
    property real   _missionPlannedDistance:    _missionValid ? missionPlannedDistance : NaN
    property real   _missionMaxTelemetry:       _missionValid ? missionMaxTelemetry : NaN
    property real   _missionTime:               _missionValid ? missionTime : 0
    property int    _batteryChangePoint:        _controllerValid ? _planMasterController.missionController.batteryChangePoint : -1
    property int    _batteriesRequired:         _controllerValid ? _planMasterController.missionController.batteriesRequired : -1
    property bool   _batteryInfoAvailable:      _batteryChangePoint >= 0 || _batteriesRequired >= 0
    property real   _gradient:                  _currentMissionItemValid && _currentMissionItem.distance > 0 ?
                                                    (_currentItemIsVTOLTakeoff ?
                                                         0 :
                                                         (Math.atan(_currentMissionItem.altDifference / _currentMissionItem.distance) * (180.0/Math.PI)))
                                                  : NaN

    property string _distanceText:                  isNaN(_distance) ?                  "-.-" : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_distance).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
    property string _altDifferenceText:             isNaN(_altDifference) ?             "-.-" : QGroundControl.unitsConversion.metersToAppSettingsVerticalDistanceUnits(_altDifference).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString
    property string _gradientText:                  isNaN(_gradient) ?                  "-.-" : _gradient.toFixed(0) + _tr(" deg")
    property string _azimuthText:                   isNaN(_azimuth) ?                   "-.-" : Math.round(_azimuth) % 360
    property string _headingText:                   isNaN(_azimuth) ?                   "-.-" : Math.round(_heading) % 360
    property string _missionPlannedDistanceText:    isNaN(_missionPlannedDistance) ?    "-.-" : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_missionPlannedDistance).toFixed(0) + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
    property string _missionMaxTelemetryText:       isNaN(_missionMaxTelemetry) ?       "-.-" : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_missionMaxTelemetry).toFixed(0) + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
    property string _batteryChangePointText:        _batteryChangePoint < 0 ?           _tr("N/A") : _batteryChangePoint
    property string _batteriesRequiredText:         _batteriesRequired < 0 ?            _tr("N/A") : _batteriesRequired

    readonly property real _margins: ScreenTools.defaultFontPixelWidth

    // Properties of UTM adapter
    property bool   _utmspEnabled:                       QGroundControl.utmspSupported

    function getMissionTime() {
        if (!_missionTime) {
            return "00:00:00"
        }
        var t = new Date(2021, 0, 0, 0, 0, Number(_missionTime))
        var days = Qt.formatDateTime(t, 'dd')
        var complete

        if (days == 31) {
            days = '0'
            complete = Qt.formatTime(t, 'hh:mm:ss')
        } else {
            complete = days + " days " + Qt.formatTime(t, 'hh:mm:ss')
        }
        return complete
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: theme ? theme.surface2 : "#f3f8fe"
        border.width: 1
        border.color: theme ? theme.border : "#d3e0ee"
    }

    RowLayout {
        id:                     missionStats
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin:     _margins * 1.4
        anchors.left:           parent.left
        spacing:                ScreenTools.defaultFontPixelWidth * 2

        QGCButton {
            id:          uploadButton
            text:        _controllerDirty ? _tr("Upload Required") : _tr("Upload")
            enabled:     _utmspEnabled ? !_controllerSyncInProgress && UTMSPStateStorage.enableMissionUploadButton : !_controllerSyncInProgress
            visible:     !_controllerOffline && !_controllerSyncInProgress
            primary:     _controllerDirty
            onClicked: {
                if (_utmspEnabled) {
                    QGroundControl.utmspManager.utmspVehicle.triggerActivationStatusBar(true);
                    UTMSPStateStorage.removeFlightPlanState = true
                    UTMSPStateStorage.indicatorDisplayStatus = true
                }
                _planMasterController.upload();
            }

            PropertyAnimation on opacity {
                easing.type:    Easing.OutQuart
                from:           0.5
                to:             1
                loops:          Animation.Infinite
                running:        _controllerDirty && !_controllerSyncInProgress
                alwaysRunToEnd: true
                duration:       2000
            }
        }

        GridLayout {
            columns:                8
            rowSpacing:             _rowSpacing
            columnSpacing:          _labelToValueSpacing

            QGCLabel {
                text:               _tr("Selected Waypoint")
                Layout.columnSpan:  8
                font.pointSize:     ScreenTools.smallFontPointSize
                color:              _sectionColor
                font.weight:        Font.DemiBold
            }

            QGCLabel { text: _tr("Alt diff:"); font.pointSize: _dataFontSize; color: _labelColor }
            QGCLabel {
                text:                   _altDifferenceText
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _mediumValueWidth
                color:                  _valueColor
            }

            Item { width: 1; height: 1 }

            QGCLabel { text: _tr("Azimuth:"); font.pointSize: _dataFontSize; color: _labelColor }
            QGCLabel {
                text:                   _azimuthText
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _smallValueWidth
                color:                  _valueColor
            }

            Item { width: 1; height: 1 }

            QGCLabel { text: _tr("Dist prev WP:"); font.pointSize: _dataFontSize; color: _labelColor }
            QGCLabel {
                text:                   _distanceText
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _largeValueWidth
                color:                  _valueColor
            }

            QGCLabel { text: _tr("Gradient:"); font.pointSize: _dataFontSize; color: _labelColor }
            QGCLabel {
                text:                   _gradientText
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _mediumValueWidth
                color:                  _valueColor
            }

            Item { width: 1; height: 1 }

            QGCLabel { text: _tr("Heading:"); font.pointSize: _dataFontSize; color: _labelColor }
            QGCLabel {
                text:                   _headingText
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _smallValueWidth
                color:                  _valueColor
            }
        }

        GridLayout {
            columns:                5
            rowSpacing:             _rowSpacing
            columnSpacing:          _labelToValueSpacing

            QGCLabel {
                text:               _tr("Total Mission")
                Layout.columnSpan:  5
                font.pointSize:     ScreenTools.smallFontPointSize
                color:              _sectionColor
                font.weight:        Font.DemiBold
            }

            QGCLabel { text: _tr("Distance:"); font.pointSize: _dataFontSize; color: _labelColor }
            QGCLabel {
                text:                   _missionPlannedDistanceText
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _largeValueWidth
                color:                  _valueColor
            }

            Item { width: 1; height: 1 }

            QGCLabel { text: _tr("Max telem dist:"); font.pointSize: _dataFontSize; color: _labelColor }
            QGCLabel {
                text:                   _missionMaxTelemetryText
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _largeValueWidth
                color:                  _valueColor
            }

            QGCLabel { text: _tr("Time:"); font.pointSize: _dataFontSize; color: _labelColor }
            QGCLabel {
                text:                   getMissionTime()
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _largeValueWidth
                color:                  _valueColor
            }
        }

        GridLayout {
            columns:                3
            rowSpacing:             _rowSpacing
            columnSpacing:          _labelToValueSpacing
            visible:                _batteryInfoAvailable

            QGCLabel {
                text:               _tr("Battery")
                Layout.columnSpan:  3
                font.pointSize:     ScreenTools.smallFontPointSize
                color:              _sectionColor
                font.weight:        Font.DemiBold
            }

            QGCLabel { text: _tr("Batteries required:"); font.pointSize: _dataFontSize; color: _labelColor }
            QGCLabel {
                text:                   _batteriesRequiredText
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _mediumValueWidth
                color:                  _valueColor
            }
        }
    }
}

