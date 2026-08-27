import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.Palette

QGCFlickable {
    height:         outerEditorRect.height
    contentHeight:  outerEditorRect.height
    clip:           true

    property var controller ///< RallyPointController
    property var theme

    function _tr(text) {
        return qsTranslate("RallyPointEditorHeader", text)
    }

    readonly property real  _margin: ScreenTools.defaultFontPixelWidth / 2
    readonly property real  _radius: ScreenTools.defaultFontPixelWidth / 2

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    Rectangle {
        id:     outerEditorRect
        width:  parent.width
        height: innerEditorRect.y + innerEditorRect.height + (_margin * 2)
        radius: _radius
        color:  theme ? theme.surface : qgcPal.missionItemEditor
        border.width: 1
        border.color: theme ? theme.border : "transparent"

        QGCLabel {
            id:                 editorLabel
            anchors.margins:    _margin
            anchors.left:       parent.left
            anchors.top:        parent.top
            text:               _tr("Rally Points")
            color:              theme ? theme.text : qgcPal.text
        }

        Rectangle {
            id:                 innerEditorRect
            anchors.margins:    _margin
            anchors.left:       parent.left
            anchors.right:      parent.right
            anchors.top:        editorLabel.bottom
            height:             infoLabel.height + (_margin * 2)
            color:              theme ? theme.surface2 : qgcPal.windowShadeDark
            radius:             _radius
            border.width:       1
            border.color:       theme ? theme.border : "transparent"

            QGCLabel {
                id:                 infoLabel
                anchors.margins:    _margin
                anchors.top:        parent.top
                anchors.left:       parent.left
                anchors.right:      parent.right
                wrapMode:           Text.WordWrap
                font.pointSize:     ScreenTools.smallFontPointSize
                text:               _tr("Rally Points provide alternate landing points when performing a Return to Launch (RTL).")
                color:              theme ? theme.text2 : qgcPal.text
            }

            /*
            QGCLabel {
                id:                 helpLabel
                anchors.margins:    _margin
                anchors.left:       parent.left
                anchors.right:      parent.right
                anchors.top:        infoLabel.bottom
                wrapMode:           Text.WordWrap
                text:               controller.supported ?
                                        qsTr("Click in the map to add new rally points.") :
                                        qsTr("This vehicle does not support Rally Points.")
            }
            */
        }
    }
}
