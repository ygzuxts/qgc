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
import QtPositioning

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.Palette

ColumnLayout {
    id:         root
    spacing:    ScreenTools.defaultFontPixelWidth * 0.5

    property var    map
    property var    fitFunctions
    property bool   showMission:          true
    property bool   showAllItems:         true
    property var    theme

    component CenterActionButton: Button {
        id: popupButton
        implicitHeight: ScreenTools.defaultFontPixelHeight * 2.4

        background: Rectangle {
            radius: theme ? theme.radius : 6
            color: !popupButton.enabled
                   ? (theme ? theme.surface3 : "#d5d9df")
                   : (popupButton.down || popupButton.hovered)
                     ? (theme ? theme.blue : "#000066")
                     : (theme ? theme.surface2 : "#eef3fb")
            border.width: 1
            border.color: !popupButton.enabled
                          ? (theme ? theme.border : "#cfd8e3")
                          : (popupButton.down || popupButton.hovered)
                            ? (theme ? theme.blueBorder : "#000066")
                            : (theme ? theme.border : "#d6e1ee")
        }

        contentItem: Text {
            text: popupButton.text
            color: !popupButton.enabled
                   ? (theme ? theme.text3 : "#98a2b3")
                   : (popupButton.down || popupButton.hovered)
                     ? (theme ? theme.textOnBlue : "#ffffff")
                     : (theme ? theme.text2 : "#405469")
            font.pixelSize: 13
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    QGCLabel {
        text: qsTr("Center map on:")
        color: theme ? theme.text2 : undefined
    }

    CenterActionButton {
        text:               qsTr("Mission")
        Layout.fillWidth:   true
        visible:            showMission

        onClicked: {
            dropPanel.hide()
            fitFunctions.fitMapViewportToMissionItems()
        }
    }

    CenterActionButton {
        text:               qsTr("All items")
        Layout.fillWidth:   true
        visible:            showAllItems

        onClicked: {
            dropPanel.hide()
            fitFunctions.fitMapViewportToAllItems()
        }
    }

    CenterActionButton {
        text:               qsTr("Launch")
        Layout.fillWidth:   true

        onClicked: {
            dropPanel.hide()
            map.center = fitFunctions.fitHomePosition()
        }
    }

    CenterActionButton {
        text:               qsTr("Vehicle")
        Layout.fillWidth:   true
        enabled:            globals.activeVehicle && globals.activeVehicle.coordinate.isValid

        onClicked: {
            dropPanel.hide()
            map.center = globals.activeVehicle.coordinate
        }
    }

    CenterActionButton {
        text:               qsTr("Current Location")
        Layout.fillWidth:   true
        enabled:            map.gcsPosition.isValid

        onClicked: {
            dropPanel.hide()
            map.center = map.gcsPosition
        }
    }

    CenterActionButton {
        text:               qsTr("Specified Location")
        Layout.fillWidth:   true

        onClicked: {
            dropPanel.hide()
            map.centerToSpecifiedLocation()
        }
    }
} // Column
