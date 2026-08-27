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
import QGroundControl.ScreenTools
import QGroundControl.Palette

QGCPopupDialog {
    id:         root
    title:      _tr("Select Mission Command")
    buttons:    Dialog.Cancel

    property var    vehicle
    property var    missionItem
    property var    map
    property bool   flyThroughCommandsAllowed
    property var    theme

    function _tr(text) {
        return qsTranslate("MissionCommandDialog", text)
    }

    ColumnLayout {
        spacing: ScreenTools.defaultFontPixelHeight * 0.75

        RowLayout {
            spacing: ScreenTools.defaultFontPixelWidth

            QGCLabel {
                text: _tr("Category:")
                color: theme ? theme.text2 : QGroundControl.globalPalette.text
            }

            QGCComboBox {
                id:                     categoryCombo
                Layout.preferredWidth:  30 * ScreenTools.defaultFontPixelWidth
                model:                  QGroundControl.missionCommandTree.categoriesForVehicle(vehicle)

                function categorySelected(category) {
                    commandList.model = QGroundControl.missionCommandTree.getCommandsForCategory(vehicle, category, flyThroughCommandsAllowed)
                }

                Component.onCompleted: {
                    var category  = missionItem.category
                    currentIndex = find(category)
                    categorySelected(category)
                }

                onActivated: (index) => { categorySelected(textAt(index)) }
            }
        }

        Repeater {
            id:                 commandList
            Layout.fillWidth:   true

            delegate: Rectangle {
                id: commandCard
                width:  parent.width
                height: commandColumn.height + ScreenTools.defaultFontPixelHeight
                radius: theme ? theme.radiusLg : 8
                color:  commandMouse.containsMouse
                        ? (theme ? theme.blue : QGroundControl.globalPalette.buttonHighlight)
                        : (theme ? theme.surface2 : QGroundControl.globalPalette.button)
                border.width: 1
                border.color: commandMouse.containsMouse
                              ? (theme ? theme.blueBorder : QGroundControl.globalPalette.buttonHighlight)
                              : (theme ? theme.border : "transparent")

                property var    mavCmdInfo: modelData
                property color  textColor:  commandMouse.containsMouse
                                            ? (theme ? theme.textOnBlue : QGroundControl.globalPalette.buttonHighlightText)
                                            : (theme ? theme.text2 : QGroundControl.globalPalette.buttonText)

                Column {
                    id:                 commandColumn
                    anchors.margins:    ScreenTools.defaultFontPixelWidth
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    anchors.top:        parent.top

                    QGCLabel {
                        text:           mavCmdInfo.friendlyName
                        color:          textColor
                        font.bold:      true
                    }

                    QGCLabel {
                        anchors.margins:    ScreenTools.defaultFontPixelWidth
                        anchors.left:       parent.left
                        anchors.right:      parent.right
                        text:               mavCmdInfo.description
                        wrapMode:           Text.WordWrap
                        color:              textColor
                    }
                }

                MouseArea {
                    id: commandMouse
                    anchors.fill:   parent
                    hoverEnabled:   true
                    onClicked: {
                        missionItem.setMapCenterHintForCommandChange(map.center)
                        missionItem.command = mavCmdInfo.command
                        root.close()
                    }
                }
            }
        }
    }
}
