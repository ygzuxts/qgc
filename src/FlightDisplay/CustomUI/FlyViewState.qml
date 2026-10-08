// FlyViewState.qml
//共享数据层：绑定 QGC activeVehicle，无连接时明确显示未连接状态

import QtQml
import QGroundControl

QtObject {
 // QGC活动飞行器（由 FlyViewCustomLayer 注入）
 property var activeVehicle: null
 property var missionController: null
 property var guidedController: null
 property var unitsConversion: QGroundControl.unitsConversion
 property bool customFlyViewEnabled: true
 property var setCustomFlyViewEnabled: null
  property bool showLeftPanel: false
  property var setShowLeftPanel: null
  property real sidePanelOpacity: 0.92
  property var setSidePanelOpacity: null
  property bool showHudExpandBar: true
  property var setShowHudExpandBar: null
  property real infoBarOpacity: 0.82
  property var setInfoBarOpacity: null
  property bool showBottomActionBar: true
  property var setShowBottomActionBar: null
 readonly property var efi: vehicleConnected && activeVehicle && activeVehicle.efi ? activeVehicle.efi : null
 readonly property var generator: vehicleConnected && activeVehicle && activeVehicle.generator ? activeVehicle.generator : null
 readonly property var rpmGroup: vehicleConnected && activeVehicle && activeVehicle.rpm ? activeVehicle.rpm : null

 property bool vehicleAvailable: !!activeVehicle
 property bool communicationLost: !!(activeVehicle && activeVehicle.communicationLost)
 property bool vehicleConnected: vehicleAvailable && !communicationLost
 property bool armed: activeVehicle ? activeVehicle.armed : false
 property bool flying: activeVehicle ? activeVehicle.flying : false
 property bool landing: activeVehicle ? activeVehicle.landing : false
 property bool healthAndArmingChecksSupported: !!(activeVehicle && activeVehicle.healthAndArmingCheckReport && activeVehicle.healthAndArmingCheckReport.supported)
 readonly property bool flightModeSetAvailable: activeVehicle ? activeVehicle.flightModeSetAvailable : false
 readonly property var flightModes: activeVehicle ? activeVehicle.flightModes : []
 property bool pendingMissionAvailable: false
 readonly property bool missionAvailable: missionController ? missionController.missionItemCount > 1 : false
 readonly property bool missionControlAvailable: missionAvailable || pendingMissionAvailable
 property bool canTakeoff: vehicleConnected && activeVehicle && !activeVehicle.flying && (!!activeVehicle.takeoffVehicleSupported || (guidedController && guidedController.showTakeoff))
 property bool canLand: vehicleConnected && activeVehicle && (!!activeVehicle.guidedModeSupported || activeVehicle.armed || activeVehicle.flying || (guidedController && guidedController.showLand))
 property bool canStartMission: vehicleConnected && activeVehicle && missionControlAvailable
 readonly property bool canHoldPosition: vehicleConnected && activeVehicle && (!!activeVehicle.pauseVehicleSupported || activeVehicle.armed || activeVehicle.flying || (guidedController && guidedController.showPause))
 readonly property bool canReturnToLaunch: vehicleConnected && activeVehicle && (!!activeVehicle.guidedModeSupported || activeVehicle.armed || activeVehicle.flying || (guidedController && guidedController.showRTL))
 readonly property bool canResumeMission: vehicleConnected && activeVehicle && missionControlAvailable
 readonly property bool canEmergencyStop: vehicleAvailable && armed
 readonly property bool canForceArm: guidedController ? guidedController.showForceArm : (vehicleAvailable && !armed)

 // ── 飞行数据（采样刷新，避免 MockLink 高频更新压垮 QML 主线程）──
 property real altitude: NaN
 property real absoluteAltitude: NaN
 property real speed: NaN
 property real groundSpeed: NaN
 property real airSpeed: NaN
 property real heading: NaN
 property real roll: NaN
 property real pitch: NaN
 property real climbRate: NaN
 property real latitude: NaN
 property real longitude: NaN
 property var primaryBattery: null
 property int battery: -1
 property real voltage: NaN
 property string batteryText: "--"
 property string batteryPercentText: "--"
 property string batteryVoltageText: "--"
 property string batteryChargeStateText: "--"
 property int throttle: -1
 property var mavlinkSentCount: 0
 property var mavlinkReceivedCount: 0
 property real mavlinkLossPercent: NaN
 readonly property int linkQualityBars: {
  if (!vehicleConnected || mavlinkLossPercent !== mavlinkLossPercent) {
   return 0
  }
  return Math.max(0, Math.min(6, 6 - Math.round(mavlinkLossPercent / 20)))
 }
 property string flightMode: "未连接"
 property string flightModeDisplayText: "--"

 readonly property string mainStatusText: {
  if (!activeVehicle) {
   return "Disconnected"
  }
  if (communicationLost) {
   return "Comms Lost"
  }
  if (activeVehicle.armed) {
   if (activeVehicle.flying) {
    return "Flying"
   }
   if (activeVehicle.landing) {
    return "Landing"
   }
   return "Armed"
  }
  if (healthAndArmingChecksSupported) {
   return activeVehicle.healthAndArmingCheckReport.canArm ? "Ready" : "Not Ready"
  }
  if (activeVehicle.readyToFlyAvailable) {
   return activeVehicle.readyToFly ? "Ready" : "Not Ready"
  }
  return activeVehicle.allSensorsHealthy && activeVehicle.autopilotPlugin && activeVehicle.autopilotPlugin.setupComplete ? "Ready" : "Not Ready"
 }
 readonly property string mainStatusTone: {
  if (!activeVehicle || communicationLost) {
   return communicationLost ? "red" : "gray"
  }
  if (activeVehicle.armed) {
   if (healthAndArmingChecksSupported && !activeVehicle.healthAndArmingCheckReport.canArm) {
    return "red"
   }
   return healthAndArmingChecksSupported && activeVehicle.healthAndArmingCheckReport.hasWarningsOrErrors ? "amber" : "green"
  }
  if (healthAndArmingChecksSupported) {
   if (!activeVehicle.healthAndArmingCheckReport.canArm) {
    return "red"
   }
   return activeVehicle.healthAndArmingCheckReport.hasWarningsOrErrors ? "amber" : "green"
  }
  if (activeVehicle.readyToFlyAvailable) {
   return activeVehicle.readyToFly ? "green" : "amber"
  }
  return activeVehicle.allSensorsHealthy && activeVehicle.autopilotPlugin && activeVehicle.autopilotPlugin.setupComplete ? "green" : "amber"
 }
 property string gpsStatus: "未连接"
 property int gpsSatellites: -1
 property string gpsSatellitesText: "--"
 property string gpsLockText: "--"
 property string gpsHdopText: "--"
 readonly property string armStateText: !vehicleConnected ? "未连接" : (armed ? "已解锁" : "未解锁")
 property string efiHealthText: "--"
 property string efiRpmText: "--"
 property string efiFuelConsumedText: "--"
 property string efiFuelFlowText: "--"
 property string efiEngineLoadText: "--"
 property string efiThrottlePosText: "--"
 property string efiCylinderTempText: "--"
 property string efiExGasTempText: "--"
 property string efiIgnVoltageText: "--"
 property string generatorStatusText: "--"
 property string generatorSpeedText: "--"
 property string generatorPowerText: "--"
 property string generatorBusVoltageText: "--"
 property string generatorBatteryCurrentText: "--"
 property string generatorLoadCurrentText: "--"
 property string generatorRuntimeText: "--"
 property string rpmSensor1Text: "--"
 property string rpmSensor2Text: "--"

 // ── 起飞高度目标 ──
 property int takeoffAlt:50

 // ──任务状态 ──
 readonly property int totalWP: missionController ? missionController.missionItemCount : 0
 readonly property int currentWP: missionController ? Math.max(0, missionController.currentMissionIndex) : 0
 readonly property bool missionRunning: activeVehicle ? (activeVehicle.armed && activeVehicle.flightMode === activeVehicle.missionFlightMode) : false
 property bool missionPaused: false

 // ── 悬停状态 ──
 property bool hovering: false

 // ── 板卡数据（UI演示）──
 property var boards: [
 { id:1, role: "Master", health:0, miss:0 },
 { id:2, role: "Standby", health:0, miss:0 },
 { id:3, role: "Standby", health:1, miss:3 }
 ]

 // ── 决权流程（UI演示）──
 property var decisionSteps: [
 { n:"1", label:"心跳检测", state:"done" },
 { n:"2", label:"数据一致性校验", state:"done" },
 { n:"3", label:"飞手确认切换", state:"active" },
 { n:"4", label:"主板切换执行", state:"wait" },
 { n:"5", label:"状态同步验证", state:"wait" }
 ]

 // ── 操作方法（当前仍为占位）──
 function toggleArm() { console.log("[State] toggleArm") }
 function setFlightMode(mode) {
  if (!activeVehicle || !mode) {
   return
  }
  activeVehicle.flightMode = mode
 }
 function _execGuided(actionCode, sliderValue) {
  if (!guidedController || actionCode < 0) {
   return false
  }
  guidedController.executeAction(actionCode, null, sliderValue === undefined ? 0 : sliderValue, false)
  return true
 }
 function _confirmGuided(actionCode, actionData) {
  if (!guidedController || actionCode < 0) {
   return false
  }
  guidedController.confirmAction(actionCode, actionData === undefined ? null : actionData)
  return true
 }
 function _appAltFromMeters(meters) {
  return unitsConversion ? unitsConversion.metersToAppSettingsVerticalDistanceUnits(meters) : meters
 }
 function _showMessage(title, message) {
  if (typeof mainWindow !== "undefined" && mainWindow && mainWindow.showMessageDialog) {
   mainWindow.showMessageDialog(title, message)
  } else {
   console.warn(title + ": " + message)
  }
 }
 function _takeoffTargetTooLow() {
  return altitude === altitude && altitude >= takeoffAlt - 0.5
 }
 function _validateTakeoffTarget() {
  if (_takeoffTargetTooLow()) {
   _showMessage("起飞目标高度过低", "当前相对高度 " + altitude.toFixed(1) + " m 已不低于起飞目标高度 " + takeoffAlt + " m，请提高目标高度，或改用悬停、降落、返航等飞行中动作。")
   return false
  }
  return true
 }
 function takeoff() {
  if (!activeVehicle)
   return
  if (!_validateTakeoffTarget())
   return
  if (activeVehicle.guidedTakeoffSupported) {
   activeVehicle.guidedModeTakeoff(takeoffAlt)
  } else {
   activeVehicle.startTakeoff()
  }
 }
 function land() {
  if (activeVehicle && activeVehicle.guidedModeSupported)
   activeVehicle.guidedModeLand()
 }
 function returnToLaunch() {
  if (!activeVehicle)
   return
  var mode = activeVehicle.rtlFlightMode ? String(activeVehicle.rtlFlightMode) : ""
  console.log("[CustomState] returnToLaunch", "current:", activeVehicle.flightMode, "target:", mode)
  if (mode !== "") {
   activeVehicle.flightMode = mode
   return
  }
  activeVehicle.guidedModeRTL(false)
 }
 function holdPosition() {
  if (!activeVehicle)
   return
  hovering = true
  missionPaused = true
  var mode = activeVehicle.pauseFlightMode ? String(activeVehicle.pauseFlightMode) : ""
  console.log("[CustomState] holdPosition", "current:", activeVehicle.flightMode, "target:", mode, "pauseSupported:", activeVehicle.pauseVehicleSupported)
  if (mode !== "") {
   activeVehicle.flightMode = mode
   return
  }
  if (activeVehicle.pauseVehicleSupported) {
   activeVehicle.pauseVehicle()
   return
  }
  if (activeVehicle.altitudeRelative) {
   activeVehicle.guidedModeChangeAltitude(0, true)
  }
 }
 function startMission() {
  if (!activeVehicle)
   return
  missionPaused = false
  pendingMissionAvailable = true
  activeVehicle.startMission()
 }
 function pauseMission() {
  holdPosition()
 }
 function resumeMission() {
  if (!activeVehicle)
   return
  missionPaused = false
  var missionMode = activeVehicle.missionFlightMode ? String(activeVehicle.missionFlightMode) : ""
  console.log("[CustomState] resumeMission", "current:", activeVehicle.flightMode, "missionMode:", missionMode, "armed:", activeVehicle.armed, "flying:", activeVehicle.flying, "resumeIndex:", missionController ? missionController.resumeMissionIndex : -1, "totalWP:", missionController ? missionController.missionItemCount : -1)

  // 飞行中从暂停/等待继续任务，对应原版 Continue Mission：回到 Mission 模式继续当前任务。
  if (activeVehicle.armed || activeVehicle.flying) {
   if (missionMode !== "") {
    activeVehicle.flightMode = missionMode
   }
   activeVehicle.startMission()
   return
  }

  // 非飞行状态才使用 MissionController 的恢复索引逻辑。
  if (missionController && missionController.resumeMissionIndex >= 0) {
   missionController.resumeMission(missionController.resumeMissionIndex)
  } else {
   if (missionMode !== "") {
    activeVehicle.flightMode = missionMode
   }
   activeVehicle.startMission()
  }
 }
 function continueMission() {
  if (!activeVehicle)
   return
  missionPaused = false
  pendingMissionAvailable = true
  var missionMode = activeVehicle.missionFlightMode ? String(activeVehicle.missionFlightMode) : ""
  console.log("[CustomState] continueMission", "current:", activeVehicle.flightMode, "missionMode:", missionMode, "armed:", activeVehicle.armed, "flying:", activeVehicle.flying, "guided:", !!guidedController)

  var resumeIndex = missionController ? missionController.resumeMissionIndex : -1
  var currentIndex = missionController ? missionController.currentMissionIndex : -1
  var targetIndex = resumeIndex >= 0 ? resumeIndex : currentIndex
  if (targetIndex >= 0 && activeVehicle.setCurrentMissionSequence) {
   console.log("[CustomState] continueMission set sequence", targetIndex, "resume:", resumeIndex, "current:", currentIndex)
   activeVehicle.setCurrentMissionSequence(targetIndex)
  }

  // 飞行中继续任务：先回到 Mission 模式。等飞控确认模式切换后，再启动任务。
  if (missionMode !== "") {
   _switchToMissionThenStart(missionMode)
  } else {
   _sendMissionStartCommand()
  }
 }
 function _switchToMissionThenStart(missionMode) {
  if (!activeVehicle) {
   return
  }
  var vehicle = activeVehicle
  var done = false

  function finish(reason) {
   if (done) {
    return
   }
   done = true
   try {
    vehicle.flightModeChanged.disconnect(onModeChanged)
   } catch (e) {
   }
   console.log("[CustomState] continueMission finish", reason, "mode:", vehicle.flightMode)
   _sendMissionStartCommand()
  }

  function onModeChanged(mode) {
   console.log("[CustomState] continueMission mode changed", mode)
   if (String(mode) === String(missionMode)) {
    finish("mission-mode-confirmed")
   }
  }

  if (String(vehicle.flightMode) === String(missionMode)) {
   finish("already-mission-mode")
   return
  }

  vehicle.flightModeChanged.connect(onModeChanged)
  console.log("[CustomState] continueMission set mission mode", "from:", vehicle.flightMode, "to:", missionMode)
  vehicle.flightMode = missionMode

  var timer = Qt.createQmlObject('import QtQml; Timer { interval: 1200; repeat: false }', this, "ContinueMissionModeTimeout")
  timer.triggered.connect(function() {
   timer.destroy()
   finish("mission-mode-timeout")
  })
  timer.start()
 }
 function _sendMissionStartCommand() {
  if (!activeVehicle)
   return
  console.log("[CustomState] send mission start command", "component:", activeVehicle.defaultComponentId ? activeVehicle.defaultComponentId() : -1, "current:", activeVehicle.flightMode)
  if (activeVehicle.defaultComponentId && activeVehicle.sendCommand) {
   // MAV_CMD_MISSION_START = 300, param1/param2=0 表示从当前/默认任务范围开始。
   activeVehicle.sendCommand(activeVehicle.defaultComponentId(), 300, true, 0, 0, 0, 0, 0, 0, 0)
  }
  activeVehicle.startMission()
 }
 function abortMission() {
  missionPaused = false
  returnToLaunch()
 }
 function emergencyStop() { console.log("[State] EMERGENCY STOP!") }
 function forceLock() { console.log("[State] Force locked") }
 function adjustTakeoffAlt(delta) { takeoffAlt = Math.max(5, Math.min(500, takeoffAlt + delta)) }
 function executeTakeoff() {
  if (!_validateTakeoffTarget())
   return
  if (!_execGuided(guidedController ? guidedController.actionTakeoff : -1, takeoffAlt)) {
   takeoff()
  }
 }
 function executeLand() {
  if (!_execGuided(guidedController ? guidedController.actionLand : -1, 0)) {
   land()
  }
 }
 function executeRTL() {
  console.log("[CustomState] executeRTL", "connected:", vehicleConnected, "armed:", armed, "flying:", flying)
  missionPaused = false
  returnToLaunch()
 }
 function executeHoldPosition() {
  console.log("[CustomState] executeHoldPosition", "connected:", vehicleConnected, "armed:", armed, "flying:", flying)
  holdPosition()
 }
 function executeStartMission() {
  if (!_execGuided(guidedController ? guidedController.actionStartMission : -1, 0)) {
   startMission()
  }
 }
 function executeResumeMission() {
  console.log("[CustomState] executeResumeMission")
  continueMission()
 }
 function executeEmergencyStop() {
  if (!_confirmGuided(guidedController ? guidedController.actionEmergencyStop : -1) && activeVehicle) {
   activeVehicle.emergencyStop()
  }
 }
 function executeForceArm() {
  if (!_confirmGuided(guidedController ? guidedController.actionForceArm : -1) && activeVehicle) {
   activeVehicle.forceArm()
  }
 }
 function startEfi() {
  if (!activeVehicle) {
   return
  }
  activeVehicle.sendSerialCommand("ld_b24_efi start")
 }
 function statusEfi() {
  if (!activeVehicle) {
   return
  }
  activeVehicle.sendSerialCommand("ld_b24_efi status")
 }
 function stopEfi() {
  if (!activeVehicle) {
   return
  }
  activeVehicle.sendSerialCommand("ld_b24_efi stop")
 }
  function toggleLeftPanelVisible() {
   if (setShowLeftPanel) {
    setShowLeftPanel(!showLeftPanel)
   }
  }
  function setSidePanelOpacityValue(value) {
   if (setSidePanelOpacity) {
    setSidePanelOpacity(value)
   }
  }
  function setInfoBarOpacityValue(value) {
   if (setInfoBarOpacity) {
    setInfoBarOpacity(value)
   }
  }
  function toggleHudExpandBarVisible() {
   if (setShowHudExpandBar) {
    setShowHudExpandBar(!showHudExpandBar)
   }
 }
 function toggleBottomActionBarVisible() {
  if (setShowBottomActionBar) {
   setShowBottomActionBar(!showBottomActionBar)
  }
 }
 function switchToCustomFlyView() {
  if (setCustomFlyViewEnabled) {
   setCustomFlyViewEnabled(true)
  }
 }
 function switchToNativeFlyView() {
  if (setCustomFlyViewEnabled) {
   setCustomFlyViewEnabled(false)
  }
 }

 property string flightTime: "--:--"

 function _factRawValue(fact) {
  if (!fact) {
   return NaN
  }
  if (fact.rawValue !== undefined && fact.rawValue !== null) {
   return Number(fact.rawValue)
  }
  if (fact.value !== undefined && fact.value !== null) {
   return Number(fact.value)
  }
  return NaN
 }

 function _factValue(fact) {
  return fact && fact.value !== undefined && fact.value !== null ? Number(fact.value) : NaN
 }

 function _factString(fact, fallback) {
  return fact ? fact.valueString : fallback
 }

 function _vehicleFact(name) {
  if (!activeVehicle || !activeVehicle.vehicle) {
   return null
  }
  return activeVehicle.vehicle[name] ? activeVehicle.vehicle[name] : null
 }

 function _resetTelemetry() {
  altitude = NaN
  absoluteAltitude = NaN
  speed = NaN
  groundSpeed = NaN
  airSpeed = NaN
  heading = NaN
  roll = NaN
  pitch = NaN
  climbRate = NaN
  latitude = NaN
  longitude = NaN
  primaryBattery = null
  battery = -1
  voltage = NaN
  batteryText = "--"
  batteryPercentText = "--"
  batteryVoltageText = "--"
  batteryChargeStateText = "--"
  throttle = -1
  mavlinkSentCount = 0
  mavlinkReceivedCount = 0
  mavlinkLossPercent = NaN
  flightMode = vehicleAvailable ? "--" : "未连接"
  flightModeDisplayText = "--"
  gpsStatus = vehicleAvailable ? "GPS N/A" : "未连接"
  gpsSatellites = -1
  gpsSatellitesText = "--"
  gpsLockText = "--"
  gpsHdopText = "--"
  efiHealthText = "--"
  efiRpmText = "--"
  efiFuelConsumedText = "--"
  efiFuelFlowText = "--"
  efiEngineLoadText = "--"
  efiThrottlePosText = "--"
  efiCylinderTempText = "--"
  efiExGasTempText = "--"
  efiIgnVoltageText = "--"
  generatorStatusText = "--"
  generatorSpeedText = "--"
  generatorPowerText = "--"
  generatorBusVoltageText = "--"
  generatorBatteryCurrentText = "--"
  generatorLoadCurrentText = "--"
  generatorRuntimeText = "--"
  rpmSensor1Text = "--"
  rpmSensor2Text = "--"
  flightTime = "--:--"
 }

 function _refreshTelemetry() {
  if (!vehicleConnected || !activeVehicle) {
   _resetTelemetry()
   return
  }

  altitude = _factRawValue(activeVehicle.altitudeRelative)
  absoluteAltitude = _factRawValue(activeVehicle.altitudeAMSL)
  speed = _factRawValue(activeVehicle.groundSpeed)
  groundSpeed = speed
  airSpeed = _factRawValue(activeVehicle.airSpeed)
  heading = _factRawValue(activeVehicle.heading)
  roll = _factRawValue(activeVehicle.roll)
  pitch = _factRawValue(activeVehicle.pitch)
  climbRate = _factRawValue(activeVehicle.climbRate)
  if (activeVehicle.coordinate && activeVehicle.coordinate.isValid) {
   latitude = Number(activeVehicle.coordinate.latitude)
   longitude = Number(activeVehicle.coordinate.longitude)
  } else {
   latitude = _factRawValue(activeVehicle.latitude)
   longitude = _factRawValue(activeVehicle.longitude)
  }

  primaryBattery = activeVehicle.batteries && activeVehicle.batteries.count > 0 ? activeVehicle.batteries.get(0) : null
  if (primaryBattery && primaryBattery.percentRemaining) {
   battery = Math.round(Math.max(0, _factRawValue(primaryBattery.percentRemaining)))
  } else if (activeVehicle.batteryPercentRemaining) {
   battery = Math.round(Math.max(0, _factRawValue(activeVehicle.batteryPercentRemaining)))
  } else {
   battery = -1
  }

  if (primaryBattery && primaryBattery.voltage) {
   voltage = _factRawValue(primaryBattery.voltage)
  } else if (activeVehicle.batteryVoltage) {
   voltage = _factRawValue(activeVehicle.batteryVoltage)
  } else {
   voltage = NaN
  }

  batteryPercentText = battery >= 0 ? (battery > 98 ? "100%" : (battery + "%")) : "--"
  batteryVoltageText = voltage === voltage ? (voltage.toFixed(1) + "V") : "--"
  batteryChargeStateText = primaryBattery && primaryBattery.chargeState ? primaryBattery.chargeState.enumStringValue : "--"

  if (battery < 0) {
   if (voltage === voltage) {
    batteryText = batteryVoltageText
   } else if (batteryChargeStateText !== "--") {
    batteryText = batteryChargeStateText
   } else {
    batteryText = "--"
   }
  } else {
   batteryText = voltage === voltage ? (batteryPercentText + "  " + batteryVoltageText) : batteryPercentText
  }

  throttle = activeVehicle.throttlePct ? Math.round(activeVehicle.throttlePct.value) : -1
  mavlinkSentCount = activeVehicle.mavlinkSentCount
  mavlinkReceivedCount = activeVehicle.mavlinkReceivedCount
  mavlinkLossPercent = activeVehicle.mavlinkLossPercent
  flightMode = activeVehicle.flightMode ? activeVehicle.flightMode : "--"
  flightModeDisplayText = flightMode
  var flightTimeFact = _vehicleFact("flightTime")
  flightTime = _factString(flightTimeFact ? flightTimeFact : activeVehicle.flightTime, "--:--")

  if (!activeVehicle.gps) {
   gpsStatus = "GPS N/A"
   gpsSatellites = -1
   gpsSatellitesText = "--"
   gpsLockText = "--"
   gpsHdopText = "--"
  } else {
   gpsSatellites = activeVehicle.gps.count ? Math.round(_factRawValue(activeVehicle.gps.count)) : -1
   gpsSatellitesText = activeVehicle.gps.count ? activeVehicle.gps.count.valueString : "--"
   gpsLockText = activeVehicle.gps.lock ? activeVehicle.gps.lock.enumStringValue : "--"
   gpsHdopText = activeVehicle.gps.hdop ? activeVehicle.gps.hdop.valueString : "--"
   gpsStatus = gpsLockText + " · " + gpsSatellitesText + "星"
  }

  efiHealthText = _factString(efi && efi.health, "--")
  efiRpmText = _factString(efi && efi.rpm, "--")
  efiFuelConsumedText = _factString(efi && efi.fuelConsumed, "--")
  efiFuelFlowText = _factString(efi && efi.fuelFlow, "--")
  efiEngineLoadText = _factString(efi && efi.engineLoad, "--")
  efiThrottlePosText = _factString(efi && efi.throttlePos, "--")
  efiCylinderTempText = _factString(efi && efi.cylinderTemp, "--")
  efiExGasTempText = _factString(efi && efi.exGasTemp, "--")
  efiIgnVoltageText = _factString(efi && efi.ignVoltage, "--")
  generatorStatusText = _factString(generator && generator.status, "--")
  generatorSpeedText = _factString(generator && generator.genSpeed, "--")
  generatorPowerText = _factString(generator && generator.powerGenerated, "--")
  generatorBusVoltageText = _factString(generator && generator.busVoltage, "--")
  generatorBatteryCurrentText = _factString(generator && generator.batteryCurrent, "--")
  generatorLoadCurrentText = _factString(generator && generator.loadCurrent, "--")
  generatorRuntimeText = _factString(generator && generator.runtime, "--")
  rpmSensor1Text = _factString(rpmGroup && rpmGroup.rpmSensor1, "--")
  rpmSensor2Text = _factString(rpmGroup && rpmGroup.rpmSensor2, "--")
 }

 property var telemetryTimer: Timer {
  interval: 250
  running: customFlyViewEnabled && vehicleAvailable
  repeat: true
  onTriggered: _refreshTelemetry()
 }

 onActiveVehicleChanged: {
  hovering = false
  missionPaused = false
  _refreshTelemetry()
 }

 onCommunicationLostChanged: _refreshTelemetry()
 Component.onCompleted: _refreshTelemetry()
}
