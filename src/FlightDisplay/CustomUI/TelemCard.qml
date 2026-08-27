// TelemCard.qml
// 单个遥测数据卡片，HUD区域复用

import QtQuick

Rectangle {
    id: root

    property string label:   ""
    property string value:   "0"
    property string unit:    ""
    property color  valColor: "#000066"
    property real   pct:     0.0
    property var    theme:   null

    height: theme ? theme.cardHMd : 64
    radius: theme ? theme.radius : 6
    color:  theme ? theme.surface2 : "#f7f8fa"
    border.color: theme ? theme.border : "#e4e8ed"
    border.width: 1

    Column {
        anchors.fill: parent
        anchors.margins: theme ? theme.spacingMd : 10
        spacing: theme ? theme.spacingXs : 3

        Text {
            text: root.label
            font.pixelSize: theme ? theme.fontXs : 10
            color: root.theme ? root.theme.text3 : "#9aa3b2"
        }

        Row {
            spacing: theme ? theme.spacingXs : 4
            Text {
                id: valText
                text: root.value
                font.pixelSize: theme ? theme.fontXl : 18
                font.weight: Font.DemiBold
                color: root.valColor
            }
            Text {
                text: root.unit
                font.pixelSize: theme ? theme.fontXs : 10
                color: root.theme ? root.theme.text3 : "#9aa3b2"
                anchors.bottom: valText.bottom
                anchors.bottomMargin: theme ? theme.spacingXs * 0.5 : 2
            }
        }

        // 进度条
        Rectangle {
            width: parent.width
            height: Math.max(3, theme ? theme.spacingXs * 0.55 : 3)
            radius: 2
            color: root.theme ? root.theme.border : "#e4e8ed"

            Rectangle {
                width: Math.max(0, Math.min(parent.width, parent.width * root.pct))
                height: parent.height
                radius: 2
                color: root.valColor
                opacity: 0.5
            }
        }
    }
}
