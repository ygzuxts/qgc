// FlyViewTopBar.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.MultiVehicleManager
import QGroundControl.Palette

Rectangle {
    id: root

    property var state: null
    property var theme: null
    property int currentTab: 0
    property bool flightModePanelVisible: false
    property bool interfaceDisplayExpanded: false
    property bool interfaceDisplaySectionExpanded: true
    property bool themeSelectExpanded: false
    property bool uiSelectExpanded: false
    readonly property real flightModePanelX: leftStatusRow ? leftStatusRow.x : (theme ? theme.spacingXs : 2)
    readonly property real flightModePanelY: root.height + 2
    signal pageSwitchRequested()
    signal settingsRequested()

    signal flightModeButtonClicked()

    readonly property real infoBarOpacity: root.state && root.state.infoBarOpacity !== undefined ? root.state.infoBarOpacity : 0.82
    readonly property color panelBg: root.theme && root.theme.darkMode ? "#000000" : "#ffffff"
    readonly property color panelText: root.theme && root.theme.darkMode ? "#e5edf8" : "#111827"
    readonly property color panelText2: root.theme && root.theme.darkMode ? "#a8b5c7" : "#4b5563"
    readonly property color panelFieldBg: root.theme && root.theme.darkMode ? "#1f2937" : "#e5e5e5"
    readonly property color panelFieldBorder: root.theme && root.theme.darkMode ? "#333333" : "#333333"
    readonly property color panelOuterBorder: root.theme && root.theme.darkMode ? "#4b5563" : "#9bbcf8"
    readonly property color panelSelectBg: root.theme && root.theme.darkMode ? "#111111" : "#f3f3f3"
    readonly property color brandBlue: root.theme ? root.theme.blue : "#000066"
    readonly property color brandHover: root.theme ? root.theme.blueL : "#E6E6F0"
    readonly property color brandPress: root.theme ? root.theme.bluePress : "#00004D"
    readonly property color brandBorder: root.theme ? root.theme.blueBorder : "#8080B3"
    readonly property real interfaceDropdownExtraHeight: 0
    readonly property var activeVehicle: root.state ? root.state.activeVehicle : null
    readonly property bool vehicleConnected: root.state && root.state.vehicleConnected
    readonly property bool communicationLost: !!(root.activeVehicle && root.activeVehicle.vehicleLinkManager && root.activeVehicle.vehicleLinkManager.communicationLost)
    readonly property bool armed: root.state && root.state.armed
    readonly property string armText: vehicleConnected ? (armed ? "已解锁" : "未解锁") : "未连接"
    readonly property string modeText: vehicleConnected && root.state && root.state.flightMode ? root.state.flightMode : "--"
    readonly property color telemetryTextColor: root.theme && root.theme.darkMode ? "#ffffff" : "#111827"
    readonly property string batteryTopText: root.state && root.state.batteryPercentText ? root.state.batteryPercentText : "--"
    readonly property string gpsSatTopText: root.state && root.state.gpsSatellites >= 0 ? root.state.gpsSatellitesText : "--"
    readonly property string gpsHdopTopText: root.state && root.state.gpsHdopText && root.state.gpsHdopText !== "--" ? root.state.gpsHdopText : "--"
    readonly property var flightModeList: root.state && root.state.flightModes ? root.state.flightModes : []

    function statusText() {
        if (!root.state || !root.state.vehicleConnected) return "未连接"
        switch (root.state.mainStatusText) {
        case "Ready": return "可起飞"
        case "Not Ready": return "未就绪"
        case "Flying": return "飞行中"
        case "Landing": return "降落中"
        case "Armed": return "已解锁"
        case "Comms Lost": return "通信丢失"
        default: return root.state.mainStatusText ? root.state.mainStatusText : "未连接"
        }
    }

    function statusColor() {
        if (!root.state || !root.state.vehicleConnected) return "#9aa3b2"
        switch (root.state.mainStatusTone) {
        case "green": return "#16a34a"
        case "red": return "#dc2626"
        case "amber": return "#f59e0b"
        default: return "#9aa3b2"
        }
    }

    function modeDisplayName(modeName) {
        var normalizedModeName = modeName ? String(modeName).trim() : "--"
        switch (normalizedModeName) {
        case "Manual": return "手动Manual"
        case "Stabilized": return "自稳Stabilized"
        case "Acro": return "特技Acro"
        case "Rattitude": return "半自稳Rattitude"
        case "Altitude": return "高度"
        case "Offboard": return "板外Offboard"
        case "Position": return "定点Position"
        case "Hold": return "等待"
        case "Mission": return "任务"
        case "Return": return "返航Return"
        case "Land": return "着陆Land"
        case "Precision Landing": return "精准降落"
        case "Takeoff": return "起飞Takeoff"
        case "VTOL Takeoff": return "垂直起飞"
        default: return modeName && modeName !== "--" ? modeName : "--"
        }
    }

    function disconnectVehicle() {
        if (root.activeVehicle) {
            console.log("[CustomTopBar] disconnect vehicle")
            root.activeVehicle.closeVehicle()
        }
    }

    height: theme ? Math.max(theme.topBarH, 58) : 58
    color: theme ? Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.0) : "transparent"

    Rectangle {
        anchors.fill: parent
        readonly property real bgAlpha: Math.max(0.15, Math.min(1.0, root.infoBarOpacity))
        color: root.theme && root.theme.darkMode ? Qt.rgba(0, 0, 0, bgAlpha) : Qt.rgba(1, 1, 1, bgAlpha)
        opacity: 1
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: root.theme ? root.theme.border : "#e4e8ed"
    }

    Item {
        anchors.fill: parent

        Rectangle {
            id: logoButton
            anchors.left: parent.left
            anchors.leftMargin: theme ? theme.spacingSm : 8
            anchors.verticalCenter: parent.verticalCenter
            width: theme ? Math.max(theme.controlHMd + 10, 54) : 54
            height: width
            radius: theme ? theme.radiusLg + 2 : 10
            color: aircraftMouse.pressed
                   ? root.brandPress
                   : aircraftMouse.containsMouse
                     ? root.brandHover
                     : "#ffffff"
            border.width: 1
            border.color: aircraftMouse.containsMouse || aircraftMouse.pressed
                          ? root.brandBorder
                          : (root.theme ? root.theme.border : "#d9e2ec")

            Image {
                anchors.centerIn: parent
                width: Math.round(parent.width * 0.76)
                height: Math.round(parent.height * 0.76)
                source: "qrc:/brand/topbar-logo.png"
                fillMode: Image.PreserveAspectFit
                mipmap: true
            }

            MouseArea {
                id: aircraftMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.interfaceDisplayExpanded = !root.interfaceDisplayExpanded
            }
        }

        Row {
            id: leftStatusRow
            anchors.left: logoButton.right
            anchors.leftMargin: theme ? theme.spacingMd : 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: theme ? theme.spacingSm : 8

            Rectangle {
                id: flightStatusModePill
                width: theme ? theme.baseWidth * 16.8 : 178
                height: theme ? theme.controlHMd : 32
                radius: height / 2
                color: flightModeMouse.pressed
                       ? root.brandPress
                       : flightModeMouse.containsMouse || root.flightModePanelVisible
                         ? root.brandHover
                         : (root.theme && root.theme.darkMode ? "#000000" : "#ffffff")
                border.width: 1
                border.color: flightModeMouse.containsMouse || flightModeMouse.pressed || root.flightModePanelVisible
                              ? root.brandBorder
                              : (root.theme && root.theme.darkMode ? "#333333" : Qt.rgba(0.83, 0.86, 0.91, 1.0))

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 7

                    Row {
                        width: 68
                        height: parent.height
                        spacing: 4

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.statusColor()
                        }

                        Text {
                            width: parent.width - x - 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.statusText()
                            font.pixelSize: theme ? theme.fontSm : 11
                            font.weight: Font.Medium
                            color: root.statusColor()
                            elide: Text.ElideRight
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.flightModePanelVisible ? "▲" : "▼"
                            font.pixelSize: theme ? theme.fontXs : 9
                            color: root.statusColor()
                        }
                    }

                    Rectangle {
                        width: 1
                        height: 17
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.theme && root.theme.darkMode ? "#333333" : "#d7dde8"
                    }

                    Text {
                        width: 76
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.modeDisplayName(modeText)
                        font.pixelSize: theme ? theme.fontSm : 11
                        font.weight: Font.Bold
                        color: root.panelText
                        elide: Text.ElideRight
                    }

                    Text {
                        id: arrowText
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.flightModePanelVisible ? "▲" : "▼"
                        font.pixelSize: theme ? theme.fontSm : 11
                        color: "#000066"
                    }
                }

                MouseArea {
                    id: flightModeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.flightModeButtonClicked()
                }
            }

            Rectangle {
                id: armStatePill
                width: theme ? theme.baseWidth * 8.2 : 96
                height: theme ? theme.controlHMd : 32
                radius: height / 2
                color: root.theme && root.theme.darkMode ? "#000000" : "#ffffff"
                border.width: 1
                border.color: root.theme && root.theme.darkMode ? "#333333" : Qt.rgba(0.83, 0.86, 0.91, 1.0)

                Row {
                    anchors.centerIn: parent
                    spacing: theme ? theme.spacingSm : 8

                    Rectangle {
                        width: theme ? theme.spacingSm : 6
                        height: width
                        radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: vehicleConnected ? (armed ? "#dc2626" : "#16a34a") : "#9aa3b2"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: armText
                        font.pixelSize: theme ? theme.fontSm : 11
                        font.weight: Font.Medium
                        color: vehicleConnected ? (armed ? "#dc2626" : "#16a34a") : "#9aa3b2"
                    }
                }
            }

            Rectangle {
                id: disconnectPill
                visible: root.activeVehicle && root.communicationLost
                width: 84
                height: theme ? theme.controlHMd : 32
                radius: height / 2
                color: disconnectMouse.pressed
                       ? Qt.rgba(220 / 255, 38 / 255, 38 / 255, 0.16)
                       : (disconnectMouse.containsMouse ? Qt.rgba(220 / 255, 38 / 255, 38 / 255, 0.08) : "transparent")
                border.width: 1
                border.color: "#dc2626"

                Text {
                    anchors.centerIn: parent
                    text: "断开连接"
                    font.pixelSize: theme ? theme.fontSm : 11
                    font.weight: Font.Medium
                    color: "#dc2626"
                }

                MouseArea {
                    id: disconnectMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.disconnectVehicle()
                }
            }
        }

        Row {
            id: centerTelemetryRow
            anchors.left: leftStatusRow.right
            anchors.leftMargin: theme ? theme.spacingXl * 1.4 : 24
            anchors.verticalCenter: parent.verticalCenter
            spacing: 34
            visible: root.vehicleConnected

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 9

                QGCColoredImage {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 42
                    source: "/qmlimages/BatteryGreen.svg"
                    color: "#00c853"
                    fillMode: Image.PreserveAspectFit
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.batteryTopText
                    font.pixelSize: 17
                    font.weight: Font.Medium
                    color: root.telemetryTextColor
                }
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 9

                QGCColoredImage {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    height: 44
                    source: "/qmlimages/Gps.svg"
                    color: root.telemetryTextColor
                    fillMode: Image.PreserveAspectFit
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    Text {
                        text: root.gpsSatTopText
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: root.telemetryTextColor
                    }

                    Text {
                        text: root.gpsHdopTopText
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: root.telemetryTextColor
                        lineHeight: 0.9
                    }
                }
            }
        }

        Row {
            id: rightButtons
            anchors.right: parent.right
            anchors.rightMargin: theme ? theme.spacingSm : 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: theme ? theme.spacingMd : 12

            Rectangle {
                width: theme ? Math.max(theme.controlHMd + 10, 52) : 52
                height: width
                radius: theme ? theme.radiusLg + 2 : 10
                color: moreMouse.pressed
                       ? root.brandPress
                       : moreMouse.containsMouse
                         ? root.brandBlue
                         : (root.theme && root.theme.darkMode ? Qt.rgba(31 / 255, 41 / 255, 55 / 255, 0.78) : "#ffffff")
                border.width: 1
                border.color: moreMouse.containsMouse || moreMouse.pressed
                              ? root.brandBorder
                              : (root.theme && root.theme.darkMode ? Qt.rgba(148 / 255, 163 / 255, 184 / 255, 0.42) : "#d7e2f0")

                Text {
                    anchors.centerIn: parent
                    text: "..."
                    font.pixelSize: theme ? theme.fontLg + 2 : 18
                    font.weight: Font.Bold
                    color: root.theme && root.theme.darkMode ? "#ffffff" : (moreMouse.containsMouse ? "#ffffff" : "#111827")
                }

                MouseArea {
                    id: moreMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.settingsRequested()
                }
            }

            Rectangle {
                width: theme ? Math.max(theme.controlHMd + 10, 52) : 52
                height: width
                radius: theme ? theme.radiusLg + 2 : 10
                color: pageMouse.pressed
                       ? root.brandPress
                       : pageMouse.containsMouse
                         ? root.brandHover
                         : (root.theme && root.theme.darkMode ? Qt.rgba(31 / 255, 41 / 255, 55 / 255, 0.78) : "#ffffff")
                border.width: 1
                border.color: pageMouse.containsMouse || pageMouse.pressed
                              ? root.brandBorder
                              : (root.theme && root.theme.darkMode ? Qt.rgba(148 / 255, 163 / 255, 184 / 255, 0.42) : "#d7e2f0")

                Image {
                    anchors.centerIn: parent
                    width: theme ? theme.iconMd + 6 : 28
                    height: theme ? theme.iconMd + 6 : 28
                    source: "qrc:/brand/topbar-logo.png"
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }

                MouseArea {
                    id: pageMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pageSwitchRequested()
                }
            }
        }
    }

    Popup {
        id: interfaceDisplayPopup
        x: logoButton.x
        y: root.height + 2
        width: 228
        height: root.interfaceDisplaySectionExpanded ? 330 : 48
        padding: 0
        topPadding: 0
        bottomPadding: 0
        leftPadding: 0
        rightPadding: 0
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
        visible: root.interfaceDisplayExpanded && !(root.state && root.state.customFlyViewEnabled === false)
        z: 80

        background: Rectangle {
            radius: 12
            color: root.panelBg
            border.width: 1
            border.color: root.panelOuterBorder
        }

        contentItem: Item {
            width: interfaceDisplayPopup.width
            height: interfaceDisplayPopup.height
            clip: false

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: root.panelBg
                z: 0
            }

            Item {
                id: interfaceDisplayColumn
                width: parent.width
                height: parent.height
                z: 1

                Rectangle {
                    y: 0
                    width: parent.width
                    height: 46
                    radius: 10
                    color: root.panelBg
                    border.width: 0
                    clip: true

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        text: "界面显示"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        color: root.panelText
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.interfaceDisplaySectionExpanded ? "▲" : "▼"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: "#000066"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.interfaceDisplaySectionExpanded = !root.interfaceDisplaySectionExpanded
                    }
                }

                Item {
                    y: 46
                    width: parent.width
                    height: root.interfaceDisplaySectionExpanded ? 284 : 0
                    visible: root.interfaceDisplaySectionExpanded
                    clip: false

                    Column {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        anchors.topMargin: 2
                        anchors.bottomMargin: 10
                        spacing: 8

                        Item {
                            width: parent.width
                            height: 58
                            z: root.themeSelectExpanded ? 80 : 1

                        Text {
                            y: 0
                            text: "主题模式"
                            font.pixelSize: 12
                            color: root.panelText2
                        }

                        Rectangle {
                            id: themeSelectBox
                            y: 22
                            width: parent.width
                            height: 34
                            radius: 2
                            color: root.themeSelectExpanded ? root.panelSelectBg : root.panelFieldBg
                            border.width: 1
                            border.color: root.panelFieldBorder

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.theme && root.theme.darkMode ? "深色主题" : "浅色主题"
                                font.pixelSize: 12
                                color: root.panelText
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: "⌃\n⌄"
                                font.pixelSize: 14
                                lineHeight: 0.62
                                horizontalAlignment: Text.AlignHCenter
                                color: root.panelText
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.themeSelectExpanded = !root.themeSelectExpanded
                                    root.uiSelectExpanded = false
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 68
                            y: themeSelectBox.y + themeSelectBox.height
                            z: 200
                            visible: root.themeSelectExpanded
                            clip: true
                            color: root.panelBg
                            border.width: 1
                            border.color: root.panelFieldBorder

                            Column {
                                anchors.fill: parent

                                Rectangle {
                                    width: parent.width
                                    height: 34
                                    color: root.theme && !root.theme.darkMode ? root.panelSelectBg : root.panelBg

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "浅色主题"
                                        font.pixelSize: 12
                                        font.weight: root.theme && !root.theme.darkMode ? Font.Bold : Font.Normal
                                        color: root.panelText
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.theme) root.theme.darkMode = false
                                            if (QGroundControl.settingsManager && QGroundControl.settingsManager.appSettings && QGroundControl.settingsManager.appSettings.indoorPalette) {
                                                QGroundControl.settingsManager.appSettings.indoorPalette.rawValue = 0
                                            }
                                            root.themeSelectExpanded = false
                                        }
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 34
                                    color: root.theme && root.theme.darkMode ? root.panelSelectBg : root.panelBg

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "深色主题"
                                        font.pixelSize: 12
                                        font.weight: root.theme && root.theme.darkMode ? Font.Bold : Font.Normal
                                        color: root.panelText
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.theme) root.theme.darkMode = true
                                            if (QGroundControl.settingsManager && QGroundControl.settingsManager.appSettings && QGroundControl.settingsManager.appSettings.indoorPalette) {
                                                QGroundControl.settingsManager.appSettings.indoorPalette.rawValue = 1
                                            }
                                            root.themeSelectExpanded = false
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                z: 100
                                color: "transparent"
                                border.width: 1
                                border.color: root.panelFieldBorder
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 58
                        z: root.uiSelectExpanded ? 80 : 1

                        Text {
                            y: 0
                            text: "界面模式"
                            font.pixelSize: 12
                            color: root.panelText2
                        }

                        Rectangle {
                            id: uiSelectBox
                            y: 22
                            width: parent.width
                            height: 34
                            radius: 2
                            color: root.uiSelectExpanded ? root.panelSelectBg : root.panelFieldBg
                            border.width: 1
                            border.color: root.panelFieldBorder

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.state && root.state.customFlyViewEnabled === false ? "原版界面" : "自定义界面"
                                font.pixelSize: 12
                                color: root.panelText
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: "⌃\n⌄"
                                font.pixelSize: 14
                                lineHeight: 0.62
                                horizontalAlignment: Text.AlignHCenter
                                color: root.panelText
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.uiSelectExpanded = !root.uiSelectExpanded
                                    root.themeSelectExpanded = false
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 68
                            y: uiSelectBox.y + uiSelectBox.height
                            z: 200
                            visible: root.uiSelectExpanded
                            clip: true
                            color: root.panelBg
                            border.width: 1
                            border.color: root.panelFieldBorder

                            Column {
                                anchors.fill: parent

                                Rectangle {
                                    width: parent.width
                                    height: 34
                                    color: root.state && root.state.customFlyViewEnabled !== false ? root.panelSelectBg : root.panelBg

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "自定义界面"
                                        font.pixelSize: 12
                                        font.weight: root.state && root.state.customFlyViewEnabled !== false ? Font.Bold : Font.Normal
                                        color: root.panelText
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.state && root.state.setCustomFlyViewEnabled) root.state.setCustomFlyViewEnabled(true)
                                            root.uiSelectExpanded = false
                                        }
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 34
                                    color: root.state && root.state.customFlyViewEnabled === false ? root.panelSelectBg : root.panelBg

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "原版界面"
                                        font.pixelSize: 12
                                        font.weight: root.state && root.state.customFlyViewEnabled === false ? Font.Bold : Font.Normal
                                        color: root.panelText
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.state && root.state.setCustomFlyViewEnabled) root.state.setCustomFlyViewEnabled(false)
                                            root.uiSelectExpanded = false
                                            root.interfaceDisplayExpanded = false
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                z: 100
                                color: "transparent"
                                border.width: 1
                                border.color: root.panelFieldBorder
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 0
                        visible: false

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "底部展开栏"
                            font.pixelSize: 12
                            color: root.panelText2
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 42
                            height: 22
                            radius: 11
                            color: root.state && root.state.showHudExpandBar ? "#000066" : (root.theme && root.theme.darkMode ? "#333333" : "#e5e7eb")
                            border.width: 0

                            Rectangle {
                                x: root.state && root.state.showHudExpandBar ? parent.width - width - 2 : 2
                                y: 2
                                width: 18
                                height: 18
                                radius: 9
                                color: "#ffffff"
                                border.width: 1
                                border.color: "#c9d4e6"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.state && root.state.setShowHudExpandBar) {
                                        root.state.setShowHudExpandBar(!(root.state.showHudExpandBar))
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 20

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "侧边栏透明度"
                            font.pixelSize: 12
                            color: root.panelText2
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round((root.state && root.state.sidePanelOpacity !== undefined ? root.state.sidePanelOpacity : 0.92) * 100) + "%"
                            font.pixelSize: 12
                            color: root.brandBlue
                        }
                    }

                    Slider {
                        width: parent.width
                        height: 30
                        from: 0
                        to: 1
                        stepSize: 0.01
                        value: root.state && root.state.sidePanelOpacity !== undefined ? root.state.sidePanelOpacity : 0.92
                        onMoved: if (root.state && root.state.setSidePanelOpacityValue) root.state.setSidePanelOpacityValue(value)
                        onPressedChanged: if (!pressed && root.state && root.state.setSidePanelOpacityValue) root.state.setSidePanelOpacityValue(value)
                        background: Rectangle {
                            x: parent.leftPadding
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            width: parent.availableWidth
                            height: 4
                            radius: 2
                            color: root.theme && root.theme.darkMode ? "#333333" : "#e5e7eb"

                            Rectangle {
                                width: parent.parent.visualPosition * parent.width
                                height: parent.height
                                radius: 2
                                color: root.theme && root.theme.darkMode ? "#ffffff" : "#333333"
                            }
                        }
                        handle: Rectangle {
                            x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            width: 16
                            height: 16
                            radius: 8
                            color: "#ffffff"
                            border.width: 1
                            border.color: "#c4c4c4"
                        }
                    }

                    Item {
                        width: parent.width
                        height: 20

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "信息栏透明度"
                            font.pixelSize: 12
                            color: root.panelText2
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round((root.state && root.state.infoBarOpacity !== undefined ? root.state.infoBarOpacity : 0.82) * 100) + "%"
                            font.pixelSize: 12
                            color: "#000066"
                        }
                    }

                    Slider {
                        width: parent.width
                        height: 30
                        from: 0
                        to: 1
                        stepSize: 0.01
                        value: root.state && root.state.infoBarOpacity !== undefined ? root.state.infoBarOpacity : 0.82
                        onMoved: if (root.state && root.state.setInfoBarOpacityValue) root.state.setInfoBarOpacityValue(value)
                        onPressedChanged: if (!pressed && root.state && root.state.setInfoBarOpacityValue) root.state.setInfoBarOpacityValue(value)
                        background: Rectangle {
                            x: parent.leftPadding
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            width: parent.availableWidth
                            height: 4
                            radius: 2
                            color: root.theme && root.theme.darkMode ? "#333333" : "#e5e7eb"

                            Rectangle {
                                width: parent.parent.visualPosition * parent.width
                                height: parent.height
                                radius: 2
                                color: root.theme && root.theme.darkMode ? "#ffffff" : "#333333"
                            }
                        }
                        handle: Rectangle {
                            x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            width: 16
                            height: 16
                            radius: 8
                            color: "#ffffff"
                            border.width: 1
                            border.color: "#c4c4c4"
                        }
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: 12
                color: "transparent"
                border.width: 2
                border.color: root.panelOuterBorder
                z: 999
            }
        }
        }

        onVisibleChanged: {
            if (!visible) {
                root.interfaceDisplayExpanded = false
                root.themeSelectExpanded = false
                root.uiSelectExpanded = false
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interfaceDisplayExpanded || root.flightModePanelVisible
        z: 39
        onClicked: {
            root.interfaceDisplayExpanded = false
            root.flightModePanelVisible = false
            root.themeSelectExpanded = false
            root.uiSelectExpanded = false
        }
    }

    /*
    Popup {
        id: flightModePopup
                                height: 34
                                color: root.theme && !root.theme.darkMode ? "#f3f3f3" : "#ffffff"

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "浅色主题"
                                    font.pixelSize: 12
                                    font.weight: root.theme && !root.theme.darkMode ? Font.Bold : Font.Normal
                                    color: "#111827"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.theme) root.theme.darkMode = false
                                        root.themeSelectExpanded = false
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 34
                                color: root.theme && root.theme.darkMode ? "#f3f3f3" : "#ffffff"

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "深色主题"
                                    font.pixelSize: 12
                                    font.weight: root.theme && root.theme.darkMode ? Font.Bold : Font.Normal
                                    color: "#111827"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.theme) root.theme.darkMode = true
                                        root.themeSelectExpanded = false
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 4

                        Text {
                            text: "界面模式"
                            font.pixelSize: 12
                            color: "#4b5563"
                        }

                        Rectangle {
                            width: parent.width
                            height: 34
                            radius: 2
                            color: root.uiSelectExpanded ? "#d3d3d3" : "#e7e7e7"
                            border.width: 0

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.state && root.state.customFlyViewEnabled === false ? "原版界面" : "自定义界面"
                                font.pixelSize: 12
                                color: "#111827"
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.uiSelectExpanded ? "⌃" : "⌄"
                                font.pixelSize: 20
                                color: "#333333"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.uiSelectExpanded = !root.uiSelectExpanded
                                    root.themeSelectExpanded = false
                                }
                            }
                        }

                        Column {
                            width: parent.width
                            visible: root.uiSelectExpanded
                            height: root.uiSelectExpanded ? 68 : 0
                            clip: true

                            Rectangle {
                                width: parent.width
                                height: 34
                                color: root.state && root.state.customFlyViewEnabled !== false ? "#f3f3f3" : "#ffffff"

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "自定义界面"
                                    font.pixelSize: 12
                                    font.weight: root.state && root.state.customFlyViewEnabled !== false ? Font.Bold : Font.Normal
                                    color: "#111827"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.state && root.state.setCustomFlyViewEnabled) root.state.setCustomFlyViewEnabled(true)
                                        root.uiSelectExpanded = false
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 34
                                color: root.state && root.state.customFlyViewEnabled === false ? "#f3f3f3" : "#ffffff"

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "原版界面"
                                    font.pixelSize: 12
                                    font.weight: root.state && root.state.customFlyViewEnabled === false ? Font.Bold : Font.Normal
                                    color: "#111827"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.state && root.state.setCustomFlyViewEnabled) root.state.setCustomFlyViewEnabled(false)
                                        root.uiSelectExpanded = false
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 34

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "底部展开栏"
                            font.pixelSize: 12
                            color: "#4b5563"
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 42
                            height: 22
                            radius: 11
                            color: root.state && root.state.showHudExpandBar ? "#000066" : "#e5e7eb"
                            border.width: 0

                            Rectangle {
                                x: root.state && root.state.showHudExpandBar ? parent.width - width - 2 : 2
                                y: 2
                                width: 18
                                height: 18
                                radius: 9
                                color: "#ffffff"
                                border.width: 1
                                border.color: "#c9d4e6"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.state && root.state.setShowHudExpandBar) {
                                        root.state.setShowHudExpandBar(!(root.state.showHudExpandBar))
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 20

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "侧边栏透明度"
                            font.pixelSize: 12
                            color: "#4b5563"
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round((root.state && root.state.sidePanelOpacity !== undefined ? root.state.sidePanelOpacity : 0.92) * 100) + "%"
                            font.pixelSize: 12
                            color: "#000066"
                        }
                    }

                    Slider {
                        width: parent.width
                        height: 36
                        from: 0
                        to: 1
                        stepSize: 0.01
                        value: root.state && root.state.sidePanelOpacity !== undefined ? root.state.sidePanelOpacity : 0.92
                        onMoved: if (root.state && root.state.setSidePanelOpacityValue) root.state.setSidePanelOpacityValue(value)
                        onPressedChanged: if (!pressed && root.state && root.state.setSidePanelOpacityValue) root.state.setSidePanelOpacityValue(value)
                    }

                    Item {
                        width: parent.width
                        height: 20

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "信息栏透明度"
                            font.pixelSize: 12
                            color: "#4b5563"
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round((root.state && root.state.infoBarOpacity !== undefined ? root.state.infoBarOpacity : 0.82) * 100) + "%"
                            font.pixelSize: 12
                            color: "#000066"
                        }
                    }

                    Slider {
                        width: parent.width
                        height: 36
                        from: 0
                        to: 1
                        stepSize: 0.01
                        value: root.state && root.state.infoBarOpacity !== undefined ? root.state.infoBarOpacity : 0.82
                        onMoved: if (root.state && root.state.setInfoBarOpacityValue) root.state.setInfoBarOpacityValue(value)
                        onPressedChanged: if (!pressed && root.state && root.state.setInfoBarOpacityValue) root.state.setInfoBarOpacityValue(value)
                    }
                }
            }
        }

        onVisibleChanged: {
            if (!visible) {
                root.interfaceDisplayExpanded = false
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interfaceDisplayExpanded || root.flightModePanelVisible
        z: 39
        onClicked: {
            root.interfaceDisplayExpanded = false
            root.flightModePanelVisible = false
        }
    }

    */
    Popup {
        id: flightModePopup
        x: modeButton.x + leftStatusRow.x
        y: root.height + 2
        width: 218
        height: Math.min(620, 116 + Math.max(1, root.flightModeList.length) * 48)
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
        visible: false
        z: 85

        background: Rectangle {
            radius: 8
            color: "#ffffff"
            border.width: 1
            border.color: "#8fb3f5"
        }

        contentItem: Item {
            width: parent.width

            Text {
                id: flightModeTitle
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.top: parent.top
                anchors.topMargin: 12
                text: "飞行模式"
                font.pixelSize: 18
                font.weight: Font.Bold
                color: "#111111"
            }

            Text {
                id: flightModeSummary
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.top: flightModeTitle.bottom
                anchors.topMargin: 8
                text: root.state && root.state.vehicleConnected
                        ? ("Disconnected · 当前 " + root.modeDisplayName(modeText) + "\nmodes: " + root.flightModeList.length)
                        : "Disconnected · 当前 --\nmodes: 0"
                font.pixelSize: 12
                color: "#32507a"
                wrapMode: Text.WordWrap
            }

            Rectangle {
                id: modeDivider
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.top: flightModeSummary.bottom
                anchors.topMargin: 10
                width: parent.width
                height: 1
                color: "#d8e2ef"
            }

            Flickable {
                id: modeListFlick
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.top: modeDivider.bottom
                anchors.topMargin: 8
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 8
                contentHeight: modeListColumn.height
                clip: true

                Column {
                    id: modeListColumn
                    width: modeListFlick.width
                    spacing: 7

                    Repeater {
                        model: root.flightModeList

                        Rectangle {
                            required property string modelData

                            width: modeListColumn.width
                            height: 42
                            radius: 7
                            color: modelData === modeText
                                   ? root.brandHover
                                   : (modeMouse.containsMouse ? root.brandHover : "#f5f6f8")
                            border.width: modelData === modeText ? 1 : 0
                            border.color: root.brandBorder

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.modeDisplayName(modelData)
                                font.pixelSize: 13
                                font.weight: modelData === modeText ? Font.Bold : Font.Normal
                                color: "#172033"
                            }

                            MouseArea {
                                id: modeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.state && root.state.setFlightMode) {
                                        root.state.setFlightMode(modelData)
                                    }
                                    root.flightModePanelVisible = false
                                }
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        height: root.flightModeList.length === 0 ? 40 : 0
                        visible: root.flightModeList.length === 0
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "未连接，暂无可用模式"
                        font.pixelSize: 12
                        color: "#24415f"
                    }
                }
            }
        }
    }
}
