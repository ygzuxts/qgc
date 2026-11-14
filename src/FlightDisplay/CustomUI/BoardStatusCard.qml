// BoardStatusCard.qml
// 单块冗余板卡状态卡片，可复用

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property int    boardId:   1
    property string role:      "Master"   // "Master" | "Standby"
    property int    health:    0          // 0=正常 1=警告 2=故障
    property int    miss:      0
    property var    theme:     null

    width: parent ? parent.width - 24 : 240
    height: theme ? theme.cardHSm : 52
    radius: theme ? theme.radius : 6

    color:  role === "Master" ? (theme ? theme.blueL : "#eff6ff")
          : health > 0        ? (theme ? theme.amberL : "#fff7ed")
          : theme ? theme.surface2 : "#f7f8fa"

    border.color: role === "Master" ? (theme ? theme.blueBorder : "#8080B3")
                : health > 0        ? "#fed7aa"
                : theme ? theme.border : "#e4e8ed"
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.margins: theme ? theme.spacingMd : 12
        spacing: theme ? theme.spacingLg : 10

        // 健康指示灯
        Rectangle {
            width: theme ? theme.spacingMd : 9
            height: theme ? theme.spacingMd : 9
            radius: width / 2
            Layout.alignment: Qt.AlignVCenter
            color: health === 0 ? "#22c55e"
                 : health === 1 ? "#f59e0b"
                 : "#ef4444"

            SequentialAnimation on opacity {
                running: health > 0
                loops: Animation.Infinite
                NumberAnimation { to: 0.2; duration: 500 }
                NumberAnimation { to: 1.0; duration: 500 }
            }
        }

        // 名称 + 角色
        Column {
            Layout.fillWidth: true
            spacing: theme ? theme.spacingXs : 2

            Text {
                text: "FCB #0" + boardId
                font.pixelSize: theme ? theme.fontMd : 12
                font.weight: Font.Medium
                color: theme ? theme.text : "#1a1d23"
            }
            Text {
                text: role === "Master" ? qsTr("Flight Controller") : qsTr("Hot Standby")
                font.pixelSize: theme ? theme.fontSm : 11
                color: role === "Master"
                       ? (theme ? theme.blue  : "#000066")
                       : (theme ? theme.text3 : "#9aa3b2")
            }
        }

        // miss 计数
        Text {
            text: miss + " miss"
            font.pixelSize: theme ? theme.fontSm : 11
            font.weight: Font.Medium
            color: miss > 0
                   ? (theme ? theme.amber : "#d97706")
                   : (theme ? theme.text3 : "#9aa3b2")
        }
    }
}
