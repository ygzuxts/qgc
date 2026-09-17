import QtQuick 2.15

Rectangle {
    id: root

    property string label: ""
    property string resultText: "--"
    property int stateIndex: 0
    property color statusGreen: "#00D084"
    property color statusRed: "#EF4444"
    property color statusYellow: "#FFB000"
    property color statusOff: "#94A3B8"
    property color textHi: "#0F172A"
    property color textLo: "#64748B"
    property bool lightMode: true
    property int itemHeight: 42
    property int labelFontSize: 15
    property int statusFontSize: 13
    property int horizontalPadding: 16

    readonly property color stateColor: stateIndex === 2 ? statusGreen :
                                        stateIndex === 3 ? statusRed :
                                        stateIndex === 1 ? statusYellow :
                                        statusOff

    height: itemHeight
    radius: 8
    color: lightMode ? Qt.rgba(1, 1, 1, 0.72) : Qt.rgba(0.08, 0.12, 0.17, 0.74)
    border.color: Qt.rgba(stateColor.r, stateColor.g, stateColor.b, stateIndex === 0 ? 0.16 : 0.36)
    border.width: 1

    Row {
        anchors.fill: parent
        anchors.leftMargin: root.horizontalPadding
        anchors.rightMargin: root.horizontalPadding
        spacing: Math.max(8, root.horizontalPadding - 4)

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 22

            Rectangle {
                anchors.centerIn: parent
                width: selfCheckPulse.width
                height: selfCheckPulse.height
                radius: width / 2
                color: Qt.rgba(root.stateColor.r, root.stateColor.g, root.stateColor.b, root.stateIndex === 1 ? 0.22 : 0.10)
                visible: root.stateIndex !== 0

                NumberAnimation on width {
                    running: root.stateIndex === 1
                    loops: Animation.Infinite
                    from: 14
                    to: 22
                    duration: 760
                }

                NumberAnimation on height {
                    running: root.stateIndex === 1
                    loops: Animation.Infinite
                    from: 14
                    to: 22
                    duration: 760
                }
            }

            Rectangle {
                id: selfCheckPulse
                anchors.centerIn: parent
                width: 14
                height: 14
                radius: 7
                color: root.stateColor
                border.color: Qt.rgba(1, 1, 1, root.lightMode ? 0.62 : 0.36)
                border.width: 1
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.textHi
            font.pixelSize: root.labelFontSize
            font.bold: true
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: 74
            text: root.stateIndex === 2 ? "通过" : root.stateIndex === 3 ? "失败" : root.stateIndex === 1 ? "检测中" : "等待中"
            color: root.stateColor
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: root.statusFontSize
            font.bold: true
        }

        Item {
            width: Math.max(8, parent.width - 22 - 12 - 92 - 74 - resultValue.implicitWidth - 72)
            height: 1
        }

        Text {
            id: resultValue
            anchors.verticalCenter: parent.verticalCenter
            text: root.stateIndex === 2 || root.stateIndex === 3 ? root.resultText : root.stateIndex === 1 ? "读取中" : "--"
            color: root.stateIndex === 3 ? root.statusRed : root.stateIndex === 2 ? root.textHi : root.textLo
            horizontalAlignment: Text.AlignRight
            font.pixelSize: root.statusFontSize
            font.bold: root.stateIndex === 2
        }
    }
}
