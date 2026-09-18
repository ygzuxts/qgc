pragma Singleton

import QtQuick 2.15

QtObject {
    property bool lightMode: false

    readonly property string cockpitFont: "Consolas"
    readonly property color bg: lightMode ? "#D8D5CC" : "#1C1C1E"
    readonly property color panel: lightMode ? "#C9C6BC" : "#111214"
    readonly property color panelBorder: lightMode ? "#A9A69D" : "#3A3A3D"
    readonly property color overlay: lightMode ? Qt.rgba(0.82, 0.80, 0.75, 0.92) : Qt.rgba(0.02, 0.022, 0.026, 0.92)
    readonly property color overlayMuted: lightMode ? Qt.rgba(0.82, 0.80, 0.75, 0.82) : Qt.rgba(0.02, 0.022, 0.026, 0.82)
    readonly property color buttonIdle: lightMode ? "#DCDAD2" : "#171719"
    readonly property color takeoffReady: Qt.rgba(0.06, 0.46, 0.25, 0.28)
    readonly property color landReady: Qt.rgba(0.64, 0.05, 0.04, 0.28)
    readonly property color cyan: lightMode ? "#202225" : "#D6D6D2"
    readonly property color amber: "#F5B83B"
    readonly property color statusYellow: "#F5B83B"
    readonly property color warningBg: Qt.rgba(0.96, 0.72, 0.23, 0.16)
    readonly property color statusRed: "#D9342B"
    readonly property color fatalRed: "#FF1F1F"
    readonly property color fatalBg: Qt.rgba(0.42, 0.0, 0.0, 0.88)
    readonly property color fatalPanel: Qt.rgba(0.18, 0.0, 0.0, 0.72)
    readonly property color statusGreen: "#42D66F"
    readonly property color statusOff: lightMode ? "#6C6B66" : "#46484C"
    readonly property color red: "#D9342B"
    readonly property color green: "#42D66F"
    readonly property color textHi: lightMode ? "#202225" : "#E6E2D8"
    readonly property color textLo: lightMode ? "#4A4A45" : "#9B9A94"
    readonly property color tapeBg: lightMode ? "#D8D5CC" : "#0A0A0B"
    readonly property color lcdBg: lightMode ? "#C9CAC2" : "#040706"
    readonly property color lcdBorder: lightMode ? "#8D8B82" : "#2B3731"
    readonly property color lcdText: lightMode ? "#2B302C" : "#56FF8C"
    readonly property color lcdGlow: lightMode ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(0.18, 1.0, 0.38, 0.45)
}
