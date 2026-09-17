pragma Singleton

import QtQuick 2.15

QtObject {
    property bool lightMode: true

    readonly property color bg: lightMode ? "#edf1f5" : "#080B10"
    readonly property color panel: lightMode ? "#f8fafc" : "#0F151D"
    readonly property color panelBorder: lightMode ? "#cbd5e1" : "#1C2733"
    readonly property color overlay: lightMode ? Qt.rgba(1, 1, 1, 0.86) : Qt.rgba(0.06, 0.09, 0.13, 0.85)
    readonly property color overlayMuted: lightMode ? Qt.rgba(0.94, 0.97, 1.0, 0.86) : Qt.rgba(0.06, 0.09, 0.13, 0.75)
    readonly property color buttonIdle: lightMode ? Qt.rgba(0.90, 0.94, 0.98, 0.92) : Qt.rgba(0.1, 0.14, 0.18, 0.85)
    readonly property color takeoffReady: lightMode ? Qt.rgba(0.16, 0.47, 0.94, 0.14) : Qt.rgba(0.2, 0.88, 1.0, 0.16)
    readonly property color landReady: lightMode ? Qt.rgba(1.0, 0.29, 0.29, 0.12) : Qt.rgba(1.0, 0.29, 0.29, 0.14)
    readonly property color cyan: "#2977ef"
    readonly property color amber: "#884600"
    readonly property color statusYellow: "#F5A400"
    readonly property color warningBg: lightMode ? Qt.rgba(1.0, 0.66, 0.0, 0.10) : Qt.rgba(1.0, 0.66, 0.0, 0.15)
    readonly property color statusRed: "#FF3B30"
    readonly property color fatalRed: "#FF1F1F"
    readonly property color fatalBg: Qt.rgba(0.55, 0.0, 0.0, lightMode ? 0.82 : 0.88)
    readonly property color fatalPanel: Qt.rgba(0.18, 0.0, 0.0, lightMode ? 0.60 : 0.72)
    readonly property color statusGreen: "#00D084"
    readonly property color statusOff: lightMode ? "#8EA0B6" : "#9AA8B8"
    readonly property color red: "#FF4B4B"
    readonly property color green: lightMode ? "#118a4f" : "#39D98A"
    readonly property color textHi: lightMode ? "#142033" : "#EAF3FF"
    readonly property color textLo: lightMode ? "#64748b" : "#6E7E90"
    readonly property color tapeBg: lightMode ? "#eef2f6" : "#080B10"
}
