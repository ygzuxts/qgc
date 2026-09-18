import QtQuick 2.15

import QGroundControl.FlightDisplay

Rectangle {
    id: root

    property var flightState

    readonly property real sideMargin: Math.max(20, Math.min(56, width * 0.07))
    readonly property real topInset: Math.max(12, Math.min(28, height * 0.07))
    readonly property real layoutScale: Math.max(0.68, Math.min(1.0, (height - topInset - 14) / 402))
    readonly property int itemHeight: Math.round(42 * layoutScale)
    readonly property int itemSpacing: Math.round(10 * layoutScale)
    readonly property int groupSpacing: Math.round(18 * layoutScale)

    color: FlightPalette.lightMode ? "#F3F7FB" : "#070B11"

    Column {
        anchors.top: parent.top
        anchors.topMargin: root.topInset
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - root.sideMargin * 2, 560)
        spacing: root.groupSpacing

        Column {
            width: parent.width
            spacing: Math.max(2, Math.round(6 * root.layoutScale))

            Text {
                text: "系统自检"
                color: FlightPalette.textHi
                font.pixelSize: Math.round(30 * root.layoutScale)
                font.bold: true
            }

            Text {
                text: flightState.selfCheckFailed ? "自检失败，请处理异常后重新启动" :
                      flightState.selfCheckFinished ? "自检完成，正在进入仪表盘" : "正在检查飞控状态"
                color: FlightPalette.textLo
                font.pixelSize: Math.round(14 * root.layoutScale)
            }
        }

        Rectangle {
            width: parent.width
            height: Math.max(5, Math.round(8 * root.layoutScale))
            radius: height / 2
            color: FlightPalette.lightMode ? "#DCE5EE" : "#172231"

            Rectangle {
                width: parent.width * flightState.selfCheckProgress
                height: parent.height
                radius: parent.radius
                color: FlightPalette.statusGreen
                Behavior on width { NumberAnimation { duration: 360; easing.type: Easing.InOutCubic } }
            }
        }

        Column {
            width: parent.width
            spacing: root.itemSpacing

            Repeater {
                model: flightState.selfCheckItems

                SelfCheckItem {
                    width: parent.width
                    itemHeight: root.itemHeight
                    labelFontSize: Math.round(15 * root.layoutScale)
                    statusFontSize: Math.round(13 * root.layoutScale)
                    horizontalPadding: Math.round(16 * root.layoutScale)
                    label: modelData
                    resultText: flightState.selfCheckResult(index)
                    statusGreen: FlightPalette.statusGreen
                    statusYellow: FlightPalette.statusYellow
                    statusRed: FlightPalette.statusRed
                    statusOff: FlightPalette.statusOff
                    textHi: FlightPalette.textHi
                    textLo: FlightPalette.textLo
                    lightMode: FlightPalette.lightMode
                    stateIndex: {
                        if (index > flightState.selfCheckDisplayStep) return 0
                        if (index === flightState.selfCheckDisplayStep && flightState.selfCheckDisplayStep < flightState.selfCheckItems.length) return 1
                        return flightState.selfCheckStates[index]
                    }
                }
            }
        }

        Rectangle {
            width: Math.min(parent.width, 180 * root.layoutScale)
            height: Math.max(34, Math.round(42 * root.layoutScale))
            anchors.horizontalCenter: parent.horizontalCenter
            radius: 7
            visible: flightState.selfCheckFailed
            color: FlightPalette.statusRed

            Text {
                anchors.centerIn: parent
                text: "重新检测"
                color: "white"
                font.pixelSize: Math.round(15 * root.layoutScale)
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: flightState.startSelfCheck(true)
            }
        }
    }
}
