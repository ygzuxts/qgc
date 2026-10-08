import QtQuick 2.15

import QGroundControl.FlightDisplay

Item {
    id: window

    anchors.fill: parent
    focus: true

    signal originalQgcModeRequested()

    property bool lightMode: false
    property bool controlOverlayOpen: false
    property bool joystickOverlayOpen: false
    property bool joystickEnabled: false

    readonly property real uiScale: Math.max(0.62, Math.min(1.35, Math.min(width / 960, height / 600)))
    readonly property bool compactLandscape: false
    readonly property int primaryMetricSize: Math.round(88 * uiScale)
    readonly property int horizonSize: Math.round(330 * uiScale)
    readonly property int sideGaugeSize: Math.round(260 * uiScale)
    readonly property real headingTapeScale: uiScale

    Binding {
        target: FlightPalette
        property: "lightMode"
        value: window.lightMode
        restoreMode: Binding.RestoreBinding
    }

    FlightStateController {
        id: flightState
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_F) {
            flightState.fatalWarningTest = !flightState.fatalWarningTest
            event.accepted = true
        } else if (event.key === Qt.Key_Escape && flightState.fatalWarningTest) {
            flightState.fatalWarningTest = false
            event.accepted = true
        }
    }

    Rectangle {
        anchors.fill: parent
        z: -1
        gradient: Gradient {
            GradientStop { position: 0.0; color: window.lightMode ? "#E0DDD4" : "#242426" }
            GradientStop { position: 0.35; color: FlightPalette.bg }
            GradientStop { position: 1.0; color: window.lightMode ? "#C9C6BC" : "#101012" }
        }

        Rectangle {
            anchors.fill: parent
            color: window.lightMode ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(1, 1, 1, 0.018)
        }
    }

    Item {
        anchors.fill: parent

        Item {
            id: normalInstrumentLayer
            anchors.fill: parent
            anchors.leftMargin: Math.round(24 * window.uiScale)
            anchors.rightMargin: Math.round(24 * window.uiScale)
            anchors.topMargin: Math.round(18 * window.uiScale)
            anchors.bottomMargin: Math.round(18 * window.uiScale)
            opacity: flightState.fatalAttitudeWarning ? 0.22 : 1.0

            Behavior on opacity { NumberAnimation { duration: 140 } }

            EmbeddedStatusBar {
                id: embeddedStatusBar
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                compactLandscape: window.compactLandscape
                flightState: flightState
                z: 12
                onThemeToggleRequested: window.lightMode = !window.lightMode
                onOriginalQgcModeRequested: window.originalQgcModeRequested()
            }

            WarningBanner {
                anchors.top: parent.top
                anchors.topMargin: embeddedStatusBar.height + Math.round(8 * window.uiScale)
                anchors.left: parent.left
                compactLandscape: window.compactLandscape
                flightState: flightState
                z: 8
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                hoverEnabled: false
                preventStealing: true
                propagateComposedEvents: false
                z: 10
                onClicked: function(mouse) { mouse.accepted = true }
                onPressed: function(mouse) { mouse.accepted = true }
                onReleased: function(mouse) { mouse.accepted = true }
            }

            SpeedPanel {
                anchors.horizontalCenter: parent.left
                anchors.horizontalCenterOffset: parent.width * 0.17
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Math.round(12 * window.uiScale)
                z: 11
                compactLandscape: window.compactLandscape
                sideGaugeSize: window.sideGaugeSize
                flightState: flightState
            }

            AttitudeCluster {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: Math.round(-6 * window.uiScale)
                z: 11
                compactLandscape: window.compactLandscape
                horizonSize: window.horizonSize
                headingTapeScale: window.headingTapeScale
                flightState: flightState
            }

            AltitudeCluster {
                anchors.horizontalCenter: parent.right
                anchors.horizontalCenterOffset: -parent.width * 0.17
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: Math.round(12 * window.uiScale)
                z: 11
                compactLandscape: window.compactLandscape
                sideGaugeSize: window.sideGaugeSize
                flightState: flightState
            }
        }

        FatalWarningOverlay {
            anchors.fill: parent
            visible: flightState.fatalAttitudeWarning
            compactLandscape: window.compactLandscape
            primaryMetricSize: window.primaryMetricSize
            overlayColor: FlightPalette.fatalBg
            z: 30
        }
    }

    TakeoffLandOverlay {
        anchors.fill: parent
        visible: window.controlOverlayOpen
        containerWidth: window.width
        z: 40
        onCloseRequested: window.controlOverlayOpen = false
    }

    SelfCheckOverlay {
        anchors.fill: parent
        visible: flightState.selfCheckActive
        flightState: flightState
        z: 35
    }

    JoystickOverlay {
        anchors.fill: parent
        visible: window.joystickOverlayOpen
        joystickEnabled: window.joystickEnabled
        z: 45
        onJoystickEnabledChangedByUser: function(enabled) { window.joystickEnabled = enabled }
        onCloseRequested: window.joystickOverlayOpen = false
    }
}
