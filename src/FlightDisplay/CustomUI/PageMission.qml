// PageMission.qml 任务列表页
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controllers

Rectangle {
    id: root

    property var state: null
    property var theme: null
    property var openCustomPlanShell: null
    signal takeoffPageRequested()
    readonly property bool compactMode: width < 320
    readonly property bool narrowMode: width < 190
    readonly property var missionController: state ? state.missionController : null
    readonly property var masterController: missionController ? missionController.masterController : null
    readonly property bool vehicleTaskAvailable: !!(state && state.vehicleConnected) &&
                                                 !!((state && state.missionAvailable) ||
                                                    (missionController && missionController.missionItemCount > 1) ||
                                                    (masterController && masterController.containsItems))
    property var savedPlans: []
    property int selectedVisibleIndex: -1
    property int pendingDeleteIndex: -1
    property string confirmAction: ""

    QGCFileDialogController { id: fileController }

    Dialog {
        id: confirmDialog
        modal: true
        dim: true
        anchors.centerIn: parent
        width: Math.min(root.width - 32, 300)
        title: confirmAction === "clearVehicle" ? "清空飞控任务" : "删除任务"
        standardButtons: Dialog.Ok | Dialog.Cancel

        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            text: confirmAction === "clearVehicle"
                  ? "确定要清空飞控上的任务吗？此操作会同步删除飞控中的任务。"
                  : "确定要删除这个本地任务吗？"
        }

        onAccepted: {
            if (confirmAction === "clearVehicle") {
                root._clearVehicleTask()
            } else if (confirmAction === "deleteTask") {
                root._deleteTaskNow(pendingDeleteIndex)
            }
            pendingDeleteIndex = -1
            confirmAction = ""
        }
        onRejected: {
            pendingDeleteIndex = -1
            confirmAction = ""
        }
    }

    function _saveDir() {
        var folder = QGroundControl.settingsManager.appSettings.missionSavePath
        folder = String(folder).replace(/\\/g, "/")
        if (folder.length > 0 && folder.charAt(folder.length - 1) !== "/") {
            folder += "/"
        }
        return folder
    }

    function _taskFile(index) {
        if (index < 0 || index >= savedPlans.length) {
            return ""
        }
        return savedPlans[index]
    }

    function _taskPath(index) {
        var file = _taskFile(index)
        if (file.length === 0) {
            return ""
        }
        return fileController.fullyQualifiedFilename(_saveDir(), file, ["*.plan"])
    }

    function _displayName(fileName) {
        var name = String(fileName)
        if (name.toLowerCase().endsWith(".plan")) {
            name = name.substring(0, name.length - 5)
        }
        return name.length > 0 ? name : "未命名任务"
    }

    function _fileNameFromPath(path) {
        var normalized = String(path).replace(/\\/g, "/")
        var slash = normalized.lastIndexOf("/")
        return slash >= 0 ? normalized.substring(slash + 1) : normalized
    }

    function _refreshSavedPlans() {
        savedPlans = fileController.getFiles(_saveDir(), ["*.plan"])
        if (savedPlans.length === 0) {
            selectedVisibleIndex = -1
        } else if (selectedVisibleIndex < 0 || selectedVisibleIndex >= savedPlans.length) {
            selectedVisibleIndex = 0
        }
    }

    function _loadSelectedTask() {
        if (!masterController || selectedVisibleIndex < 0) {
            return false
        }
        var path = _taskPath(selectedVisibleIndex)
        if (path.length === 0 || !fileController.fileExists(path)) {
            _refreshSavedPlans()
            return false
        }
        masterController.loadFromFile(path)
        return true
    }

    function _executeSelectedTask() {
        if (!_loadSelectedTask()) {
            return
        }
        if (masterController && masterController.sendToVehicle) {
            masterController.sendToVehicle()
        }
        if (state) {
            state.pendingMissionAvailable = true
        }
        root.takeoffPageRequested()
    }

    function _deleteTask(index) {
        pendingDeleteIndex = index
        confirmAction = "deleteTask"
        confirmDialog.open()
    }

    function _deleteTaskNow(index) {
        var path = _taskPath(index)
        if (path.length > 0 && fileController.fileExists(path)) {
            fileController.deleteFile(path)
        }
        _refreshSavedPlans()
    }

    function _vehicleTaskSavePath() {
        return _saveDir() + "任务_" + Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss") + ".plan"
    }

    function _saveVehicleTaskToLocal() {
        if (!masterController || !vehicleTaskAvailable) {
            return
        }
        var path = _vehicleTaskSavePath()
        var fileName = _fileNameFromPath(path)
        masterController.saveToFile(path)
        _refreshSavedPlans()
        for (var i = 0; i < savedPlans.length; i++) {
            if (String(savedPlans[i]) === fileName) {
                selectedVisibleIndex = i
                break
            }
        }
    }

    function _confirmClearVehicleTask() {
        confirmAction = "clearVehicle"
        confirmDialog.open()
    }

    function _clearVehicleTask() {
        if (masterController && masterController.removeAllFromVehicle) {
            masterController.removeAllFromVehicle()
        } else if (masterController && masterController.removeAll) {
            masterController.removeAll()
        }
    }

    function ensureSelection() {
        if (savedPlans.length === 0) {
            selectedVisibleIndex = -1
            return
        }
        if (selectedVisibleIndex < 0 || selectedVisibleIndex >= savedPlans.length) {
            selectedVisibleIndex = 0
        }
    }

    function selectVisibleIndex(visibleIndex) {
        if (visibleIndex < 0 || visibleIndex >= savedPlans.length) {
            return
        }
        selectedVisibleIndex = visibleIndex
    }

    function openPlanView() {
        if (typeof mainWindow !== "undefined" && mainWindow && mainWindow.showPlanView) {
            mainWindow.showPlanView()
        }
    }

    function openMissionBuilder() {
        if (selectedVisibleIndex >= 0) {
            _loadSelectedTask()
        }
        if (openCustomPlanShell) {
            openCustomPlanShell()
        } else {
            openPlanView()
        }
    }

    function newMission() {
        selectedVisibleIndex = -1
        if (masterController && masterController.removeAll) {
            masterController.removeAll()
        } else if (missionController && missionController.removeAll) {
            missionController.removeAll()
        }
        if (openCustomPlanShell) {
            openCustomPlanShell()
        } else {
            openPlanView()
        }
    }

    Component.onCompleted: _refreshSavedPlans()
    onVisibleChanged: if (visible) _refreshSavedPlans()

    // 背景透明度由外层 FlyViewLeftPanel 统一控制，避免文字/按钮跟着透明。
    color: "transparent"
    implicitHeight: 520

    component SmallButton: Rectangle {
        id: smallButtonRoot
        property string label: ""
        property bool enabledState: true
        property int textPixelSize: theme ? theme.fontMd : 12
        signal clicked

        radius: theme ? theme.radius : 6
        height: theme ? theme.controlHMd : 36
        color: !enabledState
               ? (theme ? theme.surface2 : "#f3f4f6")
               : smallButtonMouse.pressed
                 ? (theme ? theme.blue : "#000066")
                 : smallButtonMouse.containsMouse
                   ? (theme ? theme.blueL : "#E6E6F0")
                   : (theme ? theme.surface2 : "#f8fafc")
        border.width: 1
        border.color: !enabledState
                      ? (theme ? theme.border2 : "#e5e7eb")
                      : (smallButtonMouse.pressed || smallButtonMouse.containsMouse)
                        ? (theme ? theme.blue : "#000066")
                        : (theme ? theme.border : "#d6e1ee")
        opacity: enabledState ? 1 : 0.45
        scale: smallButtonMouse.pressed && enabledState ? 0.98 : 1.0

        Behavior on color { ColorAnimation { duration: 100 } }
        Behavior on border.color { ColorAnimation { duration: 100 } }
        Behavior on scale { NumberAnimation { duration: 80 } }

        Text {
            anchors.centerIn: parent
            text: parent.label
            font.pixelSize: parent.textPixelSize
            font.weight: Font.Medium
            color: !enabledState
                   ? (theme ? theme.text3 : "#9ca3af")
                   : smallButtonMouse.pressed
                     ? "#ffffff"
                     : smallButtonMouse.containsMouse
                       ? (theme ? theme.blue : "#000066")
                       : (theme ? theme.text : "#111827")
        }

        MouseArea {
            id: smallButtonMouse
            anchors.fill: parent
            enabled: parent.enabledState
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: parent.clicked()
        }
    }

    Column {
        id: contentCol
        anchors.fill: parent
        spacing: theme ? theme.spacingXs : 6

        SectionTitle { text: "任务列表"; theme: root.theme }

        Item {
            id: missionListArea
            width: parent.width
            height: savedPlans.length > 0
                    ? Math.min(parent.height - (theme ? theme.sectionH : 44) - (theme ? theme.controlHLg + 6 : 44) - 8,
                               missionListArea.margin * 2 + savedPlanList.implicitHeight + 46)
                    : (root.vehicleTaskAvailable ? (root.narrowMode ? 220 : 210) : 148)

            readonly property real margin: root.narrowMode ? 8 : (theme ? theme.spacingXl : 12)
            readonly property real gap: theme ? theme.spacingSm : 8

            Rectangle {
                id: emptyCard
                visible: savedPlans.length === 0
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: missionListArea.margin
                anchors.rightMargin: missionListArea.margin
                height: root.vehicleTaskAvailable ? (root.narrowMode ? 160 : 150) : 96
                radius: theme ? theme.radiusLg : 10
                color: theme ? theme.surface2 : "#f8fafc"
                border.width: 1
                border.color: theme ? theme.border : "#d7dde6"

                Item {
                    anchors.fill: parent
                    anchors.margins: root.vehicleTaskAvailable ? (root.narrowMode ? 9 : 14) : 0

                    RowLayout {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 6
                        visible: root.vehicleTaskAvailable

                        Rectangle {
                            Layout.preferredWidth: root.narrowMode ? 24 : 30
                            Layout.preferredHeight: root.narrowMode ? 24 : 30
                            radius: (root.narrowMode ? 24 : 30) / 2
                            color: theme ? theme.blueL : "#E6E6F0"

                            Text {
                                anchors.centerIn: parent
                                text: "✈"
                                font.pixelSize: root.narrowMode ? 12 : 14
                                color: theme ? theme.blue : "#000066"
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: "飞控中有任务"
                            font.pixelSize: root.narrowMode ? 13 : (theme ? theme.fontMd : 13)
                            font.weight: Font.Bold
                            color: theme ? theme.text : "#111827"
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !root.vehicleTaskAvailable
                        text: "暂无保存任务"
                        font.pixelSize: theme ? theme.fontMd : 13
                        font.weight: Font.Medium
                        color: theme ? theme.text3 : "#9aa3b2"
                    }

                    Text {
                        id: vehicleTaskHint
                        y: root.vehicleTaskAvailable ? (root.narrowMode ? 34 : 40) : 58
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: emptyCard.width - (root.narrowMode ? 18 : 26)
                        height: root.vehicleTaskAvailable ? (root.narrowMode ? 66 : 48) : implicitHeight
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                        text: root.vehicleTaskAvailable
                              ? "本地任务列表为空，可保存\n飞控任务或清空飞控任务。"
                              : "点击右下角新增"
                        font.pixelSize: root.narrowMode ? 11 : (theme ? theme.fontXs : 10)
                        color: theme ? theme.text3 : "#9aa3b2"
                    }

                    Row {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.vehicleTaskAvailable
                        spacing: root.narrowMode ? 6 : 10

                        SmallButton {
                            width: Math.max(54, Math.min(68, (emptyCard.width - (root.narrowMode ? 34 : 44)) / 2))
                            height: 24
                            label: "保存任务"
                            textPixelSize: root.narrowMode ? 10 : 11
                            enabledState: root.vehicleTaskAvailable
                            onClicked: root._saveVehicleTaskToLocal()
                        }

                        SmallButton {
                            width: Math.max(54, Math.min(68, (emptyCard.width - (root.narrowMode ? 34 : 44)) / 2))
                            height: 24
                            label: "清空飞控"
                            textPixelSize: root.narrowMode ? 10 : 11
                            enabledState: root.vehicleTaskAvailable
                            onClicked: root._confirmClearVehicleTask()
                        }
                    }
                }
            }

            Flickable {
                id: savedPlansFlickable
                anchors.top: parent.top
                anchors.topMargin: missionListArea.margin
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: missionListArea.margin
                anchors.rightMargin: missionListArea.margin
                anchors.bottomMargin: 42
                clip: true
                visible: savedPlans.length > 0
                contentWidth: width
                contentHeight: savedPlanList.implicitHeight
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                Column {
                    id: savedPlanList
                    width: savedPlansFlickable.width
                    spacing: 8

                    Repeater {
                        model: savedPlans.length

                        delegate: Rectangle {
                            id: missionRow
                            property string taskFileName: root._taskFile(index)
                            readonly property bool selected: index === selectedVisibleIndex
                            width: savedPlanList.width
                            height: 62
                            radius: theme ? theme.radiusLg : 8
                            color: selected
                                   ? (missionRowMouse.pressed ? (theme ? theme.blue : "#000066") : (theme ? theme.blueL : "#E6E6F0"))
                                   : missionRowMouse.containsMouse
                                     ? (theme ? theme.blueL : "#eaf2ff")
                                     : (theme ? theme.surface2 : "#f8fafc")
                            border.width: 1
                            border.color: selected ? (theme ? theme.blue : "#000066") : (theme ? theme.border : "#d7dde6")

                            Behavior on color { ColorAnimation { duration: 100 } }

                            MouseArea {
                                id: missionRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectVisibleIndex(index)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 10
                                spacing: theme ? theme.spacingSm : 8
                                z: 1

                                Rectangle {
                                    Layout.preferredWidth: 30
                                    Layout.preferredHeight: 30
                                    radius: 15
                                    color: missionRow.selected
                                           ? (missionRowMouse.pressed ? (theme ? theme.bluePress : "#00004D") : (theme ? theme.blue : "#000066"))
                                           : missionRowMouse.containsMouse
                                             ? (theme ? theme.blueL : "#8080B3")
                                             : (theme ? theme.border : "#cbd5e1")

                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: String(index + 1)
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                        color: missionRow.selected ? "#ffffff" : (missionRowMouse.containsMouse ? (theme ? theme.blue : "#000066") : "#ffffff")
                                    }
                                }

                                Column {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2
                                    clip: true

                                    Text {
                                        width: parent.width
                                        height: 22
                                        verticalAlignment: Text.AlignVCenter
                                        text: root._displayName(missionRow.taskFileName)
                                        font.pixelSize: theme ? theme.fontMd : 12
                                        font.weight: Font.Medium
                                        color: missionRow.selected && missionRowMouse.pressed ? "#ffffff" : (theme ? theme.text : "#1a1d23")
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                        clip: true
                                    }

                                    Text {
                                        width: parent.width
                                        height: 18
                                        verticalAlignment: Text.AlignVCenter
                                        text: missionRow.taskFileName
                                        font.pixelSize: theme ? theme.fontXs : 10
                                        color: missionRow.selected && missionRowMouse.pressed ? "#E6E6F0" : (theme ? theme.text3 : "#9aa3b2")
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                        clip: true
                                    }
                                }

                                Text {
                                    Layout.preferredWidth: 24
                                    Layout.preferredHeight: 24
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: "×"
                                    font.pixelSize: 18
                                    font.weight: Font.Medium
                                    color: deleteMouse.containsMouse ? (theme ? theme.red : "#dc2626") : (theme ? theme.text3 : "#94a3b8")

                                    MouseArea {
                                        id: deleteMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: (mouse) => {
                                            mouse.accepted = true
                                            root._deleteTask(index)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: addMissionButton
                width: 36
                height: 36
                radius: 18
                anchors.right: parent.right
                anchors.rightMargin: missionListArea.margin
                anchors.top: parent.top
                anchors.topMargin: savedPlans.length > 0
                                   ? Math.min(missionListArea.margin + savedPlanList.implicitHeight + 10,
                                              missionListArea.height - height - 6)
                                   : emptyCard.height + (theme ? theme.spacingLg : 10)
                z: 20
                color: addMissionMouse.pressed
                       ? (theme ? theme.bluePress : "#00004D")
                       : addMissionMouse.containsMouse
                         ? (theme ? theme.blue : "#000066")
                         : "#94a3b8"
                border.width: addMissionMouse.containsMouse || addMissionMouse.pressed ? 2 : 0
                border.color: theme ? theme.blueL : "#8080B3"
                scale: addMissionMouse.pressed ? 0.94 : (addMissionMouse.containsMouse ? 1.04 : 1.0)

                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on scale { NumberAnimation { duration: 80 } }

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    font.pixelSize: 22
                    font.weight: Font.Bold
                    color: "#ffffff"
                }

                MouseArea {
                    id: addMissionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.newMission()
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: theme ? theme.border : "#e4e8ed" }

        Row {
            width: parent.width
            height: theme ? theme.controlHLg + 6 : 44

            Rectangle {
                id: executeTaskButton
                width: parent.width / 2
                height: parent.height
                opacity: root.selectedVisibleIndex >= 0 ? 1 : 0.45
                color: executeTaskMouse.pressed
                       ? (theme ? theme.bluePress : "#00004D")
                       : executeTaskMouse.containsMouse
                         ? (theme ? theme.blue : "#000066")
                         : (theme ? theme.surface2 : "#f8fafc")
                border.width: 1
                border.color: executeTaskMouse.containsMouse || executeTaskMouse.pressed ? (theme ? theme.blue : "#000066") : (theme ? theme.border : "#d7dde6")

                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on border.color { ColorAnimation { duration: 100 } }

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        text: "✈"
                        font.pixelSize: 14
                        color: executeTaskMouse.containsMouse || executeTaskMouse.pressed ? "#ffffff" : (theme ? theme.text2 : "#5a6272")
                    }
                    Text {
                        text: "执行任务"
                        font.pixelSize: theme ? theme.fontMd : 12
                        font.weight: Font.Medium
                        color: executeTaskMouse.containsMouse || executeTaskMouse.pressed ? "#ffffff" : (theme ? theme.text2 : "#5a6272")
                    }
                }

                MouseArea {
                    id: executeTaskMouse
                    anchors.fill: parent
                    enabled: root.selectedVisibleIndex >= 0
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root._executeSelectedTask()
                    }
                }
            }

            Rectangle {
                id: editTaskButton
                width: parent.width / 2
                height: parent.height
                opacity: root.selectedVisibleIndex >= 0 ? 1 : 0.45
                color: editTaskMouse.pressed
                       ? (theme ? theme.bluePress : "#00004D")
                       : editTaskMouse.containsMouse
                         ? (theme ? theme.blue : "#000066")
                         : (theme ? theme.surface2 : "#f8fafc")
                border.width: 1
                border.color: editTaskMouse.containsMouse || editTaskMouse.pressed ? (theme ? theme.blue : "#000066") : (theme ? theme.border : "#d7dde6")

                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on border.color { ColorAnimation { duration: 100 } }

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        text: "✎"
                        font.pixelSize: 14
                        color: editTaskMouse.containsMouse || editTaskMouse.pressed ? "#ffffff" : (theme ? theme.text2 : "#5a6272")
                    }
                    Text {
                        text: "编辑"
                        font.pixelSize: theme ? theme.fontMd : 12
                        font.weight: Font.Medium
                        color: editTaskMouse.containsMouse || editTaskMouse.pressed ? "#ffffff" : (theme ? theme.text2 : "#5a6272")
                    }
                }

                MouseArea {
                    id: editTaskMouse
                    anchors.fill: parent
                    enabled: root.selectedVisibleIndex >= 0
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openMissionBuilder()
                }
            }
        }
    }
}
