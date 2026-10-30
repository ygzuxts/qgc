/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.AutoPilotPlugin
import QGroundControl.Palette
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.MultiVehicleManager

Rectangle {
    id:     setupView
    color:  qgcPal.window
    z:      QGroundControl.zOrderTopMost

    readonly property string configurationFontFamily: Qt.application.font.family
    readonly property bool customNavigation: true
    readonly property bool _dark: qgcPal.globalTheme === QGCPalette.Dark
    readonly property color _navColor: _dark ? "#030509" : "#f8fafc"
    readonly property color _lineColor: _dark ? "#253044" : "#d7e2f0"
    readonly property color _accent: qgcPal.brandingPurple
    readonly property real _navWidth: (ScreenTools.isMobile || width < 1000) ? Math.max(112, Math.min(170, width * 0.18)) : Math.max(220, Math.min(270, width * 0.22))
    readonly property real _pageScale: Math.max(ScreenTools.isMobile ? 1.02 : 0.78,
                                              Math.min(1.30, Math.min(mainWindow.width / 1280, mainWindow.height / 720)))
    readonly property bool _compactLayout: ScreenTools.isMobile || width < 1000
    readonly property real _contentMargin: ScreenTools.isMobile ? 8 : 24
    readonly property real _contentPadding: ScreenTools.isMobile ? 4 : 16
    property string _panelTitle: qsTr("Summary")
    signal popout()

    component NavigationButton: ConfigButton {
        id: navButton
        implicitHeight: Math.max(44, ScreenTools.defaultFontPixelHeight * 2.4)
        textColor: checked ? "#ffffff" : qgcPal.text
        background: Rectangle {
            radius: 6
            color: navButton.checked ? setupView._accent
                 : navButton.hovered ? Qt.rgba(setupView._accent.r, setupView._accent.g, setupView._accent.b, 0.10)
                 : "transparent"
        }
        contentItem: RowLayout {
            spacing: 10
            Text {
                font.family: setupView.configurationFontFamily
                text: "•"
                color: !navButton.setupComplete ? "#dc2626" : navButton.checked ? "#ffffff" : "#a8bddc"
                font.pixelSize: Math.max(14, Math.round(18 * setupView._pageScale))
                font.weight: Font.Bold
            }
            QGCLabel {
                Layout.fillWidth: true
                font.family: setupView.configurationFontFamily
                text: navButton.text
                color: navButton.textColor
                font.weight: navButton.checked ? Font.Bold : Font.Medium
                font.pixelSize: Math.max(12, Math.round((setupView._compactLayout ? 13 : 15) * setupView._pageScale))
                elide: Text.ElideRight
            }
        }
    }

    // This need to block click event leakage to underlying map.
    DeadMouseArea {
        anchors.fill: parent
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    readonly property real      _defaultTextHeight: ScreenTools.defaultFontPixelHeight
    readonly property real      _defaultTextWidth:  ScreenTools.defaultFontPixelWidth
    readonly property real      _horizontalMargin:  _defaultTextWidth / 2
    readonly property real      _verticalMargin:    _defaultTextHeight / 2
    readonly property real      _buttonWidth:       _defaultTextWidth * 18
    readonly property string    _armedVehicleText:  qsTr("This operation cannot be performed while the vehicle is armed.")

    property bool   _vehicleArmed:                  QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle.armed : false
    property string _messagePanelText:              qsTr("missing message panel text")
    property bool   _fullParameterVehicleAvailable: QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable && !QGroundControl.multiVehicleManager.activeVehicle.parameterManager.missingParameters
    property var    _corePlugin:                    QGroundControl.corePlugin

    function showSummaryPanel() {
        if (mainWindow.allowViewSwitch()) {
            _showSummaryPanel()
        }
    }

    function _showSummaryPanel() {
        _panelTitle = Qt.binding(function() { return summaryButton.text })
        if (_fullParameterVehicleAvailable) {
            if (QGroundControl.multiVehicleManager.activeVehicle.autopilotPlugin.vehicleComponents.length === 0) {
                panelLoader.setSourceComponent(noComponentsVehicleSummaryComponent)
            } else {
                panelLoader.setSource("qrc:/qml/QGroundControl/VehicleSetup/VehicleSummary.qml")
            }
        } else if (QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable) {
            panelLoader.setSourceComponent(missingParametersVehicleSummaryComponent)
        } else {
            panelLoader.setSourceComponent(disconnectedVehicleSummaryComponent)
        }
        summaryButton.checked = true
    }

    function showPanel(button, qmlSource) {
        if (mainWindow.allowViewSwitch()) {
            button.checked = true
            _panelTitle = Qt.binding(function() { return button.text })
            panelLoader.setSource(qmlSource)
        }
    }

    function showVehicleComponentPanel(vehicleComponent)
    {
        if (mainWindow.allowViewSwitch()) {
            var autopilotPlugin = QGroundControl.multiVehicleManager.activeVehicle.autopilotPlugin
            _panelTitle = vehicleComponent.name
            var prereq = autopilotPlugin.prerequisiteSetup(vehicleComponent)
            if (prereq !== "") {
                _messagePanelText = qsTr("%1 setup must be completed prior to %2 setup.").arg(prereq).arg(vehicleComponent.name)
                panelLoader.setSourceComponent(messagePanelComponent)
            } else {
                panelLoader.setSource(vehicleComponent.setupSource, vehicleComponent)
                for(var i = 0; i < componentRepeater.count; i++) {
                    var obj = componentRepeater.itemAt(i);
                    if (obj.text === vehicleComponent.name) {
                        obj.checked = true
                        break;
                    }
                }
            }
        }
    }

    function showParametersPanel() {
        if (mainWindow.allowViewSwitch()) {
            parametersButton.checked = true
            _panelTitle = Qt.binding(function() { return parametersButton.text })
            panelLoader.setSource("qrc:/qml/QGroundControl/VehicleSetup/SetupParameterEditor.qml")
        }
    }

    Component.onCompleted: _showSummaryPanel()

    Connections {
        target: QGroundControl.corePlugin
        onShowAdvancedUIChanged: {
            if(!QGroundControl.corePlugin.showAdvancedUI) {
                _showSummaryPanel()
            }
        }
    }

    Connections {
        target: QGroundControl.multiVehicleManager
        onParameterReadyVehicleAvailableChanged: {
            if (QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable || summaryButton.checked || !firmwareButton.checked) {
                // Show/Reload the Summary panel when:
                //      A new vehicle shows up
                //      The summary panel is already showing and the active vehicle goes away
                //      The active vehicle goes away and we are not on the Firmware panel.
                summaryButton.checked = true
                _showSummaryPanel()
            }
        }
    }

    Component {
        id: noComponentsVehicleSummaryComponent
        Rectangle {
            color: qgcPal.windowShade
            QGCLabel {
                anchors.margins:        _defaultTextWidth * 2
                anchors.fill:           parent
                verticalAlignment:      Text.AlignVCenter
                horizontalAlignment:    Text.AlignHCenter
                wrapMode:               Text.WordWrap
                font.pointSize:         ScreenTools.mediumFontPointSize
                text:                   qsTr("%1 does not currently support setup of your vehicle type. ").arg(QGroundControl.appName) +
                                        "If your vehicle is already configured you can still Fly."
                onLinkActivated: (link) => Qt.openUrlExternally(link)
            }
        }
    }

    Component {
        id: disconnectedVehicleSummaryComponent
        Rectangle {
            color: qgcPal.windowShade
            QGCLabel {
                anchors.margins:        _defaultTextWidth * 2
                anchors.fill:           parent
                verticalAlignment:      Text.AlignVCenter
                horizontalAlignment:    Text.AlignHCenter
                wrapMode:               Text.WordWrap
                font.pointSize:         ScreenTools.largeFontPointSize
                text:                   qsTr("Vehicle settings and info will display after connecting your vehicle.") +
                                        (ScreenTools.isMobile || !_corePlugin.options.showFirmwareUpgrade ? "" : " Click Firmware on the left to upgrade your vehicle.")

                onLinkActivated: (link) => Qt.openUrlExternally(link)
            }
        }
    }

    Component {
        id: missingParametersVehicleSummaryComponent

        Rectangle {
            color: qgcPal.windowShade

            QGCLabel {

                anchors.margins:        _defaultTextWidth * 2
                anchors.fill:           parent
                verticalAlignment:      Text.AlignVCenter
                horizontalAlignment:    Text.AlignHCenter
                wrapMode:               Text.WordWrap
                font.pointSize:         ScreenTools.mediumFontPointSize
                text:                   qsTr("You are currently connected to a vehicle but it did not return the full parameter list. ") +
                                        qsTr("As a result, the full set of vehicle setup options are not available.")

                onLinkActivated: (link) => Qt.openUrlExternally(link)
            }
        }
    }

    Component {
        id: messagePanelComponent

        Item {
            QGCLabel {
                anchors.margins:        _defaultTextWidth * 2
                anchors.fill:           parent
                verticalAlignment:      Text.AlignVCenter
                horizontalAlignment:    Text.AlignHCenter
                wrapMode:               Text.WordWrap
                font.pointSize:         ScreenTools.mediumFontPointSize
                text:                   _messagePanelText
            }
        }
    }

    Rectangle {
        id: navigationPanel
        width: setupView._navWidth
        height: parent.height
        color: setupView._navColor
        Rectangle {
            anchors.right: parent.right
            width: 1
            height: parent.height
            color: setupView._lineColor
        }
    }

    QGCButton {
        id: backButton
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 14
        width: setupView._navWidth - 28
        height: 44
        text: qsTr("Back")
        font.pixelSize: Math.max(12, Math.round(15 * setupView._pageScale))
        textColor: setupView._accent
        contentItem: Text {
            font.family: setupView.configurationFontFamily
            text: backButton.text
            color: setupView._accent
            font.pixelSize: backButton.font.pixelSize
            font.weight: Font.Normal
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        onClicked: if (mainWindow.allowViewSwitch()) setupView.popout()
        background: Rectangle {
            radius: 8
            color: backButton.hovered ? Qt.rgba(setupView._accent.r, setupView._accent.g, setupView._accent.b, 0.1) : qgcPal.window
            border.color: setupView._lineColor
        }
    }

    QGCLabel {

        font.family: setupView.configurationFontFamily
        id: navigationTitle
        anchors.top: backButton.bottom
        anchors.topMargin: setupView._contentPadding
        anchors.left: backButton.left
        width: backButton.width
        text: qsTr("Vehicle Configuration")
        font.weight: Font.Bold
        font.pixelSize: Math.max(16, Math.round((setupView._compactLayout ? 18 : 22) * setupView._pageScale))
        wrapMode: Text.WordWrap
    }

    QGCFlickable {
        id:                 buttonScroll
        width:              setupView._navWidth - 28
        anchors.topMargin:  14
        anchors.top:        navigationTitle.bottom
        anchors.bottom:     parent.bottom
        anchors.leftMargin: 14
        anchors.left:       parent.left
        contentHeight:      buttonColumn.height
        flickableDirection: Flickable.VerticalFlick
        clip:               true

        ColumnLayout {
            id:         buttonColumn
            width:      buttonScroll.width
            spacing:    8

            NavigationButton {
                id:                 summaryButton
                icon.source:        "/qmlimages/VehicleSummaryIcon.png"
                checked:            true
                text:               qsTr("Summary")
                Layout.fillWidth:   true

                onClicked: showSummaryPanel()
            }

            NavigationButton {
                visible:            QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle.flowImageIndex > 0 : false
                text:               qsTr("Optical Flow")
                Layout.fillWidth:   true
                onClicked:          showPanel(this, "qrc:/qml/QGroundControl/VehicleSetup/OpticalFlowSensor.qml")
            }

            NavigationButton {
                id:                 joystickButton
                icon.source:      "/qmlimages/Joystick.png"
                setupComplete:      _activeJoystick ? _activeJoystick.calibrated || _buttonsOnly : false
                visible:            _fullParameterVehicleAvailable && joystickManager.joysticks.length !== 0
                text:               _forcedToButtonsOnly ? qsTr("Buttons") : qsTr("Joystick")
                Layout.fillWidth:   true
                onClicked:          showPanel(this, "qrc:/qml/QGroundControl/VehicleSetup/JoystickConfig.qml")

                property var    _activeJoystick:        joystickManager.activeJoystick
                property bool   _buttonsOnly:           _activeJoystick ? _activeJoystick.axisCount == 0 : false
                property bool   _forcedToButtonsOnly:   !QGroundControl.corePlugin.options.allowJoystickSelection && _buttonsOnly
            }

            Repeater {
                id:     componentRepeater
                model:  _fullParameterVehicleAvailable ? QGroundControl.multiVehicleManager.activeVehicle.autopilotPlugin.vehicleComponents : 0

                NavigationButton {
                    icon.source:      modelData.iconResource
                    setupComplete:      modelData.setupComplete
                    text:               modelData.name
                    visible:            modelData.setupSource.toString() !== ""
                    Layout.fillWidth:   true
                    onClicked:          showVehicleComponentPanel(componentUrl)

                    property var componentUrl: modelData
                }
            }

            NavigationButton {
                id:                 parametersButton
                visible:            QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable &&
                                    !QGroundControl.multiVehicleManager.activeVehicle.usingHighLatencyLink &&
                                    _corePlugin.showAdvancedUI
                text:               qsTr("Parameters")
                Layout.fillWidth:   true
                icon.source:        "/qmlimages/subMenuButtonImage.png"
                onClicked:          showPanel(this, "qrc:/qml/QGroundControl/VehicleSetup/SetupParameterEditor.qml")
            }

            NavigationButton {
                id:                 firmwareButton
                icon.source:      "/qmlimages/FirmwareUpgradeIcon.png"
                visible:            !ScreenTools.isMobile && _corePlugin.options.showFirmwareUpgrade
                text:               qsTr("Firmware")
                Layout.fillWidth:   true

                onClicked: showPanel(this, "qrc:/qml/QGroundControl/VehicleSetup/FirmwareUpgrade.qml")
            }
        }
    }

    Rectangle {
        id:                     divider
        anchors.left:           navigationPanel.right
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        width:                  1
        color:                  setupView._lineColor
    }

    QGCLabel {

        id: panelTitle
        anchors.left: divider.right
        anchors.top: parent.top
        anchors.margins: setupView._contentMargin
        text: setupView._panelTitle
        font.weight: Font.Bold
        font.pixelSize: Math.max(20, Math.round(24 * setupView._pageScale))
    }

    Rectangle {
        id: contentCard
        anchors.left: divider.right
        anchors.right: parent.right
        anchors.top: panelTitle.bottom
        anchors.bottom: parent.bottom
        anchors.margins: setupView._contentMargin
        anchors.topMargin: setupView._contentPadding
        radius: 10
        color: qgcPal.window
        border.color: setupView._lineColor
    }

    Loader {
        id:                     panelLoader
        anchors.fill:           contentCard
        anchors.margins:        setupView._contentPadding
        clip:                   true

        function setSource(source, vehicleComponent) {
            panelLoader.source = ""
            panelLoader.vehicleComponent = vehicleComponent
            panelLoader.source = source
        }

        function setSourceComponent(sourceComponent, vehicleComponent) {
            panelLoader.sourceComponent = undefined
            panelLoader.vehicleComponent = vehicleComponent
            panelLoader.sourceComponent = sourceComponent
        }

        property var vehicleComponent
    }
}
