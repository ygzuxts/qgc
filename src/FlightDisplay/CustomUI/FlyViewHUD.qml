// FlyViewHUD.qml
// 起飞页左下角 HUD：罗盘、角度条、姿态仪、速度/经纬度/高度信息栏

import QtQuick
import QtQuick.Layouts

import QGroundControl.FlightMap
import QGroundControl.ScreenTools

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

    function fmt(value, decimals, suffix) {
        return validNumber(value) ? (Number(value).toFixed(decimals) + (suffix || "")) : "--"
    }

    readonly property bool connected: !!(state && state.vehicleConnected)
    readonly property real roll: connected && validNumber(state.roll) ? state.roll : 0
    readonly property real pitch: connected && validNumber(state.pitch) ? state.pitch : 0
    readonly property real heading: connected && validNumber(state.heading) ? state.heading : 0
    readonly property string speedText: connected ? fmt(state.groundSpeed, 1, "") : "--"
    readonly property string latText: connected ? fmt(state.latitude, 5, "") : "--"
    readonly property string lonText: connected ? fmt(state.longitude, 5, "") : "--"
    readonly property string altText: connected ? fmt(state.altitude, 1, "") : "--"
    readonly property real infoOpacity: state && state.infoBarOpacity !== undefined ? Math.max(0.1, Math.min(1, state.infoBarOpacity)) : 0.82
    readonly property color glassBg: Qt.rgba(0.05, 0.10, 0.18, 0.82 * infoOpacity)
    readonly property color glassLine: Qt.rgba(1, 1, 1, 0.16)
    readonly property real leftPad: compactMode ? Math.max(2, Math.round(4 * hudScale)) : (theme ? theme.spacingXl : 16)
    readonly property real bottomPad: compactMode ? Math.max(2, Math.round(4 * hudScale)) : (theme ? theme.spacingXl : 16)
    readonly property real hudScale: theme ? theme.uiScale : 1
    readonly property real compassValueBarH: Math.round((compactMode ? 28 : 35) * root.hudScale)
    readonly property real instrumentGap: Math.round((compactMode ? 5 : 10) * root.hudScale)
    readonly property real qgcAndroidInstrumentSize: ScreenTools.defaultFontPixelHeight * 6.4
    readonly property real instrumentMaxSize: theme && theme.mobile ? root.qgcAndroidInstrumentSize : 172
    readonly property real instrumentMinSize: theme && theme.mobile ? root.qgcAndroidInstrumentSize * 0.92 : 96
    readonly property real computedInstrumentSize: Math.max(root.instrumentMinSize, Math.min(root.instrumentMaxSize, Math.min(root.width * 0.16, (root.height - root.bottomPad * 2 - root.instrumentGap - root.compassValueBarH) / 2)))
    readonly property real instrumentSize: root.instrumentSizeOverride > 0 ? root.instrumentSizeOverride : root.computedInstrumentSize
    readonly property real telemetryGap: Math.max(8, Math.round(18 * hudScale))
    readonly property real instrumentColumnW: root.leftPad + root.instrumentSize
    readonly property bool enoughSpaceForTelemetry: root.telemetryVisible && !root.compactMode && root.width > root.instrumentColumnW + root.telemetryGap + 240
    readonly property real telemetryPreferredWidth: root.telemetryWidthOverride > 0 ? root.telemetryWidthOverride : Math.round(430 * root.hudScale)
    readonly property real telemetryScale: Math.max(0.72, Math.min(1.0, root.telemetryScaleOverride))

    color: "transparent"

    Column {
        id: instrumentColumn
        anchors.left: parent.left
        anchors.leftMargin: root.leftPad
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bottomPad
        spacing: root.instrumentGap

        CompassWidget {
            id: compass
            size: root.instrumentSize
            heading: root.heading
            roll: root.roll
            pitch: root.pitch
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

    Rectangle {
        id: angleStrip
        visible: false
    }

    Rectangle {
        id: telemetryBar
        anchors.left: instrumentColumn.right
        anchors.leftMargin: root.telemetryGap
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bottomPad + Math.round(28 * root.hudScale * root.telemetryScale)
        visible: root.enoughSpaceForTelemetry
        width: Math.max(220, Math.min(root.telemetryPreferredWidth, root.width - instrumentColumn.x - instrumentColumn.width - root.telemetryGap - root.leftPad))
        height: Math.round(66 * root.hudScale * root.telemetryScale)
        radius: Math.round(8 * root.hudScale * root.telemetryScale)
        color: root.glassBg
        border.width: 1
        border.color: root.glassLine

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Math.round(16 * root.hudScale * root.telemetryScale)
            anchors.rightMargin: Math.round(16 * root.hudScale * root.telemetryScale)
            spacing: 0

            Column {
                Layout.fillWidth: true
                spacing: Math.round(5 * root.hudScale * root.telemetryScale)

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "飞行速度"
                    font.pixelSize: Math.max(9, Math.round(12 * root.hudScale * root.telemetryScale))
                    color: Qt.rgba(1, 1, 1, 0.82)
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.speedText
                    font.pixelSize: Math.max(12, Math.round(16 * root.hudScale * root.telemetryScale))
                    font.weight: Font.Bold
                    color: "#ffffff"
                }
            }

            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: root.glassLine }

            Column {
                Layout.fillWidth: true
                spacing: Math.round(4 * root.hudScale * root.telemetryScale)

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Math.round(5 * root.hudScale * root.telemetryScale)
                    Text { text: "纬度"; font.pixelSize: Math.max(9, Math.round(12 * root.hudScale * root.telemetryScale)); color: Qt.rgba(1, 1, 1, 0.82) }
                    Text { text: root.latText; font.pixelSize: Math.max(11, Math.round(15 * root.hudScale * root.telemetryScale)); font.weight: Font.Bold; color: "#ffffff" }
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Math.round(5 * root.hudScale * root.telemetryScale)
                    Text { text: "经度"; font.pixelSize: Math.max(9, Math.round(12 * root.hudScale * root.telemetryScale)); color: Qt.rgba(1, 1, 1, 0.82) }
                    Text { text: root.lonText; font.pixelSize: Math.max(11, Math.round(15 * root.hudScale * root.telemetryScale)); font.weight: Font.Bold; color: "#ffffff" }
                }
            }

            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: root.glassLine }

            Column {
                Layout.fillWidth: true
                spacing: Math.round(5 * root.hudScale * root.telemetryScale)

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "飞行高度"
                    font.pixelSize: Math.max(9, Math.round(12 * root.hudScale * root.telemetryScale))
                    color: Qt.rgba(1, 1, 1, 0.82)
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.altText
                    font.pixelSize: Math.max(12, Math.round(16 * root.hudScale * root.telemetryScale))
                    font.weight: Font.Bold
                    color: "#ffffff"
                }
            }
        }
    }
}
