// AttitudeHUD.qml
// 仿QGC风格HUD姿态仪
// 纯标准QML，无QGC依赖

import QtQuick

Item {
    id: root

    property var theme: null

    width:  320
    height: Math.round(240 * (theme ? theme.uiScale : 1))

    // ── 外部输入属性 ──
    property real pitch:       0       // 俯仰角 deg，正值抬头
    property real roll:        0       // 横滚角 deg
    property real heading:     0       // 航向 deg  0=北
    property real airspeed:    0       // 空速 m/s
    property real altitude:    0       // 高度 m
    property bool connected:   false   // 是否连接
    property real _animatedPitch:    0
    property real _animatedRoll:     0
    property real _animatedHeading:  0
    property real _animatedAirspeed: 0
    property real _animatedAltitude: 0

    // ── 内部常量 ──
    readonly property real _displayPitch:    (root.connected && root._animatedPitch === root._animatedPitch) ? root._animatedPitch : 0
    readonly property real _displayRoll:     (root.connected && root._animatedRoll === root._animatedRoll) ? root._animatedRoll : 0
    readonly property real _displayHeading:  (root.connected && root._animatedHeading === root._animatedHeading) ? root._animatedHeading : 0
    readonly property real _displayAirspeed: (root.connected && root._animatedAirspeed === root._animatedAirspeed) ? root._animatedAirspeed : 0
    readonly property real _displayAltitude: (root.connected && root._animatedAltitude === root._animatedAltitude) ? root._animatedAltitude : 0
    readonly property real _visiblePitch: Math.max(-85, Math.min(90, root._normalize180(root._displayPitch)))
    readonly property real _visibleRoll: root._normalize180(root._displayRoll)
    readonly property real _pitchPixPerDeg: height / 34
    readonly property color _skyColor:    "#15c3ed"
    readonly property color _skyColorTop: "#15c3ed"
    readonly property color _skyColorMid: "#15c3ed"
    readonly property color _groundColor: "#ad9b32"
    readonly property color _groundColorMid: "#ad9b32"
    readonly property color _lineColor:   Qt.rgba(1,1,1,.35)
    readonly property color _textColor:   Qt.rgba(1,1,1,.7)
    readonly property color _panelBg:     Qt.rgba(0,0,0,.45)
    readonly property int   _tapeW:       44
    readonly property int _headingTickCount: 25
    readonly property int _valueTickRadius: 12
    readonly property color _accentColor: "#0074bd"

    function _normalizeHeading(deg) {
        var normalized = Math.round(deg) % 360
        if (normalized < 0) {
            normalized += 360
        }
        return normalized
    }

    function _normalize180(deg) {
        var normalized = deg % 360
        if (normalized > 180) {
            normalized -= 360
        } else if (normalized < -180) {
            normalized += 360
        }
        return normalized
    }

    function _closestAngle(currentValue, targetValue) {
        var currentNorm = ((currentValue % 360) + 360) % 360
        var targetNorm = ((targetValue % 360) + 360) % 360
        var delta = targetNorm - currentNorm
        if (delta > 180) {
            delta -= 360
        } else if (delta < -180) {
            delta += 360
        }
        return currentValue + delta
    }

    function _headingLabel(deg) {
        if (deg === 0) {
            return "N"
        } else if (deg === 90) {
            return "E"
        } else if (deg === 180) {
            return "S"
        } else if (deg === 270) {
            return "W"
        }
        return String(deg)
    }

    function _boundedTickValue(centerValue, offset, minValue, maxValue) {
        var center = Math.round(centerValue)
        if (center !== center) {
            center = minValue
        }
        return Math.max(minValue, Math.min(maxValue, center + offset))
    }

    function _syncAnimatedValues() {
        if (!connected) {
            _animatedPitch = 0
            _animatedRoll = 0
            _animatedHeading = 0
            _animatedAirspeed = 0
            _animatedAltitude = 0
            return
        }

        if (pitch === pitch) {
            _animatedPitch = pitch
        }
        if (roll === roll) {
            _animatedRoll = roll
        }
        if (heading === heading) {
            _animatedHeading = _closestAngle(_animatedHeading, heading)
        }
        if (airspeed === airspeed) {
            _animatedAirspeed = airspeed
        }
        if (altitude === altitude) {
            _animatedAltitude = altitude
        }
    }

    onConnectedChanged: _syncAnimatedValues()
    onPitchChanged: if (connected) _animatedPitch = pitch
    onRollChanged: if (connected) _animatedRoll = roll
    onHeadingChanged: if (connected) _animatedHeading = _closestAngle(_animatedHeading, heading)
    onAirspeedChanged: if (connected) _animatedAirspeed = airspeed
    onAltitudeChanged: if (connected) _animatedAltitude = altitude
    Component.onCompleted: _syncAnimatedValues()

    Behavior on _animatedPitch {
        NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
    }
    Behavior on _animatedRoll {
        NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
    }
    Behavior on _animatedHeading {
        NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
    }
    Behavior on _animatedAirspeed {
        NumberAnimation { duration: 110; easing.type: Easing.OutQuad }
    }
    Behavior on _animatedAltitude {
        NumberAnimation { duration: 110; easing.type: Easing.OutQuad }
    }

    // ── 裁剪容器 ──
    Rectangle {
        id: clipRect
        anchors.fill: parent
        clip: true
        color: "transparent"

        // ════════════════
        // 航向带（顶部固定）
        // ════════════════
        Rectangle {
            id: headingTape
            anchors.top:   parent.top
            anchors.left:  parent.left
            anchors.right: parent.right
            height: Math.round(28 * (theme ? theme.uiScale : 1))
            color: root._panelBg

            // 滚动刻度
            Item {
                anchors.fill: parent
                clip: true

                Item {
                    anchors.fill: parent

                    Repeater {
                        model: root._headingTickCount
                        delegate: Item {
                            readonly property int offsetDeg: (index - Math.floor(root._headingTickCount / 2)) * 5
                            readonly property int tickDeg: root._normalizeHeading(root._displayHeading + offsetDeg)
                            width: headingTape.width / 12
                            height: headingTape.height
                            x: headingTape.width / 2 + (offsetDeg * (headingTape.width / 120)) - width / 2

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 4
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: Math.round(1 * (theme ? theme.uiScale : 1))
                                height: tickDeg % 10 === 0 ? 10 : 5
                                color: root._lineColor
                            }
                            Text {
                                visible: tickDeg % 10 === 0
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 16
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root._headingLabel(tickDeg)
                                font.pixelSize: Math.round(9 * (theme ? theme.uiScale : 1))
                                font.weight: (tickDeg === 0 || tickDeg === 90 || tickDeg === 180 || tickDeg === 270) ? Font.Bold : Font.Normal
                                color: tickDeg === 0 ? "#ef4444" : root._textColor
                            }
                        }
                    }
                }
            }

            // 中心指针
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: Math.round(10 * (theme ? theme.uiScale : 1)); height: Math.round(10 * (theme ? theme.uiScale : 1))
                Rectangle {
                    width: Math.round(0 * (theme ? theme.uiScale : 1)); height: Math.round(0 * (theme ? theme.uiScale : 1))
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    // 三角指针
                    Canvas {
                        width: Math.round(10 * (theme ? theme.uiScale : 1)); height: Math.round(8 * (theme ? theme.uiScale : 1))
                        x: -5
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.fillStyle = "#ffffff"
                            ctx.beginPath()
                            ctx.moveTo(5, 0)
                            ctx.lineTo(0, 8)
                            ctx.lineTo(10, 8)
                            ctx.closePath()
                            ctx.fill()
                        }
                    }
                }
            }

            // 当前航向数值框
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -1
                width: Math.round(36 * (theme ? theme.uiScale : 1)); height: Math.round(16 * (theme ? theme.uiScale : 1))
                color: "#1a2a3a"
                border.color: Qt.rgba(1,1,1,.3)
                border.width: Math.round(1 * (theme ? theme.uiScale : 1))
                Text {
                    anchors.centerIn: parent
                    text: Math.round(root._displayHeading)
                    font.pixelSize: Math.round(9 * (theme ? theme.uiScale : 1)); font.weight: Font.Bold
                    color: "#ffffff"
                }
            }
        }

        // ════════════════
        // 中央姿态视窗：背景层 + 俯仰刻度层
        // ════════════════
        Item {
            id: attitudeViewport
            anchors.top: headingTape.bottom
            anchors.bottom: bottomBar.top
            anchors.left: aspdTape.right
            anchors.right: altTape.left
            clip: true

            Item {
                id: worldLayer
                width: attitudeViewport.width * 4
                height: attitudeViewport.height * 4
                anchors.centerIn: parent
                transform: [
                    Translate {
                        y: root._visiblePitch * root._pitchPixPerDeg
                    },
                    Rotation {
                        origin.x: worldLayer.width / 2
                        origin.y: worldLayer.height / 2
                        angle: -root._visibleRoll
                    }
                ]

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: root._skyColorTop }
                        GradientStop { position: 0.48; color: root._skyColorMid }
                        GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.75) }
                        GradientStop { position: 0.52; color: root._groundColorMid }
                        GradientStop { position: 1.0; color: root._groundColor }
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: Math.round(2 * (theme ? theme.uiScale : 1))
                    color: Qt.rgba(1, 1, 1, 0.8)
                }

                Repeater {
                    model: [-30, -20, -15, -10, -5, 0, 5, 10, 15, 20, 30]

                    delegate: Item {
                        width: Math.max(120, attitudeViewport.width * 0.62)
                        height: Math.round(18 * (theme ? theme.uiScale : 1))
                        x: (worldLayer.width - width) / 2
                        y: worldLayer.height / 2 - (modelData * root._pitchPixPerDeg) - height / 2

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: modelData === 0 ? parent.width : (Math.abs(modelData) % 10 === 0 ? parent.width * 0.72 : parent.width * 0.4)
                            height: modelData === 0 ? 2 : 1
                            color: Qt.rgba(1, 1, 1, modelData === 0 ? 0.85 : 0.58)
                        }

                        Text {
                            visible: modelData !== 0
                            anchors.right: parent.horizontalCenter
                            anchors.rightMargin: (Math.abs(modelData) % 10 === 0 ? 56 : 28)
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.abs(modelData)
                            font.pixelSize: Math.round(9 * (theme ? theme.uiScale : 1))
                            font.weight: Font.Medium
                            color: Qt.rgba(1, 1, 1, 0.82)
                        }

                        Text {
                            visible: modelData !== 0
                            anchors.left: parent.horizontalCenter
                            anchors.leftMargin: (Math.abs(modelData) % 10 === 0 ? 56 : 28)
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.abs(modelData)
                            font.pixelSize: Math.round(9 * (theme ? theme.uiScale : 1))
                            font.weight: Font.Medium
                            color: Qt.rgba(1, 1, 1, 0.82)
                        }
                    }
                }
            }

            // 固定前景：横滚刻度弧
            Canvas {
                id: rollScale
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 4
                width: Math.min(parent.width * 0.9, 190)
                height: Math.round(54 * (theme ? theme.uiScale : 1))

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    var cx = width / 2
                    var cy = height + 18
                    var radius = width * 0.38
                    var marks = [-60, -45, -30, -20, -10, 0, 10, 20, 30, 45, 60]

                    ctx.strokeStyle = "rgba(255,255,255,0.72)"
                    ctx.lineWidth = 1.5
                    ctx.beginPath()
                    ctx.arc(cx, cy, radius, Math.PI * 1.16, Math.PI * 1.84)
                    ctx.stroke()

                    for (var i = 0; i < marks.length; i++) {
                        var deg = marks[i]
                        var rad = (deg - 90) * Math.PI / 180
                        var outerR = radius
                        var innerR = radius - (deg % 30 === 0 ? 12 : 7)
                        ctx.beginPath()
                        ctx.moveTo(cx + Math.cos(rad) * innerR, cy + Math.sin(rad) * innerR)
                        ctx.lineTo(cx + Math.cos(rad) * outerR, cy + Math.sin(rad) * outerR)
                        ctx.stroke()
                    }
                }
            }

            // 固定前景：顶部红色三角和横滚数值
            Item {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 2
                width: Math.round(48 * (theme ? theme.uiScale : 1))
                height: Math.round(26 * (theme ? theme.uiScale : 1))

                Canvas {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.round(12 * (theme ? theme.uiScale : 1))
                    height: Math.round(10 * (theme ? theme.uiScale : 1))
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        ctx.fillStyle = "#ff3b30"
                        ctx.beginPath()
                        ctx.moveTo(width / 2, height)
                        ctx.lineTo(0, 0)
                        ctx.lineTo(width, 0)
                        ctx.closePath()
                        ctx.fill()
                    }
                }

                Text {
                    anchors.top: parent.top
                    anchors.topMargin: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Math.round(root._displayRoll)
                    font.pixelSize: Math.round(10 * (theme ? theme.uiScale : 1))
                    font.weight: Font.Bold
                    color: "#ffffff"
                }
            }

            // 固定前景：中心飞机机身参考
            Item {
                anchors.centerIn: parent

                Rectangle {
                    x: -42; y: -1; width: Math.round(20 * (theme ? theme.uiScale : 1)); height: Math.round(2 * (theme ? theme.uiScale : 1))
                    color: root._accentColor; radius: 1
                }

                Rectangle {
                    x: 22; y: -1; width: Math.round(20 * (theme ? theme.uiScale : 1)); height: Math.round(2 * (theme ? theme.uiScale : 1))
                    color: root._accentColor; radius: 1
                }

                Rectangle {
                    x: -16; y: -1; width: Math.round(32 * (theme ? theme.uiScale : 1)); height: Math.round(2 * (theme ? theme.uiScale : 1))
                    color: root._accentColor; radius: 1
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.round(6 * (theme ? theme.uiScale : 1)); height: Math.round(6 * (theme ? theme.uiScale : 1)); radius: 3
                    color: root._accentColor
                }

                Rectangle {
                    x: -1; y: -12; width: Math.round(2 * (theme ? theme.uiScale : 1)); height: Math.round(10 * (theme ? theme.uiScale : 1))
                    color: root._accentColor; radius: 1
                }
            }
        }

        // ════════════════
        // 空速带（左侧）
        // ════════════════
        Rectangle {
            id: aspdTape
            anchors.top:    headingTape.bottom
            anchors.bottom: bottomBar.top
            anchors.left:   parent.left
            width: root._tapeW
            color: root._panelBg

            Text {
                anchors.top: parent.top
                anchors.topMargin: 4
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Airspeed"); font.pixelSize: Math.round(9 * (theme ? theme.uiScale : 1)); color: root._textColor
            }

            // 刻度
            Item {
                anchors.top: parent.top; anchors.topMargin: 18
                anchors.bottom: parent.bottom; anchors.bottomMargin: 18
                anchors.left: parent.left; anchors.right: parent.right
                clip: true

                Repeater {
                    model: root._valueTickRadius * 2 + 1
                    delegate: Item {
                        readonly property int tickValue: root._boundedTickValue(root._displayAirspeed, index - root._valueTickRadius, 0, 200)
                        width: parent.width
                        y: parent.height / 2 - (tickValue - root._displayAirspeed) * (parent.height / 20)

                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: tickValue % 5 === 0 ? 10 : 5; height: Math.round(1 * (theme ? theme.uiScale : 1))
                            color: root._lineColor
                        }
                        Text {
                            visible: tickValue % 5 === 0
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            text: tickValue
                            font.pixelSize: Math.round(8 * (theme ? theme.uiScale : 1)); color: root._textColor
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }

            // 当前空速框
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                width: parent.width - 2; height: Math.round(20 * (theme ? theme.uiScale : 1))
                color: "#1a2a3a"
                border.color: Qt.rgba(1,1,1,.4)
                border.width: Math.round(1 * (theme ? theme.uiScale : 1))
                Text {
                    anchors.centerIn: parent
                    text: root._displayAirspeed.toFixed(1)
                    font.pixelSize: Math.round(11 * (theme ? theme.uiScale : 1)); font.weight: Font.Bold; color: "#ffffff"
                }
            }

            // 左侧竖线
            Rectangle { anchors.right: parent.right; width: Math.round(1 * (theme ? theme.uiScale : 1)); height: parent.height; color: Qt.rgba(1,1,1,.15) }
        }

        // ════════════════
        // 高度带（右侧）
        // ════════════════
        Rectangle {
            id: altTape
            anchors.top:    headingTape.bottom
            anchors.bottom: bottomBar.top
            anchors.right:  parent.right
            width: root._tapeW
            color: root._panelBg

            Text {
                anchors.top: parent.top; anchors.topMargin: 4
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Height"); font.pixelSize: Math.round(9 * (theme ? theme.uiScale : 1)); color: root._textColor
            }

            // 刻度
            Item {
                anchors.top: parent.top; anchors.topMargin: 18
                anchors.bottom: parent.bottom; anchors.bottomMargin: 18
                anchors.left: parent.left; anchors.right: parent.right
                clip: true

                Repeater {
                    model: root._valueTickRadius * 2 + 1
                    delegate: Item {
                        readonly property int tickValue: root._boundedTickValue(root._displayAltitude, index - root._valueTickRadius, 0, 1000)
                        width: parent.width
                        y: parent.height/2 - (tickValue - root._displayAltitude) * (parent.height / 20)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: tickValue % 5 === 0 ? 10 : 5; height: Math.round(1 * (theme ? theme.uiScale : 1))
                            color: root._lineColor
                        }
                        Text {
                            visible: tickValue % 5 === 0
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            text: tickValue
                            font.pixelSize: Math.round(8 * (theme ? theme.uiScale : 1)); color: root._textColor
                        }
                    }
                }
            }

            // 当前高度框
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                width: parent.width - 2; height: Math.round(20 * (theme ? theme.uiScale : 1))
                color: "#1a2a3a"
                border.color: Qt.rgba(1,1,1,.4)
                border.width: Math.round(1 * (theme ? theme.uiScale : 1))
                Text {
                    anchors.centerIn: parent
                    text: root._displayAltitude.toFixed(1)
                    font.pixelSize: Math.round(11 * (theme ? theme.uiScale : 1)); font.weight: Font.Bold; color: "#ffffff"
                }
            }

            // 右侧竖线
            Rectangle { anchors.left: parent.left; width: Math.round(1 * (theme ? theme.uiScale : 1)); height: parent.height; color: Qt.rgba(1,1,1,.15) }
        }

        // ════════════════
        // 底部状态条
        // ════════════════
        Rectangle {
            id: bottomBar
            anchors.bottom: parent.bottom
            anchors.left:   parent.left
            anchors.right:  parent.right
            height: Math.round(20 * (theme ? theme.uiScale : 1))
            color: root._panelBg

            Row {
                anchors.centerIn: parent; spacing: 20
                Repeater {
                    model: [
                        { label: qsTr("Roll"), value: root._displayRoll.toFixed(1)    + "°" },
                        { label: qsTr("Tilt"), value: root._displayPitch.toFixed(1)   + "°" },
                        { label: qsTr("Yaw"), value: root._displayHeading.toFixed(0) + "°" }
                    ]
                    delegate: Row {
                        spacing: 4
                        Text { text: modelData.label; font.pixelSize: Math.round(9 * (theme ? theme.uiScale : 1)); color: root._textColor }
                        Text { text: modelData.value; font.pixelSize: Math.round(9 * (theme ? theme.uiScale : 1)); font.weight: Font.Bold; color: "#ffffff" }
                    }
                }
            }
        }
    }

    // 外边框
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: Qt.rgba(1,1,1,.22)
        border.width: Math.round(1 * (theme ? theme.uiScale : 1))
    }
}
