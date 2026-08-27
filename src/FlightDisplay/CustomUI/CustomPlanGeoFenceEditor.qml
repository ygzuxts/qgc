import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtPositioning

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Palette

QGCFlickable {
    id:             root
    contentHeight:  geoFenceEditorRect.height
    clip:           true

    property var    myGeoFenceController
    property var    flightMap
    property var    theme

    function _tr(text) {
        return qsTranslate("GeoFenceEditor", text)
    }

    readonly property real  _editFieldWidth:    Math.min(width - _margin * 2, ScreenTools.defaultFontPixelWidth * 15)
    readonly property real  _margin:            ScreenTools.defaultFontPixelWidth / 2
    readonly property real  _radius:            ScreenTools.defaultFontPixelWidth / 2

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    component PanelSectionHeader: Item {
        id: sectionRoot
        width: parent ? parent.width : 0
        height: titleLabel.implicitHeight + ScreenTools.defaultFontPixelHeight * 0.45

        property alias text: titleLabel.text
        property color textColor: theme ? theme.text : qgcPal.text
        property color lineColor: theme ? theme.blueBorder : "#8080B3"

        QGCLabel {
            id: titleLabel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            text: ""
            color: sectionRoot.textColor
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 2
            color: sectionRoot.lineColor
            opacity: 1
        }
    }

    component PanelButton: Button {
        id: panelButton
        Layout.fillWidth: true
        implicitHeight: ScreenTools.defaultFontPixelHeight * 2.4
        property var themeRef: root.theme

        background: Rectangle {
            radius: themeRef ? themeRef.radius : 6
            color: !panelButton.enabled
                   ? (themeRef ? themeRef.surface3 : "#d5d9df")
                   : (panelButton.down || panelButton.hovered)
                     ? (themeRef ? themeRef.blue : "#000066")
                     : (themeRef ? themeRef.surface2 : "#eef3fb")
            border.width: 1
            border.color: !panelButton.enabled
                          ? (themeRef ? themeRef.border : "#cfd8e3")
                          : (panelButton.down || panelButton.hovered)
                            ? (themeRef ? themeRef.blueBorder : "#000066")
                            : (themeRef ? themeRef.border : "#d6e1ee")
        }

        contentItem: Text {
            text: panelButton.text
            color: !panelButton.enabled
                   ? (themeRef ? themeRef.text3 : "#98a2b3")
                   : (panelButton.down || panelButton.hovered)
                     ? (themeRef ? themeRef.textOnBlue : "#ffffff")
                     : (themeRef ? themeRef.text2 : "#405469")
            font.pixelSize: 13
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    Rectangle {
        id:     geoFenceEditorRect
        anchors.left:   parent.left
        anchors.right:  parent.right
        height: geoFenceItems.y + geoFenceItems.height + (_margin * 2)
        radius: _radius
        color:  theme ? theme.surface : qgcPal.missionItemEditor
        border.width: 1
        border.color: theme ? theme.border : "transparent"

        QGCLabel {
            id:                 geoFenceLabel
            anchors.margins:    _margin
            anchors.left:       parent.left
            anchors.top:        parent.top
            text:               _tr("GeoFence")
            anchors.leftMargin: ScreenTools.defaultFontPixelWidth
            color:              theme ? theme.text : qgcPal.text
        }

        Rectangle {
            id:                 geoFenceItems
            anchors.margins:    _margin
            anchors.left:       parent.left
            anchors.right:      parent.right
            anchors.top:        geoFenceLabel.bottom
            height:             fenceColumn.y + fenceColumn.height + (_margin * 2)
            color:              theme ? theme.surface2 : qgcPal.windowShadeDark
            radius:             _radius
            border.width:       1
            border.color:       theme ? theme.border : "transparent"

            Column {
                id:                 fenceColumn
                anchors.margins:    _margin
                anchors.top:        parent.top
                anchors.left:       parent.left
                anchors.right:      parent.right
                spacing:            _margin

                QGCLabel {
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    wrapMode:           Text.WordWrap
                    font.pointSize:     myGeoFenceController.supported ? ScreenTools.smallFontPointSize : ScreenTools.defaultFontPointSize
                    text:               myGeoFenceController.supported ?
                                            _tr("GeoFencing allows you to set a virtual fence around the area you want to fly in.") :
                                            _tr("This vehicle does not support GeoFence.")
                    color:              theme ? theme.text2 : qgcPal.text
                }

                Column {
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    spacing:            _margin
                    visible:            myGeoFenceController.supported

                    Repeater {
                        model: myGeoFenceController.params

                        Item {
                            width:  fenceColumn.width
                            height: textField.height

                            property bool showCombo: modelData.enumStrings.length > 0

                            QGCLabel {
                                id:                 textFieldLabel
                                anchors.baseline:   textField.baseline
                                text:               myGeoFenceController.paramLabels[index]
                                color:              theme ? theme.text2 : qgcPal.text
                            }

                            FactTextField {
                                id:             textField
                                anchors.right:  parent.right
                                width:          _editFieldWidth
                                showUnits:      true
                                fact:           modelData
                                visible:        !parent.showCombo
                            }

                            FactComboBox {
                                id:             comboField
                                anchors.right:  parent.right
                                width:          _editFieldWidth
                                indexModel:     false
                                fact:           showCombo ? modelData : _nullFact
                                visible:        parent.showCombo

                                property var _nullFact: Fact { }
                            }
                        }
                    }

                    PanelSectionHeader {
                        id:             insertSection
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        text:           _tr("Insert GeoFence")
                    }

                    PanelButton {
                        Layout.fillWidth:   true
                        text:               _tr("Polygon Fence")

                        onClicked: {
                            var rect = Qt.rect(flightMap.centerViewport.x, flightMap.centerViewport.y, flightMap.centerViewport.width, flightMap.centerViewport.height)
                            var topLeftCoord = flightMap.toCoordinate(Qt.point(rect.x, rect.y), false /* clipToViewPort */)
                            var bottomRightCoord = flightMap.toCoordinate(Qt.point(rect.x + rect.width, rect.y + rect.height), false /* clipToViewPort */)
                            myGeoFenceController.addInclusionPolygon(topLeftCoord, bottomRightCoord)
                        }
                    }

                    PanelButton {
                        Layout.fillWidth:   true
                        text:               _tr("Circular Fence")

                        onClicked: {
                            var rect = Qt.rect(flightMap.centerViewport.x, flightMap.centerViewport.y, flightMap.centerViewport.width, flightMap.centerViewport.height)
                            var topLeftCoord = flightMap.toCoordinate(Qt.point(rect.x, rect.y), false /* clipToViewPort */)
                            var bottomRightCoord = flightMap.toCoordinate(Qt.point(rect.x + rect.width, rect.y + rect.height), false /* clipToViewPort */)
                            myGeoFenceController.addInclusionCircle(topLeftCoord, bottomRightCoord)
                        }
                    }

                    PanelSectionHeader {
                        id:             polygonSection
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        text:           _tr("Polygon Fences")
                    }

                    QGCLabel {
                        text:       _tr("None")
                        visible:    polygonSection.checked && myGeoFenceController.polygons.count === 0
                        color:      theme ? theme.text3 : qgcPal.text
                    }

                    GridLayout {
                        Layout.fillWidth:   true
                        columns:            3
                        flow:               GridLayout.TopToBottom
                        visible:            polygonSection.checked && myGeoFenceController.polygons.count > 0

                        QGCLabel {
                            text:               _tr("Inclusion")
                            Layout.column:      0
                            Layout.alignment:   Qt.AlignHCenter
                            color:              theme ? theme.text2 : qgcPal.text
                        }

                        Repeater {
                            model: myGeoFenceController.polygons

                            QGCCheckBox {
                                checked:            object.inclusion
                                onClicked:          object.inclusion = checked
                                Layout.alignment:   Qt.AlignHCenter
                            }
                        }

                        QGCLabel {
                            text:               _tr("Edit")
                            Layout.column:      1
                            Layout.alignment:   Qt.AlignHCenter
                            color:              theme ? theme.text2 : qgcPal.text
                        }

                        Repeater {
                            model: myGeoFenceController.polygons

                            QGCRadioButton {
                                checked:            _interactive
                                Layout.alignment:   Qt.AlignHCenter

                                property bool _interactive: object.interactive

                                on_InteractiveChanged: checked = _interactive

                                onClicked: {
                                    myGeoFenceController.clearAllInteractive()
                                    object.interactive = checked
                                }
                            }
                        }

                        QGCLabel {
                            text:               _tr("Delete")
                            Layout.column:      2
                            Layout.alignment:   Qt.AlignHCenter
                            color:              theme ? theme.text2 : qgcPal.text
                        }

                        Repeater {
                            model: myGeoFenceController.polygons

                            PanelButton {
                                text:               _tr("Del")
                                Layout.alignment:   Qt.AlignHCenter
                                onClicked:          myGeoFenceController.deletePolygon(index)
                            }
                        }
                    } // GridLayout

                    PanelSectionHeader {
                        id:             circleSection
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        text:           _tr("Circular Fences")
                    }

                    QGCLabel {
                        text:       _tr("None")
                        visible:    circleSection.checked && myGeoFenceController.circles.count === 0
                        color:      theme ? theme.text3 : qgcPal.text
                    }

                    GridLayout {
                        anchors.left:       parent.left
                        anchors.right:      parent.right
                        columns:            4
                        flow:               GridLayout.TopToBottom
                        visible:            polygonSection.checked && myGeoFenceController.circles.count > 0

                        QGCLabel {
                            text:               _tr("Inclusion")
                            Layout.column:      0
                            Layout.alignment:   Qt.AlignHCenter
                            color:              theme ? theme.text2 : qgcPal.text
                        }

                        Repeater {
                            model: myGeoFenceController.circles

                            QGCCheckBox {
                                checked:            object.inclusion
                                onClicked:          object.inclusion = checked
                                Layout.alignment:   Qt.AlignHCenter
                            }
                        }

                        QGCLabel {
                            text:               _tr("Edit")
                            Layout.column:      1
                            Layout.alignment:   Qt.AlignHCenter
                            color:              theme ? theme.text2 : qgcPal.text
                        }

                        Repeater {
                            model: myGeoFenceController.circles

                            QGCRadioButton {
                                checked:            _interactive
                                Layout.alignment:   Qt.AlignHCenter

                                property bool _interactive: object.interactive

                                on_InteractiveChanged: checked = _interactive

                                onClicked: {
                                    myGeoFenceController.clearAllInteractive()
                                    object.interactive = checked
                                }
                            }
                        }

                        QGCLabel {
                            text:               _tr("Radius")
                            Layout.column:      2
                            Layout.alignment:   Qt.AlignHCenter
                            color:              theme ? theme.text2 : qgcPal.text
                        }

                        Repeater {
                            model: myGeoFenceController.circles

                            FactTextField {
                                fact:               object.radius
                                Layout.fillWidth:   true
                                Layout.alignment:   Qt.AlignHCenter
                            }
                        }

                        QGCLabel {
                            text:               _tr("Delete")
                            Layout.column:      3
                            Layout.alignment:   Qt.AlignHCenter
                            color:              theme ? theme.text2 : qgcPal.text
                        }

                        Repeater {
                            model: myGeoFenceController.circles

                            PanelButton {
                                text:               _tr("Del")
                                Layout.alignment:   Qt.AlignHCenter
                                onClicked:          myGeoFenceController.deleteCircle(index)
                            }
                        }
                    } // GridLayout

                    PanelSectionHeader {
                        id:             breachReturnSection
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        text:           _tr("Breach Return Point")
                    }

                    PanelButton {
                        text:               _tr("Add Breach Return Point")
                        visible:            breachReturnSection.visible && !myGeoFenceController.breachReturnPoint.isValid
                        anchors.left:       parent.left
                        anchors.right:      parent.right

                        onClicked: myGeoFenceController.breachReturnPoint = flightMap.center
                    }

                    PanelButton {
                        text:               _tr("Remove Breach Return Point")
                        visible:            breachReturnSection.visible && myGeoFenceController.breachReturnPoint.isValid
                        anchors.left:       parent.left
                        anchors.right:      parent.right

                        onClicked: myGeoFenceController.breachReturnPoint = QtPositioning.coordinate()
                    }

                    ColumnLayout {
                        anchors.left:       parent.left
                        anchors.right:      parent.right
                        spacing:            _margin
                        visible:            breachReturnSection.visible && myGeoFenceController.breachReturnPoint.isValid

                        QGCLabel {
                            text: _tr("Altitude")
                            color: theme ? theme.text2 : qgcPal.text
                        }

                        FactTextField {
                            fact: myGeoFenceController.breachReturnAltitude
                        }
                    }

                }
            }
        }
    } // Rectangle
}
