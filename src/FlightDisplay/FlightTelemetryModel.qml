pragma Singleton

import QtQuick 2.15

import QGroundControl
import QGroundControl.FlightDisplay

QtObject {
    property bool dataSuppressed: false
    property var activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property bool communicationLost: activeVehicle ? activeVehicle.vehicleLinkManager.communicationLost : false
    property bool connected: activeVehicle && !communicationLost
    property var batteryFactGroup: activeVehicle && activeVehicle.batteries && activeVehicle.batteries.count > 0 ? activeVehicle.batteries.get(0) : null

    property real roll: factValue(activeVehicle ? activeVehicle.vehicle.roll : null, 0)
    property real pitch: factValue(activeVehicle ? activeVehicle.vehicle.pitch : null, 0)
    // Prefer measured airspeed when it is available; PX4 SITL commonly only publishes ground speed.
    property real measuredAirSpeed: factValue(activeVehicle ? activeVehicle.vehicle.airSpeed : null, 0)
    property real groundSpeed: factValue(activeVehicle ? activeVehicle.vehicle.groundSpeed : null, 0)
    property real airspeed: Math.abs(measuredAirSpeed) > 0.01 ? measuredAirSpeed : groundSpeed
    property real altitude: factValue(activeVehicle ? activeVehicle.vehicle.altitudeRelative : null, 0)
    property real altitudeAMSL: factValue(activeVehicle ? activeVehicle.vehicle.altitudeAMSL : null, 0)
    property real vspeed: factValue(activeVehicle ? activeVehicle.vehicle.climbRate : null, 0)
    property real flightTime: factValue(activeVehicle ? activeVehicle.vehicle.flightTime : null, 0)
    property int localFlightTime: 0
    property real displayFlightTime: Math.max(flightTime, localFlightTime)
    property bool armed: activeVehicle ? activeVehicle.armed : false
    property bool flying: activeVehicle ? activeVehicle.flying : false
    property int battery: Math.round(factValue(batteryFactGroup ? batteryFactGroup.percentRemaining : null, -1))
    property real batteryVoltage: factValue(batteryFactGroup ? batteryFactGroup.voltage : null, -1)
    property real batteryCurrent: factValue(batteryFactGroup ? batteryFactGroup.current : null, -1)
    property var motorLoad: [0.62, 0.58, 0.71, 0.55, 0.66, 0.60]
    property var motorTemp: [46, 44, 52, 41, 48, 45]
    property int gpsSat: Math.round(factValue(activeVehicle ? activeVehicle.gps.count : null, 0))
    property real gpsHdop: factValue(activeVehicle ? activeVehicle.gps.hdop : null, 0)
    property bool displayConnected: activeVehicle && !dataSuppressed
    property string flightMode: displayConnected ? activeVehicle.flightMode : "OFFLINE"
    property string displayMode: displayConnected ? activeVehicle.flightMode : "OFFLINE"
    property string connectionState: displayConnected ? "LINK OK" : "NO LINK"
    property string modeState: displayConnected ? activeVehicle.flightMode : "--"
    property string modePillText: displayConnected ? translatedFlightMode(activeVehicle.flightMode) : "未连接"
    property string armPillText: displayConnected ? (armed ? "已解锁" : "已上锁") : "未连接"
    property color modePillColor: displayConnected ? (flying ? FlightPalette.statusGreen : FlightPalette.statusYellow) : FlightPalette.statusOff
    property color armPillColor: displayConnected ? (armed ? FlightPalette.statusYellow : FlightPalette.statusGreen) : FlightPalette.statusOff
    property real heading: factValue(activeVehicle ? activeVehicle.vehicle.heading : null, 0)
    property real turnRate: 0
    property real _lastHeading: heading
    property double _lastHeadingTime: Date.now()
    property real displayRoll: dataSuppressed ? 0 : roll
    property real displayPitch: dataSuppressed ? 0 : pitch
    property real displayAirspeed: dataSuppressed ? 0 : airspeed
    property real displayAirspeedKnots: displayAirspeed * 1.94384449
    property real displayVspeed: dataSuppressed ? 0 : vspeed
    property real displayAltitude: dataSuppressed ? 0 : altitude
    property real displayAltitudeFeet: displayAltitude * 3.280839895
    property real displayAltitudeAMSL: dataSuppressed ? 0 : altitudeAMSL
    property real displayHeading: dataSuppressed ? 0 : heading
    property real displayTurnRate: dataSuppressed ? 0 : turnRate
    property real displaySlipSkid: dataSuppressed ? 0 : Math.max(-1, Math.min(1, roll / 30.0))
    property real displayBattery: dataSuppressed ? 0 : battery
    property real displayBatteryVoltage: dataSuppressed ? -1 : batteryVoltage
    property real displayBatteryCurrent: dataSuppressed ? -1 : batteryCurrent
    property int displayGpsSat: dataSuppressed ? 0 : gpsSat
    property real displayGpsHdop: dataSuppressed ? 0 : gpsHdop
    property var guidedController: globals.guidedControllerFlyView
    property date localTime: new Date()

    function factValue(fact, fallback) {
        if (!fact) {
            return fallback
        }

        var value = fact.rawValue
        return isFinite(value) ? value : fallback
    }

    function formatElapsed(seconds) {
        var total = Math.max(0, Math.floor(seconds))
        var minutes = Math.floor(total / 60)
        var secs = total % 60

        return String(minutes).padStart(2, "0") + ":" +
               String(secs).padStart(2, "0")
    }

    function translatedFlightMode(mode) {
        switch (mode) {
        case "Manual":
            return "手动"
        case "Stabilized":
            return "自稳"
        case "Acro":
            return "特技"
        case "Altitude":
        case "Altitude Hold":
            return "定高"
        case "Position":
        case "Position Hold":
        case "Loiter":
            return "定点"
        case "Mission":
        case "Auto Mission":
            return "任务"
        case "Return":
        case "Return to Launch":
        case "RTL":
            return "返航"
        case "Land":
            return "降落"
        case "Takeoff":
            return "起飞"
        case "Hold":
            return "悬停"
        case "Offboard":
            return "外部控制"
        case "Follow Me":
            return "跟随"
        default:
            return mode && mode.length > 0 ? mode : "--"
        }
    }

    function directTakeoff() {
        if (!activeVehicle) {
            return
        }

        if (activeVehicle.guidedTakeoffSupported) {
            activeVehicle.guidedModeTakeoff(activeVehicle.minimumTakeoffAltitudeMeters())
        } else {
            activeVehicle.startTakeoff()
        }
    }

    property Timer clockTimer: Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: FlightTelemetryModel.localTime = new Date()
    }

    property Timer flightClockTimer: Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (FlightTelemetryModel.connected && FlightTelemetryModel.armed) {
                FlightTelemetryModel.localFlightTime += 1
            } else {
                FlightTelemetryModel.localFlightTime = 0
            }
        }
    }

    property Timer turnRateTimer: Timer {
        interval: 250
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var now = Date.now()
            var elapsed = Math.max(0.001, (now - FlightTelemetryModel._lastHeadingTime) / 1000.0)
            var delta = FlightTelemetryModel.heading - FlightTelemetryModel._lastHeading

            if (delta > 180) {
                delta -= 360
            } else if (delta < -180) {
                delta += 360
            }

            var rate = delta / elapsed
            FlightTelemetryModel.turnRate = isFinite(rate) ? rate : 0
            FlightTelemetryModel._lastHeading = FlightTelemetryModel.heading
            FlightTelemetryModel._lastHeadingTime = now
        }
    }
}
