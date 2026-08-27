import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Shapes 1.15

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Toolbar

// ============================================================
// FlightConsoleDemo.qml
// 一个"载人超轻飞行器 / 无人机地面站"风格的座舱屏 UI demo
// 设计定位：航空 PFD（姿态仪、空速/高度带）+ 汽车中控（地图卡片、
// 底部功能条、状态环）的混合体。纯 QtQuick 实现，无外部资源，
// 可直接用 qmlscene FlightConsoleDemo.qml 运行，或拖进 Qt Creator。
// ============================================================

Item {
    id: window
    anchors.fill: parent
    property bool lightMode: true

    Rectangle {
        anchors.fill: parent
        color: palette.bg
        z: -1
    }

    // ---------------- 配色 / 设计令牌 ----------------
    QtObject {
        id: palette
        readonly property color bg: window.lightMode ? "#edf1f5" : "#080B10"
        readonly property color panel: window.lightMode ? "#f8fafc" : "#0F151D"
        readonly property color panelBorder: window.lightMode ? "#cbd5e1" : "#1C2733"
        readonly property color overlay: window.lightMode ? Qt.rgba(1, 1, 1, 0.86) : Qt.rgba(0.06, 0.09, 0.13, 0.85)
        readonly property color overlayMuted: window.lightMode ? Qt.rgba(0.94, 0.97, 1.0, 0.86) : Qt.rgba(0.06, 0.09, 0.13, 0.75)
        readonly property color buttonIdle: window.lightMode ? Qt.rgba(0.90, 0.94, 0.98, 0.92) : Qt.rgba(0.1, 0.14, 0.18, 0.85)
        readonly property color takeoffReady: window.lightMode ? Qt.rgba(0.16, 0.47, 0.94, 0.14) : Qt.rgba(0.2, 0.88, 1.0, 0.16)
        readonly property color landReady: window.lightMode ? Qt.rgba(1.0, 0.29, 0.29, 0.12) : Qt.rgba(1.0, 0.29, 0.29, 0.14)
        readonly property color cyan: "#2977ef"
        readonly property color amber: "#884600"
        readonly property color red: "#FF4B4B"
        readonly property color green: window.lightMode ? "#118a4f" : "#39D98A"
        readonly property color textHi: window.lightMode ? "#142033" : "#EAF3FF"
        readonly property color textLo: window.lightMode ? "#64748b" : "#6E7E90"
        readonly property color tapeBg: window.lightMode ? "#eef2f6" : "#080B10"
    }

    // ---------------- 飞行数据 ----------------
    QtObject {
        id: telemetry

        property var activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
        property var batteryFactGroup: activeVehicle && activeVehicle.batteries && activeVehicle.batteries.count > 0 ? activeVehicle.batteries.get(0) : null

        property real roll: factValue(activeVehicle ? activeVehicle.vehicle.roll : null, 0)
        property real pitch: factValue(activeVehicle ? activeVehicle.vehicle.pitch : null, 0)
        property real airspeed: factValue(activeVehicle ? activeVehicle.vehicle.airSpeed : null,
                                        factValue(activeVehicle ? activeVehicle.vehicle.groundSpeed : null, 0))
        property real altitude: factValue(activeVehicle ? activeVehicle.vehicle.altitudeRelative : null, 0)
        property real altitudeAMSL: factValue(activeVehicle ? activeVehicle.vehicle.altitudeAMSL : null, 0)
        property real vspeed: factValue(activeVehicle ? activeVehicle.vehicle.climbRate : null, 0)
        property real flightTime: factValue(activeVehicle ? activeVehicle.vehicle.flightTime : null, 0)
        property int battery: Math.round(factValue(batteryFactGroup ? batteryFactGroup.percentRemaining : null, 0))
        property var motorLoad: [0.62, 0.58, 0.71, 0.55, 0.66, 0.60]
        property var motorTemp: [46, 44, 52, 41, 48, 45]
        property int gpsSat: Math.round(factValue(activeVehicle ? activeVehicle.gps.count : null, 0))
        property string flightMode: activeVehicle ? activeVehicle.flightMode : "未连接"
        property string displayMode: activeVehicle ? activeVehicle.flightMode : "未连接"
        property real heading: factValue(activeVehicle ? activeVehicle.vehicle.heading : null, 0)
        property var guidedController: globals.guidedControllerFlyView
        property date localTime: new Date()

        function factValue(fact, fallback) {
            if (!fact) {
                return fallback
            }

            var value = fact.rawValue
            return isNaN(value) ? fallback : value
        }

        function formatElapsed(seconds) {
            var total = Math.max(0, Math.floor(seconds))
            var minutes = Math.floor(total / 60)
            var secs = total % 60

            return String(minutes).padStart(2, "0") + ":" +
                   String(secs).padStart(2, "0")
        }
    }

    Timer {
        interval: 60; running: false; repeat: true
        property real t: 0
        onTriggered: {
            t += 0.03
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: telemetry.localTime = new Date()
    }

    // ================= 顶部状态条 =================
    Rectangle {
        id: topBar
        width: parent.width; height: 46
        color: palette.panel
        border.color: palette.panelBorder; border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20; anchors.rightMargin: 20
            spacing: 24

            Text { text: "future"; color: palette.cyan; font.pixelSize: 16; font.bold: true }
            Rectangle { width: 1; height: 20; color: palette.panelBorder }

            Text { text: telemetry.flightMode; color: palette.textHi; font.pixelSize: 13 }

            Item { Layout.fillWidth: true }

            Item {
                Layout.preferredWidth: Math.max(indicatorRow.implicitWidth, lightIndicatorRow.implicitWidth)
                Layout.preferredHeight: 30
                Layout.alignment: Qt.AlignVCenter

                Row {
                    id: indicatorRow
                    visible: !window.lightMode
                    anchors.centerIn: parent
                    height: parent.height - 8
                    spacing: 10

                    VehicleGPSIndicator {
                        height: parent.height
                    }

                    APMBatteryIndicator {
                        height: parent.height
                    }
                }

                Row {
                    id: lightIndicatorRow
                    visible: window.lightMode
                    anchors.centerIn: parent
                    spacing: 14

                    Row {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter

                        QGCColoredImage {
                            width: 18
                            height: 18
                            anchors.verticalCenter: parent.verticalCenter
                            source: "/qmlimages/Gps.svg"
                            fillMode: Image.PreserveAspectFit
                            color: palette.textHi
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: telemetry.gpsSat
                            color: palette.textHi
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }

                    Row {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter

                        QGCColoredImage {
                            width: 18
                            height: 18
                            anchors.verticalCenter: parent.verticalCenter
                            source: "/qmlimages/Battery.svg"
                            fillMode: Image.PreserveAspectFit
                            color: palette.textHi
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.max(0, Math.min(100, telemetry.battery)) + "%"
                            color: palette.textHi
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                }
            }

            Text {
                text: Qt.formatTime(telemetry.localTime, "hh:mm")
                color: palette.textHi; font.pixelSize: 13
            }

            Rectangle {
                Layout.preferredWidth: 58
                Layout.preferredHeight: 28
                radius: 14
                color: palette.buttonIdle
                border.color: palette.panelBorder

                Text {
                    anchors.centerIn: parent
                    text: window.lightMode ? "深色" : "浅色"
                    color: palette.textHi
                    font.pixelSize: 12
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: window.lightMode = !window.lightMode
                }
            }
        }
    }

    // ================= 主体单面板仪表布局 =================
    Rectangle {
        anchors.top: topBar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        color: palette.panel
        radius: 10
        border.color: palette.panelBorder
        clip: true

        Item {
            anchors.fill: parent
            anchors.margins: Math.max(18, parent.height * 0.04)

            Column {
                width: Math.max(150, parent.width * 0.20)
                anchors.horizontalCenter: parent.left
                anchors.horizontalCenterOffset: parent.width * 0.16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: telemetry.airspeed.toFixed(0)
                    color: palette.cyan
                    font.pixelSize: Math.min(104, Math.max(64, window.width * 0.085))
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "速度 km/h"
                    color: palette.textLo
                    font.pixelSize: 15
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: (telemetry.vspeed >= 0 ? "↑ +" : "↓ ") + telemetry.vspeed.toFixed(1) + " m/s"
                    color: telemetry.vspeed >= 0 ? palette.cyan : palette.amber
                    font.pixelSize: 20
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "垂直速度"
                    color: palette.textLo
                    font.pixelSize: 13
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 10

                Item {
                    width: Math.min(window.width * 0.28, window.height * 0.52)
                    height: width
                    anchors.horizontalCenter: parent.horizontalCenter

                    InstrumentsArtificialHorizon {
                        anchors.fill: parent
                        roll: telemetry.roll
                        pitch: telemetry.pitch
                        pitchScale: 30
                    }
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 3

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "飞行时间"
                        color: palette.textLo
                        font.pixelSize: 12
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: telemetry.activeVehicle ? telemetry.formatElapsed(telemetry.flightTime) : "--:--"
                        color: palette.textHi
                        font.family: "Consolas"
                        font.pixelSize: 34
                        font.bold: true
                    }
                }
            }

            Column {
                width: Math.max(150, parent.width * 0.20)
                anchors.horizontalCenter: parent.right
                anchors.horizontalCenterOffset: -parent.width * 0.16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: telemetry.altitude.toFixed(0)
                    color: palette.amber
                    font.pixelSize: Math.min(104, Math.max(64, window.width * 0.085))
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "高度 m"
                    color: palette.textLo
                    font.pixelSize: 15
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: telemetry.activeVehicle ? telemetry.altitudeAMSL.toFixed(0) + " m" : "-- m"
                    color: palette.amber
                    font.pixelSize: 20
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "海拔"
                    color: palette.textLo
                    font.pixelSize: 13
                }
            }
        }
    }

    // ============================================================
    // 组件定义
    // ============================================================

    // ---- 姿态仪（人工地平仪） ----
    component AttitudeIndicator: Item {
        property real roll: 0
        property real pitch: 0
        Canvas {
            id: cv
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                var w = width, h = height
                ctx.clearRect(0, 0, w, h)
                var cx = w / 2, cy = h / 2
                var r = Math.min(w, h) / 2 - 4

                ctx.save()
                ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.clip()

                ctx.translate(cx, cy)
                ctx.rotate(-roll * Math.PI / 180)
                var pOff = pitch * 3

                // 天空
                ctx.fillStyle = "#1B3A5C"
                ctx.fillRect(-w, -h + pOff, w * 2, h * 2)
                // 地面
                ctx.fillStyle = "#3C2B18"
                ctx.fillRect(-w, pOff, w * 2, h * 2)
                // 地平线
                ctx.strokeStyle = palette.textHi
                ctx.lineWidth = 2
                ctx.beginPath(); ctx.moveTo(-w, pOff); ctx.lineTo(w, pOff); ctx.stroke()

                // 俯仰刻度线
                ctx.strokeStyle = "#9FB4C8"
                ctx.lineWidth = 1
                for (var d = -30; d <= 30; d += 10) {
                    if (d === 0) continue
                    var yy = pOff - d * 3
                    var lw = (d % 20 === 0) ? 30 : 16
                    ctx.beginPath(); ctx.moveTo(-lw, yy); ctx.lineTo(lw, yy); ctx.stroke()
                }
                ctx.restore()

                // 固定的飞机符号（不随横滚旋转）
                ctx.strokeStyle = palette.amber
                ctx.lineWidth = 3
                ctx.beginPath()
                ctx.moveTo(cx - 40, cy); ctx.lineTo(cx - 12, cy)
                ctx.moveTo(cx + 12, cy); ctx.lineTo(cx + 40, cy)
                ctx.stroke()
                ctx.beginPath(); ctx.arc(cx, cy, 3, 0, Math.PI * 2)
                ctx.fillStyle = palette.amber; ctx.fill()

                // 外圈
                ctx.strokeStyle = palette.panelBorder
                ctx.lineWidth = 2
                ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.stroke()

                // 横滚角标签
                ctx.fillStyle = palette.textLo
                ctx.font = "11px sans-serif"
                ctx.textAlign = "center"
                ctx.fillText("ROLL " + roll.toFixed(0) + "°", cx, cy + r - 8)
            }
        }
        onRollChanged: cv.requestPaint()
        onPitchChanged: cv.requestPaint()
    }

    // ---- 空速 / 高度带（竖直滚动式数字条） ----
    component TapeGauge: Rectangle {
        property real value: 0
        property string unit: ""
        property color accent: "#33E1FF"
        color: palette.tapeBg
        radius: 6
        border.color: palette.panelBorder

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: value.toFixed(0)
                color: accent
                font.pixelSize: 20
                font.bold: true
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: unit
                color: palette.textLo
                font.pixelSize: 10
            }
        }
        Rectangle {
            width: 3; height: parent.height * 0.5
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: accent
            opacity: 0.5
        }
    }

    // ---- 电池环形量表 ----
    component BatteryRing: Item {
        property real value: 0
        width: 140; height: 140
        Canvas {
            id: ring
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                var w = width, h = height, cx = w/2, cy = h/2, r = w/2 - 8
                ctx.clearRect(0,0,w,h)
                ctx.lineWidth = 10
                ctx.lineCap = "round"

                ctx.strokeStyle = palette.panelBorder
                ctx.beginPath()
                ctx.arc(cx, cy, r, Math.PI*0.75, Math.PI*2.25)
                ctx.stroke()

                var col = value > 30 ? palette.green : palette.red
                var frac = value/100
                ctx.strokeStyle = col
                ctx.beginPath()
                ctx.arc(cx, cy, r, Math.PI*0.75, Math.PI*0.75 + frac*Math.PI*1.5)
                ctx.stroke()
            }
        }
        onValueChanged: ring.requestPaint()
        Column {
            anchors.centerIn: parent
            spacing: 0
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Math.round(value) + "%"
                color: palette.textHi
                font.pixelSize: 26; font.bold: true
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "BATTERY"
                color: palette.textLo
                font.pixelSize: 10
            }
        }
    }
}
