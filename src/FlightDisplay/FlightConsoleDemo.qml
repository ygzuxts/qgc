import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Shapes 1.15

import QGroundControl

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

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        z: -1
    }

    // ---------------- 配色 / 设计令牌 ----------------
    QtObject {
        id: palette
        readonly property color bg: "#080B10"
        readonly property color panel: "#0F151D"
        readonly property color panelBorder: "#1C2733"
        readonly property color cyan: "#33E1FF"
        readonly property color amber: "#FFB238"
        readonly property color red: "#FF4B4B"
        readonly property color green: "#39D98A"
        readonly property color textHi: "#EAF3FF"
        readonly property color textLo: "#6E7E90"
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
        property real vspeed: factValue(activeVehicle ? activeVehicle.vehicle.climbRate : null, 0)
        property int battery: Math.round(factValue(batteryFactGroup ? batteryFactGroup.percentRemaining : null, 0))
        property real voltage: factValue(batteryFactGroup ? batteryFactGroup.voltage : null, 0)
        property real current: factValue(batteryFactGroup ? batteryFactGroup.current : null, 0)
        property var motorLoad: [0.62, 0.58, 0.71, 0.55, 0.66, 0.60]
        property var motorTemp: [46, 44, 52, 41, 48, 45]
        property int gpsSat: Math.round(factValue(activeVehicle ? activeVehicle.gps.count : null, 0))
        property int linkLevel: 4 // 0-5
        property string flightMode: activeVehicle ? activeVehicle.flightMode : "未连接"
        property string displayMode: activeVehicle ? activeVehicle.flightMode : "未连接"
        property real heading: factValue(activeVehicle ? activeVehicle.vehicle.heading : null, 0)
        property var guidedController: globals.guidedControllerFlyView

        function factValue(fact, fallback) {
            if (!fact) {
                return fallback
            }

            var value = fact.rawValue
            return isNaN(value) ? fallback : value
        }
    }

    Timer {
        interval: 60; running: false; repeat: true
        property real t: 0
        onTriggered: {
            t += 0.03
        }
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

            // GPS
            RowLayout {
                spacing: 6
                Text { text: "GPS"; color: palette.textLo; font.pixelSize: 12 }
                Text { text: telemetry.gpsSat + " 星"; color: palette.green; font.pixelSize: 13; font.bold: true }
            }

            // 图传/数链信号条
            RowLayout {
                spacing: 3
                Repeater {
                    model: 5
                    Rectangle {
                        width: 4
                        height: 6 + index * 3
                        radius: 1
                        color: index < telemetry.linkLevel ? palette.cyan : palette.panelBorder
                        anchors.bottom: parent.bottom
                    }
                }
            }

            Text {
                text: Qt.formatTime(new Date(), "hh:mm")
                color: palette.textHi; font.pixelSize: 13
            }
        }
    }

    // ================= 主体三栏布局 =================
    RowLayout {
        anchors.top: topBar.bottom
        anchors.bottom: bottomBar.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        spacing: 12

        // ---------- 左栏：航空式 PFD（姿态仪 + 空速/高度带） ----------
        Rectangle {
            Layout.preferredWidth: 320
            Layout.fillHeight: true
            color: palette.panel
            radius: 10
            border.color: palette.panelBorder

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                // 空速带
                TapeGauge {
                    Layout.preferredWidth: 54
                    Layout.fillHeight: true
                    value: telemetry.airspeed
                    unit: "km/h"
                    accent: palette.cyan
                }

                // 姿态仪
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    InstrumentsArtificialHorizon {
                        width: Math.min(parent.width * 0.85, parent.height * 0.7)
                        height: width
                        anchors.centerIn: parent
                        roll: telemetry.roll
                        pitch: telemetry.pitch
                        pitchScale: 30
                    }
                }

                // 高度带
                TapeGauge {
                    Layout.preferredWidth: 54
                    Layout.fillHeight: true
                    value: telemetry.altitude
                    unit: "m"
                    accent: palette.amber
                }
            }
        }

        // ---------- 中栏：汽车式中控地图卡片 ----------
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            radius: 10
            border.color: "transparent"
            clip: true

            // 网格背景，模拟地图
            Canvas {
                visible: false
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.strokeStyle = "#152230"
                    ctx.lineWidth = 1
                    var step = 36
                    for (var x = 0; x < width; x += step) {
                        ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke()
                    }
                    for (var y = 0; y < height; y += step) {
                        ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke()
                    }
                }
            }

            // 规划航线（虚线）
            Shape {
                visible: false
                anchors.fill: parent
                ShapePath {
                    strokeColor: palette.cyan
                    strokeWidth: 2
                    fillColor: "transparent"
                    strokeStyle: ShapePath.DashLine
                    dashPattern: [4, 3]
                    startX: 60; startY: 260
                    PathLine { x: 220; y: 150 }
                    PathLine { x: 420; y: 190 }
                    PathLine { x: 560; y: 90 }
                }
            }

            // 航点
            Repeater {
                model: [ {x:60,y:260}, {x:220,y:150}, {x:420,y:190}, {x:560,y:90} ]
                Rectangle {
                    visible: false
                    x: modelData.x - 5; y: modelData.y - 5
                    width: 10; height: 10; radius: 5
                    color: palette.bg
                    border.color: palette.amber; border.width: 2
                }
            }

            // 自身位置图标（带航向指向）
            Item {
                visible: false
                x: 300; y: 320
                width: 28; height: 28
                rotation: telemetry.heading
                Shape {
                    anchors.fill: parent
                    ShapePath {
                        fillColor: palette.cyan
                        strokeColor: "transparent"
                        startX: 14; startY: 0
                        PathLine { x: 26; y: 26 }
                        PathLine { x: 14; y: 19 }
                        PathLine { x: 2; y: 26 }
                        PathLine { x: 14; y: 0 }
                    }
                }
            }

            // 中栏左上角：飞行/图传缩略信息卡（悬浮卡片，汽车中控常见样式）
            Rectangle {
                anchors.top: parent.top; anchors.left: parent.left
                anchors.margins: 12
                width: 168; height: 64
                radius: 8
                color: Qt.rgba(0.06, 0.09, 0.13, 0.85)
                border.color: palette.panelBorder
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 2
                    Text { text: "垂直速度"; color: palette.textLo; font.pixelSize: 11 }
                    Text {
                        text: (telemetry.vspeed >= 0 ? "+" : "") + telemetry.vspeed.toFixed(1) + " m/s"
                        color: palette.textHi; font.pixelSize: 18; font.bold: true
                    }
                }
            }
        }

        // ---------- 右栏：汽车式状态环 + 电机监控（EV仪表既视感） ----------
        Rectangle {
            Layout.preferredWidth: 260
            Layout.fillHeight: true
            color: palette.panel
            radius: 10
            border.color: palette.panelBorder

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                // 电池环形量表
                BatteryRing {
                    Layout.alignment: Qt.AlignHCenter
                    value: telemetry.battery
                }

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "电压"; color: palette.textLo; font.pixelSize: 11 }
                        Text { text: telemetry.voltage.toFixed(1) + " V"; color: palette.textHi; font.pixelSize: 15; font.bold: true }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "电流"; color: palette.textLo; font.pixelSize: 11 }
                        Text { text: telemetry.current.toFixed(1) + " A"; color: palette.textHi; font.pixelSize: 15; font.bold: true }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: palette.panelBorder }

                Text { text: "起飞 / 降落"; color: palette.textLo; font.pixelSize: 11 }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        radius: 8
                        color: telemetry.guidedController && telemetry.guidedController.showTakeoff ? Qt.rgba(0.2, 0.88, 1.0, 0.16) : Qt.rgba(0.1, 0.14, 0.18, 0.85)
                        border.color: telemetry.guidedController && telemetry.guidedController.showTakeoff ? palette.cyan : palette.panelBorder
                        opacity: telemetry.guidedController && telemetry.guidedController.showTakeoff ? 1.0 : 0.55

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 8

                            Text { text: "↗"; color: palette.cyan; font.pixelSize: 18; font.bold: true }
                            Text {
                                Layout.fillWidth: true
                                text: telemetry.guidedController ? telemetry.guidedController.takeoffTitle : "起飞"
                                color: palette.textHi
                                font.pixelSize: 14
                                font.bold: true
                            }
                            Text {
                                text: telemetry.guidedController && telemetry.guidedController.showTakeoff ? "READY" : "LOCKED"
                                color: telemetry.guidedController && telemetry.guidedController.showTakeoff ? palette.cyan : palette.textLo
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: telemetry.guidedController && telemetry.guidedController.showTakeoff
                            onClicked: telemetry.guidedController.confirmAction(telemetry.guidedController.actionTakeoff)
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        radius: 8
                        color: telemetry.guidedController && telemetry.guidedController.showLand ? Qt.rgba(1.0, 0.29, 0.29, 0.14) : Qt.rgba(0.1, 0.14, 0.18, 0.85)
                        border.color: telemetry.guidedController && telemetry.guidedController.showLand ? palette.red : palette.panelBorder
                        opacity: telemetry.guidedController && telemetry.guidedController.showLand ? 1.0 : 0.55

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 8

                            Text { text: "↘"; color: palette.red; font.pixelSize: 18; font.bold: true }
                            Text {
                                Layout.fillWidth: true
                                text: telemetry.guidedController ? telemetry.guidedController.landTitle : "降落"
                                color: palette.textHi
                                font.pixelSize: 14
                                font.bold: true
                            }
                            Text {
                                text: telemetry.guidedController && telemetry.guidedController.showLand ? "READY" : "LOCKED"
                                color: telemetry.guidedController && telemetry.guidedController.showLand ? palette.red : palette.textLo
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: telemetry.guidedController && telemetry.guidedController.showLand
                            onClicked: telemetry.guidedController.confirmAction(telemetry.guidedController.actionLand)
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 8
                        color: Qt.rgba(0.06, 0.09, 0.13, 0.75)
                        border.color: palette.panelBorder

                        Text {
                            anchors.centerIn: parent
                            text: telemetry.activeVehicle ? "飞控状态 · " + telemetry.flightMode : "等待飞控连接"
                            color: palette.textLo
                            font.pixelSize: 11
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }

    // ================= 底部功能条（汽车中控常见的快捷操作条） =================
    Rectangle {
        id: bottomBar
        width: parent.width; height: 64
        anchors.bottom: parent.bottom
        color: palette.panel
        border.color: palette.panelBorder

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16; anchors.rightMargin: 16
            spacing: 10

            // 飞行模式切换（体验 / 玩家 / 自动）
            RowLayout {
                spacing: 6
                Repeater {
                    model: ["体验模式", "玩家模式", "自动模式"]
                    Rectangle {
                        width: 92; height: 38; radius: 8
                        color: telemetry.displayMode === modelData ? palette.cyan : "transparent"
                        border.color: telemetry.displayMode === modelData ? palette.cyan : palette.panelBorder
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 12
                            color: telemetry.displayMode === modelData ? palette.bg : palette.textHi
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // 一键返航（关键操作，红色高亮，圆角大按钮，符合应急操作的可达性设计）
            Rectangle {
                width: 130; height: 40; radius: 20
                color: Qt.rgba(1, 0.29, 0.29, 0.12)
                border.color: palette.red; border.width: 1.5
                Text {
                    anchors.centerIn: parent
                    text: "⟲ 一键返航"
                    color: palette.red
                    font.pixelSize: 13; font.bold: true
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
        color: palette.bg
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
