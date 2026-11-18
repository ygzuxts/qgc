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
    signal preflightRequested()
    signal takeoffSetupRequested()

    function actionLabel(index) {
        switch (index) {
        case 0: return qsTr("Hold Position")
        case 1: return qsTr("Resume Mission")
        case 2: return qsTr("Execute Mission")
        case 3: return qsTr("Takeoff Setup")
        case 4: return qsTr("Check")
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
        case 3: return true
        case 4: return true
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
        case 3:
            root.takeoffSetupRequested()
            break
        case 4:
            root.preflightRequested()
            break
        default:
            root.state.executeRTL()
            break
        }
    }

    height: theme ? theme.bottomBarH : 52
    color: theme.surface
    radius: 8

    RowLayout {
        anchors.fill: parent
        anchors.margins: 3
        spacing: theme ? theme.spacingSm : 6

        // 操作按钮
        Repeater {
            model: 6
            delegate: Rectangle {
                id: actionButton
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0
                Layout.preferredWidth: 1
                radius: 8
                opacity: root.actionEnabled(index) ? 1 : 0.65
                color: actionMouse.pressed || actionMouse.containsMouse
                       ? root.theme.blueL
                       : index === 4 ? root.theme.redL : root.theme.surface2
                border.width: 0

                Text {
                    anchors.fill: parent
                    anchors.margins: 3
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    text: root.actionLabel(index)
                    font.pixelSize: 12; font.weight: Font.Medium
                    color: index === 4 ? (root.theme.darkMode ? "#ffb4b4" : "#991b1b") : root.theme.text
                }
                MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    enabled: root.actionEnabled(index)
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    // Match the existing takeoff page's deliberate return command.
                    onClicked: {
                        if (index !== 5) {
                            root.triggerAction(index)
                        }
                    }
                    onPressAndHold: {
                        if (index === 5 && root.actionEnabled(index)) {
                            root.triggerAction(index)
                        }
                    }
                }
            }
        }

    }
}
