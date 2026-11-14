// FlyViewTopBar.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.MultiVehicleManager
import QGroundControl.Palette
import QGroundControl.ScreenTools

Rectangle {
    id: root

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

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
    signal analyzeToolsRequested()

    signal flightModeButtonClicked()
    signal flightModePanelCloseRequested()

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
    readonly property bool compactPopupLayout: root.theme && root.theme.mobile
    readonly property real popupScale: root.compactPopupLayout ? 0.78 : 1.0
    readonly property real popupUnit: (root.theme ? root.theme.uiScale : 1) * root.popupScale
    readonly property real interfacePopupWidth: root.compactPopupLayout ? Math.round(168 * (root.theme ? root.theme.uiScale : 1)) : Math.round(228 * (root.theme ? root.theme.uiScale : 1))
    readonly property real interfacePopupHeaderH: Math.round(46 * root.popupUnit)
    readonly property real interfacePopupBodyH: Math.round(226 * root.popupUnit)
    readonly property var activeVehicle: root.state ? root.state.activeVehicle : null
    readonly property bool vehicleConnected: root.state && root.state.vehicleConnected
    readonly property bool communicationLost: !!(root.activeVehicle && root.activeVehicle.vehicleLinkManager && root.activeVehicle.vehicleLinkManager.communicationLost)
    readonly property bool armed: root.state && root.state.armed
    readonly property string armText: vehicleConnected ? (armed ? qsTr("Armed") : qsTr("Disarmed")) : qsTr("Disconnected")
    readonly property color armColor: vehicleConnected ? (armed ? "#16a34a" : "#dc2626") : "#9aa3b2"
    readonly property string modeText: vehicleConnected && root.state && root.state.flightMode ? root.state.flightMode : "--"
    readonly property var flightModeList: root.state && root.state.flightModes ? root.state.flightModes : []

    function statusText() {
        if (!root.state || !root.state.vehicleConnected) return qsTr("Disconnected")
        switch (root.state.mainStatusText) {
        case "Ready": return qsTr("Ready to Fly")
        case "Not Ready": return qsTr("Not Ready")
        case "Flying": return qsTr("Flying")
        case "Landing": return qsTr("Landing")
        case "Armed": return qsTr("Armed")
        case "Comms Lost": return qsTr("Communication Lost")
        default: return root.state.mainStatusText ? root.state.mainStatusText : qsTr("Disconnected")
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
        case "手动":
        case "Manual": return qsTr("Manual")
        case "自稳":
        case "Stabilized": return qsTr("Stabilized")
        case "特技":
        case "Acro": return qsTr("Acro")
        case "半自稳":
        case "Rattitude": return qsTr("Rattitude")
        case "定高":
        case "Altitude": return qsTr("Altitude Hold")
        case "外部控制":
        case "Offboard": return qsTr("Offboard")
        case "定点":
        case "Position": return qsTr("Position")
        case "悬停":
        case "Hold": return qsTr("Hold")
        case "任务":
        case "Mission": return qsTr("Mission")
        case "返航":
        case "Return": return qsTr("Return")
        case "降落":
        case "Land": return qsTr("Land")
        case "精准降落":
        case "Precision Land":
        case "Precision Landing": return qsTr("Precision Land")
        case "起飞":
        case "Takeoff": return qsTr("Takeoff")
        case "VTOL Takeoff": return qsTr("VTOL Takeoff")
        default: return modeName && modeName !== "--" ? modeName : "--"
        }
    }

    function disconnectVehicle() {
        if (root.activeVehicle) {
            console.log("[CustomTopBar] disconnect vehicle")
            root.activeVehicle.closeVehicle()
        }
    }

    height: 28
    color: theme ? Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.0) : "transparent"

    Rectangle {
        anchors.fill: parent
        readonly property real bgAlpha: Math.max(0.15, Math.min(1.0, root.infoBarOpacity))
        readonly property color surfaceColor: "#102e4d"
        color: Qt.rgba(surfaceColor.r, surfaceColor.g, surfaceColor.b, 1)
        opacity: 1
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.round(1 * (theme ? theme.uiScale : 1))
        color: root.theme ? root.theme.border : "#e4e8ed"
    }

    Rectangle {
        id: connectionProgressTrack

        readonly property real progress: root.activeVehicle ? root.activeVehicle.loadProgress : 0

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Math.max(2, Math.round(root.height * 0.05))
        visible: root.vehicleConnected && root.activeVehicle && !root.activeVehicle.initialConnectComplete
        color: root.theme && root.theme.darkMode ? root.panelFieldBg : "#edf4ff"

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, connectionProgressTrack.progress))
            height: parent.height
            color: root.theme && root.theme.darkMode ? root.panelOuterBorder : root.brandBlue
        }
    }

    Item {
        anchors.fill: parent

        DeadMouseArea {
            anchors.fill: parent
        }

        Rectangle {
            id: logoButton
            anchors.left: parent.left
            anchors.leftMargin: theme ? theme.spacingSm : 8
            anchors.verticalCenter: parent.verticalCenter
            width: theme ? 24 : 54
            height: width
            radius: theme ? theme.radiusLg + 2 : 10
            color: aircraftMouse.pressed
                   ? root.brandPress
                   : aircraftMouse.containsMouse
                     ? root.brandHover
                     : "#ffffff"
            border.width: Math.round(1 * (theme ? theme.uiScale : 1))
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

            Timer {
                id: switchNativeHoldTimer
                interval: 6000
                repeat: false
                onTriggered: {
                    root.interfaceDisplayExpanded = false
                    root.themeSelectExpanded = false
                    root.uiSelectExpanded = false
                    if (root.state && root.state.setCustomFlyViewEnabled) {
                        root.state.setCustomFlyViewEnabled(false)
                    }
                }
            }

            MouseArea {
                id: aircraftMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: switchNativeHoldTimer.restart()
                onReleased: {
                    if (switchNativeHoldTimer.running) {
                        switchNativeHoldTimer.stop()
                        root.interfaceDisplayExpanded = !root.interfaceDisplayExpanded
                    }
                }
                onCanceled: switchNativeHoldTimer.stop()
                onExited: if (pressed) switchNativeHoldTimer.stop()
            }
        }

        Button {
            id: vehicleConfigButton
            anchors.right: rightButtons.left
            anchors.rightMargin: theme ? theme.spacingSm : 8
            anchors.verticalCenter: parent.verticalCenter
            width: logoButton.width
            height: logoButton.height
            hoverEnabled: true
            Accessible.name: qsTr("Vehicle Configuration")
            ToolTip.visible: hovered
            ToolTip.text: qsTr("Vehicle Configuration")

            background: Rectangle {
                radius: root.theme ? root.theme.radiusLg + 2 : 10
                color: vehicleConfigButton.down ? root.brandPress
                     : vehicleConfigButton.hovered ? root.brandHover
                     : root.panelBg
                border.width: 1
                border.color: vehicleConfigButton.hovered || vehicleConfigButton.down
                              ? root.brandBorder : root.panelOuterBorder
            }

            contentItem: QGCColoredImage {
                source: "/qmlimages/Gears.svg"
                color: vehicleConfigButton.down ? "#ffffff" : root.panelText
                fillMode: Image.PreserveAspectFit
                sourceSize.width: Math.round(vehicleConfigButton.width * 0.6)
                sourceSize.height: sourceSize.width
            }
            padding: Math.round(width * 0.2)

            onClicked: {
                root.interfaceDisplayExpanded = false
                root.flightModePanelCloseRequested()
                mainWindow.showVehicleConfig()
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
                width: Math.min(root.width * 0.36, Math.max(theme ? theme.baseWidth * 20.5 : 218, contentRow.implicitWidth + Math.round(22 * (theme ? theme.uiScale : 1))))
                height: 24
                radius: height / 2
                color: flightModeMouse.pressed
                       ? root.brandPress
                       : flightModeMouse.containsMouse || root.flightModePanelVisible
                         ? root.brandHover
                         : (root.theme && root.theme.darkMode ? "#000000" : "#ffffff")
                border.width: Math.round(1 * (theme ? theme.uiScale : 1))
                border.color: flightModeMouse.containsMouse || flightModeMouse.pressed || root.flightModePanelVisible
                              ? root.brandBorder
                              : (root.theme && root.theme.darkMode ? "#333333" : Qt.rgba(0.83, 0.86, 0.91, 1.0))

                Row {
                    id: contentRow
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 7

                    Row {
                        width: statusTextItem.implicitWidth + statusArrowText.implicitWidth + Math.round(18 * (theme ? theme.uiScale : 1))
                        height: parent.height
                        spacing: 4

                        Rectangle {
                            width: Math.round(6 * (theme ? theme.uiScale : 1))
                            height: Math.round(6 * (theme ? theme.uiScale : 1))
                            radius: 3
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.statusColor()
                        }

                        Text {
                            id: statusTextItem
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.statusText()
                            font.pixelSize: theme ? theme.fontSm : 11
                            font.weight: Font.Medium
                            color: root.statusColor()
                        }

                        Text {
                            id: statusArrowText
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.flightModePanelVisible ? "▼" : "▲"
                            font.pixelSize: theme ? theme.fontXs : 9
                            color: root.statusColor()
                        }
                    }

                    Rectangle {
                        width: Math.round(1 * (theme ? theme.uiScale : 1))
                        height: Math.round(17 * (theme ? theme.uiScale : 1))
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.theme && root.theme.darkMode ? "#333333" : "#d7dde8"
                    }

                    Text {
                        width: implicitWidth
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.modeDisplayName(modeText)
                        font.pixelSize: theme ? theme.fontSm : 11
                        font.weight: Font.Bold
                        color: root.panelText
                    }

                    Text {
                        id: arrowText
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.flightModePanelVisible ? "▼" : "▲"
                        font.pixelSize: theme ? theme.fontSm : 11
                        color: root.brandBlue
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
                id: vtolSwitchButton
                visible: !!(root.activeVehicle && root.activeVehicle.vtol && root.activeVehicle.flying)
                width: Math.max(64, vtolSwitchLabel.implicitWidth + 20)
                height: 24
                radius: height / 2
                color: root.panelBg
                border.width: 1
                border.color: root.brandBorder

                Text {
                    id: vtolSwitchLabel
                    anchors.centerIn: parent
                    text: root.activeVehicle && root.activeVehicle.vtolInFwdFlight
                          ? qsTr("Fixed Wing") : qsTr("Multi-Rotor")
                    color: root.brandBlue
                    font.pixelSize: theme ? theme.fontSm : 11
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.flightModePanelCloseRequested()
                        vtolSwitchPopup.open()
                    }
                }
                onVisibleChanged: if (!visible) vtolSwitchPopup.close()

                Popup {
                    id: vtolSwitchPopup
                    y: vtolSwitchButton.height + 8
                    width: Math.round(260 * (root.theme ? root.theme.uiScale : 1))
                    padding: 10
                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                    property var targetVehicle: null
                    property bool targetForward: false
                    onOpened: {
                        targetVehicle = root.activeVehicle
                        targetForward = !targetVehicle.vtolInFwdFlight
                    }
                    onClosed: transitionHold.reset()
                    background: Rectangle {
                        color: root.panelBg
                        radius: 8
                        border.color: root.brandBorder
                    }
                    contentItem: Rectangle {
                        id: transitionHold
                        implicitHeight: Math.round(48 * (root.theme ? root.theme.uiScale : 1))
                        property real progress: 0
                        enabled: !!(vtolSwitchPopup.targetVehicle
                                     && vtolSwitchPopup.targetVehicle === root.activeVehicle
                                     && root.vehicleConnected && !root.communicationLost
                                     && root.activeVehicle.vtol
                                     && root.activeVehicle.flying
                                     && root.activeVehicle.vtolInFwdFlight !== vtolSwitchPopup.targetForward)
                        function reset() {
                            transitionTimer.stop()
                            progress = 0
                        }
                        onEnabledChanged: if (!enabled) reset()
                        radius: 6
                        clip: true
                        color: transitionMouse.pressed ? root.brandHover : root.panelBg
                        opacity: enabled ? 1 : 0.45
                        border.width: 1
                        border.color: root.brandBorder
                        Rectangle {
                            width: parent.width * transitionHold.progress
                            height: parent.height
                            color: root.brandBlue
                            opacity: 0.2
                        }
                        Text {
                            anchors.centerIn: parent
                            text: vtolSwitchPopup.targetForward
                                  ? qsTr("Hold to transition to Fixed Wing")
                                  : qsTr("Hold to transition to Multi-Rotor")
                            font.pixelSize: Math.round(13 * (root.theme ? root.theme.uiScale : 1))
                            font.weight: Font.Medium
                            color: root.brandBlue
                        }
                        Timer {
                            id: transitionTimer
                            interval: 16
                            repeat: true
                            onTriggered: {
                                transitionHold.progress = Math.min(1, transitionHold.progress + interval / 750)
                                if (transitionHold.progress >= 1) {
                                    stop()
                                    if (transitionHold.enabled)
                                        vtolSwitchPopup.targetVehicle.vtolInFwdFlight = vtolSwitchPopup.targetForward
                                    vtolSwitchPopup.close()
                                }
                            }
                        }
                        MouseArea {
                            id: transitionMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onPressed: {
                                transitionHold.progress = 0
                                transitionTimer.restart()
                            }
                            onReleased: transitionHold.reset()
                            onCanceled: transitionHold.reset()
                            onExited: transitionHold.reset()
                        }
                    }
                }
            }

            Rectangle {
                id: vehicleMessagesButton
                width: height
                height: 24
                radius: height / 2
                color: root.theme && root.theme.darkMode ? "#000000" : "#ffffff"
                border.width: Math.round(1 * (theme ? theme.uiScale : 1))
                border.color: root.theme && root.theme.darkMode ? "#333333" : "#d7dde8"

                MainStatusIndicator {
                    id: vehicleMessagesIndicator
                    anchors.centerIn: parent
                    height: parent.height
                    messageIconOnly: true
                }

                MouseArea {
                    id: vehicleMessagesMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.flightModePanelCloseRequested()
                        vehicleMessagesIndicator.dropMainStatusIndicator()
                    }
                }

                ToolTip.visible: vehicleMessagesMouse.containsMouse
                ToolTip.text: qsTr("Vehicle messages and overall status")
            }

            Rectangle {
                id: armStatePill
                width: Math.max(theme ? theme.baseWidth * 8.2 : 96, armStateRow.implicitWidth + Math.round(18 * (theme ? theme.uiScale : 1)))
                height: 24
                radius: height / 2
                color: root.theme && root.theme.darkMode ? "#000000" : "#ffffff"
                border.width: Math.round(1 * (theme ? theme.uiScale : 1))
                border.color: root.theme && root.theme.darkMode ? "#333333" : Qt.rgba(0.83, 0.86, 0.91, 1.0)

                Row {
                    id: armStateRow
                    anchors.centerIn: parent
                    spacing: theme ? theme.spacingSm : 8

                    Rectangle {
                        width: theme ? theme.spacingSm : 6
                        height: width
                        radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.armColor
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.activeVehicle ? root.armText : qsTr("Connect")
                        font.pixelSize: theme ? theme.fontSm : 11
                        font.weight: Font.Medium
                        color: root.armColor
                    }
                }

                MouseArea {
                    id: connectMouse
                    anchors.fill: parent
                    enabled: !root.activeVehicle
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.flightModePanelCloseRequested()
                        vehicleMessagesIndicator.dropMainStatusIndicator()
                    }
                }

                ToolTip.visible: connectMouse.enabled && connectMouse.containsMouse
                ToolTip.text: qsTr("Select Link to Connect")
            }

            Rectangle {
                id: disconnectPill
                visible: root.activeVehicle && root.communicationLost
                width: Math.round(84 * (theme ? theme.uiScale : 1))
                height: 24
                radius: height / 2
                color: disconnectMouse.pressed
                       ? Qt.rgba(220 / 255, 38 / 255, 38 / 255, 0.16)
                       : (disconnectMouse.containsMouse ? Qt.rgba(220 / 255, 38 / 255, 38 / 255, 0.08) : "transparent")
                border.width: Math.round(1 * (theme ? theme.uiScale : 1))
                border.color: "#dc2626"

                Text {
                    anchors.centerIn: parent
                    text: qsTr("Disconnect")
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
            height: 24
            spacing: ScreenTools.defaultFontPixelWidth * 1.75
            visible: root.vehicleConnected

            Repeater {
                model: {
                    const sources = root.activeVehicle ? root.activeVehicle.toolIndicators : []
                    const indicators = []
                    for (let i = 0; i < sources.length; ++i) {
                        if (/\/(VehicleGPSIndicator|BatteryIndicator|APMBatteryIndicator|PX4BatteryIndicator)\.qml$/.test(String(sources[i]))) {
                            indicators.push(sources[i])
                        }
                    }
                    return indicators
                }

                Loader {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    source: modelData
                    visible: item && item.showIndicator
                }
            }
        }

        Row {
            id: rightButtons
            anchors.right: parent.right
            anchors.rightMargin: theme ? theme.spacingSm : 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: theme ? theme.spacingMd : 12

            Button {
                id: analyzeToolsButton
                width: moreButton.width
                height: moreButton.height
                icon.source: "/qmlimages/Analyze.svg"
                icon.color: down ? "#ffffff" : root.panelText
                icon.width: theme ? theme.iconMd : 22
                icon.height: icon.width
                Accessible.name: qsTr("分析工具")
                ToolTip.visible: hovered
                ToolTip.text: Accessible.name
                onClicked: root.analyzeToolsRequested()

                background: Rectangle {
                    radius: moreButton.radius
                    color: analyzeToolsButton.down ? root.brandPress
                         : analyzeToolsButton.hovered ? root.brandHover : moreButton.idleColor
                    border.width: moreButton.border.width
                    border.color: analyzeToolsButton.hovered || analyzeToolsButton.down
                                  ? root.brandBorder : moreButton.idleBorderColor
                }
            }

            Rectangle {
                id: moreButton
                width: theme ? 24 : 52
                height: width
                radius: theme ? theme.radiusLg + 2 : 10
                readonly property color idleColor: root.theme && root.theme.darkMode
                                                   ? Qt.rgba(31 / 255, 41 / 255, 55 / 255, 0.78) : "#ffffff"
                readonly property color idleBorderColor: root.theme && root.theme.darkMode
                                                         ? Qt.rgba(148 / 255, 163 / 255, 184 / 255, 0.42) : "#d7e2f0"
                Accessible.name: qsTranslate("PageSettings", "System Settings")
                ToolTip.visible: moreMouse.containsMouse
                ToolTip.text: Accessible.name
                color: moreMouse.pressed
                       ? root.brandPress
                       : moreMouse.containsMouse
                         ? root.brandHover
                         : idleColor
                border.width: Math.round(1 * (theme ? theme.uiScale : 1))
                border.color: moreMouse.containsMouse || moreMouse.pressed
                              ? root.brandBorder
                              : idleBorderColor

                Text {
                    anchors.centerIn: parent
                    text: "..."
                    font.pixelSize: theme ? theme.fontLg + 2 : 18
                    font.weight: Font.Bold
                    color: moreMouse.pressed ? "#ffffff" : root.panelText
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
                width: theme ? 24 : 52
                height: width
                radius: theme ? theme.radiusLg + 2 : 10
                color: pageMouse.pressed
                       ? root.brandPress
                       : pageMouse.containsMouse
                         ? root.brandHover
                         : (root.theme && root.theme.darkMode ? Qt.rgba(31 / 255, 41 / 255, 55 / 255, 0.78) : "#ffffff")
                border.width: Math.round(1 * (theme ? theme.uiScale : 1))
                border.color: pageMouse.containsMouse || pageMouse.pressed
                              ? root.brandBorder
                              : (root.theme && root.theme.darkMode ? Qt.rgba(148 / 255, 163 / 255, 184 / 255, 0.42) : "#d7e2f0")

                Image {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    source: "qrc:/brand/topbar-logo.png"
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }

                Accessible.name: qsTr("Flight")
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
        width: Math.min(root.interfacePopupWidth, root.width - logoButton.x - Math.round(8 * (theme ? theme.uiScale : 1)))
        height: root.interfaceDisplaySectionExpanded ? root.interfacePopupHeaderH + root.interfacePopupBodyH : root.interfacePopupHeaderH
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
            border.width: Math.round(1 * (theme ? theme.uiScale : 1))
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
                    height: root.interfacePopupHeaderH
                    radius: 10
                    color: root.panelBg
                    border.width: Math.round(0 * (theme ? theme.uiScale : 1))
                    clip: true

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: Math.round((root.compactPopupLayout ? 14 : 20) * root.popupUnit)
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Display")
                        font.pixelSize: Math.round((root.compactPopupLayout ? 15 : 18) * root.popupUnit)
                        font.weight: Font.Bold
                        color: root.panelText
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: Math.round((root.compactPopupLayout ? 14 : 20) * root.popupUnit)
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.interfaceDisplaySectionExpanded ? "▲" : "▼"
                        font.pixelSize: Math.round(12 * root.popupUnit)
                        font.weight: Font.Bold
                        color: root.brandBlue
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.interfaceDisplaySectionExpanded = !root.interfaceDisplaySectionExpanded
                    }
                }

                Item {
                    y: root.interfacePopupHeaderH
                    width: parent.width
                    height: root.interfaceDisplaySectionExpanded ? root.interfacePopupBodyH : 0
                    visible: root.interfaceDisplaySectionExpanded
                    clip: false

                    Column {
                        anchors.fill: parent
                        anchors.leftMargin: Math.round((root.compactPopupLayout ? 8 : 12) * root.popupUnit)
                        anchors.rightMargin: Math.round((root.compactPopupLayout ? 8 : 12) * root.popupUnit)
                        anchors.topMargin: Math.round(2 * root.popupUnit)
                        anchors.bottomMargin: Math.round(10 * root.popupUnit)
                        spacing: Math.round((root.compactPopupLayout ? 6 : 8) * root.popupUnit)

                        Item {
                            width: parent.width
                            height: Math.round(58 * root.popupUnit)
                            z: root.themeSelectExpanded ? 80 : 1

                        Text {
                            y: 0
                            text: qsTr("Theme")
                            font.pixelSize: Math.round(12 * root.popupUnit)
                            color: root.panelText2
                        }

                        Rectangle {
                            id: themeSelectBox
                            y: Math.round(22 * root.popupUnit)
                            width: parent.width
                            height: Math.round(34 * root.popupUnit)
                            radius: 2
                            color: root.themeSelectExpanded ? root.panelSelectBg : root.panelFieldBg
                            border.width: Math.round(1 * (theme ? theme.uiScale : 1))
                            border.color: root.panelFieldBorder

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: Math.round(10 * root.popupUnit)
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.theme && root.theme.darkMode ? qsTr("Dark Theme") : qsTr("Light Theme")
                                font.pixelSize: Math.round(12 * root.popupUnit)
                                color: root.panelText
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: Math.round(8 * root.popupUnit)
                                anchors.verticalCenter: parent.verticalCenter
                                text: "⌃\n⌄"
                                font.pixelSize: Math.round(14 * root.popupUnit)
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
                            height: Math.round(68 * root.popupUnit)
                            y: themeSelectBox.y + themeSelectBox.height
                            z: 200
                            visible: root.themeSelectExpanded
                            clip: true
                            color: root.panelBg
                            border.width: Math.round(1 * root.popupUnit)
                            border.color: root.panelFieldBorder

                            Column {
                                anchors.fill: parent

                                Rectangle {
                                    width: parent.width
                                    height: Math.round(34 * root.popupUnit)
                                    color: root.theme && !root.theme.darkMode ? root.panelSelectBg : root.panelBg

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: Math.round(10 * root.popupUnit)
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: qsTr("Light Theme")
                                        font.pixelSize: Math.round(12 * root.popupUnit)
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
                                    height: Math.round(34 * root.popupUnit)
                                    color: root.theme && root.theme.darkMode ? root.panelSelectBg : root.panelBg

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: Math.round(10 * root.popupUnit)
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: qsTr("Dark Theme")
                                        font.pixelSize: Math.round(12 * root.popupUnit)
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
                                border.width: Math.round(1 * root.popupUnit)
                                border.color: root.panelFieldBorder
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: Math.round(0 * (theme ? theme.uiScale : 1))
                        visible: false
                        z: root.uiSelectExpanded ? 80 : 1

                        Text {
                            y: 0
                            text: qsTr("Interface Mode")
                            font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
                            color: root.panelText2
                        }

                        Rectangle {
                            id: uiSelectBox
                            y: 22
                            width: parent.width
                            height: Math.round(34 * (theme ? theme.uiScale : 1))
                            radius: 2
                            color: root.uiSelectExpanded ? root.panelSelectBg : root.panelFieldBg
                            border.width: Math.round(1 * (theme ? theme.uiScale : 1))
                            border.color: root.panelFieldBorder

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.state && root.state.customFlyViewEnabled === false ? qsTr("Standard Interface") : qsTr("Custom Interface")
                                font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
                                color: root.panelText
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: "⌃\n⌄"
                                font.pixelSize: Math.round(14 * (theme ? theme.uiScale : 1))
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
                            height: Math.round(68 * (theme ? theme.uiScale : 1))
                            y: uiSelectBox.y + uiSelectBox.height
                            z: 200
                            visible: root.uiSelectExpanded
                            clip: true
                            color: root.panelBg
                            border.width: Math.round(1 * (theme ? theme.uiScale : 1))
                            border.color: root.panelFieldBorder

                            Column {
                                anchors.fill: parent

                                Rectangle {
                                    width: parent.width
                                    height: Math.round(34 * (theme ? theme.uiScale : 1))
                                    color: root.state && root.state.customFlyViewEnabled !== false ? root.panelSelectBg : root.panelBg

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: qsTr("Custom Interface")
                                        font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
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
                                    height: Math.round(34 * (theme ? theme.uiScale : 1))
                                    color: root.state && root.state.customFlyViewEnabled === false ? root.panelSelectBg : root.panelBg

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: qsTr("Standard Interface")
                                        font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
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
                                border.width: Math.round(1 * (theme ? theme.uiScale : 1))
                                border.color: root.panelFieldBorder
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: Math.round(0 * (theme ? theme.uiScale : 1))
                        visible: false

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Bottom Panel")
                            font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
                            color: root.panelText2
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.round(42 * (theme ? theme.uiScale : 1))
                            height: Math.round(22 * (theme ? theme.uiScale : 1))
                            radius: 11
                            color: root.state && root.state.showHudExpandBar ? root.brandBlue : (root.theme && root.theme.darkMode ? "#333333" : "#e5e7eb")
                            border.width: Math.round(0 * (theme ? theme.uiScale : 1))

                            Rectangle {
                                x: root.state && root.state.showHudExpandBar ? parent.width - width - 2 : 2
                                y: 2
                                width: Math.round(18 * (theme ? theme.uiScale : 1))
                                height: Math.round(18 * (theme ? theme.uiScale : 1))
                                radius: 9
                                color: "#ffffff"
                                border.width: Math.round(1 * (theme ? theme.uiScale : 1))
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
                        height: Math.round(20 * (theme ? theme.uiScale : 1))

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Sidebar Opacity")
                            font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
                            color: root.panelText2
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round((root.state && root.state.sidePanelOpacity !== undefined ? root.state.sidePanelOpacity : 0.92) * 100) + "%"
                            font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
                            color: root.brandBlue
                        }
                    }

                    Slider {
                        width: parent.width
                        height: Math.round(30 * (theme ? theme.uiScale : 1))
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
                            height: Math.round(4 * (theme ? theme.uiScale : 1))
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
                            width: Math.round(16 * (theme ? theme.uiScale : 1))
                            height: Math.round(16 * (theme ? theme.uiScale : 1))
                            radius: 8
                            color: "#ffffff"
                            border.width: Math.round(1 * (theme ? theme.uiScale : 1))
                            border.color: "#c4c4c4"
                        }
                    }

                    Item {
                        width: parent.width
                        height: Math.round(20 * (theme ? theme.uiScale : 1))

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Info Bar Opacity")
                            font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
                            color: root.panelText2
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round((root.state && root.state.infoBarOpacity !== undefined ? root.state.infoBarOpacity : 0.82) * 100) + "%"
                            font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
                            color: root.brandBlue
                        }
                    }

                    Slider {
                        width: parent.width
                        height: Math.round(30 * (theme ? theme.uiScale : 1))
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
                            height: Math.round(4 * (theme ? theme.uiScale : 1))
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
                            width: Math.round(16 * (theme ? theme.uiScale : 1))
                            height: Math.round(16 * (theme ? theme.uiScale : 1))
                            radius: 8
                            color: "#ffffff"
                            border.width: Math.round(1 * (theme ? theme.uiScale : 1))
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
                border.width: Math.round(2 * (theme ? theme.uiScale : 1))
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
            root.flightModePanelCloseRequested()
            root.themeSelectExpanded = false
            root.uiSelectExpanded = false
        }
    }

    /*
    Popup {
        id: flightModePopup
                                height: Math.round(34 * (theme ? theme.uiScale : 1))
                                color: root.theme && !root.theme.darkMode ? "#f3f3f3" : "#ffffff"

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "浅色主题"
                                    font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
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
                                height: Math.round(34 * (theme ? theme.uiScale : 1))
                                color: root.theme && root.theme.darkMode ? "#f3f3f3" : "#ffffff"

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "深色主题"
                                    font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
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
                            font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
                            color: "#4b5563"
                        }

                        Rectangle {
                            width: parent.width
                            height: Math.round(34 * (theme ? theme.uiScale : 1))
                            radius: 2
                            color: root.uiSelectExpanded ? "#d3d3d3" : "#e7e7e7"
                            border.width: Math.round(0 * (theme ? theme.uiScale : 1))

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.state && root.state.customFlyViewEnabled === false ? "原版界面" : "自定义界面"
                                font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
                                color: "#111827"
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.uiSelectExpanded ? "⌃" : "⌄"
                                font.pixelSize: Math.round(20 * (theme ? theme.uiScale : 1))
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
                                height: Math.round(34 * (theme ? theme.uiScale : 1))
                                color: root.state && root.state.customFlyViewEnabled !== false ? "#f3f3f3" : "#ffffff"

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "自定义界面"
                                    font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
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
                                height: Math.round(34 * (theme ? theme.uiScale : 1))
                                color: root.state && root.state.customFlyViewEnabled === false ? "#f3f3f3" : "#ffffff"

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "原版界面"
                                    font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
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
                        height: Math.round(34 * (theme ? theme.uiScale : 1))

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "底部展开栏"
                            font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
                            color: "#4b5563"
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.round(42 * (theme ? theme.uiScale : 1))
                            height: Math.round(22 * (theme ? theme.uiScale : 1))
                            radius: 11
                            color: root.state && root.state.showHudExpandBar ? root.brandBlue : "#e5e7eb"
                            border.width: Math.round(0 * (theme ? theme.uiScale : 1))

                            Rectangle {
                                x: root.state && root.state.showHudExpandBar ? parent.width - width - 2 : 2
                                y: 2
                                width: Math.round(18 * (theme ? theme.uiScale : 1))
                                height: Math.round(18 * (theme ? theme.uiScale : 1))
                                radius: 9
                                color: "#ffffff"
                                border.width: Math.round(1 * (theme ? theme.uiScale : 1))
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
                        height: Math.round(20 * (theme ? theme.uiScale : 1))

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "侧边栏透明度"
                            font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
                            color: "#4b5563"
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round((root.state && root.state.sidePanelOpacity !== undefined ? root.state.sidePanelOpacity : 0.92) * 100) + "%"
                            font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
                            color: root.brandBlue
                        }
                    }

                    Slider {
                        width: parent.width
                        height: Math.round(36 * (theme ? theme.uiScale : 1))
                        from: 0
                        to: 1
                        stepSize: 0.01
                        value: root.state && root.state.sidePanelOpacity !== undefined ? root.state.sidePanelOpacity : 0.92
                        onMoved: if (root.state && root.state.setSidePanelOpacityValue) root.state.setSidePanelOpacityValue(value)
                        onPressedChanged: if (!pressed && root.state && root.state.setSidePanelOpacityValue) root.state.setSidePanelOpacityValue(value)
                    }

                    Item {
                        width: parent.width
                        height: Math.round(20 * (theme ? theme.uiScale : 1))

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "信息栏透明度"
                            font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
                            color: "#4b5563"
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round((root.state && root.state.infoBarOpacity !== undefined ? root.state.infoBarOpacity : 0.82) * 100) + "%"
                            font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
                            color: root.brandBlue
                        }
                    }

                    Slider {
                        width: parent.width
                        height: Math.round(36 * (theme ? theme.uiScale : 1))
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
            root.flightModePanelCloseRequested()
        }
    }

    */
    Popup {
        id: flightModePopup
        x: modeButton.x + leftStatusRow.x
        y: root.height + 2
        width: Math.round(218 * (theme ? theme.uiScale : 1))
        height: Math.min(620, 116 + Math.max(1, root.flightModeList.length) * 48)
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
        visible: false
        z: 85

        background: Rectangle {
            radius: 8
            color: "#ffffff"
            border.width: Math.round(1 * (theme ? theme.uiScale : 1))
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
                text: qsTr("Flight Mode ")
                font.pixelSize: Math.round(18 * (theme ? theme.uiScale : 1))
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
                        ? (qsTr("Disconnected · Current ") + root.modeDisplayName(modeText) + "\nmodes: " + root.flightModeList.length)
                        : qsTr("Disconnected · Current --\\nModes: 0")
                font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
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
                height: Math.round(1 * (theme ? theme.uiScale : 1))
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
                            height: Math.round(42 * (theme ? theme.uiScale : 1))
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
                                font.pixelSize: Math.round(13 * (theme ? theme.uiScale : 1))
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
                                    root.flightModePanelCloseRequested()
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
                        text: qsTr("Disconnected; no modes available")
                        font.pixelSize: Math.round(12 * (theme ? theme.uiScale : 1))
                        color: "#24415f"
                    }
                }
            }
        }
    }
}
