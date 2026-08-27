// DecisionFlowItem.qml
// 单条决权流程条目，可复用

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string stepNum:  "1"
    property string label:    ""
    property string state:    "wait"   // "done" | "active" | "wait"
    property var    theme:    null

    width: parent ? parent.width - 24 : 240
    height: 36
    radius: theme ? theme.radius : 6

    color:  state === "done"   ? (theme ? theme.greenL : "#f0fdf4")
          : state === "active" ? (theme ? theme.amberL : "#fff7ed")
          : theme ? theme.surface2 : "#f7f8fa"

    border.color: state === "done"   ? "#bbf7d0"
                : state === "active" ? "#fed7aa"
                : theme ? theme.border : "#e4e8ed"
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // 序号圆圈
        Rectangle {
            width: 20; height: 20; radius: 10
            Layout.alignment: Qt.AlignVCenter
            color: state === "done"   ? "#22c55e"
                 : state === "active" ? "#f59e0b"
                 : theme ? theme.border : "#e4e8ed"

            Text {
                anchors.centerIn: parent
                text: stepNum
                font.pixelSize: 10
                font.weight: Font.Bold
                color: state === "wait"
                       ? (theme ? theme.text3 : "#9aa3b2")
                       : (theme ? theme.textOnBlue : "#ffffff")
            }
        }

        // 标签
        Text {
            Layout.fillWidth: true
            text: label
            font.pixelSize: 12
            color: theme ? theme.text2 : "#5a6272"
        }

        // 状态标签
        Rectangle {
            height: 20
            radius: 4
            implicitWidth: stText.implicitWidth + 12
            color: state === "done"   ? (theme ? theme.greenL : "#dcfce7")
                 : state === "active" ? (theme ? theme.amberL : "#fef3c7")
                 : theme ? theme.surface2 : "#f7f8fa"
            border.color: state === "wait" ? (theme ? theme.border : "#e4e8ed") : "transparent"

            Text {
                id: stText
                anchors.centerIn: parent
                text: state === "done"   ? "通过"
                    : state === "active" ? "等待"
                    : "待定"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: state === "done"   ? (theme ? theme.green  : "#16a34a")
                     : state === "active" ? (theme ? theme.amber  : "#d97706")
                     : (theme ? theme.text3 : "#9aa3b2")
            }
        }
    }
}
