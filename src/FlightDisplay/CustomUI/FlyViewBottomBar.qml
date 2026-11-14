// FlyViewBottomBar.qml
// 底部操作按钮条

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property var state: null
    property var theme: null

    signal failoverRequested()
    signal missionCheckRequested()

    function actionLabel(index) {
        switch (index) {
        case 0: return qsTr("Hold Position")
        case 1: return qsTr("Resume Mission")
        case 2: return qsTr("Execute Mission")
        default: return qsTr("Return and Land (hold)")
        }
    }

    function actionEnabled(index) {
        if (!root.state) {
            return false
        }
        switch (index) {
        case 0: return root.state.canHoldPosition
        case 1: return root.state.canResumeMission
        case 2: return root.state.canStartMission
        default: return root.state.canReturnToLaunch
        }
    }

    function triggerAction(index) {
        if (!root.state) {
            return
        }
        switch (index) {
        case 0:
            root.state.executeHoldPosition()
            break
        case 1:
            root.state.executeResumeMission()
            break
        case 2:
            root.missionCheckRequested()
            break
        default:
            root.state.executeRTL()
            break
        }
    }

    function summaryLabel(index) {
        switch (index) {
        case 0: return qsTr("Link")
        case 1: return qsTr("Mission")
        default: return qsTr("Mode")
        }
    }

    function summaryValue(index) {
        switch (index) {
        case 0: return root.state && root.state.vehicleConnected ? qsTr("Connected") : qsTr("Disconnected")
        case 1: return root.state && root.state.vehicleConnected ? (root.state.currentWP + "/" + root.state.totalWP) : "--/--"
        default: return root.state ? root.state.flightMode : qsTr("Disconnected")
        }
    }

    function summaryHighlight(index) {
        return index === 0 && root.state && root.state.vehicleConnected
    }

    height: theme ? theme.bottomBarH : 52
    color:  theme ? theme.surface : "#ffffff"

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: root.theme ? root.theme.border : "#e4e8ed"
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: theme ? theme.spacingSm : 8
        spacing: theme ? theme.spacingSm : 6

        // 操作按钮
        Repeater {
            model: 4
            delegate: Rectangle {
                id: actionButton
                Layout.fillWidth: true; height: theme ? theme.controlHMd : 36
                radius: root.theme ? root.theme.radius : 6
                opacity: root.actionEnabled(index) ? 1 : 0.45
                color: actionMouse.pressed || actionMouse.containsMouse
                       ? (root.theme ? root.theme.blue : "#000066")
                       : (root.theme ? root.theme.blueL : "#f3f7ff")
                border.width: 0

                Text {
                    anchors.fill: parent
                    anchors.margins: 3
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    text: root.actionLabel(index)
                    font.pixelSize: theme ? theme.fontMd : 13; font.weight: Font.Medium
                    color: actionMouse.pressed || actionMouse.containsMouse
                         ? "#ffffff"
                         : (root.theme ? root.theme.text : "#111827")
                }
                MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    enabled: root.actionEnabled(index)
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    // Match the existing takeoff page's deliberate return command.
                    onClicked: {
                        if (index !== 3) {
                            root.triggerAction(index)
                        }
                    }
                    onPressAndHold: {
                        if (index === 3 && root.actionEnabled(index)) {
                            root.triggerAction(index)
                        }
                    }
                }
            }
        }

        Rectangle { width: 1; height: theme ? theme.controlHMd - theme.spacingXs : 30; color: root.theme ? root.theme.border : "#e4e8ed" }

        // 确认切换
        Rectangle {
            Layout.preferredWidth: theme ? theme.baseWidth * 11 : 110; height: theme ? theme.controlHMd : 36
            radius: root.theme ? root.theme.radius : 6
            color: root.theme ? root.theme.amberL : "#fef3c7"
            border.color: "#fde68a"
            border.width: 1
            visible: false

            Text {
                anchors.centerIn: parent
                text: qsTr("⚠ Confirm Failover")
                font.pixelSize: theme ? theme.fontMd : 12; font.weight: Font.DemiBold
                color: root.theme ? root.theme.amber : "#d97706"
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.failoverRequested()
            }
        }

        Rectangle { width: 1; height: theme ? theme.controlHMd - theme.spacingXs : 30; color: root.theme ? root.theme.border : "#e4e8ed" }

        // 飞行状态摘要
        Row {
            visible: root.width >= 640
            spacing: theme ? theme.spacingXs : 4
            Repeater {
                model: 3
                delegate: Rectangle {
                    width: theme ? theme.baseWidth * 6.8 : 68; height: theme ? theme.controlHMd : 36
                    radius: root.theme ? root.theme.radius : 6
                    color:  root.summaryHighlight(index) ? (root.theme ? root.theme.blueL : "#E6E6F0") : (root.theme ? root.theme.surface2 : "#f7f8fa")
                    border.color: root.summaryHighlight(index) ? (root.theme ? root.theme.blueBorder : "#8080B3") : (root.theme ? root.theme.border : "#e4e8ed")
                    border.width: 1

                    Column {
                        anchors.centerIn: parent; spacing: theme ? theme.spacingXs : 3

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.summaryLabel(index)
                            font.pixelSize: theme ? theme.fontXs : 9
                            color: root.theme ? root.theme.text3 : "#9aa3b2"
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.summaryValue(index)
                            font.pixelSize: theme ? theme.fontXs : 9; font.weight: Font.DemiBold
                            color: root.summaryHighlight(index) ? (root.theme ? root.theme.blue : "#000066") : (root.theme ? root.theme.text : "#1a1d23")
                        }
                    }
                }
            }
        }

    }
}
