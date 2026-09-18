import QtQuick 2.15

import QGroundControl.FlightDisplay

QtObject {
    id: root

    property bool selfCheckActive: false
    property bool fatalWarningTest: false
    property bool hadTelemetryConnection: false
    property bool selfCheckCompletedForConnection: false
    property bool connectionLossConfirmed: false
    property real selfCheckProgress: 0
    property int selfCheckElapsedMs: 0
    readonly property int selfCheckTimeoutMs: 15000
    readonly property int selfCheckDurationMs: 2400
    readonly property var selfCheckItems: ["电池", "GPS", "通信链路", "姿态传感器", "电机", "舵机限位"]
    property var selfCheckStates: [0, 0, 0, 0, 0, 0] // 0 waiting, 1 checking, 2 passed, 3 failed
    property var selfCheckReasons: ["", "", "", "", "", ""]
    property int selfCheckDisplayStep: 0
    readonly property bool selfCheckFailed: selfCheckStates.indexOf(3) >= 0
    readonly property bool selfCheckFinished: selfCheckDisplayStep >= selfCheckStates.length
    readonly property bool dataSuppressed: connectionLossConfirmed
    readonly property int lowBatteryThreshold: 25
    readonly property bool batteryReadingValid: !dataSuppressed && FlightTelemetryModel.activeVehicle && FlightTelemetryModel.battery >= 0
    readonly property bool lowBatteryWarning: batteryReadingValid && FlightTelemetryModel.battery <= lowBatteryThreshold
    readonly property real fatalRollLimit: 45
    readonly property real fatalPitchLimit: 30
    readonly property bool fatalAttitudeWarning: fatalWarningTest ||
                                                (FlightTelemetryModel.connected &&
                                                 (Math.abs(FlightTelemetryModel.roll) >= fatalRollLimit ||
                                                  Math.abs(FlightTelemetryModel.pitch) >= fatalPitchLimit))

    onDataSuppressedChanged: FlightTelemetryModel.dataSuppressed = dataSuppressed
    Component.onCompleted: {
        FlightTelemetryModel.dataSuppressed = dataSuppressed
        if (FlightTelemetryModel.connected) {
            hadTelemetryConnection = true
            startSelfCheck(false)
        }
    }

    function startSelfCheck(force) {
        if (!force && selfCheckCompletedForConnection) {
            return
        }
        selfCheckRetryTimer.stop()
        selfCheckElapsedMs = 0
        selfCheckProgress = 0
        selfCheckStates = [1, 1, 1, 1, 1, 1]
        selfCheckReasons = ["", "", "", "", "", ""]
        selfCheckDisplayStep = 0
        selfCheckActive = true
        selfCheckTimer.restart()
    }

    function evaluateSelfCheck() {
        var states = selfCheckStates.slice()
        var reasons = selfCheckReasons.slice()
        if (!batteryReadingValid) {
            states[0] = 2; reasons[0] = "模拟器未提供"
        } else if (FlightTelemetryModel.battery < lowBatteryThreshold) {
            states[0] = 3; reasons[0] = "电量偏低，需要 " + lowBatteryThreshold + "%+"
        } else { states[0] = 2; reasons[0] = batteryText() }
        if (FlightTelemetryModel.gpsSat < 6 || FlightTelemetryModel.gpsHdop <= 0) {
            states[1] = 2; reasons[1] = "模拟器未提供"
        } else if (FlightTelemetryModel.gpsHdop > 2.0) {
            states[1] = 3; reasons[1] = "HDOP 偏高，需要 <= 2.0"
        } else { states[1] = 2; reasons[1] = FlightTelemetryModel.gpsSat + " 星  HDOP " + FlightTelemetryModel.gpsHdop.toFixed(1) }
        if (!FlightTelemetryModel.connected) {
            states[2] = 3; reasons[2] = "未连接"
        } else { states[2] = 2; reasons[2] = "已连接" }
        if (Math.abs(FlightTelemetryModel.roll) > 5 || Math.abs(FlightTelemetryModel.pitch) > 5) {
            states[3] = 3; reasons[3] = "姿态偏差 > 5°"
        } else { states[3] = 2; reasons[3] = "横滚 " + FlightTelemetryModel.roll.toFixed(1) + "  俯仰 " + FlightTelemetryModel.pitch.toFixed(1) }
        states[4] = 2; reasons[4] = "模拟器跳过"
        states[5] = 2; reasons[5] = "模拟器跳过"
        selfCheckStates = states
        selfCheckReasons = reasons
    }

    function selfCheckResult(index) {
        switch (index) {
        case 0:
            return selfCheckReasons[index] || batteryText()
        case 1:
            return selfCheckReasons[index]
        case 2:
            return selfCheckReasons[index]
        case 3:
            return selfCheckReasons[index]
        case 4:
            return selfCheckReasons[index] || "读取中"
        case 5:
            return selfCheckReasons[index] || "读取中"
        default:
            return "--"
        }
    }

    function batteryText() {
        return batteryReadingValid ? (Math.max(0, Math.min(100, FlightTelemetryModel.battery)) + "%") : "--"
    }

    function limitedMetricColor(value, maximumValue, normalColor) {
        var ratio = maximumValue > 0 ? Math.max(0, Math.min(1, Math.abs(value) / maximumValue)) : 0
        if (ratio >= 0.92) {
            return FlightPalette.statusRed
        }
        if (ratio >= 0.75) {
            return FlightPalette.statusYellow
        }
        return normalColor
    }

    function batteryGaugeColor() {
        if (!batteryReadingValid) {
            return FlightPalette.statusOff
        }
        if (FlightTelemetryModel.battery < 20) {
            return FlightPalette.statusRed
        }
        if (FlightTelemetryModel.battery <= 40) {
            return FlightPalette.statusYellow
        }
        return FlightPalette.green
    }

    property Timer selfCheckTimer: Timer {
        id: selfCheckTimer
        interval: 50
        repeat: true
        onTriggered: {
            root.selfCheckElapsedMs += interval
            root.evaluateSelfCheck()
            root.selfCheckDisplayStep = Math.min(root.selfCheckStates.length, Math.floor(root.selfCheckElapsedMs / 400))
            root.selfCheckProgress = root.selfCheckDisplayStep / root.selfCheckStates.length

            if (root.selfCheckDisplayStep >= root.selfCheckStates.length) {
                stop()
                root.selfCheckCompletedForConnection = true
                if (!root.selfCheckFailed) selfCheckHoldTimer.restart()
            }
        }
    }

    property Timer selfCheckHoldTimer: Timer {
        id: selfCheckHoldTimer
        interval: 250
        repeat: false
        onTriggered: if (!root.selfCheckFailed) root.selfCheckActive = false
    }

    property Timer selfCheckRetryTimer: Timer {
        id: selfCheckRetryTimer
        interval: 2000
        repeat: true
        running: false
        onTriggered: root.startSelfCheck(true)
    }

    property Timer connectionLossConfirmTimer: Timer {
        id: connectionLossConfirmTimer
        interval: 1500
        repeat: false
        onTriggered: {
            if (!FlightTelemetryModel.connected && root.hadTelemetryConnection) {
                root.connectionLossConfirmed = true
            }
        }
    }

    property Connections telemetryConnections: Connections {
        target: FlightTelemetryModel
        function onConnectedChanged() {
            if (FlightTelemetryModel.connected) {
                root.hadTelemetryConnection = true
                root.connectionLossConfirmed = false
                connectionLossConfirmTimer.stop()
                root.startSelfCheck(false)
            } else {
                if (root.hadTelemetryConnection) {
                    connectionLossConfirmTimer.restart()
                }
                selfCheckTimer.stop()
                selfCheckHoldTimer.stop()
                root.selfCheckActive = false
                root.selfCheckProgress = 0
                root.selfCheckElapsedMs = 0
                root.selfCheckStates = [0, 0, 0, 0, 0, 0]
                root.selfCheckReasons = ["", "", "", "", "", ""]
                root.selfCheckDisplayStep = 0
            }
        }
    }
}
