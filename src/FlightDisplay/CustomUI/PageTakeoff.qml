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
    readonly property var safetyControllerVehicle: safetyController.vehicle
    readonly property bool vehicleConnected: !!(state && state.vehicleConnected)
    readonly property bool vehicleAvailable: !!(state && state.vehicleAvailable)
    readonly property bool parametersReady: !!(activeVehicle && activeVehicle.parameterManager && activeVehicle.parameterManager.parametersReady)
    readonly property bool hasMission: !!(root.state && root.state.missionAvailable)
    readonly property bool showMissionControl: hasMission && vehicleConnected
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
    property bool actionsExpanded: false
    property bool actionAltConfirmed: true
    property bool actionSpeedConfirmed: true
    property var safetyConfirmed: [ true, true, true, true ]
    property var safetyExpanded: [ false, false, false, false ]

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
            actionsExpanded = false
            syncActionValuesFromVehicle()
            syncTakeoffAltFromParam()
        }
    }
    onTakeoffSafetyFactChanged: syncTakeoffAltFromParam()
    onActiveVehicleChanged: syncActionValuesFromVehicle()

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
        if (!parametersReady || !safetyControllerVehicle) {
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
        if (!parametersReady || !safetyControllerVehicle) {
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
        if (!root.missionStartEnabled()) {
            startMissionCheckPopup.close()
            return
        }
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
        return !!(root.state.missionRunning || root.state.canResumeMission)
    }

    function missionStartEnabled() {
        if (!state || !root.vehicleConnected || !root.hasMission) {
            return false
        }
        if (!root.state.canStartMission) return false
        if (guided && guided.showStartMission !== undefined) {
            return guided.showStartMission
        }
        return !root.missionIsActive()
    }

    function missionContinueEnabled() {
        if (!state || !root.vehicleConnected || !root.hasMission) {
            return false
        }
        return root.state.canResumeMission
    }

    function continueMissionNow() {
        if (!root.missionContinueEnabled()) return
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
        return !!(root.state.missionRunning && root.state.canHoldPosition)
    }

    function missionAbortEnabled() {
        return root.missionIsActive()
    }

    function pauseMissionNow() {
        if (!root.missionPauseEnabled()) return
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
        if (!root.missionAbortEnabled()) return
        root.state.missionSessionActive = false
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

    function additionalActionEnabled(kind) {
        if (!activeVehicle || !root.vehicleConnected || !activeVehicle.armed || !activeVehicle.flying || !activeVehicle.guidedModeSupported) {
            return false
        }
        if (kind === "speed") {
            return activeVehicle.haveMRSpeedLimits || activeVehicle.fixedWing || activeVehicle.vtolInFwdFlight
        }
        return true
    }

    function _clampActionAltitude(value) {
        var numberValue = Number(value)
        if (!(numberValue === numberValue)) {
            numberValue = activeVehicle && activeVehicle.altitudeRelative ? Number(activeVehicle.altitudeRelative.rawValue) : 50
        }
        return Math.max(0, Math.min(1000, Math.round(numberValue)))
    }

    function _clampActionSpeed(value) {
        var numberValue = Number(value)
        if (!(numberValue === numberValue)) {
            numberValue = 5
        }
        return Math.max(0.1, Math.min(100, Math.round(numberValue * 10) / 10))
    }

    function syncActionValuesFromVehicle() {
        if (actionAltEditor && activeVehicle && activeVehicle.altitudeRelative) {
            actionAltEditor.valueText = String(root._clampActionAltitude(activeVehicle.altitudeRelative.rawValue))
        }
        if (actionSpeedEditor) {
            var speed = state && state.groundSpeed === state.groundSpeed ? Number(state.groundSpeed) : 5
            actionSpeedEditor.valueText = root._clampActionSpeed(Math.max(1, speed)).toFixed(1)
        }
        root.actionAltConfirmed = true
        root.actionSpeedConfirmed = true
    }

    function useDefaultActionAltitude() {
        if (activeVehicle && activeVehicle.altitudeRelative) {
            actionAltEditor.valueText = String(root._clampActionAltitude(activeVehicle.altitudeRelative.rawValue))
        } else {
            actionAltEditor.valueText = "50"
        }
        root.actionAltConfirmed = false
    }

    function useDefaultActionSpeed() {
        actionSpeedEditor.valueText = "5.0"
        root.actionSpeedConfirmed = false
    }

    function adjustActionAltitude(delta) {
        actionAltEditor.valueText = String(root._clampActionAltitude(Number(actionAltEditor.valueText) + delta))
        root.actionAltConfirmed = false
    }

    function adjustActionSpeed(delta) {
        actionSpeedEditor.valueText = root._clampActionSpeed(Number(actionSpeedEditor.valueText) + delta).toFixed(1)
        root.actionSpeedConfirmed = false
    }

    function confirmActionAltitude() {
        if (!activeVehicle) {
            return
        }
        var targetAlt = root._clampActionAltitude(actionAltEditor.valueText)
        var currentAlt = activeVehicle.altitudeRelative ? Number(activeVehicle.altitudeRelative.rawValue) : 0
        activeVehicle.guidedModeChangeAltitude(targetAlt - currentAlt, false)
        actionAltEditor.valueText = String(targetAlt)
        root.actionAltConfirmed = true
    }

    function confirmActionSpeed() {
        if (!activeVehicle) {
            return
        }
        var targetSpeed = root._clampActionSpeed(actionSpeedEditor.valueText)
        if (activeVehicle.vtolInFwdFlight || activeVehicle.fixedWing) {
            activeVehicle.guidedModeChangeEquivalentAirspeedMetersSecond(targetSpeed)
        } else {
            activeVehicle.guidedModeChangeGroundSpeedMetersSecond(targetSpeed)
        }
        actionSpeedEditor.valueText = targetSpeed.toFixed(1)
        root.actionSpeedConfirmed = true
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

    function safetyFact(index) {
        switch (index) {
        case 0: return rtlAltFact
        case 1: return takeoffSafetyFact
        case 2: return batteryThresholdFact
        default: return linkLossTimeoutFact
        }
    }

    function safetyParamName(index) {
        switch (index) {
        case 0: return rtlAltParamName.length > 0 ? rtlAltParamName : "RTL_RETURN_ALT"
        case 1: return takeoffSafetyParamName.length > 0 ? takeoffSafetyParamName : "MIS_TAKEOFF_ALT"
        case 2: return batteryThresholdParamName.length > 0 ? batteryThresholdParamName : "BAT_LOW_THR"
        default: return linkLossTimeoutParamName.length > 0 ? linkLossTimeoutParamName : "COM_DL_LOSS_T"
        }
    }

    function safetyUnit(index) {
        if (index === 2) {
            return batteryThresholdParamName.indexOf("VOLT") !== -1 ? "V" : (batteryThresholdParamName.indexOf("MAH") !== -1 ? "mAh" : "")
        }
        return index === 3 ? "s" : "m"
    }

    function safetyStep(index) {
        if (index === 2) {
            return batteryThresholdParamName === "BAT_LOW_THR" ? 0.01 : 0.1
        }
        return index === 3 ? 1 : 1
    }

    function safetyDecimals(index) {
        return index === 2 ? (batteryThresholdParamName === "BAT_LOW_THR" ? 2 : 1) : 0
    }

    function safetyRangeText(index) {
        switch (index) {
        case 0: return "范围 0–1000 m"
        case 1: return "范围 0–500 m"
        case 2: return batteryThresholdParamName === "BAT_LOW_THR" ? "范围 0.00–1.00" : "按当前飞控参数单位"
        default: return "范围 0–300 s"
        }
    }

    function safetyRawValue(index) {
        var fact = root.safetyFact(index)
        if (!fact) {
            return NaN
        }
        var value = fact.rawValue !== undefined && fact.rawValue !== null ? Number(fact.rawValue) : NaN
        if (value === value) {
            return value
        }
        value = fact.value !== undefined && fact.value !== null ? Number(fact.value) : NaN
        if (value === value) {
            return value
        }
        if (fact.valueString !== undefined && fact.valueString !== null) {
            value = parseFloat(String(fact.valueString).replace(",", "."))
            if (value === value) {
                return value
            }
        }
        return NaN
    }

    function safetyValueText(index) {
        var value = root.safetyRawValue(index)
        if (!(value === value)) {
            return ""
        }
        return value.toFixed(root.safetyDecimals(index))
    }

    function clampSafetyValue(index, value) {
        var numberValue = Number(value)
        if (!(numberValue === numberValue)) {
            numberValue = root.safetyRawValue(index)
        }
        if (!(numberValue === numberValue)) {
            numberValue = 0
        }
        switch (index) {
        case 0: numberValue = Math.max(0, Math.min(1000, numberValue)); break
        case 1: numberValue = Math.max(0, Math.min(500, numberValue)); break
        case 2:
            if (batteryThresholdParamName === "BAT_LOW_THR") {
                numberValue = Math.max(0, Math.min(1, numberValue))
            }
            break
        default: numberValue = Math.max(0, Math.min(300, numberValue)); break
        }
        return Number(numberValue.toFixed(root.safetyDecimals(index)))
    }

    function safetyConfirmedAt(index) {
        return safetyConfirmed[index] !== false
    }

    function setSafetyConfirmed(index, confirmed) {
        var values = safetyConfirmed.slice(0)
        values[index] = confirmed
        safetyConfirmed = values
    }

    function safetyExpandedAt(index) {
        return safetyExpanded[index] === true
    }

    function toggleSafetyExpanded(index) {
        var values = safetyExpanded.slice(0)
        values[index] = !values[index]
        safetyExpanded = values
    }

    function safetyCollapsedValue(index) {
        var factText = root.safetyValue(index)
        if (factText && factText !== "--") {
            return factText
        }
        var value = root.safetyValueText(index)
        var unit = root.safetyUnit(index)
        if (value.length === 0) {
            return "--"
        }
        return unit.length > 0 ? (value + " " + unit) : value
    }

    function useDefaultSafetyValue(index, editor) {
        var fact = root.safetyFact(index)
        if (fact && fact.defaultValueAvailable) {
            editor.valueText = root.clampSafetyValue(index, fact.defaultValue).toFixed(root.safetyDecimals(index))
        } else {
            editor.valueText = root.safetyValueText(index)
        }
        root.setSafetyConfirmed(index, false)
    }

    function adjustSafetyValue(index, editor, delta) {
        editor.valueText = root.clampSafetyValue(index, Number(editor.valueText) + delta).toFixed(root.safetyDecimals(index))
        root.setSafetyConfirmed(index, false)
    }

    function confirmSafetyValue(index, editor) {
        var fact = root.safetyFact(index)
        if (!fact) {
            return
        }
        var value = root.clampSafetyValue(index, editor.valueText)
        fact.value = value
        editor.valueText = value.toFixed(root.safetyDecimals(index))
        root.setSafetyConfirmed(index, true)
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
        opacity: enabled ? 1 : 0.45
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
            enabled: takeoffAltButtonRoot.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: takeoffAltButtonRoot.activated()
        }
    }

    component ActionValueEditor: Column {
        id: editorRoot

        property string title: ""
        property string subtitle: ""
        property string unit: ""
        property string rangeText: ""
        property alias valueText: valueInput.text
        property bool confirmed: true
        property bool enabledState: true
        property bool showHeader: true
        signal minus
        signal plus
        signal useDefault
        signal confirm
        signal edited

        spacing: 6
        opacity: enabledState ? 1 : 0.48

        Text {
            width: parent.width
            visible: editorRoot.showHeader
            height: visible ? implicitHeight : 0
            text: editorRoot.title
            font.pixelSize: Math.round(14 * (theme ? theme.uiScale : 1))
            font.weight: Font.Bold
            color: root.textMain
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: editorRoot.showHeader
            height: visible ? implicitHeight : 0
            text: editorRoot.subtitle
            font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
            color: root.textSub
            elide: Text.ElideRight
        }

        Row {
            width: parent.width
            spacing: 8
            height: Math.round(34 * (theme ? theme.uiScale : 1))

            TextInput {
                id: valueInput
                width: Math.round(44 * (theme ? theme.uiScale : 1))
                height: parent.height
                enabled: editorRoot.enabledState
                selectByMouse: true
                font.pixelSize: Math.round(13 * (theme ? theme.uiScale : 1))
                color: root.textMain
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                validator: DoubleValidator { bottom: 0; top: 1000; decimals: 1 }
                onTextEdited: editorRoot.edited()

                Rectangle {
                    anchors.fill: parent
                    z: -1
                    radius: 2
                    color: root.theme && root.theme.darkMode ? "#0b0b0b" : "#ffffff"
                    border.width: Math.round(1 * (theme ? theme.uiScale : 1))
                    border.color: root.cardBorder
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: editorRoot.unit
                font.pixelSize: Math.round(13 * (theme ? theme.uiScale : 1))
                color: root.textSub
            }

            TakeoffAltButton {
                width: Math.round(30 * (theme ? theme.uiScale : 1))
                height: parent.height
                enabled: editorRoot.enabledState
                label: "−"
                onActivated: editorRoot.minus()
            }

            TakeoffAltButton {
                width: Math.round(30 * (theme ? theme.uiScale : 1))
                height: parent.height
                enabled: editorRoot.enabledState
                label: "+"
                onActivated: editorRoot.plus()
            }
        }

        Row {
            width: parent.width
            spacing: 8
            height: Math.round(32 * (theme ? theme.uiScale : 1))

            TakeoffAltButton {
                width: Math.round(94 * (theme ? theme.uiScale : 1))
                height: parent.height
                enabled: editorRoot.enabledState
                label: "使用默认值"
                onActivated: editorRoot.useDefault()
            }

            TakeoffAltButton {
                width: Math.round(74 * (theme ? theme.uiScale : 1))
                height: parent.height
                enabled: editorRoot.enabledState
                label: editorRoot.confirmed ? "已确认" : "确认执行"
                primary: !editorRoot.confirmed
                onActivated: editorRoot.confirm()
            }
        }

        Text {
            width: parent.width
            text: editorRoot.rangeText
            font.pixelSize: Math.round(11 * (theme ? theme.uiScale : 1))
            color: root.textSub
            elide: Text.ElideRight
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
                        text: root.missionIsActive() ? (root.state && root.state.missionPaused ? "已暂停" : "执行中") : "待执行"
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
                        text: "起飞目标高度"
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

        PanelCard {
            visible: root.vehicleConnected && !!(activeVehicle && activeVehicle.flying)
            contentItem: Column {
                width: parent.width
                spacing: 8

                Row {
                    width: parent.width
                    height: Math.round(28 * (theme ? theme.uiScale : 1))

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "飞行动作"
                        font.pixelSize: Math.round(16 * (theme ? theme.uiScale : 1))
                        font.weight: Font.Bold
                        color: root.textMain
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.actionsExpanded ? "收起" : "展开"
                        font.pixelSize: Math.round(15 * (theme ? theme.uiScale : 1))
                        color: root.brandBlue
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.actionsExpanded = !root.actionsExpanded
                    }
                }

                Column {
                    width: parent.width
                    spacing: 14
                    visible: root.actionsExpanded
                    height: visible ? implicitHeight : 0

                    ActionValueEditor {
                        id: actionAltEditor
                        width: parent.width
                        title: "改变高度"
                        subtitle: "目标相对高度"
                        unit: "m"
                        rangeText: "范围 0–1000 m"
                        valueText: "50"
                        confirmed: root.actionAltConfirmed
                        enabledState: root.additionalActionEnabled("altitude")
                        onEdited: root.actionAltConfirmed = false
                        onMinus: root.adjustActionAltitude(-1)
                        onPlus: root.adjustActionAltitude(1)
                        onUseDefault: root.useDefaultActionAltitude()
                        onConfirm: root.confirmActionAltitude()
                    }

                    ActionValueEditor {
                        id: actionSpeedEditor
                        width: parent.width
                        title: "改变最大地速"
                        subtitle: "最大地速"
                        unit: "m/s"
                        rangeText: "范围 0.1–100.0 m/s"
                        valueText: "5.0"
                        confirmed: root.actionSpeedConfirmed
                        enabledState: root.additionalActionEnabled("speed")
                        onEdited: root.actionSpeedConfirmed = false
                        onMinus: root.adjustActionSpeed(-0.5)
                        onPlus: root.adjustActionSpeed(0.5)
                        onUseDefault: root.useDefaultActionSpeed()
                        onConfirm: root.confirmActionSpeed()
                    }

                    Text {
                        width: parent.width
                        text: "飞行中可用；未解锁或未起飞时会自动禁用。"
                        wrapMode: Text.WordWrap
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
            color: root.textMain
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
                    id: safetyCardContent
                    width: parent.width
                    spacing: 8

                    RowLayout {
                        width: parent.width
                        height: Math.round(42 * (theme ? theme.uiScale : 1))
                        spacing: 8

                        Column {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            Text {
                                width: parent.width
                                text: root.safetyLabel(index)
                                font.pixelSize: Math.round(15 * (theme ? theme.uiScale : 1))
                                font.weight: Font.Bold
                                color: root.textMain
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: root.safetyParamName(index)
                                font.pixelSize: Math.round(11 * (theme ? theme.uiScale : 1))
                                color: root.brandBlue
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            id: valueSummary
                            Layout.preferredWidth: Math.round(54 * (theme ? theme.uiScale : 1))
                            Layout.alignment: Qt.AlignVCenter
                            text: root.safetyCollapsedValue(index)
                            horizontalAlignment: Text.AlignRight
                            font.pixelSize: Math.round(13 * (theme ? theme.uiScale : 1))
                            font.weight: Font.DemiBold
                            color: theme && theme.darkMode ? "#dbeafe" : "#475569"
                            elide: Text.ElideRight
                        }

                        Text {
                            id: expandText
                            Layout.preferredWidth: Math.round(28 * (theme ? theme.uiScale : 1))
                            Layout.alignment: Qt.AlignVCenter
                            text: root.safetyExpandedAt(index) ? "收起" : "展开"
                            horizontalAlignment: Text.AlignRight
                            font.pixelSize: Math.round(13 * (theme ? theme.uiScale : 1))
                            color: root.brandBlue
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleSafetyExpanded(index)
                        }
                    }

                    ActionValueEditor {
                        id: safetyEditor
                        width: parent.width
                        visible: root.safetyExpandedAt(index)
                        height: visible ? implicitHeight : 0
                        title: ""
                        subtitle: ""
                        unit: root.safetyUnit(index)
                        rangeText: root.safetyRangeText(index)
                        valueText: root.safetyValueText(index)
                        confirmed: root.safetyConfirmedAt(index)
                        enabledState: !!root.safetyFact(index)
                        showHeader: false
                        onEdited: root.setSafetyConfirmed(index, false)
                        onMinus: root.adjustSafetyValue(index, safetyEditor, -root.safetyStep(index))
                        onPlus: root.adjustSafetyValue(index, safetyEditor, root.safetyStep(index))
                        onUseDefault: root.useDefaultSafetyValue(index, safetyEditor)
                        onConfirm: root.confirmSafetyValue(index, safetyEditor)
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
