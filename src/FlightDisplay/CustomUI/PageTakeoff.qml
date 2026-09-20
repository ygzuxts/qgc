// PageTakeoff.qml 起飞/起降页右侧栏

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactSystem

Rectangle {
    id: root

    property var state: null
    property var theme: null
    readonly property var activeVehicle: state ? state.activeVehicle : null
    readonly property var guided: state ? state.guidedController : null
    readonly property bool vehicleConnected: !!(state && state.vehicleConnected)
    readonly property bool vehicleAvailable: !!(state && state.vehicleAvailable)
    readonly property bool parametersReady: !!(activeVehicle && activeVehicle.parameterManager && activeVehicle.parameterManager.parametersReady)
    readonly property bool hasMission: !!(state && (state.missionControlAvailable || state.missionAvailable || state.totalWP > 1))
    readonly property bool showMissionControl: hasMission && vehicleAvailable
    readonly property var takeoffSafetyFact: _resolveFirstFact(["MIS_TAKEOFF_ALT", "PILOT_TKOFF_ALT", "Q_RTL_ALT"])
    readonly property string takeoffSafetyParamName: _resolveFirstParamName(["MIS_TAKEOFF_ALT", "PILOT_TKOFF_ALT", "Q_RTL_ALT"])
    readonly property var rtlAltFact: _resolveFirstFact(["RTL_RETURN_ALT", "RTL_ALT", "r.RTL_ALTITUDE"])
    readonly property string rtlAltParamName: _resolveFirstParamName(["RTL_RETURN_ALT", "RTL_ALT", "r.RTL_ALTITUDE"])
    readonly property var batteryThresholdFact: _resolveFirstFact(["BAT_LOW_THR", "BATT_LOW_MAH", "r.BATT_LOW_MAH", "BATT_LOW_VOLT", "r.BATT_LOW_VOLT"])
    readonly property string batteryThresholdParamName: _resolveFirstParamName(["BAT_LOW_THR", "BATT_LOW_MAH", "r.BATT_LOW_MAH", "BATT_LOW_VOLT", "r.BATT_LOW_VOLT"])
    readonly property var linkLossTimeoutFact: _resolveFirstFact(["COM_DL_LOSS_T", "FS_GCS_TIMEOUT", "COM_RC_LOSS_T"])
    readonly property string linkLossTimeoutParamName: _resolveFirstParamName(["COM_DL_LOSS_T", "FS_GCS_TIMEOUT", "COM_RC_LOSS_T"])
    readonly property color panelBg: theme && theme.darkMode ? "#000000" : "#ffffff"
    readonly property color cardBg: theme && theme.darkMode ? "#000000" : "#ffffff"
    readonly property color cardBorder: theme && theme.darkMode ? "#2b2b2b" : "#d7dde6"
    readonly property color textMain: theme && theme.darkMode ? "#e5edf8" : "#1a1d23"
    readonly property color textSub: theme && theme.darkMode ? "#a8b5c7" : "#9aa3b2"
    readonly property color textMuted: theme && theme.darkMode ? "#6b7280" : "#b6beca"
    readonly property color brandBlue: theme ? theme.blue : "#000066"
    readonly property color brandHover: theme ? theme.blueL : "#E6E6F0"
    readonly property color brandPress: theme ? theme.bluePress : "#00004D"
    readonly property color brandBorder: theme ? theme.blueBorder : "#8080B3"
    property bool takeoffTargetExpanded: false
    property bool takeoffAltConfirmed: true

    // 背景透明度由外层 FlyViewRightPanel 统一控制，避免文字/按钮跟着透明。
    color: "transparent"
    implicitHeight: content.implicitHeight + 22

    Component.onCompleted: {
        takeoffTargetExpanded = false
        syncTakeoffAltFromParam()
    }
    onVisibleChanged: {
        if (visible) {
            takeoffTargetExpanded = false
            syncTakeoffAltFromParam()
        }
    }
    onTakeoffSafetyFactChanged: syncTakeoffAltFromParam()

    Connections {
        target: root.takeoffSafetyFact
        ignoreUnknownSignals: true
        function onRawValueChanged() {
            if (root.takeoffAltConfirmed) {
                root.syncTakeoffAltFromParam()
            }
        }
        function onValueChanged() {
            if (root.takeoffAltConfirmed) {
                root.syncTakeoffAltFromParam()
            }
        }
    }

    FactPanelController { id: safetyController }

    function _resolveFirstFact(names) {
        if (!parametersReady) {
            return null
        }
        for (var i = 0; i < names.length; i++) {
            if (safetyController.parameterExists(-1, names[i])) {
                return safetyController.getParameterFact(-1, names[i], false)
            }
        }
        return null
    }

    function _resolveFirstParamName(names) {
        if (!parametersReady) {
            return ""
        }
        for (var i = 0; i < names.length; i++) {
            if (safetyController.parameterExists(-1, names[i])) {
                return names[i]
            }
        }
        return ""
    }

    function actionLabel(index) {
        switch (index) {
        case 0: return "起飞"
        case 1: return "着陆"
        case 2: return "返航降落"
        default: return "原地悬停"
        }
    }

    function actionIcon(index) {
        switch (index) {
        case 0: return "qrc:/res/nicewing_takeoff.svg"
        case 1: return "qrc:/res/nicewing_land.svg"
        case 2: return "qrc:/res/nicewing_rtl.svg"
        default: return "qrc:/res/nicewing_pause.svg"
        }
    }

    function actionHint(index) {
        return index === 3 ? "保持当前位置高度" : "长按执行"
    }

    function actionEnabled(index) {
        if (!state) {
            return false
        }
        switch (index) {
        case 0: return state.canTakeoff
        case 1: return state.canLand
        case 2: return state.canReturnToLaunch
        default: return state.canHoldPosition
        }
    }

    function triggerAction(index) {
        if (!state) {
            return
        }
        switch (index) {
        case 0: state.executeTakeoff(); break
        case 1: state.executeLand(); break
        case 2: state.executeRTL(); break
        default: state.executeHoldPosition(); break
        }
    }

    function missionLoadedText() {
        if (!root.hasMission) {
            return "未加载"
        }
        var count = state ? state.totalWP : 0
        return count > 0 ? (count + " 个任务项") : "已加载"
    }

    function gpsCheckText() {
        if (!state || !root.vehicleConnected) {
            return "--"
        }
        var lock = state.gpsLockText && state.gpsLockText !== "--" ? state.gpsLockText : "--"
        var sats = state.gpsSatellitesText && state.gpsSatellitesText !== "--" ? state.gpsSatellitesText + "星" : "--"
        return lock + " · " + sats
    }

    function openStartMissionCheck() {
        console.log("[CustomTakeoff] open start mission check", "connected:", root.vehicleConnected, "hasMission:", root.hasMission, "running:", state ? state.missionRunning : false)
        startMissionCheckPopup.open()
    }

    function confirmStartMission() {
        console.log("[CustomTakeoff] confirm start mission", "connected:", root.vehicleConnected, "hasMission:", root.hasMission)
        startMissionCheckPopup.close()
        if (!state) {
            return
        }
        state.startMission()
    }

    function missionIsActive() {
        if (!state || !root.vehicleConnected || !root.hasMission) {
            return false
        }
        if (state.missionRunning || state.missionPaused) {
            return true
        }
        if (guided && (guided.showPause || guided.showContinueMission)) {
            return true
        }
        return !!(activeVehicle && activeVehicle.armed && activeVehicle.flying && !(guided && guided.showStartMission))
    }

    function missionStartEnabled() {
        if (!state || !root.vehicleConnected || !root.hasMission) {
            return false
        }
        if (guided && guided.showStartMission !== undefined) {
            return guided.showStartMission
        }
        return !root.missionIsActive()
    }

    function missionContinueEnabled() {
        if (!state || !root.vehicleConnected || !root.hasMission) {
            return false
        }
        return !!(state.missionPaused || (guided && guided.showContinueMission))
    }

    function continueMissionNow() {
        console.log("[CustomTakeoff] continue mission clicked",
                    "guided:", !!guided,
                    "showContinue:", guided ? guided.showContinueMission : false,
                    "action:", guided ? guided.actionContinueMission : -1)

        // 不调用原版 executeAction(actionContinueMission)，它最终会走 activeVehicle.startMission()。
        // PX4 的 startMission 会同步等待模式切换/解锁反馈，UI 会明显卡顿。
        // 暂停后继续任务只需要从 Hold/Loiter 异步切回 Mission 模式，PX4 会继续当前任务。
        if (activeVehicle && activeVehicle.missionFlightMode) {
            activeVehicle.flightMode = activeVehicle.missionFlightMode
            if (state) {
                state.missionPaused = false
                state.pendingMissionAvailable = true
            }
            return
        }

        // 兜底：没有 Mission 模式属性时才走自定义恢复逻辑。
        if (state && state.continueMission) {
            state.continueMission()
        }
    }

    function missionPauseEnabled() {
        if (!state || !root.vehicleConnected || !root.hasMission) {
            return false
        }
        return !!(state.missionRunning || (guided && guided.showPause) || (activeVehicle && activeVehicle.armed && activeVehicle.flying && !state.missionPaused))
    }

    function missionAbortEnabled() {
        return root.missionIsActive()
    }

    function pauseMissionNow() {
        if (!activeVehicle) {
            console.warn("[CustomTakeoff] pause ignored: no active vehicle")
            return
        }
        var mode = activeVehicle.pauseFlightMode ? String(activeVehicle.pauseFlightMode) : ""
        console.log("[CustomTakeoff] pause mission direct", "current:", activeVehicle.flightMode, "target:", mode, "pauseSupported:", activeVehicle.pauseVehicleSupported)
        if (mode !== "") {
            activeVehicle.flightMode = mode
            if (state) state.missionPaused = true
            return
        }
        if (activeVehicle.pauseVehicleSupported) {
            activeVehicle.pauseVehicle()
            if (state) state.missionPaused = true
            return
        }
        if (state) state.executeHoldPosition()
    }

    function abortMissionNow() {
        if (!activeVehicle) {
            console.warn("[CustomTakeoff] abort ignored: no active vehicle")
            return
        }
        var mode = activeVehicle.rtlFlightMode ? String(activeVehicle.rtlFlightMode) : ""
        console.log("[CustomTakeoff] abort mission direct", "current:", activeVehicle.flightMode, "target:", mode)
        if (mode !== "") {
            activeVehicle.flightMode = mode
            if (state) state.missionPaused = false
            return
        }
        if (state) state.executeRTL()
    }

    function _clampTakeoffAlt(value) {
        var numberValue = Number(value)
        if (!(numberValue === numberValue)) {
            numberValue = 50
        }
        return Math.max(0, Math.min(500, Math.round(numberValue)))
    }

    function _takeoffAltText(value) {
        return String(root._clampTakeoffAlt(value))
    }

    function _currentTakeoffAltInputValue() {
        if (takeoffAltInput && takeoffAltInput.text.length > 0) {
            return root._clampTakeoffAlt(takeoffAltInput.text)
        }
        return state ? root._clampTakeoffAlt(state.takeoffAlt) : 50
    }

    function _applyTakeoffAltToUi(value, confirmed) {
        var alt = root._clampTakeoffAlt(value)
        if (state) {
            state.takeoffAlt = alt
        }
        if (takeoffAltInput) {
            takeoffAltInput.text = root._takeoffAltText(alt)
        }
        root.takeoffAltConfirmed = confirmed
    }

    function syncTakeoffAltFromParam() {
        if (takeoffSafetyFact) {
            root._applyTakeoffAltToUi(takeoffSafetyFact.rawValue, true)
        } else if (state) {
            root._applyTakeoffAltToUi(state.takeoffAlt, true)
        }
    }

    function defaultTakeoffAlt() {
        if (takeoffSafetyFact && takeoffSafetyFact.defaultValueAvailable) {
            return root._clampTakeoffAlt(takeoffSafetyFact.defaultValue)
        }
        if (takeoffSafetyFact) {
            return root._clampTakeoffAlt(takeoffSafetyFact.rawValue)
        }
        return 50
    }

    function useDefaultTakeoffAlt() {
        root._applyTakeoffAltToUi(root.defaultTakeoffAlt(), false)
    }

    function adjustTakeoffAlt(delta) {
        root._applyTakeoffAltToUi(root._currentTakeoffAltInputValue() + delta, false)
    }

    function confirmTakeoffAlt() {
        var alt = root._currentTakeoffAltInputValue()
        if (takeoffSafetyFact) {
            takeoffSafetyFact.value = alt
        }
        root._applyTakeoffAltToUi(alt, true)
    }

    function safetyLabel(index) {
        switch (index) {
        case 0: return "返航高度"
        case 1: return "最大起飞高度"
        case 2: return batteryThresholdParamName === "BAT_LOW_THR" ? "低电量告警阈值" : (batteryThresholdParamName.indexOf("VOLT") !== -1 ? "低电量电压阈值" : "低电量容量阈值")
        default: return "失联超时"
        }
    }

    function safetyValue(index) {
        switch (index) {
        case 0: return rtlAltFact ? rtlAltFact.valueString : "--"
        case 1: return takeoffSafetyFact ? takeoffSafetyFact.valueString : "--"
        case 2: return batteryThresholdFact ? batteryThresholdFact.valueString : "--"
        default: return linkLossTimeoutFact ? linkLossTimeoutFact.valueString : "--"
        }
    }

    component PanelCard: Rectangle {
        property alias contentItem: inner.data
        Layout.fillWidth: true
        radius: 8
        color: root.cardBg
        border.width: Math.round(1 * (theme ? theme.uiScale : 1))
        border.color: root.cardBorder
        implicitHeight: inner.implicitHeight + 20

        Column {
            id: inner
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            spacing: 8
        }
    }

    component SmallActionButton: Rectangle {
        id: smallActionRoot
        property string label: ""
        property bool enabledState: true
        property bool requireHold: false
        property real holdProgress: 0
        property bool holding: false
        property string tone: "normal"
        property int buttonHeight: Math.round(42 * (theme ? theme.uiScale : 1))
        signal clicked

        radius: 8
        clip: true
        height: buttonHeight
        implicitHeight: height
        Layout.preferredHeight: height
        color: !enabledState
               ? (theme && theme.darkMode ? "#111827" : "#f3f6fb")
               : smallActionRoot.holding
                 ? (tone === "danger" ? "#fee2e2" : root.brandHover)
                 : smallActionMouse.containsMouse
                   ? (tone === "danger" ? "#ffe4e6" : root.brandHover)
                   : (tone === "danger" ? "#fff1f2" : (theme && theme.darkMode ? "#111111" : "#ffffff"))
        border.width: enabledState && (smallActionMouse.containsMouse || smallActionRoot.holding) ? 1 : 0
        border.color: tone === "danger" ? "#fca5a5" : root.brandBorder

        Behavior on color { ColorAnimation { duration: 90 } }
        Behavior on border.color { ColorAnimation { duration: 90 } }

        Timer {
            id: smallHoldTimer
            interval: 16
            repeat: true
            onTriggered: {
                smallActionRoot.holdProgress = Math.min(1, smallActionRoot.holdProgress + interval / 750)
                if (smallActionRoot.holdProgress >= 1) {
                    stop()
                    smallActionRoot.holding = false
                    smallActionRoot.holdProgress = 0
                    smallActionRoot.clicked()
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: smallActionRoot.label
            font.pixelSize: Math.round(13 * (theme ? theme.uiScale : 1))
            font.weight: Font.Medium
            color: smallActionRoot.tone === "danger"
                   ? (smallActionRoot.enabledState ? "#ef4444" : "#fca5a5")
                   : (smallActionRoot.enabledState ? (smallActionRoot.holding || smallActionMouse.containsMouse ? root.brandBlue : root.textMain) : root.textMuted)
        }

        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: parent.width * smallActionRoot.holdProgress
            height: Math.round(4 * (theme ? theme.uiScale : 1))
            radius: 0
            visible: smallActionRoot.enabledState && smallActionRoot.requireHold && smallActionRoot.holding
            color: smallActionRoot.tone === "danger" ? "#ef4444" : root.brandBlue
        }

        MouseArea {
            id: smallActionMouse
            anchors.fill: parent
            enabled: smallActionRoot.enabledState
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (!smallActionRoot.requireHold) {
                    smallActionRoot.clicked()
                }
            }
            onPressed: {
                if (smallActionRoot.requireHold) {
                    smallActionRoot.holdProgress = 0
                    smallActionRoot.holding = true
                    smallHoldTimer.restart()
                }
            }
            onReleased: {
                if (smallActionRoot.requireHold && smallActionRoot.holding) {
                    smallActionRoot.holding = false
                    smallHoldTimer.stop()
                    smallActionRoot.holdProgress = 0
                }
            }
            onCanceled: {
                if (smallActionRoot.requireHold) {
                    smallActionRoot.holding = false
                    smallHoldTimer.stop()
                    smallActionRoot.holdProgress = 0
                }
            }
        }
    }

    component TakeoffAltButton: Rectangle {
        id: takeoffAltButtonRoot
        property string label: ""
        property bool primary: false
        signal activated

        radius: 6
        clip: true
        color: takeoffAltButtonMouse.pressed
               ? (primary ? root.brandPress : root.brandHover)
               : takeoffAltButtonMouse.containsMouse
                 ? (primary ? root.brandBlue : root.brandHover)
                 : (primary ? root.brandBlue : (theme && theme.darkMode ? "#111111" : "#ffffff"))
        border.width: 1
        border.color: primary ? root.brandBorder : root.cardBorder

        Text {
            anchors.centerIn: parent
            text: takeoffAltButtonRoot.label
            font.pixelSize: Math.round(13 * (theme ? theme.uiScale : 1))
            font.weight: Font.Medium
            color: takeoffAltButtonRoot.primary ? "#ffffff" : root.textMain
        }

        MouseArea {
            id: takeoffAltButtonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: takeoffAltButtonRoot.activated()
        }
    }

    ColumnLayout {
        id: content
        width: parent.width
        spacing: 10
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 10
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        PanelCard {
            implicitHeight: Math.round(48 * (theme ? theme.uiScale : 1))
            contentItem: RowLayout {
                width: parent.width
                Text {
                    text: "飞行时间"
                    font.pixelSize: Math.round(16 * (theme ? theme.uiScale : 1))
                    color: root.textMain
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    text: state && state.flightTime ? state.flightTime : "--:--"
                    font.pixelSize: Math.round(17 * (theme ? theme.uiScale : 1))
                    font.weight: Font.Bold
                    color: root.brandBlue
                }
            }
        }

        PanelCard {
            visible: root.showMissionControl
            implicitHeight: Math.round(150 * (theme ? theme.uiScale : 1))
            contentItem: Column {
                width: parent.width
                spacing: 12

                Row {
                    width: parent.width
                    height: Math.round(24 * (theme ? theme.uiScale : 1))
                    Text {
                        text: "任务控制"
                        font.pixelSize: Math.round(16 * (theme ? theme.uiScale : 1))
                        font.weight: Font.Bold
                        color: root.textMain
                    }
                    Text {
                        anchors.right: parent.right
                        text: root.missionIsActive() ? (state && state.missionPaused ? "已暂停" : "执行中") : "待执行"
                        font.pixelSize: Math.round(13 * (theme ? theme.uiScale : 1))
                        color: root.missionIsActive() ? "#16a34a" : root.textSub
                    }
                }

                Grid {
                    width: parent.width
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10

                    SmallActionButton {
                        width: (parent.width - parent.columnSpacing) / 2
                        label: "开始任务"
                        requireHold: true
                        enabledState: root.missionStartEnabled()
                        onClicked: root.openStartMissionCheck()
                    }
                    SmallActionButton {
                        width: (parent.width - parent.columnSpacing) / 2
                        label: "继续任务"
                        requireHold: true
                        enabledState: root.missionContinueEnabled()
                        onClicked: root.continueMissionNow()
                    }
                    SmallActionButton {
                        width: (parent.width - parent.columnSpacing) / 2
                        label: "暂停任务"
                        requireHold: true
                        enabledState: root.missionPauseEnabled()
                        onClicked: {
                            console.log("[CustomTakeoff] pause mission clicked")
                            root.pauseMissionNow()
                        }
                    }
                    SmallActionButton {
                        width: (parent.width - parent.columnSpacing) / 2
                        label: "中止任务"
                        tone: "danger"
                        requireHold: true
                        enabledState: root.missionAbortEnabled()
                        onClicked: {
                            console.log("[CustomTakeoff] abort mission clicked")
                            root.abortMissionNow()
                        }
                    }
                }
            }
        }

        PanelCard {
            visible: root.vehicleConnected
            contentItem: Column {
                width: parent.width
                spacing: 8

                Row {
                    width: parent.width
                    height: Math.round(24 * (theme ? theme.uiScale : 1))
                    Text {
                        text: "起飞目标..."
                        font.pixelSize: Math.round(16 * (theme ? theme.uiScale : 1))
                        font.weight: Font.Bold
                        color: root.textMain
                    }
                    Text {
                        anchors.right: parent.right
                        text: root.takeoffTargetExpanded ? "收起" : "展开"
                        font.pixelSize: Math.round(15 * (theme ? theme.uiScale : 1))
                        color: root.brandBlue
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.takeoffTargetExpanded = !root.takeoffTargetExpanded
                    }
                }

                Column {
                    width: parent.width
                    spacing: 8
                    visible: root.takeoffTargetExpanded
                    height: visible ? implicitHeight : 0

                    Text {
                        text: "一键起飞高度"
                        font.pixelSize: Math.round(15 * (theme ? theme.uiScale : 1))
                        color: root.textMain
                    }
                    Text {
                        text: root.takeoffSafetyParamName.length > 0 ? root.takeoffSafetyParamName : "本地起飞目标高度"
                        font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
                        color: root.textSub
                    }
                    Row {
                        spacing: 8
                        TextInput {
                            id: takeoffAltInput
                            width: Math.round(54 * (theme ? theme.uiScale : 1))
                            height: Math.round(36 * (theme ? theme.uiScale : 1))
                            text: "50"
                            selectByMouse: true
                            font.pixelSize: Math.round(14 * (theme ? theme.uiScale : 1))
                            color: root.textMain
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            validator: IntValidator { bottom: 0; top: 500 }
                            onTextEdited: root.takeoffAltConfirmed = false
                            onEditingFinished: root._applyTakeoffAltToUi(text, false)
                            Rectangle {
                                anchors.fill: parent
                                z: -1
                                color: root.theme && root.theme.darkMode ? "#0b0b0b" : "#ffffff"
                                border.width: Math.round(1 * (theme ? theme.uiScale : 1))
                                border.color: root.cardBorder
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "m"
                            font.pixelSize: Math.round(14 * (theme ? theme.uiScale : 1))
                            color: root.textSub
                        }
                        TakeoffAltButton {
                            width: Math.round(34 * (theme ? theme.uiScale : 1))
                            height: Math.round(34 * (theme ? theme.uiScale : 1))
                            label: "-"
                            onActivated: root.adjustTakeoffAlt(-1)
                        }
                        TakeoffAltButton {
                            width: Math.round(34 * (theme ? theme.uiScale : 1))
                            height: Math.round(34 * (theme ? theme.uiScale : 1))
                            label: "+"
                            onActivated: root.adjustTakeoffAlt(1)
                        }
                    }
                    Row {
                        spacing: 8
                        TakeoffAltButton {
                            width: Math.round(98 * (theme ? theme.uiScale : 1))
                            height: Math.round(34 * (theme ? theme.uiScale : 1))
                            label: "使用默认值"
                            onActivated: root.useDefaultTakeoffAlt()
                        }
                        TakeoffAltButton {
                            width: Math.round(70 * (theme ? theme.uiScale : 1))
                            height: Math.round(34 * (theme ? theme.uiScale : 1))
                            label: root.takeoffAltConfirmed ? "已确认" : "确认数值"
                            primary: !root.takeoffAltConfirmed
                            onActivated: root.confirmTakeoffAlt()
                        }
                    }
                    Text {
                        text: "范围 0–500 m"
                        font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
                        color: root.textSub
                    }
                }
            }
        }

        Repeater {
            model: 4
            delegate: Rectangle {
                id: guidedActionButton
                property real holdProgress: 0
                property bool holding: false

                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(72 * (theme ? theme.uiScale : 1))
                radius: 8
                clip: true
                color: !root.actionEnabled(index)
                       ? (theme && theme.darkMode ? "#050505" : "#fbfcfe")
                       : guidedActionButton.holding
                         ? (theme && theme.darkMode ? "#111827" : "#eef5ff")
                         : guidedActionMouse.containsMouse
                           ? (theme && theme.darkMode ? "#0b1220" : "#f7fbff")
                           : (theme && theme.darkMode ? root.cardBg : "#ffffff")
                border.width: Math.round(1 * (theme ? theme.uiScale : 1))
                border.color: root.actionEnabled(index) && (guidedActionMouse.containsMouse || guidedActionButton.holding)
                              ? "#8080B3"
                              : root.cardBorder
                opacity: root.actionEnabled(index) ? 1 : 0.52

                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on border.color { ColorAnimation { duration: 100 } }

                Timer {
                    id: holdTimer
                    interval: 16
                    repeat: true
                    onTriggered: {
                        guidedActionButton.holdProgress = Math.min(1, guidedActionButton.holdProgress + interval / 800)
                        if (guidedActionButton.holdProgress >= 1) {
                            stop()
                            guidedActionButton.holding = false
                            root.triggerAction(index)
                        }
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 16

                    QGCColoredImage {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.round(34 * (theme ? theme.uiScale : 1))
                        height: Math.round(34 * (theme ? theme.uiScale : 1))
                        sourceSize.width: width
                        sourceSize.height: height
                        source: root.actionIcon(index)
                        fillMode: Image.PreserveAspectFit
                        color: root.actionEnabled(index) ? (guidedActionButton.holding || guidedActionMouse.containsMouse ? root.brandBlue : root.textMain) : root.textMuted
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.actionLabel(index)
                            font.pixelSize: Math.round(16 * (theme ? theme.uiScale : 1))
                            font.weight: Font.Medium
                            color: root.actionEnabled(index) ? (guidedActionButton.holding || guidedActionMouse.containsMouse ? root.brandBlue : root.textMain) : root.textMuted
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.actionHint(index)
                            font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
                            color: root.textSub
                        }
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    width: parent.width * guidedActionButton.holdProgress
                    height: Math.round(4 * (theme ? theme.uiScale : 1))
                    radius: 0
                    visible: root.actionEnabled(index) && guidedActionButton.holding
                    color: root.brandBlue
                }

                MouseArea {
                    id: guidedActionMouse
                    anchors.fill: parent
                    enabled: root.actionEnabled(index)
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onPressed: {
                        guidedActionButton.holdProgress = 0
                        guidedActionButton.holding = true
                        holdTimer.restart()
                    }
                    onReleased: {
                        if (guidedActionButton.holding) {
                            guidedActionButton.holding = false
                            holdTimer.stop()
                            guidedActionButton.holdProgress = 0
                        }
                    }
                    onCanceled: {
                        guidedActionButton.holding = false
                        holdTimer.stop()
                        guidedActionButton.holdProgress = 0
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(1 * (theme ? theme.uiScale : 1))
            color: root.cardBorder
        }

        Text {
            Layout.fillWidth: true
            text: "安全设置"
            font.pixelSize: Math.round(15 * (theme ? theme.uiScale : 1))
            font.weight: Font.Bold
            color: root.textSub
            leftPadding: 2
        }

        PanelCard {
            visible: !root.parametersReady
            contentItem: Text {
                width: parent.width
                text: "参数未就绪，当前\n无法读取和修改飞\n控安全参数"
                wrapMode: Text.WordWrap
                font.pixelSize: Math.round(15 * (theme ? theme.uiScale : 1))
                lineHeight: 1.15
                color: root.textMain
            }
        }

        Repeater {
            model: 4
            delegate: PanelCard {
                visible: root.vehicleConnected && root.parametersReady
                contentItem: Column {
                    width: parent.width
                    spacing: 4
                    Text {
                        text: root.safetyLabel(index)
                        font.pixelSize: Math.round(15 * (theme ? theme.uiScale : 1))
                        font.weight: Font.Bold
                        color: root.textMain
                    }
                    Text {
                        text: root.safetyValue(index)
                        font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
                        color: root.textSub
                    }
                }
            }
        }
    }

    Popup {
        id: startMissionCheckPopup
        parent: Overlay.overlay
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: Math.min(450, parent ? parent.width - 48 : 450)
        height: Math.round(252 * (theme ? theme.uiScale : 1))
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
        padding: 0

        background: Rectangle {
            radius: 0
            color: theme && theme.darkMode ? "#111111" : "#ffffff"
            border.width: Math.round(1 * (theme ? theme.uiScale : 1))
            border.color: theme && theme.darkMode ? "#3a3a3a" : "#d7dde6"
        }

        contentItem: Column {
            spacing: 0

            Column {
                width: startMissionCheckPopup.width
                height: Math.round(210 * (theme ? theme.uiScale : 1))
                leftPadding: 18
                rightPadding: 18
                topPadding: 14
                spacing: 10

                Text {
                    text: "开始任务前检查"
                    font.pixelSize: Math.round(15 * (theme ? theme.uiScale : 1))
                    font.weight: Font.Bold
                    color: root.textMain
                }

                Repeater {
                    model: [
                        { label: "飞行器连接", value: root.vehicleConnected ? "已连接" : "未连接" },
                        { label: "任务已加载", value: root.missionLoadedText() },
                        { label: "飞行器可执行", value: state ? state.mainStatusText : "--" },
                        { label: "GPS 定位", value: root.gpsCheckText() },
                        { label: "电池电量", value: state ? state.batteryPercentText : "--" }
                    ]

                    Row {
                        width: startMissionCheckPopup.width - 36
                        height: Math.round(17 * (theme ? theme.uiScale : 1))
                        spacing: 8

                        Text {
                            text: "•"
                            width: Math.round(10 * (theme ? theme.uiScale : 1))
                            font.pixelSize: Math.round(18 * (theme ? theme.uiScale : 1))
                            color: "#16a34a"
                            verticalAlignment: Text.AlignVCenter
                        }
                        Text {
                            text: modelData.label
                            font.pixelSize: Math.round(13 * (theme ? theme.uiScale : 1))
                            color: root.textMain
                            verticalAlignment: Text.AlignVCenter
                        }
                        Text {
                            width: parent.width - 10 - 8 - 110
                            text: modelData.value
                            font.pixelSize: Math.round(13 * (theme ? theme.uiScale : 1))
                            color: root.textMain
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }
                }

                Text {
                    width: startMissionCheckPopup.width - 36
                    text: "GPS 或电池项为警告时仍可执行，但请确认现场飞行条件安全。"
                    wrapMode: Text.WordWrap
                    font.pixelSize: Math.round(13 * (theme ? theme.uiScale : 1))
                    color: "#f59e0b"
                }
            }

            Row {
                width: startMissionCheckPopup.width
                height: Math.round(42 * (theme ? theme.uiScale : 1))

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    Rectangle {
                        width: Math.round(88 * (theme ? theme.uiScale : 1))
                        height: Math.round(30 * (theme ? theme.uiScale : 1))
                        radius: 4
                        color: confirmMouse.pressed
                               ? root.brandPress
                               : confirmMouse.containsMouse
                                 ? root.brandHover
                                 : (theme && theme.darkMode ? "#2b2b2b" : "#ffffff")
                        border.width: Math.round(1 * (theme ? theme.uiScale : 1))
                        border.color: confirmMouse.containsMouse || confirmMouse.pressed ? root.brandBorder : (theme && theme.darkMode ? "#3a3a3a" : "#cfd4dc")
                        Text {
                            anchors.centerIn: parent
                            text: "确定"
                            font.pixelSize: Math.round(13 * (theme ? theme.uiScale : 1))
                            color: confirmMouse.pressed ? "#ffffff" : (confirmMouse.containsMouse ? root.brandBlue : root.textMain)
                        }
                        MouseArea {
                            id: confirmMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.confirmStartMission()
                            }
                        }
                    }

                    Rectangle {
                        width: Math.round(88 * (theme ? theme.uiScale : 1))
                        height: Math.round(30 * (theme ? theme.uiScale : 1))
                        radius: 4
                        color: cancelMouse.pressed
                               ? root.brandPress
                               : cancelMouse.containsMouse
                                 ? root.brandHover
                                 : (theme && theme.darkMode ? "#2b2b2b" : "#ffffff")
                        border.width: Math.round(1 * (theme ? theme.uiScale : 1))
                        border.color: cancelMouse.containsMouse || cancelMouse.pressed ? root.brandBorder : (theme && theme.darkMode ? "#3a3a3a" : "#cfd4dc")
                        Text {
                            anchors.centerIn: parent
                            text: "取消"
                            font.pixelSize: Math.round(13 * (theme ? theme.uiScale : 1))
                            color: cancelMouse.pressed ? "#ffffff" : (cancelMouse.containsMouse ? root.brandBlue : root.textMain)
                        }
                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: startMissionCheckPopup.close()
                        }
                    }
                }
            }
        }
    }
}
