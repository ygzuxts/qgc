import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

Rectangle {
    id: root

    property var state: null
    property var theme: null
    property var missionController: null
    readonly property bool wantsMapInteractive: planMapHover.hovered

    readonly property var missionItems: missionController ? missionController.visualItems : null
    readonly property int missionCount: missionController ? missionController.missionItemCount : 0
    readonly property int visibleItemCount: missionItems ? Math.max(0, missionItems.count - 1) : 0
    property int currentLayerIndex: 0
    property bool terrainProfileVisible: true

    signal closeRequested()

    function itemAt(visibleIndex) {
        if (!missionItems) {
            return null
        }
        const visualIndex = visibleIndex + 1
        if (visualIndex < 0 || visualIndex >= missionItems.count) {
            return null
        }
        return missionItems.get(visualIndex)
    }

    function itemTitle(item, visibleIndex) {
        if (!item) {
            return "任务项 " + String(visibleIndex + 1)
        }
        const base = item.commandName && item.commandName.length > 0 ? item.commandName : (item.commandDescription && item.commandDescription.length > 0 ? item.commandDescription : "任务项")
        return "SEQ " + item.sequenceNumber + " · " + base
    }

    function itemSubtitle(item) {
        if (!item) {
            return "等待接入 PlanView 底层逻辑"
        }
        const parts = []
        if (item.specifiesCoordinate && item.coordinate && item.coordinate.isValid) {
            parts.push(item.coordinate.latitude.toFixed(5) + ", " + item.coordinate.longitude.toFixed(5))
        }
        if (item.altitude) {
            parts.push("高度 " + Number(item.altitude.value).toFixed(0) + "m")
        }
        return parts.length > 0 ? parts.join("  ") : "可直接复用 MissionController / PlanMasterController"
    }

    color: "transparent"

    Rectangle {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 12
        height: theme ? theme.topBarH + 6 : 58
        radius: theme ? theme.radiusLg : 8
        color: theme ? theme.overlaySurfaceStrong : Qt.rgba(1, 1, 1, 0.94)
        border.width: 1
        border.color: theme ? theme.border : "#e4e8ed"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 10

            Rectangle {
                width: 34
                height: 34
                radius: 9
                color: theme ? theme.blueL : "#E6E6F0"
                border.width: 1
                border.color: theme ? theme.blueBorder : "#8080B3"

                Text {
                    anchors.centerIn: parent
                    text: "✎"
                    font.pixelSize: 16
                    color: theme ? theme.blue : "#000066"
                }
            }

            Column {
                spacing: 2

                Text {
                    text: "任务规划"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: theme ? theme.text : "#1a1d23"
                }

                Text {
                    text: "任务规划"
                    font.pixelSize: 10
                    color: theme ? theme.text3 : "#9aa3b2"
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 96
                height: 32
                radius: 8
                color: theme ? theme.surface2 : "#f8fafc"
                border.width: 1
                border.color: theme ? theme.border : "#e4e8ed"

                Text {
                    anchors.centerIn: parent
                    text: "返回飞行"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: theme ? theme.text2 : "#5a6272"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof mainWindow !== "undefined" && mainWindow && mainWindow.showPlanView) {
                            mainWindow.showPlanView()
                        }
                    }
                }
            }

            Rectangle {
                width: 88
                height: 32
                radius: 8
                color: theme ? theme.blueL : "#E6E6F0"
                border.width: 1
                border.color: theme ? theme.blueBorder : "#8080B3"

                Text {
                    anchors.centerIn: parent
                    text: "返回飞行"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: theme ? theme.blue : "#000066"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }
    }

    Item {
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        Rectangle {
            id: toolRail
            anchors.top: parent.top
            anchors.bottom: bottomDock.top
            anchors.left: parent.left
            anchors.topMargin: 14
            anchors.leftMargin: 14
            anchors.bottomMargin: 14
            width: 0
            radius: 0
            color: "transparent"
            border.width: 0
            clip: false
        }

        Rectangle {
            id: rightPanel
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: bottomDock.top
            anchors.topMargin: 14
            anchors.rightMargin: 14
            anchors.bottomMargin: 14
            width: 328
            radius: 14
            color: theme ? theme.overlaySurface : Qt.rgba(1, 1, 1, 0.88)
            border.width: 1
            border.color: theme ? theme.border : "#e4e8ed"
            clip: true

            WheelHandler {
                target: null
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: function(event) {
                    event.accepted = true
                }
            }

            Flickable {
                anchors.fill: parent
                contentWidth: width
                contentHeight: inspectorColumn.implicitHeight
                clip: true
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                Column {
                    id: inspectorColumn
                    width: parent.width
                    spacing: 0

                    SectionTitle { text: "任务规划"; theme: root.theme }

                    Rectangle { width: parent.width; height: 1; color: theme ? theme.border : "#e4e8ed" }
                    SectionTitle { text: root.currentLayerIndex === 0 ? "航线规划" : (root.currentLayerIndex === 1 ? "电子围栏" : "返航点"); theme: root.theme }

                    Column {
                        x: 12
                        width: parent.width - 24
                        spacing: 8
                        y: 12

                        Repeater {
                            model: root.currentLayerIndex === 0 ? Math.max(visibleItemCount, 3) : 3

                            delegate: Rectangle {
                                property var missionItem: index < visibleItemCount ? root.itemAt(index) : null
                                width: parent.width - 24
                                height: 58
                                radius: 8
                                color: index === 0 ? (theme ? theme.surface3 : "#eef3fb") : (theme ? theme.surface2 : "#f7f8fa")
                                border.width: 1
                                border.color: index === 0 ? (theme ? theme.blueBorder : "#8080B3") : (theme ? theme.border : "#e4e8ed")

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 10

                                    Rectangle {
                                        width: 28
                                        height: 28
                                        radius: 8
                                        color: theme ? theme.blueL : "#E6E6F0"
                                        border.width: 1
                                        border.color: theme ? theme.blueBorder : "#8080B3"

                                        Text {
                                            anchors.centerIn: parent
                                            text: root.currentLayerIndex === 0 ? (missionItem ? String(missionItem.sequenceNumber) : "+") : String(index + 1)
                                            font.pixelSize: 11
                                            font.weight: Font.Bold
                                            color: theme ? theme.blue : "#000066"
                                        }
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 3

                                        Text {
                                            text: root.currentLayerIndex === 0 ? root.itemTitle(missionItem, index) : (root.currentLayerIndex === 1 ? "Fence Segment " + String(index + 1) : "Rally Point " + String(index + 1))
                                            font.pixelSize: 12
                                            font.weight: Font.Medium
                                            color: theme ? theme.text : "#1a1d23"
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: root.currentLayerIndex === 0 ? root.itemSubtitle(missionItem) : (root.currentLayerIndex === 1 ? "编辑围栏边界与安全区域" : "编辑返航点位置")
                                            font.pixelSize: 10
                                            color: theme ? theme.text3 : "#9aa3b2"
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: mapOverlayArea
            anchors.top: parent.top
            anchors.left: toolRail.right
            anchors.right: rightPanel.left
            anchors.bottom: bottomDock.top
            anchors.margins: 14

            HoverHandler {
                id: planMapHover
            }

            Item { anchors.fill: parent }
        }

        Rectangle {
            id: bottomDock
            anchors.left: toolRail.right
            anchors.right: rightPanel.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.bottomMargin: 14
            height: 84
            radius: 14
            color: theme ? theme.overlaySurface : Qt.rgba(1, 1, 1, 0.88)
            border.width: 1
            border.color: theme ? theme.border : "#e4e8ed"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Repeater {
                    model: [
                        { title: "任务", value: "编辑" },
                        { title: "地图", value: "可用" },
                        { title: "连线", value: "正常" },
                        { title: "状态", value: "就绪" }
                    ]

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 54
                        radius: 10
                        color: index === 0 ? (theme ? theme.blueL : "#E6E6F0") : (theme ? theme.surface : "#ffffff")
                        border.width: 1
                        border.color: index === 0 ? (theme ? theme.blueBorder : "#8080B3") : (theme ? theme.border : "#e4e8ed")

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.title
                                font.pixelSize: 10
                                color: index === 0 ? (theme ? theme.blue : "#000066") : (theme ? theme.text3 : "#9aa3b2")
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.value
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: index === 0 ? (theme ? theme.blue : "#000066") : (theme ? theme.text : "#1a1d23")
                            }
                        }
                    }
                }
            }
        }

        Item {
            anchors.left: toolRail.right
            anchors.right: rightPanel.left
            anchors.bottom: bottomDock.top
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.bottomMargin: 10
            height: 0
            visible: false
        }
    }
}
