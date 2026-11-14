// CompassWidget.qml
// 仿QGC风格罗盘，纯标准QML无QGC依赖

import QtQuick

Item {
    id: root

    width:  size
    height: size + valueBarHeight   // 底部留航向数值空间

    property real size:        180
    property real heading:     0
    property var  theme:       null
    property real infoBarOpacity: 1.0
    readonly property real valueBarHeight: Math.round(35 * (theme ? theme.uiScale : 1))

    // 颜色
    readonly property color _bgColor:     theme ? theme.surface  : "#ffffff"
    readonly property color _rimColor:    theme ? theme.border   : "#e4e8ed"
    readonly property color _textColor:   theme ? theme.text2    : "#5a6272"
    readonly property color _text3Color:  theme ? theme.text3    : "#9aa3b2"
    readonly property color _mainText:    theme ? theme.text     : "#1a1d23"

    // ── 表盘圆形底板 ──
    Rectangle {
        id: dialCircle
        width: root.size; height: root.size; radius: root.size / 2
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        color: root._bgColor
        border.color: root._rimColor
        border.width: 1.5

        // ── 旋转层（刻度盘随航向反向转，保持N朝上固定）──
        Item {
            id: dialRotation
            anchors.fill: parent
            rotation: 0   // 刻度盘固定不转，指针转

            // 刻度盘 Canvas
            Canvas {
                id: dialCanvas
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    var cx = width / 2, cy = height / 2
                    var r  = width / 2 - 4

                    // 主刻度（每10度）
                    for (var i = 0; i < 36; i++) {
                        var angle = (i * 10 - 90) * Math.PI / 180
                        var isMajor = (i % 9 === 0)  // N E S W
                        var inner = isMajor ? r - 14 : (i % 3 === 0 ? r - 10 : r - 6)
                        ctx.strokeStyle = isMajor ? "#9aa3b2" : "#d0d5de"
                        ctx.lineWidth   = isMajor ? 1.5 : 1
                        ctx.beginPath()
                        ctx.moveTo(cx + Math.cos(angle) * inner, cy + Math.sin(angle) * inner)
                        ctx.lineTo(cx + Math.cos(angle) * r,     cy + Math.sin(angle) * r)
                        ctx.stroke()
                    }

                    // 外圈
                    ctx.strokeStyle = "#e4e8ed"
                    ctx.lineWidth   = 1
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, 0, Math.PI * 2)
                    ctx.stroke()
                }
            }

            // N E S W 文字
            Repeater {
                model: [
                    { label: "N", angle: 0,   color: "#ef4444", bold: true  },
                    { label: "E", angle: 90,  color: "#5a6272", bold: false },
                    { label: "S", angle: 180, color: "#5a6272", bold: false },
                    { label: "W", angle: 270, color: "#5a6272", bold: false }
                ]
                delegate: Text {
                    property real _r: root.size / 2 - 20
                    property real _rad: (modelData.angle - 90) * Math.PI / 180
                    x: root.size / 2 + _r * Math.cos(_rad) - width  / 2
                    y: root.size / 2 + _r * Math.sin(_rad) - height / 2
                    text: modelData.label
                    font.pixelSize: Math.round(11 * (theme ? theme.uiScale : 1))
                    font.weight: modelData.bold ? Font.Bold : Font.Medium
                    color: modelData.color
                }
            }
        }

        // ── 红色指针（随航向旋转）──
        Item {
            id: needle
            anchors.fill: parent
            rotation: root.heading

            Canvas {
                id: needleCanvas
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    var cx = width / 2, cy = height / 2
                    var tipY   = cy - (root.size * 0.36)
                    var baseHW = root.size * 0.055
                    var baseY  = cy + (root.size * 0.18)
                    var midY   = cy + (root.size * 0.04)

                    ctx.fillStyle = "#ef4444"
                    ctx.beginPath()
                    ctx.moveTo(cx, tipY)
                    ctx.lineTo(cx + baseHW, midY)
                    ctx.lineTo(cx, cy)
                    ctx.lineTo(cx - baseHW, midY)
                    ctx.closePath()
                    ctx.fill()

                    ctx.fillStyle = "#ffffff"
                    ctx.strokeStyle = "#d0d5de"
                    ctx.lineWidth = 0.5
                    ctx.beginPath()
                    ctx.moveTo(cx, cy)
                    ctx.lineTo(cx + baseHW, midY)
                    ctx.lineTo(cx, baseY)
                    ctx.lineTo(cx - baseHW, midY)
                    ctx.closePath()
                    ctx.fill()
                    ctx.stroke()

                    ctx.fillStyle = "#ffffff"
                    ctx.strokeStyle = "#9aa3b2"
                    ctx.lineWidth = 1
                    ctx.beginPath()
                    ctx.arc(cx, cy, root.size * 0.045, 0, Math.PI * 2)
                    ctx.fill()
                    ctx.stroke()
                }
            }
        }

        // 中心点压顶
        Rectangle {
            anchors.centerIn: parent
            width: root.size * 0.07; height: width; radius: width / 2
            color: "#ffffff"
            border.color: "#c0c8d4"
            border.width: Math.round(1 * (theme ? theme.uiScale : 1))
        }
    }

    // 底部航向读数
    Rectangle {
        anchors.top: dialCircle.bottom
        anchors.topMargin: Math.round(5 * (theme ? theme.uiScale : 1))
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.valueBarHeight - Math.round(5 * (theme ? theme.uiScale : 1))
        radius: Math.round(6 * (theme ? theme.uiScale : 1))
        color: Qt.rgba(0.03, 0.05, 0.09, infoBarOpacity)

        Row {
            anchors.centerIn: parent
            spacing: Math.round(8 * (theme ? theme.uiScale : 1))

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Heading")
                font.pixelSize: Math.round(11 * (theme ? theme.uiScale : 1))
                color: Qt.rgba(1, 1, 1, 0.82)
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: (Math.round(((root.heading % 360) + 360) % 360) % 360) + "°"
                font.pixelSize: Math.round(19 * (theme ? theme.uiScale : 1))
                font.weight: Font.Bold
                color: "#ffffff"
            }
        }
    }
}
