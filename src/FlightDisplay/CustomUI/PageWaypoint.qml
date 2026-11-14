// PageWaypoint.qml 航点规划页面
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtPositioning
import QGroundControl.Controls
import QGroundControl.FactControls

Rectangle {
    id: root

    property var state: null
    property var theme: null
    readonly property bool compactMode: width < 320

    readonly property var missionController: state ? state.missionController : null
    readonly property var missionItems: missionController ? missionController.visualItems : null
    readonly property int visibleItemCount: missionItems ? Math.max(0, missionItems.count - 1) : 0
    readonly property bool hasSelection: selectedVisualIndex >= 1 && missionItems && selectedVisualIndex < missionItems.count
    readonly property var selectedItem: hasSelection ? missionItems.get(selectedVisualIndex) : null
    readonly property int currentPlanViewVIIndex: missionController ? missionController.currentPlanViewVIIndex : -1

    property int selectedVisualIndex: -1
    property var stats: ({ distance: 0, time: 0, maxAlt: 0, minAlt: 0, avgSpd: 0 })

    function visualIndexFromVisible(visibleIndex) {
        return visibleIndex + 1
    }

    function selectedVisibleIndex() {
        return hasSelection ? selectedVisualIndex - 1 : -1
    }

    function itemAtVisibleIndex(visibleIndex) {
        if (!missionItems) {
            return null
        }
        const visualIndex = visualIndexFromVisible(visibleIndex)
        if (visualIndex < 1 || visualIndex >= missionItems.count) {
            return null
        }
        return missionItems.get(visualIndex)
    }

    function itemName(item, visibleIndex) {
        if (!item) {
            return "SEQ " + String(visibleIndex + 1)
        }
        return "SEQ " + item.sequenceNumber
    }

    function itemAltitude(item) {
        if (!item || !item.altitude) {
            return 0
        }
        return Number(item.altitude.value)
    }

    function itemSpeed(item) {
        if (!item || item.specifiedFlightSpeed !== item.specifiedFlightSpeed) {
            return 0
        }
        return Number(item.specifiedFlightSpeed)
    }

    function itemAction(item) {
        if (!item) {
            return qsTr("None")
        }
        return item.commandDescription && item.commandDescription.length > 0 ? item.commandDescription : item.commandName
    }

    function ensureSelection() {
        if (!missionItems || missionItems.count <= 1) {
            selectedVisualIndex = -1
            return
        }
        if (currentPlanViewVIIndex >= 1 && currentPlanViewVIIndex < missionItems.count) {
            selectedVisualIndex = currentPlanViewVIIndex
            return
        }
        if (selectedVisualIndex < 1 || selectedVisualIndex >= missionItems.count) {
            selectedVisualIndex = 1
        }
    }

    function baseCoordinateForInsert() {
        if (selectedItem && selectedItem.specifiesCoordinate && selectedItem.coordinate && selectedItem.coordinate.isValid) {
            return selectedItem.coordinate
        }
        if (missionController && missionController.plannedHomePosition && missionController.plannedHomePosition.isValid) {
            return missionController.plannedHomePosition
        }
        if (state && state.activeVehicle && state.activeVehicle.coordinate && state.activeVehicle.coordinate.isValid) {
            return state.activeVehicle.coordinate
        }
        return QtPositioning.coordinate(0, 0, 0)
    }

    function cloneCoordinate(source) {
        if (!source || !source.isValid) {
            return QtPositioning.coordinate(0, 0, 0)
        }
        return QtPositioning.coordinate(source.latitude, source.longitude, source.altitude)
    }

    function _setCurrentVisualIndex(visualIndex, force) {
        if (!missionController || !missionItems || visualIndex < 1 || visualIndex >= missionItems.count) {
            return
        }
        const item = missionItems.get(visualIndex)
        if (!item) {
            return
        }
        selectedVisualIndex = visualIndex
        missionController.setCurrentPlanViewSeqNum(item.sequenceNumber, force === undefined ? false : force)
    }

    function addWaypoint(copyFromSelection) {
        if (!missionController) {
            return
        }
        const sourceItem = selectedItem
        const sourceVisualIndex = selectedVisualIndex
        const insertIndex = hasSelection ? sourceVisualIndex + 1 : -1
        const coordinate = cloneCoordinate(baseCoordinateForInsert())
        const newItem = missionController.insertSimpleMissionItem(coordinate, insertIndex, true)
        if (!newItem) {
            return
        }
        if (copyFromSelection && sourceItem) {
            if (sourceItem.altitude && newItem.altitude) {
                newItem.altitude.value = sourceItem.altitude.value
            }
            if (sourceItem.specifiesCoordinate && newItem.specifiesCoordinate && sourceItem.coordinate && sourceItem.coordinate.isValid) {
                newItem.coordinate = cloneCoordinate(sourceItem.coordinate)
            }
        }
        const newVisualIndex = insertIndex >= 0 ? insertIndex : Math.max(1, missionItems.count - 1)
        _setCurrentVisualIndex(newVisualIndex, true)
        refreshStats()
    }

    function addTakeoff() {
        if (!missionController || !missionController.isInsertTakeoffValid) {
            return
        }
        const insertIndex = hasSelection ? selectedVisualIndex + 1 : -1
        const newItem = missionController.insertTakeoffItem(cloneCoordinate(baseCoordinateForInsert()), insertIndex, true)
        if (newItem) {
            _setCurrentVisualIndex(insertIndex >= 0 ? insertIndex : missionItems.count - 1, true)
            refreshStats()
        }
    }

    function addLand() {
        if (!missionController || !missionController.isInsertLandValid) {
            return
        }
        const insertIndex = hasSelection ? selectedVisualIndex + 1 : -1
        const newItem = missionController.insertLandItem(cloneCoordinate(baseCoordinateForInsert()), insertIndex, true)
        if (newItem) {
            _setCurrentVisualIndex(insertIndex >= 0 ? insertIndex : missionItems.count - 1, true)
            refreshStats()
        }
    }

    function removeWaypoint() {
        if (!hasSelection || !missionController) {
            return
        }
        const removeIndex = selectedVisualIndex
        missionController.removeVisualItem(removeIndex)
        if (!missionItems || missionItems.count <= 1) {
            selectedVisualIndex = -1
        } else {
            selectedVisualIndex = Math.min(removeIndex, missionItems.count - 1)
            if (selectedVisualIndex < 1) {
                selectedVisualIndex = 1
            }
            _setCurrentVisualIndex(selectedVisualIndex, true)
        }
        refreshStats()
    }

    function refreshStats() {
        if (!missionItems || missionItems.count <= 1) {
            stats = { distance: 0, time: 0, maxAlt: 0, minAlt: 0, avgSpd: 0 }
            return
        }

        let maxAlt = 0
        let minAlt = 0
        let speedSum = 0
        let speedCount = 0

        for (let i = 1; i < missionItems.count; i++) {
            const item = missionItems.get(i)
            const alt = itemAltitude(item)
            if (i === 1) {
                maxAlt = alt
                minAlt = alt
            } else {
                maxAlt = Math.max(maxAlt, alt)
                minAlt = Math.min(minAlt, alt)
            }
            const speed = itemSpeed(item)
            if (speed > 0) {
                speedSum += speed
                speedCount++
            }
        }

        stats = {
            distance: missionController ? Number(missionController.missionTotalDistance) : 0,
            time: missionController ? Number(missionController.missionTime) / 60 : 0,
            maxAlt: maxAlt,
            minAlt: minAlt,
            avgSpd: speedCount > 0 ? speedSum / speedCount : 0
        }
    }

    function statLabel(index) {
        switch (index) {
        case 0: return qsTr("Leg Distance")
        case 1: return qsTr("Estimated Time")
        case 2: return qsTr("Maximum Altitude")
        case 3: return qsTr("Minimum Altitude")
        case 4: return qsTr("Average Speed")
        default: return qsTr("Waypoint Count")
        }
    }

    function statValue(index) {
        switch (index) {
        case 0: return stats.distance.toFixed(0) + " m"
        case 1: return stats.time.toFixed(1) + " min"
        case 2: return stats.maxAlt.toFixed(0) + " m"
        case 3: return stats.minAlt.toFixed(0) + " m"
        case 4: return stats.avgSpd > 0 ? stats.avgSpd.toFixed(1) + " m/s" : "--"
        default: return visibleItemCount
        }
    }

    color: theme ? theme.surface : "#fff"
    clip: true
    implicitHeight: contentCol.implicitHeight

    Component.onCompleted: {
        ensureSelection()
        refreshStats()
    }

    Connections {
        target: missionItems

        function onCountChanged() {
            ensureSelection()
            refreshStats()
        }
    }

    Connections {
        target: missionController

        function onCurrentPlanViewSeqNumChanged() {
            ensureSelection()
        }
    }

    Connections {
        target: missionController

        function onMissionTotalDistanceChanged() {
            refreshStats()
        }

        function onMissionTimeChanged() {
            refreshStats()
        }
    }

    component ActionButton: Rectangle {
        property string label: ""
        property bool buttonEnabled: true
        signal clicked

        radius: theme ? theme.radius : 6
        height: theme ? theme.controlHSm : 30
        color: buttonEnabled ? (theme ? theme.blueL : "#E6E6F0") : (theme ? theme.surface2 : "#eef2f7")
        border.width: 1
        border.color: buttonEnabled ? (theme ? theme.blueBorder : "#8080B3") : (theme ? theme.border : "#d7dde6")
        opacity: buttonEnabled ? 1 : 0.55

        Text {
            anchors.centerIn: parent
            text: parent.label
            font.pixelSize: theme ? theme.fontSm : 11
            font.weight: Font.Medium
            color: theme ? theme.blue : "#000066"
        }

        MouseArea {
            anchors.fill: parent
            enabled: parent.buttonEnabled
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: parent.clicked()
        }
    }

    component MiniActionButton: Rectangle {
        property string label: ""
        property bool buttonEnabled: true
        signal clicked

        width: theme ? theme.iconMd + theme.spacingXs : 28
        height: theme ? theme.controlHSm - theme.spacingXs : 22
        radius: theme ? theme.radius : 6
        color: buttonEnabled ? (theme ? theme.blueL : "#E6E6F0") : (theme ? theme.surface2 : "#eef2f7")
        border.width: 1
        border.color: buttonEnabled ? (theme ? theme.blueBorder : "#8080B3") : (theme ? theme.border : "#d7dde6")
        opacity: buttonEnabled ? 1 : 0.55

        Text {
            anchors.centerIn: parent
            text: parent.label
            font.pixelSize: theme ? theme.fontSm : 11
            font.weight: Font.Bold
            color: theme ? theme.blue : "#000066"
        }

        MouseArea {
            anchors.fill: parent
            enabled: parent.buttonEnabled
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: parent.clicked()
        }
    }

    Column {
        id: contentCol
        anchors.fill: parent
        anchors.margins: 0

        SectionTitle { text: qsTr("Waypoint List"); theme: root.theme }

        Column {
            width: parent.width
            padding: theme ? theme.spacingXl : 12
            spacing: theme ? theme.spacingSm : 8

            Text {
                width: parent.width - ((theme ? theme.spacingXl : 12) * 2)
                text: qsTr("Total: ") + visibleItemCount + qsTr(" mission items")
                font.pixelSize: theme ? theme.fontMd : 12
                color: theme ? theme.text2 : "#4b5563"
            }

            GridLayout {
                width: parent.width - ((theme ? theme.spacingXl : 12) * 2)
                columns: root.compactMode ? 1 : 3
                columnSpacing: theme ? theme.spacingSm : 8
                rowSpacing: theme ? theme.spacingSm : 8

                ActionButton {
                    label: qsTr("Add")
                    buttonEnabled: !!missionController
                    Layout.fillWidth: true
                    onClicked: addWaypoint(false)
                }

                ActionButton {
                    label: qsTr("Duplicate")
                    buttonEnabled: hasSelection
                    Layout.fillWidth: true
                    onClicked: addWaypoint(true)
                }

                ActionButton {
                    label: qsTr("Delete")
                    buttonEnabled: hasSelection
                    Layout.fillWidth: true
                    onClicked: removeWaypoint()
                }

                ActionButton {
                    label: qsTr("Takeoff Point")
                    buttonEnabled: missionController ? missionController.isInsertTakeoffValid : false
                    Layout.fillWidth: true
                    onClicked: addTakeoff()
                }

                ActionButton {
                    label: qsTr("Landing Point")
                    buttonEnabled: missionController ? missionController.isInsertLandValid : false
                    Layout.fillWidth: true
                    onClicked: addLand()
                }
            }

            Rectangle {
                width: parent.width - ((theme ? theme.spacingXl : 12) * 2)
                height: theme ? theme.baseFont * 21.5 : 280
                radius: theme ? theme.radiusLg : 8
                border.width: 1
                border.color: theme ? theme.border : "#e4e8ed"
                color: theme ? theme.surface2 : "#f8fafc"

                ListView {
                    id: listView
                    anchors.fill: parent
                    anchors.margins: theme ? theme.spacingXs : 4
                    model: visibleItemCount
                    clip: true

                    delegate: Rectangle {
                        id: cell
                        property var missionItem: root.itemAtVisibleIndex(index)

                        width: listView.width - ((theme ? theme.spacingXs : 4) * 2)
                        height: theme ? theme.cardHSm : 54
                        radius: theme ? theme.radius : 6
                        color: root.visualIndexFromVisible(index) === selectedVisualIndex
                             ? (theme ? theme.blueL : "#E6E6F0")
                             : (theme ? theme.surface : "#fff")
                        border.width: 1
                        border.color: root.visualIndexFromVisible(index) === selectedVisualIndex
                                    ? (theme ? theme.blue : "#000066")
                                    : (theme ? theme.border : "#e4e8ed")

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: theme ? theme.spacingMd : 10
                            spacing: theme ? theme.spacingSm : 8

                            Text {
                                text: root.itemName(cell.missionItem, index)
                                font.pixelSize: theme ? theme.fontMd : 13
                                font.weight: Font.Medium
                                Layout.preferredWidth: root.compactMode
                                                       ? (theme ? theme.baseWidth * 5.5 : 58)
                                                       : (theme ? theme.baseWidth * 6.2 : 66)
                                color: theme ? theme.text : "#1f2937"
                            }

                            Text {
                                text: root.itemAltitude(cell.missionItem).toFixed(0) + " m"
                                font.pixelSize: theme ? theme.fontSm : 11
                                Layout.preferredWidth: root.compactMode
                                                       ? (theme ? theme.baseWidth * 4.5 : 48)
                                                       : (theme ? theme.baseWidth * 5.2 : 56)
                                color: theme ? theme.text2 : "#4b5563"
                            }

                            Text {
                                text: root.itemSpeed(cell.missionItem) > 0 ? root.itemSpeed(cell.missionItem).toFixed(1) + " m/s" : "--"
                                font.pixelSize: theme ? theme.fontSm : 11
                                Layout.preferredWidth: root.compactMode
                                                       ? (theme ? theme.baseWidth * 4.8 : 52)
                                                       : (theme ? theme.baseWidth * 5.9 : 64)
                                color: theme ? theme.text2 : "#4b5563"
                            }

                            Text {
                                text: root.itemAction(cell.missionItem)
                                Layout.fillWidth: true
                                font.pixelSize: theme ? theme.fontSm : 11
                                elide: Text.ElideRight
                                color: theme ? theme.text3 : "#9ca3af"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root._setCurrentVisualIndex(root.visualIndexFromVisible(index), false)
                        }
                    }
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: theme ? theme.border : "#e4e8ed" }
        SectionTitle { text: qsTr("Waypoint Details"); theme: root.theme }

        Column {
            width: parent.width
            padding: theme ? theme.spacingXl : 12
            spacing: theme ? theme.spacingSm : 8

            Loader {
                width: parent.width - ((theme ? theme.spacingXl : 12) * 2)
                active: hasSelection

                sourceComponent: MissionItemEditor {
                    width: root.width - ((theme ? theme.spacingXl : 12) * 2)
                    map: null
                    masterController: root.missionController ? root.missionController.masterController : null
                    missionItem: root.selectedItem
                    readOnly: false

                    onClicked: root._setCurrentVisualIndex(root.selectedVisualIndex, false)
                    onRemove: root.removeWaypoint()
                }

                onActiveChanged: {
                    if (!active) {
                        selectedVisualIndex = -1
                    }
                }
            }

            Rectangle {
                width: parent.width - ((theme ? theme.spacingXl : 12) * 2)
                height: visible ? (theme ? theme.cardHMd : 64) : 0
                radius: theme ? theme.radiusLg : 8
                color: theme ? theme.surface2 : "#f8fafc"
                border.width: 1
                border.color: theme ? theme.border : "#e4e8ed"
                visible: !hasSelection
                clip: true

                Text {
                    anchors.centerIn: parent
                    text: visibleItemCount > 0 ? qsTr("Select a mission item to view details") : qsTr("No mission items")
                    font.pixelSize: theme ? theme.fontMd : 12
                    color: theme ? theme.text3 : "#94a3b8"
                }
            }

            Rectangle {
                width: parent.width - ((theme ? theme.spacingXl : 12) * 2)
                height: statsContent.implicitHeight + ((theme ? theme.spacingXl : 12) * 2)
                radius: theme ? theme.radiusLg : 8
                color: theme ? theme.surface2 : "#f8fafc"
                border.width: 1
                border.color: theme ? theme.border : "#e4e8ed"

                Column {
                    id: statsContent
                    anchors.fill: parent
                    anchors.margins: theme ? theme.spacingXl : 12
                    spacing: theme ? theme.spacingSm : 6

                    Text {
                        text: qsTr("Route Parameters")
                        font.pixelSize: theme ? theme.fontMd : 13
                        font.weight: Font.Medium
                        color: theme ? theme.text : "#111827"
                    }

                    GridLayout {
                        columns: root.compactMode ? 1 : 2
                        columnSpacing: theme ? theme.spacingXl + theme.spacingXs : 16
                        rowSpacing: theme ? theme.spacingSm : 6

                        Repeater {
                            model: 6

                            delegate: RowLayout {
                                spacing: theme ? theme.spacingSm : 6

                                Text {
                                    text: root.statLabel(index)
                                    font.pixelSize: theme ? theme.fontSm : 11
                                    color: theme ? theme.text2 : "#4b5563"
                                }

                                Text {
                                    text: root.statValue(index)
                                    font.pixelSize: theme ? theme.fontSm : 11
                                    font.weight: Font.Medium
                                    color: theme ? theme.blue : "#000066"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
