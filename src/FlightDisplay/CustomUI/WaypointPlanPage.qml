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
import QtPositioning

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.FlightMap

Item {
    id: root

    property var state: null
    property var theme: null
    property var missionController: null
    signal closeRequested()

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

    // ---- 启用逻辑（起飞点 → 航点/着陆/兴趣点 → 着陆定位）----
    readonly property bool takeoffEnabled:      !hasTakeoff && !!missionController
    readonly property bool waypointEnabled:     hasTakeoff && !hasLand
    readonly property bool landEnabled:         hasTakeoff && !hasLand && !!missionController
    readonly property bool roiEnabled:          hasTakeoff && !hasLand
    readonly property bool landLocateEnabled:   hasLand
    readonly property bool fenceEnabled:        !!_geoFenceController && _geoFenceController.supported
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
        if (item.isLandItem || item.isLandCommand) {
            return true
        }
        var name = item.commandName ? String(item.commandName) : ""
        var desc = item.commandDescription ? String(item.commandDescription) : ""
        var pattern = item.patternName ? String(item.patternName) : ""
        return name === "Land" ||
               name === "VTOL Land" ||
               name === "Landing Pattern" ||
               pattern === "VTOL Landing" ||
               pattern === "Fixed Wing Landing" ||
               pattern === "Landing Pattern" ||
               desc === "Landing Pattern" ||
               item.landingCoordinate !== undefined
    }

    function _refreshTools() {
        hasTakeoff = _findTakeoff()
        landSeqNum = _findLandSeq()
        hasLand = landSeqNum > 0
        if (!hasTakeoff) {
            currentTool = toolTakeoff
        } else if (!hasLand) {
            if (currentTool !== toolWaypoint && currentTool !== toolLand && currentTool !== toolROI) {
                currentTool = toolWaypoint
            }
        } else {
            currentTool = toolLandLocate
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
        if (_missionItems.count <= 1) {
            messageDialog.text = "当前没有可保存的任务"
            messageDialog.open()
            return
        }
        if (!lastSavedFile || lastSavedFile.length === 0) {
            lastSavedFile = _savePath() + "任务_" + Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss") + ".plan"
        }
        _masterController.saveToFile(lastSavedFile)
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
    }

    function _addCircleFence() {
        if (!_geoFenceController || !fenceEnabled) {
            return
        }
        var topLeft = planMap.toCoordinate(Qt.point(planMap.width * 0.25, planMap.height * 0.30), false)
        var bottomRight = planMap.toCoordinate(Qt.point(planMap.width * 0.75, planMap.height * 0.70), false)
        _geoFenceController.addInclusionCircle(topLeft, bottomRight)
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

    function _vehicleIsFixedWing() {
        return _planVehicle && _planVehicle.fixedWing && !_vehicleIsVTOL()
    }

    function _vehicleIsMultiRotor() {
        return !_vehicleIsVTOL() && _planVehicle && _planVehicle.multiRotor
    }

    function _createSimpleLandItem(landCoordinate) {
        var item = missionController.insertSimpleMissionItem(landCoordinate, -1, true)
        if (item) {
            item.setMapCenterHintForCommandChange(landCoordinate)
            item.command = mavCmdNavLand
            if (item.coordinate !== undefined) {
                item.coordinate = landCoordinate
            }
        }
        return item
    }

    function _createLandAtCoordinate(coordinate) {
        if (!landEnabled || !missionController) {
            messageDialog.text = "当前状态不能添加着陆点"
            messageDialog.open()
            return false
        }
        var landCoordinate = _normalizeMapCoordinate(coordinate)
        if (!landCoordinate.isValid) {
            messageDialog.text = "地图坐标无效，无法添加着陆点"
            messageDialog.open()
            return false
        }
        var landItem = null
        if (_vehicleIsVTOL() && missionController.insertComplexMissionItem) {
            landItem = missionController.insertComplexMissionItem("VTOL Landing", landCoordinate, -1, true)
        } else if (_vehicleIsFixedWing() && missionController.insertComplexMissionItem) {
            landItem = missionController.insertComplexMissionItem("Fixed Wing Landing", landCoordinate, -1, true)
        } else if (_vehicleIsMultiRotor()) {
            landItem = _createSimpleLandItem(landCoordinate)
        }
        if (!landItem) {
            landItem = missionController.insertLandItem(landCoordinate, -1, true)
        }
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
            messageDialog.text = "着陆点添加失败，请确认已创建起飞点且任务中没有已有着陆点"
            messageDialog.open()
        }
        return selected
    }

    function _setTool(tool) {
        currentTool = tool
    }

    function _applyUniformSpeed(item) {
        if (uniformSpeedEnabled && item && item.specifiedFlightSpeed !== undefined) {
            item.specifiedFlightSpeed = uniformSpeedMps
        }
    }

    function _itemTitle(item) {
        if (!item) {
            return "任务项"
        }
        var seq = item.sequenceNumber !== undefined ? item.sequenceNumber : ""
        if (item.isTakeoffItem) {
            return "起飞 " + seq
        }
        if (_isLandVisualItem(item)) {
            return "着陆 " + seq
        }
        if (item.commandName && String(item.commandName).indexOf("ROI") >= 0) {
            return "兴趣点 " + seq
        }
        return "航点 " + seq
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
        rightTab = 0
        if (_visibleItemCount === 0) {
            lastSavedFile = ""
            currentTool = toolTakeoff
        }
        landSeqNum = _findLandSeq()
        _refreshTools()
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
        anchors.right: rightPanel.left
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
                planMap.focus = true
                var coordinate = root._normalizeMapCoordinate(planMap.toCoordinate(Qt.point(mouse.x, mouse.y), false))

                switch (root.currentTool) {
                case root.toolTakeoff:
                    if (root.takeoffEnabled && root.missionController) {
                        var takeoffItem = root.missionController.insertTakeoffItem(coordinate, -1, true)
                        if (takeoffItem) {
                            takeoffItem.coordinate = coordinate
                            if (takeoffItem.launchCoordinate !== undefined) {
                                takeoffItem.launchCoordinate = coordinate
                            }
                            root.hasTakeoff = true
                            root.missionController.setCurrentPlanViewSeqNum(takeoffItem.sequenceNumber, true)
                            root.currentTool = root.toolWaypoint
                        }
                    }
                    break
                case root.toolWaypoint:
                    if (root.waypointEnabled && root.missionController) {
                        var wpItem = root.missionController.insertSimpleMissionItem(coordinate, -1, true)
                        root._applyUniformSpeed(wpItem)
                    }
                    break
                case root.toolLand:
                    root._createLandAtCoordinate(coordinate)
                    break
                case root.toolROI:
                    if (root.roiEnabled && root.missionController) {
                        root.missionController.insertROIMissionItem(coordinate, -1, true)
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
                            root.missionController.setCurrentPlanViewSeqNum(sequenceNumber, false)
                        }
                    }
                }
            }

            // 航点连线
            MissionLineView {
                model: root.missionController ? root.missionController.simpleFlightPathSegments : null
                opacity: root.fenceMode ? 0.5 : 1
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
            width: 46
            height: 46
            radius: 23
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: 10
            anchors.leftMargin: 10
            z: 30
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
                font.pixelSize: theme ? theme.fontLg + 2 : 18
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
            anchors.topMargin: 2
            z: 30
            text: "保存"
            font.pixelSize: theme ? theme.fontXs : 9
            color: theme ? theme.green : "#16a34a"
        }

        // 左下角信息栏（照搬起飞界面 HUD：姿态/航向/速度/经纬度/高度）
        FlyViewHUD {
            id: planHud
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            state: root.state
            theme: root.theme
        }
    }

    // ---------- 右侧“任务规划”面板 ----------
    Rectangle {
        id: rightPanel
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 344
        color: theme ? theme.surface : "#ffffff"
        clip: true

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
                height: theme ? theme.sectionH : 44
                color: theme ? theme.surface : "#ffffff"

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: theme ? theme.border : "#e4e8ed"
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: "任务规划"
                    font.pixelSize: theme ? theme.fontLg : 15
                    font.weight: Font.DemiBold
                    color: theme ? theme.text : "#1a1d23"
                }
            }

            // 航线规划 / 电子围栏 切换
            RowLayout {
                width: parent.width - 24
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                RectBtn {
                    Layout.fillWidth: true
                    label: "✈ 航线规划"
                    btnSelected: root.rightTab === 0
                    btnEnabled: true
                    onClicked: root.rightTab = 0
                }

                RectBtn {
                    Layout.fillWidth: true
                    label: "⌗ 电子围栏"
                    btnSelected: root.rightTab === 1
                    btnEnabled: root.fenceEnabled
                    onClicked: root.rightTab = 1
                }
            }

            Flickable {
                width: parent.width
                height: parent.height - (theme ? theme.sectionH : 44) - (theme ? theme.controlHMd + 14 : 50)
                contentWidth: width
                contentHeight: panelContent.implicitHeight
                clip: true
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                Column {
                    id: panelContent
                    width: parent.width - 28
                    x: 14
                    spacing: 12

                    // ======== 航线规划 ========
                    Column {
                        width: parent.width
                        spacing: 10
                        visible: root.rightTab === 0

                        SectionTitle { text: "点击地图新增"; theme: root.theme }

                        GridLayout {
                            width: parent.width
                            columns: 2
                            columnSpacing: 8
                            rowSpacing: 8

                            RectBtn {
                                Layout.fillWidth: true
                                label: "起飞"
                                btnSelected: root.currentTool === root.toolTakeoff
                                btnEnabled: root.takeoffEnabled
                                onClicked: root._setTool(root.toolTakeoff)
                            }
                            RectBtn {
                                Layout.fillWidth: true
                                label: "航点"
                                btnSelected: root.currentTool === root.toolWaypoint
                                btnEnabled: root.waypointEnabled
                                onClicked: root._setTool(root.toolWaypoint)
                            }
                            RectBtn {
                                Layout.fillWidth: true
                                label: "着陆"
                                btnSelected: root.currentTool === root.toolLand
                                btnEnabled: root.landEnabled
                                onClicked: root._setTool(root.toolLand)
                            }
                            RectBtn {
                                Layout.fillWidth: true
                                label: "兴趣点"
                                btnSelected: root.currentTool === root.toolROI
                                btnEnabled: root.roiEnabled
                                onClicked: root._setTool(root.toolROI)
                            }
                        }

                        Text {
                            width: parent.width
                            text: "选择类型后点击地图添加"
                            font.pixelSize: theme ? theme.fontXs : 10
                            color: theme ? theme.text3 : "#9aa3b2"
                        }

                        // 选中项
                        SectionTitle { text: "选中项"; theme: root.theme }

                        Rectangle {
                            width: parent.width
                            height: root.hasSelection ? selectedCardContent.implicitHeight + 22 : 0
                            visible: root.hasSelection
                            radius: theme ? theme.radiusLg : 8
                            color: theme ? theme.surface : "#ffffff"
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

                                    Text {
                                        Layout.fillWidth: true
                                        text: root._itemTitle(root.selectedItem)
                                        font.pixelSize: theme ? theme.fontLg : 15
                                        font.weight: Font.DemiBold
                                        color: theme ? theme.text : "#111827"
                                        elide: Text.ElideRight
                                    }

                                    RectBtn {
                                        Layout.preferredWidth: 76
                                        height: 34
                                        label: "删除"
                                        danger: true
                                        onClicked: root._removeSelected()
                                    }
                                }

                                Text {
                                    width: parent.width
                                    text: root._coordText(root.selectedItem) + "  高度 " + root._altText(root.selectedItem) + " m"
                                    font.pixelSize: theme ? theme.fontSm : 11
                                    color: theme ? theme.text3 : "#8b98aa"
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: "高度"
                                    font.pixelSize: theme ? theme.fontMd : 12
                                    color: theme ? theme.text2 : "#5a6272"
                                }

                                RowLayout {
                                    width: parent.width
                                    spacing: 8

                                    FactTextField {
                                        Layout.fillWidth: true
                                        fact: root.selectedItem && root.selectedItem.altitude ? root.selectedItem.altitude : null
                                    }

                                    Text {
                                        text: "m"
                                        font.pixelSize: theme ? theme.fontSm : 11
                                        color: theme ? theme.text2 : "#5a6272"
                                    }
                                }

                                Text {
                                    width: parent.width
                                    text: "速度"
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
                                        background: Rectangle {
                                            radius: 3
                                            color: theme ? theme.surface : "#ffffff"
                                            border.width: 1
                                            border.color: theme ? theme.border : "#cbd5e1"
                                        }
                                        onEditingFinished: {
                                            if (root.selectedItem && root.selectedItem.specifiedFlightSpeed !== undefined) {
                                                var v = Number(text)
                                                if (v === v && v >= 0) {
                                                    root.selectedItem.specifiedFlightSpeed = v
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
                            color: theme ? theme.surface2 : "#f8fafc"
                            border.width: 1
                            border.color: theme ? theme.border : "#e4e8ed"
                            visible: !root.hasSelection

                            Text {
                                anchors.centerIn: parent
                                width: parent.width - 20
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                text: root._visibleItemCount > 0 ? "点击地图中的航点/着陆点查看与编辑" : "选择类型后点击地图添加任务项"
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

                        SectionTitle { text: "地理围栏"; theme: root.theme }

                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: "地理围栏允许你在飞行区域周围设置虚拟围栏。"
                            font.pixelSize: theme ? theme.fontXs : 10
                            color: theme ? theme.text3 : "#9aa3b2"
                        }

                        SectionTitle { text: "插入地理围栏"; theme: root.theme }

                        GridLayout {
                            width: parent.width
                            columns: 2
                            columnSpacing: 8
                            rowSpacing: 8

                            RectBtn {
                                Layout.fillWidth: true
                                label: "＋ 多边形围栏"
                                btnEnabled: root.fenceEnabled
                                onClicked: root._addPolyFence()
                            }
                            RectBtn {
                                Layout.fillWidth: true
                                label: "＋ 圆形围栏"
                                btnEnabled: root.fenceEnabled
                                onClicked: root._addCircleFence()
                            }
                        }

                        SectionTitle { text: "多边形围栏"; theme: root.theme }

                        RowLayout {
                            width: parent.width
                            spacing: 8
                            visible: root._geoFenceController && root._geoFenceController.polygons.count > 0

                            Text {
                                Layout.preferredWidth: 38
                                text: "包含"
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: theme ? theme.fontXs : 10
                                color: theme ? theme.text3 : "#8b98aa"
                            }
                            Text {
                                Layout.preferredWidth: 38
                                text: "编辑"
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: theme ? theme.fontXs : 10
                                color: theme ? theme.text3 : "#8b98aa"
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                Layout.preferredWidth: 54
                                text: "删除"
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: theme ? theme.fontXs : 10
                                color: theme ? theme.text3 : "#8b98aa"
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
                                    text: "多边形 " + (index + 1)
                                    font.pixelSize: theme ? theme.fontSm : 11
                                    color: theme ? theme.text : "#1a1d23"
                                    elide: Text.ElideRight
                                }

                                RectBtn {
                                    Layout.preferredWidth: 54
                                    height: 28
                                    label: "删除"
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
                            text: root._geoFenceController && root._geoFenceController.polygons.count === 0 ? "暂无多边形围栏" : ""
                            visible: root._geoFenceController && root._geoFenceController.polygons.count === 0
                            font.pixelSize: theme ? theme.fontSm : 11
                            color: theme ? theme.text3 : "#9aa3b2"
                        }

                        SectionTitle { text: "圆形围栏"; theme: root.theme }

                        RowLayout {
                            width: parent.width
                            spacing: 8
                            visible: root._geoFenceController && root._geoFenceController.circles.count > 0

                            Text {
                                Layout.preferredWidth: 38
                                text: "包含"
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: theme ? theme.fontXs : 10
                                color: theme ? theme.text3 : "#8b98aa"
                            }
                            Text {
                                Layout.preferredWidth: 38
                                text: "编辑"
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: theme ? theme.fontXs : 10
                                color: theme ? theme.text3 : "#8b98aa"
                            }
                            Text {
                                Layout.fillWidth: true
                                text: "半径"
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: theme ? theme.fontXs : 10
                                color: theme ? theme.text3 : "#8b98aa"
                            }
                            Text {
                                Layout.preferredWidth: 54
                                text: "删除"
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: theme ? theme.fontXs : 10
                                color: theme ? theme.text3 : "#8b98aa"
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
                                    label: "删除"
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
                            text: root._geoFenceController && root._geoFenceController.circles.count === 0 ? "暂无圆形围栏" : ""
                            visible: root._geoFenceController && root._geoFenceController.circles.count === 0
                            font.pixelSize: theme ? theme.fontSm : 11
                            color: theme ? theme.text3 : "#9aa3b2"
                        }

                        SectionTitle { text: "越界返回点"; theme: root.theme }

                        RectBtn {
                            width: parent.width
                            height: theme ? theme.controlHMd : 34
                            label: root._geoFenceController && root._geoFenceController.breachReturnPoint.isValid ? "移除越界返回点" : "增加越界返回点"
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
                                text: "返回高度"
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
                text: "保存成功"
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
                    color: okMouse.containsMouse ? (theme ? theme.blue : "#000066") : (theme ? theme.blueL : "#E6E6F0")
                    border.width: 1
                    border.color: theme ? theme.blueBorder : "#8080B3"

                    Text {
                        anchors.centerIn: parent
                        text: "确定"
                        font.pixelSize: theme ? theme.fontMd : 12
                        font.weight: Font.Medium
                        color: theme ? theme.blue : "#000066"
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
                text: "任务尚未保存"
                font.pixelSize: theme ? theme.fontLg : 15
                font.weight: Font.DemiBold
                color: theme ? theme.text : "#1a1d23"
                horizontalAlignment: Text.AlignHCenter
                padding: 18
            }

            Text {
                width: parent.width
                text: "当前任务有未保存的修改，是否保存？"
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
                    color: promptSaveMouse.containsMouse ? (theme ? theme.blue : "#000066") : (theme ? theme.blueL : "#E6E6F0")
                    border.width: 1
                    border.color: theme ? theme.blueBorder : "#8080B3"

                    Text {
                        anchors.centerIn: parent
                        text: "保存"
                        font.pixelSize: theme ? theme.fontMd : 12
                        font.weight: Font.Medium
                        color: theme ? theme.blue : "#000066"
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
                        text: "不保存"
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
                        text: "取消"
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
                    color: msgOkMouse.containsMouse ? (theme ? theme.blue : "#000066") : (theme ? theme.blueL : "#E6E6F0")
                    border.width: 1
                    border.color: theme ? theme.blueBorder : "#8080B3"

                    Text {
                        anchors.centerIn: parent
                        text: "确定"
                        font.pixelSize: theme ? theme.fontMd : 12
                        font.weight: Font.Medium
                        color: theme ? theme.blue : "#000066"
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

    component RectBtn: Rectangle {
        property string label: ""
        property bool btnSelected: false
        property bool btnEnabled: true
        property bool danger: false
        signal clicked

        implicitHeight: theme ? theme.controlHMd : 34
        radius: theme ? theme.radius : 6
        color: btnSelected
               ? (btnMouse.containsMouse ? (theme ? theme.blue : "#00004D") : (theme ? theme.blue : "#000066"))
               : danger
                 ? (btnMouse.containsMouse ? (theme ? theme.red : "#dc2626") : (theme ? theme.redL : "#fee2e2"))
                 : btnMouse.containsMouse && btnEnabled
                   ? (theme ? theme.blueL : "#E6E6F0")
                   : (theme ? theme.surface2 : "#f8fafc")
        border.width: 1
        border.color: btnSelected
                      ? (theme ? theme.blueBorder : "#000066")
                      : danger
                        ? (theme ? theme.red : "#dc2626")
                        : (theme ? theme.border : "#d7dde6")
        opacity: btnEnabled ? 1 : 0.45

        Behavior on color { ColorAnimation { duration: 100 } }

        Text {
            anchors.centerIn: parent
            text: parent.label
            font.pixelSize: theme ? theme.fontMd : 12
            font.weight: Font.Medium
            color: btnSelected || (danger && btnMouse.containsMouse && btnEnabled)
                   ? "#ffffff"
                   : danger
                     ? (theme ? theme.red : "#dc2626")
                     : (btnMouse.containsMouse && btnEnabled ? (theme ? theme.blue : "#000066") : (theme ? theme.text : "#1a1d23"))
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
