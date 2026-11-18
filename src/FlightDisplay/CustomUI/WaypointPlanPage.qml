// WaypointPlanPage.qml 航点规划页面
// 布局：
//   - 顶部：沿用原有信息栏（本页面不画顶栏，只占信息栏下方区域）
//   - 地图：照搬起飞界面（左下角叠加姿态仪/航向/遥测 HUD）
//   - 地图左上角：圆形“保存”按钮（点击保存任务并弹“保存成功”提示）
//   - 右侧“任务规划”面板：航线规划 / 电子围栏 两个 tab 切换
//       * 航线规划：点击地图新增（起飞/航点/着陆/兴趣点/着陆定位）
//       * 电子围栏：多边形围栏 / 圆形围栏 新增与删除
//   - 返回：由信息栏右上角按钮触发（有修改弹保存弹窗，已保存直接返回任务栏）

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtLocation
import QtPositioning

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.FlightMap
import QGroundControl.Palette
import QGroundControl.ScreenTools

Item {
    id: root

    property var state: null
    property var theme: null
    property var missionController: null
    property string initialPlanFile: ""
    property int initialSequenceNumber: -1
    property real hudInstrumentSize: 0
    property real hudTelemetryWidth: 0
    property real hudHeight: 0
    property real topInset: 0
    property bool panelCollapsed: false
    signal closeRequested()

    property QGCPalette qgcPal: QGCPalette { colorGroupEnabled: true }
    readonly property color brandBlue: theme ? theme.blue : qgcPal.brandingPurple
    readonly property color brandHover: theme ? theme.blueL : Qt.rgba(brandBlue.r, brandBlue.g, brandBlue.b, 0.12)
    readonly property color brandPress: theme ? theme.bluePress : Qt.darker(brandBlue, 1.10)
    readonly property color brandBorder: theme ? theme.blueBorder : Qt.rgba(brandBlue.r, brandBlue.g, brandBlue.b, 0.42)
    readonly property real pageScale: theme ? theme.uiScale : 1
    readonly property real sidePanelOpacity: state && state.sidePanelOpacity !== undefined ? Math.max(0.15, Math.min(1.0, state.sidePanelOpacity)) : 0.92
    readonly property color sidePanelSurface: theme ? Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, root.sidePanelOpacity) : Qt.rgba(1, 1, 1, root.sidePanelOpacity)
    readonly property color sidePanelSurface2: theme ? Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, root.sidePanelOpacity) : Qt.rgba(0.97, 0.98, 0.99, root.sidePanelOpacity)
    readonly property color panelTitleText: theme && theme.darkMode ? "#f8fafc" : "#0f172a"
    readonly property color panelBodyText: theme && theme.darkMode ? "#dbeafe" : "#334155"
    readonly property color panelMutedText: theme && theme.darkMode ? "#94a3b8" : "#64748b"
    readonly property color panelHintText: theme && theme.darkMode ? "#c7d2fe" : "#475569"
    readonly property color panelHeaderText: theme && theme.darkMode ? "#bfdbfe" : "#3b4a60"
    readonly property real panelTitleFont: Math.max(13, Math.round((theme ? theme.fontLg : 15) * root.compactScale))
    readonly property real panelSectionFont: Math.max(11, Math.round((theme ? theme.fontMd : 12) * root.compactScale))
    readonly property real panelBodyFont: Math.max(10, Math.round((theme ? theme.fontSm : 11) * root.compactScale))
    readonly property real panelMetaFont: Math.max(9, Math.round((theme ? theme.fontXs : 10) * root.compactScale))
    readonly property bool mobileLayout: (theme && theme.mobile) || root.width < 1100 || root.height < 650
    readonly property real compactScale: mobileLayout ? 0.92 : 1.0
    readonly property real panelHeaderH: Math.round((theme ? theme.sectionH : 44) * compactScale)
    readonly property real panelButtonH: Math.round((theme ? theme.controlHMd : 34) * compactScale)
    readonly property real panelSideMargin: Math.round((mobileLayout ? 10 : 14) * root.pageScale)
    readonly property real panelGap: Math.round((mobileLayout ? 7 : 10) * root.pageScale)
    readonly property real saveButtonSize: Math.round((mobileLayout ? 28 : 46) * root.pageScale)
    readonly property real planHudInstrumentSize: root.hudInstrumentSize
    readonly property real planHudTelemetryScale: root.mobileLayout ? 0.86 : 1.0
    readonly property real planHudTelemetryWidth: root.hudTelemetryWidth > 0 ? root.hudTelemetryWidth * root.planHudTelemetryScale : 0
    readonly property real panelWidth: root.mobileLayout
                                       ? Math.max(220, Math.min(310, root.width * 0.32))
                                       : Math.max(260, Math.min(360, root.width * 0.30))

    // ---- 控制器 ----
    readonly property var _masterController:        missionController ? missionController.masterController : null
    readonly property var _geoFenceController:      _masterController ? _masterController.geoFenceController : null
    readonly property var _planVehicle:             _masterController && _masterController.controllerVehicle ? _masterController.controllerVehicle : (state ? state.activeVehicle : null)
    readonly property var _missionItems:            missionController ? missionController.visualItems : null
    readonly property int _visibleItemCount:        _missionItems ? Math.max(0, _missionItems.count - 1) : 0
    readonly property var _defaultAltitudeFact:     QGroundControl.settingsManager.appSettings.defaultMissionItemAltitude

    // ---- 工具 id ----
    readonly property int toolTakeoff:      0
    readonly property int toolWaypoint:     1
    readonly property int toolLand:         2
    readonly property int toolROI:          3
    readonly property int toolPolyFence:    4
    readonly property int toolCircleFence:  5
    readonly property int toolLandLocate:   6
    readonly property int mavCmdNavLand:    21
    readonly property int mavCmdNavRTL:     20
    readonly property int mavCmdNavVTOLLand: 85

    // ---- 状态 ----
    property int currentTool: toolTakeoff
    property int rightTab: 0                 // 0: 航线规划, 1: 电子围栏
    property bool hasTakeoff: false
    property bool hasLand: false
    property bool pendingChanges: false
    property string lastSavedFile: ""
    property int landSeqNum: -1
    property bool uniformSpeedEnabled: false
    property real uniformSpeedMps: 15.0
    property bool editingSelectedField: false

    // ---- 启用逻辑（起飞点 → 航点/着陆/兴趣点 → 着陆定位）----
    readonly property bool takeoffEnabled:      !hasTakeoff && !!missionController
    readonly property bool waypointEnabled:     hasTakeoff && (missionController ? (missionController.flyThroughCommandsAllowed || (hasLand && !_vehicleIsMultiRotor())) : !hasLand)
    readonly property bool landEnabled:         hasTakeoff && !!missionController && missionController.isInsertLandValid
    readonly property bool roiEnabled:          hasTakeoff && (missionController ? (missionController.flyThroughCommandsAllowed || (hasLand && !_vehicleIsMultiRotor())) : !hasLand)
    readonly property bool landLocateEnabled:   hasLand
    // Local planning does not require the connected vehicle to support fence uploads.
    readonly property bool fenceEnabled:        !!_geoFenceController && !_geoFenceController.syncInProgress
    readonly property bool fenceMode:           rightTab === 1
    readonly property bool isDirty:             pendingChanges

    // ---- 选中项 ----
    readonly property int currentVII:           missionController ? missionController.currentPlanViewVIIndex : -1
    readonly property bool hasSelection:        currentVII >= 1 && _missionItems && currentVII < _missionItems.count
    readonly property var selectedItem:         hasSelection ? _missionItems.get(currentVII) : null

    // ================= 逻辑函数 =================

    function _findTakeoff() {
        if (!_missionItems) {
            return false
        }
        for (var i = 1; i < _missionItems.count; i++) {
            var item = _missionItems.get(i)
            if (item && item.isTakeoffItem) {
                return true
            }
        }
        return false
    }

    function _findLandSeq() {
        if (!_missionItems) {
            return -1
        }
        for (var i = 1; i < _missionItems.count; i++) {
            var item = _missionItems.get(i)
            if (_isLandVisualItem(item)) {
                return item.sequenceNumber !== undefined ? item.sequenceNumber : i
            }
        }
        return -1
    }

    function _isLandVisualItem(item) {
        if (!item) {
            return false
        }
        if (_isRTLVisualItem(item)) {
            return true
        }
        if (item.isLandItem || item.isLandCommand) {
            return true
        }
        var command = item.command !== undefined ? Number(item.command) : -1
        var name = item.commandName ? String(item.commandName) : ""
        var desc = item.commandDescription ? String(item.commandDescription) : ""
        var pattern = item.patternName ? String(item.patternName) : ""
        return command === mavCmdNavLand ||
               command === mavCmdNavVTOLLand ||
               name === "Land" ||
               name === "VTOL Land" ||
               name === "Landing Pattern" ||
               pattern === "VTOL Landing" ||
               pattern === "Fixed Wing Landing" ||
               pattern === "Landing Pattern" ||
               desc === "Landing Pattern" ||
               item.landingCoordinate !== undefined
    }

    function _isRTLVisualItem(item) {
        if (!item) {
            return false
        }
        var command = item.command !== undefined ? Number(item.command) : -1
        var name = item.commandName ? String(item.commandName) : ""
        var desc = item.commandDescription ? String(item.commandDescription) : ""
        return command === mavCmdNavRTL ||
               name === "Return To Launch" ||
               name === "Return to Launch" ||
               name === "RTL" ||
               desc === "Return To Launch" ||
               desc === "Return to Launch"
    }

    function _refreshTools() {
        hasTakeoff = _findTakeoff()
        landSeqNum = _findLandSeq()
        hasLand = landSeqNum > 0
        if (!hasTakeoff) {
            currentTool = toolTakeoff
        } else if (currentTool === toolWaypoint && !waypointEnabled) {
            currentTool = toolLandLocate
        } else if (currentTool === toolROI && !roiEnabled) {
            currentTool = toolLandLocate
        } else if (currentTool === toolLand && !landEnabled) {
            currentTool = waypointEnabled ? toolWaypoint : toolLandLocate
        } else if (currentTool !== toolWaypoint && currentTool !== toolLand && currentTool !== toolROI && currentTool !== toolLandLocate) {
            currentTool = waypointEnabled ? toolWaypoint : toolLandLocate
        }
    }

    function _savePath() {
        var folder = QGroundControl.settingsManager.appSettings.missionSavePath
        folder = String(folder).replace(/\\/g, "/")
        if (folder.length === 0) {
            folder = "."
        }
        if (folder.charAt(folder.length - 1) !== "/") {
            folder += "/"
        }
        return folder
    }

    function _doSave(saveAndClose) {
        if (!_masterController || !_missionItems) {
            return
        }
        if (_missionItems.count <= 1 && !(_geoFenceController && _geoFenceController.containsItems)) {
            messageDialog.text = qsTr("No mission to save")
            messageDialog.open()
            return
        }
        var saveFile = lastSavedFile
        if (!saveFile || saveFile.length === 0) {
            saveFile = _savePath() + qsTr("Mission_") + Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss") + ".plan"
        }
        _masterController.saveToFile(saveFile)
        // The controller clears currentPlanFile when opening the save file fails.
        if (_masterController.currentPlanFile !== saveFile) {
            return
        }
        lastSavedFile = saveFile
        pendingChanges = false
        if (saveAndClose) {
            _clearFenceInteractive()
            root.closeRequested()
        } else {
            saveSuccessDialog.open()
        }
    }

    // 供信息栏右上角按钮调用：有修改弹保存弹窗，已保存直接返回
    function requestReturn() {
        if (isDirty) {
            savePromptDialog.open()
        } else {
            _clearFenceInteractive()
            root.closeRequested()
        }
    }

    function _clearFenceInteractive() {
        if (_geoFenceController) {
            _geoFenceController.clearAllInteractive()
        }
    }

    function _removeSelected() {
        if (!missionController || !hasSelection) {
            return
        }
        missionController.removeVisualItem(currentVII)
    }

    function _addPolyFence() {
        if (!_geoFenceController || !fenceEnabled) {
            return
        }
        var topLeft = planMap.toCoordinate(Qt.point(planMap.width * 0.25, planMap.height * 0.30), false)
        var bottomRight = planMap.toCoordinate(Qt.point(planMap.width * 0.75, planMap.height * 0.70), false)
        _geoFenceController.addInclusionPolygon(topLeft, bottomRight)
        root.pendingChanges = true
    }

    function _addCircleFence() {
        if (!_geoFenceController || !fenceEnabled) {
            return
        }
        var topLeft = planMap.toCoordinate(Qt.point(planMap.width * 0.25, planMap.height * 0.30), false)
        var bottomRight = planMap.toCoordinate(Qt.point(planMap.width * 0.75, planMap.height * 0.70), false)
        _geoFenceController.addInclusionCircle(topLeft, bottomRight)
        root.pendingChanges = true
    }

    function _locateLand() {
        if (!missionController) {
            return
        }
        var seq = landSeqNum > 0 ? landSeqNum : _findLandSeq()
        if (seq > 0) {
            missionController.setCurrentPlanViewSeqNum(seq, true)
        }
    }

    function _normalizeMapCoordinate(coordinate) {
        if (!coordinate || !coordinate.isValid) {
            return QtPositioning.coordinate()
        }
        var normalized = QtPositioning.coordinate(Number(coordinate.latitude),
                                                  Number(coordinate.longitude),
                                                  Number(coordinate.altitude))
        if (!(normalized.altitude === normalized.altitude)) {
            normalized.altitude = _defaultAltitudeFact ? Number(_defaultAltitudeFact.rawValue) : 50
        }
        return normalized
    }

    function _selectLandItem(landItem) {
        var seq = -1
        if (landItem && landItem.sequenceNumber !== undefined) {
            seq = landItem.sequenceNumber
        }
        if (seq <= 0) {
            seq = _findLandSeq()
        }
        landSeqNum = seq
        hasLand = seq > 0
        if (hasLand && missionController) {
            missionController.setCurrentPlanViewSeqNum(seq, true)
        }
        return hasLand
    }

    function _vehicleIsVTOL() {
        return _planVehicle && _planVehicle.vtol
    }

    function _vehicleIsMultiRotor() {
        return !_vehicleIsVTOL() && _planVehicle && _planVehicle.multiRotor
    }

    function _landButtonText() {
        return _vehicleIsMultiRotor() ? qsTr("Return") : qsTr("Land")
    }

    function _insertIndexBeforeLandIfNeeded() {
        if (!hasLand || _vehicleIsMultiRotor() || !_missionItems) {
            return -1
        }
        for (var i = 1; i < _missionItems.count; i++) {
            if (_isLandVisualItem(_missionItems.get(i))) {
                return i
            }
        }
        return -1
    }

    function _createLandAtCoordinate(coordinate) {
        if (!landEnabled || !missionController) {
            messageDialog.text = _landButtonText() + qsTr("Cannot add here")
            messageDialog.open()
            return false
        }
        var landCoordinate = _normalizeMapCoordinate(coordinate)
        if (!landCoordinate.isValid) {
            messageDialog.text = qsTr("Invalid map coordinates; cannot add item") + _landButtonText()
            messageDialog.open()
            return false
        }
        var landItem = missionController.insertLandItem(landCoordinate, -1, true)
        if (landItem) {
            // 固定翼/复合翼着陆是复杂任务项：
            // landingCoordinate 是用户点的着陆点，coordinate 是最终进近点。
            if (landItem.landingCoordinate !== undefined) {
                landItem.landingCoordinate = landCoordinate
            } else if (landItem.coordinate !== undefined) {
                landItem.coordinate = landCoordinate
            }
        }
        var selected = _selectLandItem(landItem)
        if (selected) {
            currentTool = toolLandLocate
        } else {
            messageDialog.text = _landButtonText() + qsTr("Failed to add item. Check whether insertion is allowed here.")
            messageDialog.open()
        }
        return selected
    }

    function _vehicleCoordinateForTakeoff() {
        var vehicle = root.state && root.state.activeVehicle ? root.state.activeVehicle : root._planVehicle
        if (vehicle && vehicle.coordinate && vehicle.coordinate.isValid) {
            return root._normalizeMapCoordinate(vehicle.coordinate)
        }
        if (vehicle && vehicle.homePosition && vehicle.homePosition.isValid) {
            return root._normalizeMapCoordinate(vehicle.homePosition)
        }
        if (root.missionController && root.missionController.plannedHomePosition && root.missionController.plannedHomePosition.isValid) {
            return root._normalizeMapCoordinate(root.missionController.plannedHomePosition)
        }
        return QtPositioning.coordinate()
    }

    function _createTakeoffFromVehicle() {
        if (!root.takeoffEnabled || !root.missionController) {
            return false
        }
        var coordinate = root._vehicleCoordinateForTakeoff()
        if (!coordinate.isValid) {
            messageDialog.text = qsTr("Vehicle position is invalid; cannot create takeoff point")
            messageDialog.open()
            return false
        }
        var takeoffItem = root.missionController.insertTakeoffItem(coordinate, -1, true)
        if (!takeoffItem) {
            messageDialog.text = qsTr("Failed to Create Takeoff Point")
            messageDialog.open()
            return false
        }
        if (takeoffItem.launchCoordinate !== undefined) {
            takeoffItem.launchCoordinate = coordinate
        } else {
            takeoffItem.coordinate = coordinate
        }
        root.hasTakeoff = true
        root.pendingChanges = true
        root.missionController.setCurrentPlanViewSeqNum(takeoffItem.sequenceNumber, true)
        root.currentTool = root.toolWaypoint
        return true
    }

    function _setTool(tool) {
        if (tool === toolTakeoff) {
            _createTakeoffFromVehicle()
            return
        }
        currentTool = tool
    }

    function _applyUniformSpeed(item) {
        if (uniformSpeedEnabled && item && item.specifiedFlightSpeed !== undefined) {
            item.specifiedFlightSpeed = uniformSpeedMps
        }
    }

    function _itemTitle(item) {
        if (!item) {
            return qsTr("Mission Item")
        }
        var seq = item.sequenceNumber !== undefined ? item.sequenceNumber : ""
        if (item.isTakeoffItem) {
            return qsTr("Takeoff ") + seq
        }
        if (_isRTLVisualItem(item)) {
            return qsTr("Return ") + seq
        }
        if (_isLandVisualItem(item)) {
            return qsTr("Land ") + seq
        }
        if (item.commandName && String(item.commandName).indexOf("ROI") >= 0) {
            return qsTr("Point of interest ") + seq
        }
        return qsTr("Waypoint ") + seq
    }

    function _itemTypeText(item) {
        if (!item) {
            return qsTr("Mission Item")
        }
        if (item.isTakeoffItem) {
            return qsTr("Takeoff")
        }
        if (_isRTLVisualItem(item)) {
            return qsTr("Return")
        }
        if (_isLandVisualItem(item)) {
            return qsTr("Land")
        }
        if (item.commandName && String(item.commandName).indexOf("ROI") >= 0) {
            return qsTr("Point of Interest")
        }
        return qsTr("Waypoint")
    }

    function _itemSeqText(item) {
        return item && item.sequenceNumber !== undefined ? String(item.sequenceNumber) : ""
    }

    function _selectedCommandEditable() {
        return root.selectedItem &&
               root._itemTypeText(root.selectedItem) === qsTr("Waypoint") &&
               root.selectedItem.command !== undefined &&
               root.selectedItem.setMapCenterHintForCommandChange !== undefined
    }

    function _openSelectedCommandDialog() {
        if (root._selectedCommandEditable()) {
            selectedCommandDialog.createObject(mainWindow).open()
        }
    }

    function _coordText(item) {
        if (!item || !item.specifiesCoordinate || !item.coordinate || !item.coordinate.isValid) {
            return "--, --"
        }
        return Number(item.coordinate.latitude).toFixed(5) + ", " + Number(item.coordinate.longitude).toFixed(5)
    }

    function _altText(item) {
        if (!item || !item.altitude) {
            return "--"
        }
        return Number(item.altitude.value).toFixed(1)
    }

    function _speedText(item) {
        if (!item || item.specifiedFlightSpeed === undefined || item.specifiedFlightSpeed !== item.specifiedFlightSpeed || Number(item.specifiedFlightSpeed) <= 0) {
            return "15.0"
        }
        return Number(item.specifiedFlightSpeed).toFixed(1)
    }

    // ================= 生命周期 =================

    Component.onCompleted: {
        pendingChanges = false
        lastSavedFile = initialPlanFile
        rightTab = 0
        if (_visibleItemCount === 0) {
            currentTool = toolTakeoff
        }
        landSeqNum = _findLandSeq()
        _refreshTools()
        if (missionController && initialSequenceNumber >= 0) {
            missionController.setCurrentPlanViewSeqNum(initialSequenceNumber, true)
        }
        if (_visibleItemCount > 0) {
            mapFitFunctions.fitMapViewportToMissionItems()
        }
    }

    Connections {
        target: _missionItems
        function onCountChanged() {
            landSeqNum = _findLandSeq()
            _refreshTools()
        }
    }

    Connections {
        target: missionController
        function onDirtyChanged(dirty) {
            if (dirty) {
                pendingChanges = true
            }
        }
    }

    Connections {
        target: root._geoFenceController
        function onDirtyChanged(dirty) {
            if (dirty) {
                root.pendingChanges = true
            }
        }
    }

    // ================= 界面 =================

    // 背景
    Rectangle {
        anchors.fill: parent
        color: theme ? theme.surface3 : "#edf3fa"
    }

    // ---------- 地图区（左侧，占据除右侧面板外的空间）----------
    Item {
        id: mapArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true

        FlightMap {
            id: planMap
            anchors.fill: parent
            mapName: "WaypointPlannerPage"
            allowGCSLocationCenter: true
            allowVehicleLocationCenter: true
            planView: true

            zoomLevel: QGroundControl.flightMapZoom
            center: QGroundControl.flightMapPosition

            onZoomLevelChanged: {
                QGroundControl.flightMapZoom = planMap.zoomLevel
            }
            onCenterChanged: {
                QGroundControl.flightMapPosition = planMap.center
            }

            onMapClicked: (mouse) => {
                if (root.rightTab !== 0) {
                    return
                }
                if (!root.hasTakeoff || root.currentTool === root.toolTakeoff) {
                    return
                }

                planMap.focus = true
                var coordinate = root._normalizeMapCoordinate(planMap.toCoordinate(Qt.point(mouse.x, mouse.y), false))

                switch (root.currentTool) {
                case root.toolWaypoint:
                    if (root.waypointEnabled && root.missionController) {
                        var wpItem = root.missionController.insertSimpleMissionItem(coordinate, root._insertIndexBeforeLandIfNeeded(), true)
                        root._applyUniformSpeed(wpItem)
                    }
                    break
                case root.toolLand:
                    root._createLandAtCoordinate(coordinate)
                    break
                case root.toolROI:
                    if (root.roiEnabled && root.missionController) {
                        root.missionController.insertROIMissionItem(coordinate, root._insertIndexBeforeLandIfNeeded(), true)
                    }
                    break
                }
            }

            // 任务项可视化
            Repeater {
                model: root._missionItems
                delegate: MissionItemMapVisual {
                    map: planMap
                    vehicle: root.state ? root.state.activeVehicle : null
                    interactive: !root.fenceMode
                    onClicked: (sequenceNumber) => {
                        if (root.missionController) {
                            root.missionController.setCurrentPlanViewSeqNum(sequenceNumber, true)
                        }
                    }
                }
            }

            // 航点连线
            MissionLineView {
                model: root.missionController ? root.missionController.simpleFlightPathSegments : null
                opacity: root.fenceMode ? 0.5 : 1
            }

            // 当前连接飞行器图标：沿用原版 PlanView 逻辑，显示所有已连接 vehicle
            MapItemView {
                model: QGroundControl.multiVehicleManager.vehicles
                delegate: VehicleMapItem {
                    vehicle: object
                    coordinate: object.coordinate
                    map: planMap
                    size: ScreenTools.defaultFontPixelHeight * 3
                    z: QGroundControl.zOrderMapItems - 1
                }
            }

            // 电子围栏：GeoFenceMapVisuals 内部会 addMapItem，必须用 Loader 按需销毁，不能只 visible=false
            Loader {
                active: root.fenceMode
                sourceComponent: Component {
                    GeoFenceMapVisuals {
                        map: planMap
                        myGeoFenceController: root._geoFenceController
                        interactive: true
                        homePosition: root.missionController ? root.missionController.plannedHomePosition : QtPositioning.coordinate()
                        planView: true
                        opacity: 1
                    }
                }
            }

            MapFitFunctions {
                id: mapFitFunctions
                map: planMap
                usePlannedHomePosition: true
                planMasterController: root._masterController
            }
        }

        // 地图左上角：圆形保存按钮（信息栏下方）
        Rectangle {
            id: saveButton
            width: root.saveButtonSize
            height: root.saveButtonSize
            radius: width / 2
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: root.topInset + Math.round((root.mobileLayout ? 5 : 10) * root.pageScale)
            anchors.leftMargin: Math.round((root.mobileLayout ? 5 : 10) * root.pageScale)
            z: 60
            color: saveMouse.pressed
                   ? (theme ? theme.green : "#16a34a")
                   : saveMouse.containsMouse
                     ? (theme ? theme.green : "#16a34a")
                     : (theme ? theme.greenL : "#dcfce7")
            border.width: 1
            border.color: theme ? theme.green : "#16a34a"

            Text {
                anchors.centerIn: parent
                text: "✓"
                font.pixelSize: Math.round((theme ? theme.fontLg + 2 : 18) * (root.mobileLayout ? 0.62 : 1.0))
                font.weight: Font.Bold
                color: saveMouse.containsMouse || saveMouse.pressed ? "#ffffff" : (theme ? theme.green : "#16a34a")
            }

            MouseArea {
                id: saveMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: _doSave(false)
            }
        }
        Text {
            anchors.top: saveButton.bottom
            anchors.horizontalCenter: saveButton.horizontalCenter
            anchors.topMargin: Math.round((root.mobileLayout ? 1 : 2) * root.pageScale)
            z: 60
            text: qsTr("Save")
            font.pixelSize: Math.max(7, Math.round((theme ? theme.fontXs : 9) * (root.mobileLayout ? 0.70 : 1.0)))
            color: theme ? theme.green : "#16a34a"
        }

    }

    // 左下角信息栏：尺寸和起飞界面一致，但宽度只占地图区域，不能压到右侧任务规划面板
    FlyViewHUD {
        id: planHud
        anchors.left: mapArea.left
        anchors.right: root.panelCollapsed ? mapArea.right : rightPanel.left
        anchors.bottom: mapArea.bottom
        height: root.hudHeight > 0 ? root.hudHeight : Math.min(parent.height * 0.72, Math.max(260, Math.round(280 * root.pageScale)))
        z: 8
        state: root.state
        theme: root.theme
        instrumentSizeOverride: root.planHudInstrumentSize
        telemetryWidthOverride: root.planHudTelemetryWidth
        telemetryScaleOverride: root.planHudTelemetryScale
        telemetryVisible: true
        compactMode: false
    }

    // ---------- 右侧“任务规划”面板 ----------
    Rectangle {
        id: rightPanel
        anchors.top: parent.top
        anchors.topMargin: root.topInset
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: root.panelWidth
        visible: !root.panelCollapsed
        color: root.sidePanelSurface
        clip: true
        z: 70

        DeadMouseArea {
            anchors.fill: parent
        }

        WheelHandler {
            target: null
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: function(event) {
                event.accepted = true
            }
        }

        Rectangle {
            anchors.left: parent.left
            width: 1
            height: parent.height
            color: theme ? theme.border : "#e4e8ed"
        }

        Column {
            anchors.fill: parent
            spacing: 0

            // 面板标题
            Rectangle {
                width: parent.width
                height: root.panelHeaderH
                color: root.sidePanelSurface

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: theme ? theme.border : "#e4e8ed"
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: root.panelSideMargin
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Plan View")
                    font.pixelSize: root.panelTitleFont
                    font.weight: Font.Bold
                    color: root.panelTitleText
                }
            }

            // 航线规划 / 电子围栏 切换
            RowLayout {
                width: parent.width - root.panelSideMargin * 2
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: root.panelGap

                RectBtn {
                    Layout.fillWidth: true
                    label: qsTr("✈ Route Planning")
                    btnSelected: root.rightTab === 0
                    btnEnabled: true
                    onClicked: root.rightTab = 0
                }

                RectBtn {
                    Layout.fillWidth: true
                    label: qsTr("⌗ Geofence")
                    btnSelected: root.rightTab === 1
                    btnEnabled: true
                    onClicked: root.rightTab = 1
                }
            }

            Flickable {
                width: parent.width
                height: parent.height - root.panelHeaderH - root.panelButtonH - root.panelGap
                contentWidth: width
                contentHeight: panelContent.implicitHeight
                clip: true
                interactive: !root.editingSelectedField
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                Column {
                    id: panelContent
                    width: parent.width - root.panelSideMargin * 2
                    x: root.panelSideMargin
                    spacing: root.panelGap

                    // ======== 航线规划 ========
                    Column {
                        width: parent.width
                        spacing: root.panelGap
                        visible: root.rightTab === 0

                        SectionTitle { text: qsTr("Click the map to add"); theme: root.theme }

                        GridLayout {
                            width: parent.width
                            columns: 2
                            columnSpacing: root.panelGap
                            rowSpacing: root.panelGap

                            RectBtn {
                                Layout.fillWidth: true
                                label: qsTr("Takeoff")
                                btnSelected: root.currentTool === root.toolTakeoff
                                btnEnabled: root.takeoffEnabled
                                onClicked: root._setTool(root.toolTakeoff)
                            }
                            RectBtn {
                                Layout.fillWidth: true
                                label: qsTr("Waypoint")
                                btnSelected: root.currentTool === root.toolWaypoint
                                btnEnabled: root.waypointEnabled
                                onClicked: root._setTool(root.toolWaypoint)
                            }
                            RectBtn {
                                Layout.fillWidth: true
                                label: root._landButtonText()
                                btnSelected: root.currentTool === root.toolLand
                                btnEnabled: root.landEnabled
                                onClicked: root._setTool(root.toolLand)
                            }
                            RectBtn {
                                Layout.fillWidth: true
                                label: qsTr("Point of Interest")
                                btnSelected: root.currentTool === root.toolROI
                                btnEnabled: root.roiEnabled
                                onClicked: root._setTool(root.toolROI)
                            }
                        }

                        Text {
                            width: parent.width
                            text: qsTr("Select a type, then click the map to add")
                            font.pixelSize: theme ? theme.fontXs : 10
                            color: theme ? theme.text3 : "#9aa3b2"
                        }

                        // 选中项
                        SectionTitle { text: qsTr("Selected Item"); theme: root.theme }

                        Rectangle {
                            width: parent.width
                            height: root.hasSelection ? selectedCardContent.implicitHeight + 22 : 0
                            visible: root.hasSelection
                            radius: theme ? theme.radiusLg : 8
                            color: root.sidePanelSurface
                            border.width: 1
                            border.color: theme ? theme.border : "#d7dde6"
                            clip: true

                            Column {
                                id: selectedCardContent
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 10
                                spacing: 10

                                RowLayout {
                                    width: parent.width
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Math.round(4 * root.pageScale)

                                        Text {
                                            id: selectedCommandText
                                            text: root._itemTypeText(root.selectedItem)
                                            font.pixelSize: theme ? theme.fontLg : 15
                                            font.weight: Font.DemiBold
                                            color: root._selectedCommandEditable()
                                                   ? (commandTextMouse.containsMouse ? root.brandBlue : (theme ? theme.text : "#111827"))
                                                   : (theme ? theme.text : "#111827")
                                            elide: Text.ElideRight

                                            MouseArea {
                                                id: commandTextMouse
                                                anchors.fill: parent
                                                enabled: root._selectedCommandEditable()
                                                hoverEnabled: enabled
                                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                onClicked: root._openSelectedCommandDialog()
                                            }
                                        }

                                        Text {
                                            visible: root._selectedCommandEditable()
                                            text: "▾"
                                            font.pixelSize: Math.max(10, Math.round((theme ? theme.fontMd : 12) * root.compactScale))
                                            font.weight: Font.DemiBold
                                            color: commandTextMouse.containsMouse ? root.brandBlue : (theme ? theme.text2 : "#64748b")
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: root._itemSeqText(root.selectedItem)
                                            font.pixelSize: theme ? theme.fontLg : 15
                                            font.weight: Font.DemiBold
                                            color: theme ? theme.text : "#111827"
                                            elide: Text.ElideRight
                                        }
                                    }

                                    RectBtn {
                                        Layout.preferredWidth: 76
                                        height: 34
                                        label: qsTr("Delete")
                                        danger: true
                                        onClicked: root._removeSelected()
                                    }
                                }

                                Text {
                                    width: parent.width
                                    text: root._coordText(root.selectedItem) + qsTr("  Altitude ") + root._altText(root.selectedItem) + " m"
                                    font.pixelSize: theme ? theme.fontSm : 11
                                    color: theme ? theme.text3 : "#8b98aa"
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: qsTr("Height")
                                    font.pixelSize: theme ? theme.fontMd : 12
                                    color: theme ? theme.text2 : "#5a6272"
                                }

                                RowLayout {
                                    width: parent.width
                                    spacing: 8

                                    FactTextField {
                                        id: selectedAltitudeField
                                        Layout.fillWidth: true
                                        fact: root.selectedItem && root.selectedItem.altitude ? root.selectedItem.altitude : null
                                        onActiveFocusChanged: root.editingSelectedField = activeFocus || selectedSpeedField.activeFocus
                                    }

                                    Text {
                                        text: "m"
                                        font.pixelSize: theme ? theme.fontSm : 11
                                        color: theme ? theme.text2 : "#5a6272"
                                    }
                                }

                                Text {
                                    width: parent.width
                                    text: qsTr("Speed")
                                    font.pixelSize: theme ? theme.fontMd : 12
                                    color: theme ? theme.text2 : "#5a6272"
                                }

                                RowLayout {
                                    width: parent.width
                                    spacing: 8

                                    TextField {
                                        id: selectedSpeedField
                                        Layout.fillWidth: true
                                        height: 32
                                        text: root._speedText(root.selectedItem)
                                        selectByMouse: true
                                        font.pixelSize: theme ? theme.fontSm : 11
                                        color: theme ? theme.text : "#111827"
                                        onActiveFocusChanged: root.editingSelectedField = activeFocus || selectedAltitudeField.activeFocus
                                        background: Rectangle {
                                            radius: 3
                                            color: root.sidePanelSurface
                                            border.width: 1
                                            border.color: theme ? theme.border : "#cbd5e1"
                                        }
                                        onEditingFinished: {
                                            if (root.selectedItem && root.selectedItem.specifiedFlightSpeed !== undefined) {
                                                var v = Number(text)
                                                if (v === v && v >= 0) {
                                                    root.selectedItem.specifiedFlightSpeed = v
                                                    root.pendingChanges = true
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        text: "m/s"
                                        font.pixelSize: theme ? theme.fontSm : 11
                                        color: theme ? theme.text2 : "#5a6272"
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 64
                            radius: theme ? theme.radiusLg : 8
                            color: root.sidePanelSurface2
                            border.width: 1
                            border.color: theme ? theme.border : "#e4e8ed"
                            visible: !root.hasSelection

                            Text {
                                anchors.centerIn: parent
                                width: parent.width - 20
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                text: root._visibleItemCount > 0 ? qsTr("Select a waypoint or landing point on the map to view and edit") : qsTr("Select a type, then click the map to add a mission item")
                                font.pixelSize: theme ? theme.fontSm : 11
                                color: theme ? theme.text3 : "#9aa3b2"
                            }
                        }
                    }

                    // ======== 电子围栏 ========
                    Column {
                        width: parent.width
                        spacing: 10
                        visible: root.rightTab === 1

                        PanelSectionTitle { text: qsTr("GeoFence") }

                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: qsTr("Geofences define virtual boundaries around the flight area.")
                            font.pixelSize: root.panelBodyFont
                            font.weight: Font.Medium
                            color: root.panelHintText
                            lineHeight: 1.18
                        }

                        Text {
                            width: parent.width
                            visible: !!root._geoFenceController && !root._geoFenceController.supported
                            text: qsTr("The connected vehicle does not report fence upload support. Fences can still be edited and saved locally.")
                            wrapMode: Text.WordWrap
                            font.pixelSize: root.panelBodyFont
                            color: root.panelHintText
                        }

                        PanelSectionTitle { text: qsTr("Insert GeoFence") }

                        GridLayout {
                            width: parent.width
                            columns: 2
                            columnSpacing: 8
                            rowSpacing: 8

                            RectBtn {
                                Layout.fillWidth: true
                                label: qsTr("＋ Polygon Fence")
                                btnEnabled: root.fenceEnabled
                                onClicked: root._addPolyFence()
                            }
                            RectBtn {
                                Layout.fillWidth: true
                                label: qsTr("＋ Circular Fence")
                                btnEnabled: root.fenceEnabled
                                onClicked: root._addCircleFence()
                            }
                        }

                        PanelSectionTitle { text: qsTr("Polygon Fence") }

                        RowLayout {
                            width: parent.width
                            spacing: 8
                            visible: root._geoFenceController && root._geoFenceController.polygons.count > 0

                            ColumnHeaderText {
                                Layout.preferredWidth: 38
                                text: qsTr("Inclusion")
                                horizontalAlignment: Text.AlignHCenter
                            }
                            ColumnHeaderText {
                                Layout.preferredWidth: 38
                                text: qsTr("Edit")
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Item { Layout.fillWidth: true }
                            ColumnHeaderText {
                                Layout.preferredWidth: 54
                                text: qsTr("Delete")
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        Repeater {
                            model: root._geoFenceController ? root._geoFenceController.polygons : null
                            delegate: RowLayout {
                                width: parent.width
                                height: 36
                                spacing: 8

                                CheckBox {
                                    Layout.preferredWidth: 38
                                    checked: object.inclusion
                                    onClicked: object.inclusion = checked
                                }

                                RadioButton {
                                    Layout.preferredWidth: 38
                                    checked: object.interactive
                                    onClicked: {
                                        if (root._geoFenceController) {
                                            root._geoFenceController.clearAllInteractive()
                                        }
                                        object.interactive = checked
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: qsTr("Polygon ") + (index + 1)
                                    font.pixelSize: root.panelBodyFont
                                    font.weight: Font.DemiBold
                                    color: root.panelTitleText
                                    elide: Text.ElideRight
                                }

                                RectBtn {
                                    Layout.preferredWidth: 54
                                    height: 28
                                    label: qsTr("Delete")
                                    danger: true
                                    onClicked: {
                                        if (root._geoFenceController) {
                                            root._geoFenceController.deletePolygon(index)
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            text: root._geoFenceController && root._geoFenceController.polygons.count === 0 ? qsTr("No polygon fences") : ""
                            visible: root._geoFenceController && root._geoFenceController.polygons.count === 0
                            font.pixelSize: root.panelBodyFont
                            color: root.panelMutedText
                        }

                        PanelSectionTitle { text: qsTr("Circular Fence") }

                        RowLayout {
                            width: parent.width
                            spacing: 8
                            visible: root._geoFenceController && root._geoFenceController.circles.count > 0

                            ColumnHeaderText {
                                Layout.preferredWidth: 38
                                text: qsTr("Inclusion")
                                horizontalAlignment: Text.AlignHCenter
                            }
                            ColumnHeaderText {
                                Layout.preferredWidth: 38
                                text: qsTr("Edit")
                                horizontalAlignment: Text.AlignHCenter
                            }
                            ColumnHeaderText {
                                Layout.fillWidth: true
                                text: qsTr("Radius")
                                horizontalAlignment: Text.AlignHCenter
                            }
                            ColumnHeaderText {
                                Layout.preferredWidth: 54
                                text: qsTr("Delete")
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        Repeater {
                            model: root._geoFenceController ? root._geoFenceController.circles : null
                            delegate: RowLayout {
                                width: parent.width
                                height: 36
                                spacing: 8

                                CheckBox {
                                    Layout.preferredWidth: 38
                                    checked: object.inclusion
                                    onClicked: object.inclusion = checked
                                }

                                RadioButton {
                                    Layout.preferredWidth: 38
                                    checked: object.interactive
                                    onClicked: {
                                        if (root._geoFenceController) {
                                            root._geoFenceController.clearAllInteractive()
                                        }
                                        object.interactive = checked
                                    }
                                }

                                FactTextField {
                                    Layout.fillWidth: true
                                    height: 30
                                    fact: object.radius
                                }

                                RectBtn {
                                    Layout.preferredWidth: 54
                                    height: 28
                                    label: qsTr("Delete")
                                    danger: true
                                    onClicked: {
                                        if (root._geoFenceController) {
                                            root._geoFenceController.deleteCircle(index)
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            text: root._geoFenceController && root._geoFenceController.circles.count === 0 ? qsTr("No circular fences") : ""
                            visible: root._geoFenceController && root._geoFenceController.circles.count === 0
                            font.pixelSize: root.panelBodyFont
                            color: root.panelMutedText
                        }

                        PanelSectionTitle { text: qsTr("Breach Return Point") }

                        RectBtn {
                            width: parent.width
                            height: theme ? theme.controlHMd : 34
                            label: root._geoFenceController && root._geoFenceController.breachReturnPoint.isValid ? qsTr("Remove Breach Return Point") : qsTr("Add Breach Return Point")
                            btnEnabled: root.fenceEnabled
                            danger: root._geoFenceController && root._geoFenceController.breachReturnPoint.isValid
                            onClicked: {
                                if (!root._geoFenceController) {
                                    return
                                }
                                if (root._geoFenceController.breachReturnPoint.isValid) {
                                    root._geoFenceController.breachReturnPoint = QtPositioning.coordinate()
                                } else {
                                    root._geoFenceController.breachReturnPoint = planMap.center
                                }
                            }
                        }

                        RowLayout {
                            width: parent.width
                            spacing: 8
                            visible: root._geoFenceController && root._geoFenceController.breachReturnPoint.isValid

                            Text {
                                text: qsTr("Return Altitude")
                                font.pixelSize: theme ? theme.fontSm : 11
                                color: theme ? theme.text2 : "#5a6272"
                            }
                            FactTextField {
                                Layout.fillWidth: true
                                fact: root._geoFenceController ? root._geoFenceController.breachReturnAltitude : null
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: panelCollapseHandle
        width: Math.max(22, Math.round(26 * root.pageScale))
        height: Math.max(48, Math.round(58 * root.pageScale))
        radius: Math.round(width / 2)
        color: root.sidePanelSurface
        border.color: theme ? theme.border : "#d7dde6"
        border.width: 1
        z: 80
        anchors.right: root.panelCollapsed ? parent.right : rightPanel.left
        anchors.rightMargin: root.panelCollapsed ? 0 : -Math.round(width / 2)
        anchors.top: parent.top
        anchors.topMargin: root.topInset + Math.round((parent.height - root.topInset - height) / 2)

        Text {
            anchors.centerIn: parent
            text: root.panelCollapsed ? "‹" : "›"
            font.pixelSize: Math.max(18, Math.round(22 * root.pageScale))
            font.weight: Font.Bold
            color: theme ? theme.text : "#111827"
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.panelCollapsed = !root.panelCollapsed
        }
    }

    Component {
        id: selectedCommandDialog

        CustomPlanMissionCommandDialog {
            vehicle: root._planVehicle
            missionItem: root.selectedItem
            map: planMap
            theme: root.theme
            flyThroughCommandsAllowed: true
        }
    }

    // ================= 弹窗 =================

    // 保存成功提示
    Popup {
        id: saveSuccessDialog
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape
        parent: root
        anchors.centerIn: parent
        width: 300
        padding: 0

        background: Rectangle {
            radius: theme ? theme.radiusLg : 10
            color: theme ? theme.surface : "#ffffff"
            border.width: 1
            border.color: theme ? theme.border : "#e4e8ed"
        }

        contentItem: Column {
            width: saveSuccessDialog.width
            spacing: 0

            Rectangle {
                width: parent.width
                height: 56
                color: theme ? theme.greenL : "#dcfce7"

                Text {
                    anchors.centerIn: parent
                    text: "✓"
                    font.pixelSize: 26
                    font.weight: Font.Bold
                    color: theme ? theme.green : "#16a34a"
                }
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Saved Successfully")
                font.pixelSize: theme ? theme.fontLg : 15
                font.weight: Font.DemiBold
                color: theme ? theme.text : "#1a1d23"
                padding: 16
            }

            Rectangle {
                width: parent.width
                height: 44
                color: "transparent"

                Rectangle {
                    anchors.centerIn: parent
                    width: 120
                    height: 32
                    radius: theme ? theme.radius : 6
                    color: okMouse.containsMouse ? root.brandBlue : root.brandHover
                    border.width: 1
                    border.color: theme ? theme.blueBorder : "#8080B3"

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Ok")
                        font.pixelSize: theme ? theme.fontMd : 12
                        font.weight: Font.Medium
                        color: okMouse.containsMouse ? "#ffffff" : root.brandBlue
                    }

                    MouseArea {
                        id: okMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: saveSuccessDialog.close()
                    }
                }
            }
        }
    }

    // 未保存修改弹窗
    Popup {
        id: savePromptDialog
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape
        parent: root
        anchors.centerIn: parent
        width: 340
        padding: 0

        background: Rectangle {
            radius: theme ? theme.radiusLg : 10
            color: theme ? theme.surface : "#ffffff"
            border.width: 1
            border.color: theme ? theme.border : "#e4e8ed"
        }

        contentItem: Column {
            width: savePromptDialog.width
            spacing: 0

            Text {
                width: parent.width
                text: qsTr("Unsaved Mission")
                font.pixelSize: theme ? theme.fontLg : 15
                font.weight: Font.DemiBold
                color: theme ? theme.text : "#1a1d23"
                horizontalAlignment: Text.AlignHCenter
                padding: 18
            }

            Text {
                width: parent.width
                text: qsTr("The current mission has unsaved changes. Save them?")
                font.pixelSize: theme ? theme.fontMd : 12
                color: theme ? theme.text2 : "#5a6272"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                padding: 14
                topPadding: 0
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10
                padding: 16

                Rectangle {
                    width: 88
                    height: 34
                    radius: theme ? theme.radius : 6
                    color: promptSaveMouse.containsMouse ? root.brandBlue : root.brandHover
                    border.width: 1
                    border.color: theme ? theme.blueBorder : "#8080B3"

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Save")
                        font.pixelSize: theme ? theme.fontMd : 12
                        font.weight: Font.Medium
                        color: promptSaveMouse.containsMouse ? "#ffffff" : root.brandBlue
                    }

                    MouseArea {
                        id: promptSaveMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root._doSave(true)
                    }
                }

                Rectangle {
                    width: 88
                    height: 34
                    radius: theme ? theme.radius : 6
                    color: promptDiscardMouse.containsMouse ? (theme ? theme.text3 : "#9aa3b2") : (theme ? theme.surface2 : "#f1f5f9")
                    border.width: 1
                    border.color: theme ? theme.border : "#d7dde6"

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Discard")
                        font.pixelSize: theme ? theme.fontMd : 12
                        font.weight: Font.Medium
                        color: theme ? theme.text2 : "#5a6272"
                    }

                    MouseArea {
                        id: promptDiscardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            savePromptDialog.close()
                            root._clearFenceInteractive()
                            root.closeRequested()
                        }
                    }
                }

                Rectangle {
                    width: 88
                    height: 34
                    radius: theme ? theme.radius : 6
                    color: promptCancelMouse.containsMouse ? (theme ? theme.surface3 : "#eef2f7") : (theme ? theme.surface2 : "#f8fafc")
                    border.width: 1
                    border.color: theme ? theme.border : "#e4e8ed"

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Cancel")
                        font.pixelSize: theme ? theme.fontMd : 12
                        font.weight: Font.Medium
                        color: theme ? theme.text2 : "#5a6272"
                    }

                    MouseArea {
                        id: promptCancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: savePromptDialog.close()
                    }
                }
            }
        }
    }

    // 通用消息弹窗
    Popup {
        id: messageDialog
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape
        parent: root
        anchors.centerIn: parent
        width: 300
        padding: 0

        property string text: ""

        background: Rectangle {
            radius: theme ? theme.radiusLg : 10
            color: theme ? theme.surface : "#ffffff"
            border.width: 1
            border.color: theme ? theme.border : "#e4e8ed"
        }

        contentItem: Column {
            width: messageDialog.width
            spacing: 0

            Text {
                width: parent.width
                text: messageDialog.text
                font.pixelSize: theme ? theme.fontMd : 12
                color: theme ? theme.text : "#1a1d23"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                padding: 20
            }

            Rectangle {
                width: parent.width
                height: 44
                color: "transparent"

                Rectangle {
                    anchors.centerIn: parent
                    width: 120
                    height: 32
                    radius: theme ? theme.radius : 6
                    color: msgOkMouse.containsMouse ? root.brandBlue : root.brandHover
                    border.width: 1
                    border.color: theme ? theme.blueBorder : "#8080B3"

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Ok")
                        font.pixelSize: theme ? theme.fontMd : 12
                        font.weight: Font.Medium
                        color: msgOkMouse.containsMouse ? "#ffffff" : root.brandBlue
                    }

                    MouseArea {
                        id: msgOkMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: messageDialog.close()
                    }
                }
            }
        }
    }

    // ================= 组件 =================

    component PanelSectionTitle: Text {
        width: parent ? parent.width : implicitWidth
        topPadding: Math.round(2 * root.pageScale)
        text: ""
        font.pixelSize: root.panelSectionFont
        font.weight: Font.Bold
        color: root.panelTitleText
        elide: Text.ElideRight
    }

    component ColumnHeaderText: Text {
        font.pixelSize: root.panelMetaFont
        font.weight: Font.DemiBold
        color: root.panelHeaderText
        elide: Text.ElideRight
    }

    component RectBtn: Rectangle {
        property string label: ""
        property bool btnSelected: false
        property bool btnEnabled: true
        property bool danger: false
        signal clicked

        implicitHeight: root.panelButtonH
        radius: theme ? theme.radius : 6
        color: btnSelected
               ? (btnMouse.containsMouse ? root.brandPress : root.brandBlue)
               : danger
                 ? (btnMouse.containsMouse ? (theme ? theme.red : "#dc2626") : (theme ? theme.redL : "#fee2e2"))
                 : btnMouse.containsMouse && btnEnabled
                   ? root.brandHover
                   : root.sidePanelSurface2
        border.width: 1
        border.color: btnSelected
                      ? root.brandBorder
                      : danger
                        ? (theme ? theme.red : "#dc2626")
                        : (theme ? theme.border : "#d7dde6")
        opacity: btnEnabled ? 1 : 0.45

        Behavior on color { ColorAnimation { duration: 100 } }

        Text {
            anchors.centerIn: parent
            width: parent.width - Math.round(8 * root.pageScale)
            horizontalAlignment: Text.AlignHCenter
            text: parent.label
            font.pixelSize: Math.max(10, Math.round((theme ? theme.fontMd : 12) * root.compactScale))
            font.weight: Font.Medium
            color: btnSelected || (danger && btnMouse.containsMouse && btnEnabled)
                   ? "#ffffff"
                   : danger
                     ? (theme ? theme.red : "#dc2626")
                     : (btnMouse.containsMouse && btnEnabled ? root.brandBlue : (theme ? theme.text : "#1a1d23"))
            elide: Text.ElideRight
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            enabled: btnEnabled
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: parent.clicked()
        }
    }
}
