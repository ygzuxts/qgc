// FlyViewHUD.qml
// 起飞页左下角 HUD：罗盘、角度条、姿态仪、速度/姿态/高度信息栏

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import QGroundControl.Controls
import QGroundControl.Templates as T

import QGroundControl.FlightMap
import QGroundControl.ScreenTools
import QGroundControl.Palette

Rectangle {
    id: root

    property var state: null
    property var theme: null
    property real instrumentSizeOverride: 0
    property real telemetryWidthOverride: 0
    property real telemetryScaleOverride: 1.0
    property bool telemetryVisible: true
    property bool compactMode: false

    function validNumber(value) {
        return value !== undefined && value !== null && value === value
    }

    readonly property bool mobileLayout: theme ? theme.mobile : ScreenTools.isMobileLayout
    readonly property real edgePad: Math.max(2, Math.round(4 * hudScale))

    readonly property bool connected: !!(state && state.vehicleConnected)
    readonly property real heading: connected && validNumber(state.heading) ? state.heading : 0
    readonly property real infoOpacity: state && state.infoBarOpacity !== undefined ? Math.max(0.1, Math.min(1, state.infoBarOpacity)) : 0.82
    readonly property color glassLine: Qt.rgba(1, 1, 1, 0.16)
    readonly property real leftPad: compactMode ? Math.max(2, Math.round(4 * hudScale)) : (theme ? theme.spacingXl : 16)
    readonly property real bottomPad: mobileLayout ? edgePad : compactMode ? Math.max(2, Math.round(4 * hudScale)) : (theme ? theme.spacingXl : 16)
    readonly property real hudScale: theme ? theme.uiScale : 1
    readonly property real compassValueBarH: Math.round((compactMode ? 28 : 35) * root.hudScale)
    readonly property real instrumentGap: Math.round((compactMode ? 5 : 10) * root.hudScale)
    readonly property real qgcAndroidInstrumentSize: Math.min(ScreenTools.defaultFontPixelHeight * 6.38, (root.height - root.bottomPad * 2) / 2.1, root.width * 0.198)
    readonly property real instrumentMaxSize: theme && theme.mobile ? root.qgcAndroidInstrumentSize : 172
    readonly property real instrumentMinSize: theme && theme.mobile ? root.qgcAndroidInstrumentSize * 0.92 : 96
    readonly property real computedInstrumentSize: root.mobileLayout ? root.qgcAndroidInstrumentSize : Math.max(root.instrumentMinSize, Math.min(root.instrumentMaxSize, Math.min(root.width * 0.16, (root.height - root.bottomPad * 2 - root.instrumentGap - root.compassValueBarH) / 2)))
    readonly property real instrumentSize: root.instrumentSizeOverride > 0 ? root.instrumentSizeOverride : root.computedInstrumentSize
    readonly property real telemetryGap: Math.max(8, Math.round(18 * hudScale))
    readonly property real instrumentColumnW: root.leftPad + root.instrumentSize
    readonly property bool enoughSpaceForTelemetry: root.telemetryVisible && !root.compactMode && root.width > (root.mobileLayout ? mobileInstruments.width + root.edgePad * 3 + 220 : root.instrumentColumnW + root.telemetryGap + 240)
    readonly property real telemetryPreferredWidth: root.telemetryWidthOverride > 0 ? root.telemetryWidthOverride : Math.round(430 * root.hudScale)
    readonly property real telemetryScale: Math.max(0.72, Math.min(1.0, root.telemetryScaleOverride))

    QGCPalette { id: qgcPal }

    color: "transparent"

    Column {
        id: instrumentColumn
        visible: !root.mobileLayout
        anchors.left: parent.left
        anchors.leftMargin: root.leftPad
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bottomPad
        spacing: root.instrumentGap

        CompassWidget {
            id: compass
            size: root.instrumentSize
            heading: root.heading
            theme: root.theme
            infoBarOpacity: root.infoOpacity
        }

        QGCAttitudeWidget {
            id: attitude
            size: root.instrumentSize
            vehicle: root.state ? root.state.activeVehicle : null
            showPitch: true
            showHeading: false
        }
    }

    // Stock instruments in a compact vertical capsule at the map's bottom left.
    Rectangle {
        id: mobileInstruments
        visible: root.mobileLayout
        anchors.left: parent.left
        anchors.leftMargin: root.edgePad
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bottomPad
        readonly property real inset: Math.max(2, root.instrumentSize * 0.025)
        width: root.instrumentSize + inset * 2
        height: root.instrumentSize * 2 + inset * 3
        radius: width / 2
        color: qgcPal.window

        // Stock labels use screen-based font sizes. Render at the stock design
        // size, then scale the whole instrument so labels and geometry agree.
        readonly property real designSize: ScreenTools.defaultFontPixelHeight * 10

        Item {
            id: mobileAttitude
            anchors.top: parent.top
            anchors.topMargin: mobileInstruments.inset
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.instrumentSize
            height: width

            QGCAttitudeWidget {
                size: mobileInstruments.designSize
                scale: root.instrumentSize / size
                transformOrigin: Item.TopLeft
                vehicle: root.state ? root.state.activeVehicle : null
                showPitch: true
                showHeading: false
            }
        }

        Item {
            anchors.top: mobileAttitude.bottom
            anchors.topMargin: mobileInstruments.inset
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.instrumentSize
            height: width

            QGCCompassWidget {
                size: mobileInstruments.designSize
                scale: root.instrumentSize / size
                transformOrigin: Item.TopLeft
                vehicle: root.state ? root.state.activeVehicle : null
            }
        }
    }

    // Reuse the stock data model and persistence, with a fixed six-slot renderer.
    T.HorizontalFactValueGrid {
        id: telemetryModel
        visible: false
        settingsGroup: "CustomFlyViewTelemetry"
        specificVehicleForCard: null

        function ensureSixSlots() {
            if (!columns) return
            while (columns.count < 3) appendColumn()
            while (columns.count > 3) deleteLastColumn()
            while (rowCount < 2) appendRow()
            while (rowCount > 2) deleteLastRow()
        }
        onColumnsChanged: Qt.callLater(ensureSixSlots)
        Component.onCompleted: ensureSixSlots()
    }

    Component {
        id: telemetryValueEditor
        InstrumentValueEditDialog { }
    }

    Rectangle {
        id: telemetryBar
        anchors.left: root.mobileLayout ? mobileInstruments.right : instrumentColumn.right
        anchors.leftMargin: root.mobileLayout ? root.edgePad : root.telemetryGap
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bottomPad
        visible: root.enoughSpaceForTelemetry
        width: Math.max(220, Math.min(root.telemetryPreferredWidth, root.mobileLayout ? root.width - mobileInstruments.width - root.edgePad * 3 : root.width - instrumentColumn.x - instrumentColumn.width - root.telemetryGap - root.leftPad))
        height: Math.max(120, Math.round(128 * root.hudScale * root.telemetryScale))
        radius: Math.round(8 * root.hudScale * root.telemetryScale)
        // Match the heading strip's tint and alpha, including the opacity setting.
        color: Qt.rgba(0.03, 0.05, 0.09, root.infoOpacity)
        border.width: 1
        border.color: root.glassLine

        Row {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 0

            Repeater {
                model: telemetryModel.columns

                Item {
                    id: telemetryColumn
                    required property var object
                    required property int index
                    width: parent.width / 3
                    height: parent.height

                    Rectangle {
                        visible: telemetryColumn.index > 0
                        width: 1
                        height: parent.height - 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.glassLine
                    }

                    Column {
                        anchors.fill: parent
                        anchors.leftMargin: 5
                        anchors.rightMargin: 5
                        spacing: 0

                        Repeater {
                            model: telemetryColumn.object

                            Rectangle {
                                id: telemetrySlot
                                required property var object
                                required property int index
                                objectName: "telemetrySlot_" + telemetryColumn.index + "_" + index
                                readonly property var valueData: object
                                readonly property var fact: valueData ? valueData.fact : null
                                readonly property string valueText: root.connected && fact ? fact.enumOrValueString : "--"
                                readonly property string unitText: fact && valueData.showUnits
                                                                   ? (fact.units === "deg" ? "°" : fact.units) : ""
                                width: parent.width
                                height: parent.height / 2
                                radius: 5
                                color: slotMouse.pressed ? Qt.rgba(1, 1, 1, 0.16)
                                                        : slotMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                                Column {
                                    anchors.centerIn: parent
                                    width: parent.width - 4
                                    spacing: 1

                                    Text {
                                        width: parent.width
                                        text: telemetrySlot.valueData
                                              ? (telemetrySlot.valueData.displayText || (telemetrySlot.fact ? telemetrySlot.fact.shortDescription : qsTr("Select Data")))
                                              : qsTr("Select Data")
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        font.pointSize: 12
                                        color: Qt.rgba(1, 1, 1, 0.82)
                                    }
                                    Text {
                                        width: parent.width
                                        text: telemetrySlot.valueText + (telemetrySlot.unitText ? " " + telemetrySlot.unitText : "")
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        font.pointSize: 16
                                        font.bold: true
                                        color: "#ffffff"
                                    }
                                }

                                MouseArea {
                                    id: slotMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: !!telemetrySlot.valueData
                                    onClicked: {
                                        var dialog = telemetryValueEditor.createObject(mainWindow, {
                                            instrumentValueData: telemetrySlot.valueData
                                        })
                                        if (dialog) dialog.open()
                                    }
                                }
                                ToolTip.visible: slotMouse.containsMouse
                                ToolTip.text: qsTr("Click to choose displayed data")
                            }
                        }
                    }
                }
            }
        }
    }
}
