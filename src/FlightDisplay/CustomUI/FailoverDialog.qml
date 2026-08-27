// FailoverDialog.qml
// 冗余切换确认弹窗

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property int  fromBoardId: 1
    property int  toBoardId:   2
    property var  theme:       null

    signal confirmed()
    signal cancelled()

    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.4)
    visible: false

    // 点击背景关闭
    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.visible = false
            root.cancelled()
            _cdTimer.stop()
        }
    }

    // 倒计时
    property int _countdown: 10
    Timer {
        id: _cdTimer
        interval: 1000
        repeat: true
        onTriggered: {
            root._countdown--
            if (root._countdown <= 0) {
                root.visible = false
                root.cancelled()
                stop()
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            _countdown = 10
            _cdTimer.start()
        } else {
            _cdTimer.stop()
        }
    }

    // 弹窗主体
    Rectangle {
        width: 440; height: 230
        anchors.centerIn: parent
        radius: 12
        color: root.theme ? root.theme.surface : "#ffffff"
        border.color: root.theme ? root.theme.border : "#e4e8ed"
        border.width: 1

        // 顶部红色强调条
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 3; radius: 2
            color: root.theme ? root.theme.red : "#dc2626"
        }

        // 阻止背景点击穿透
        MouseArea { anchors.fill: parent }

        Column {
            anchors.centerIn: parent
            spacing: 10
            width: parent.width - 64

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "⚠  冗余切换请求"
                font.pixelSize: 16; font.weight: Font.Bold
                color: root.theme ? root.theme.text : "#1a1d23"
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "主控板 FCB #0" + root.fromBoardId + " 心跳超时\n检测到可用热备板卡，请确认是否切换。"
                font.pixelSize: 13
                color: root.theme ? root.theme.text2 : "#5a6272"
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.6
                width: parent.width
                wrapMode: Text.Wrap
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "候选主板：FCB #0" + root.toBoardId + " · 健康状态正常"
                font.pixelSize: 12; font.weight: Font.Medium
                color: root.theme ? root.theme.blue : "#000066"
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "自动取消倒计时：" + root._countdown + " 秒"
                font.pixelSize: 11
                color: root.theme ? root.theme.text3 : "#9aa3b2"
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Rectangle {
                    width: 160; height: 40; radius: 8
                    color: root.theme ? root.theme.green : "#16a34a"
                    Text {
                        anchors.centerIn: parent
                        text: "确认切换"
                        font.pixelSize: 13; font.weight: Font.DemiBold
                        color: "#ffffff"
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.visible = false
                            root.confirmed()
                        }
                    }
                }

                Rectangle {
                    width: 160; height: 40; radius: 8
                    color: root.theme ? root.theme.surface2 : "#f7f8fa"
                    border.color: root.theme ? root.theme.border : "#e4e8ed"
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "暂不切换"
                        font.pixelSize: 13; font.weight: Font.Medium
                        color: root.theme ? root.theme.text2 : "#5a6272"
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.visible = false
                            root.cancelled()
                        }
                    }
                }
            }
        }
    }
}
