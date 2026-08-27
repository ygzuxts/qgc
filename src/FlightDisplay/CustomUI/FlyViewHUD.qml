// FlyViewHUD.qml
// 起飞页左下角 HUD：罗盘、角度条、姿态仪、速度/经纬度/高度信息栏

import QtQuick
import QtQuick.Layouts

import QGroundControl.FlightMap

Rectangle {
    id: root

    property var state: null
    property var theme: null

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
    readonly property real leftPad: theme ? theme.spacingXl : 16
    readonly property real bottomPad: theme ? theme.spacingXl : 16

    color: "transparent"

    CompassWidget {
        id: compass
        anchors.left: parent.left
        anchors.leftMargin: root.leftPad
        anchors.bottom: attitude.top
        anchors.bottomMargin: 8
        size: 112
        heading: root.heading
        roll: root.roll
        pitch: root.pitch
        theme: root.theme
        infoBarOpacity: root.infoOpacity
    }

    Rectangle {
        id: angleStrip
        anchors.left: compass.left
        anchors.right: compass.right
        anchors.bottom: attitude.top
        anchors.bottomMargin: 8
        height: 28
        radius: 5
        color: root.glassBg
        visible: false

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            Repeater {
                model: [
                    { label: "横滚", value: root.fmt(root.roll, 1, "°") },
                    { label: "航向", value: root.fmt(root.heading, 0, "°") },
                    { label: "俯仰", value: root.fmt(root.pitch, 1, "°") }
                ]

                delegate: Column {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        font.pixelSize: 8
                        color: Qt.rgba(1, 1, 1, 0.72)
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.connected ? modelData.value : "0.0°"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: "#ffffff"
                    }
                }
            }
        }
    }

    QGCAttitudeWidget {
        id: attitude
        anchors.left: compass.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bottomPad
        size: 112
        vehicle: root.state ? root.state.activeVehicle : null
        showPitch: true
        showHeading: false
    }

    Rectangle {
        id: telemetryBar
        anchors.left: attitude.right
        anchors.leftMargin: 18
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bottomPad + 28
        width: 430
        height: 66
        radius: 8
        color: root.glassBg
        border.width: 1
        border.color: root.glassLine

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 0

            Column {
                Layout.fillWidth: true
                spacing: 5

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "飞行速度"
                    font.pixelSize: 12
                    color: Qt.rgba(1, 1, 1, 0.82)
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.speedText
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: "#ffffff"
                }
            }

            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: root.glassLine }

            Column {
                Layout.fillWidth: true
                spacing: 4

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 5
                    Text { text: "纬度"; font.pixelSize: 12; color: Qt.rgba(1, 1, 1, 0.82) }
                    Text { text: root.latText; font.pixelSize: 15; font.weight: Font.Bold; color: "#ffffff" }
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 5
                    Text { text: "经度"; font.pixelSize: 12; color: Qt.rgba(1, 1, 1, 0.82) }
                    Text { text: root.lonText; font.pixelSize: 15; font.weight: Font.Bold; color: "#ffffff" }
                }
            }

            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: root.glassLine }

            Column {
                Layout.fillWidth: true
                spacing: 5

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "飞行高度"
                    font.pixelSize: 12
                    color: Qt.rgba(1, 1, 1, 0.82)
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.altText
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: "#ffffff"
                }
            }
        }
    }
}
