import QtQuick

import QGroundControl.ScreenTools

QtObject {
    property bool darkMode: false
    readonly property bool mobile: ScreenTools.isMobile
    readonly property real baseFont: ScreenTools.defaultFontPixelHeight
    readonly property real baseWidth: ScreenTools.defaultFontPixelWidth
    readonly property real compactScale: mobile ? 0.92 : 1.0

    readonly property color bg:       darkMode ? "#000000" : "#ffffff"
    readonly property color surface:  darkMode ? "#000000" : "#ffffff"
    readonly property color surface2: darkMode ? "#000000" : "#ffffff"
    readonly property color surface3: darkMode ? "#000000" : "#ffffff"
    readonly property color border:   darkMode ? "#2b2b2b" : "#e4e8ed"
    readonly property color border2:  darkMode ? "#1f1f1f" : "#edf0f4"
    readonly property color text:     darkMode ? "#e5edf8" : "#1a1d23"
    readonly property color text2:    darkMode ? "#a8b5c7" : "#5a6272"
    readonly property color text3:    darkMode ? "#7f8da3" : "#9aa3b2"
    readonly property color textOnBlue: "#ffffff"
    // 自定义界面统一使用品牌蓝系。所有 hover/pressed/selected 状态尽量引用这组颜色，
    // 避免不同页面出现灰、黑、黄等不一致的交互色。
    // NiceWing 品牌交互色：所有自定义 hover/pressed/selected 统一走这个色系。
    readonly property color brandBlue:       "#000066"
    readonly property color brandBlueHover:  darkMode ? Qt.rgba(0, 0, 102 / 255, 0.38)
                                                      : Qt.rgba(0, 0, 102 / 255, 0.12)
    readonly property color brandBluePress:  "#00004D"
    readonly property color brandBlueBorder: darkMode ? Qt.rgba(120 / 255, 120 / 255, 210 / 255, 0.78)
                                                      : Qt.rgba(0, 0, 102 / 255, 0.42)
    readonly property color blue:       brandBlue
    readonly property color blueL:      brandBlueHover
    readonly property color bluePress:  brandBluePress
    readonly property color blueBorder: brandBlueBorder
    readonly property color green:    "#16a34a"
    readonly property color greenL:   darkMode ? "#183a28" : "#dcfce7"
    readonly property color red:      "#dc2626"
    readonly property color redL:     darkMode ? "#402028" : "#fee2e2"
    readonly property color amber:    "#d97706"
    readonly property color amberL:   darkMode ? "#493515" : "#fef3c7"
    readonly property color cyan:     "#0891b2"
    readonly property color purple:   "#6B2327"
    readonly property color overlaySurface: darkMode ? Qt.rgba(0, 0, 0, 0.88) : Qt.rgba(1, 1, 1, 0.88)
    readonly property color overlaySurfaceStrong: darkMode ? Qt.rgba(0, 0, 0, 0.94) : Qt.rgba(1, 1, 1, 0.94)

    readonly property int fontXs:      Math.round(baseFont * 0.72)
    readonly property int fontSm:      Math.round(baseFont * 0.84)
    readonly property int fontMd:      Math.round(baseFont * 0.96)
    readonly property int fontLg:      Math.round(baseFont * 1.10)
    readonly property int fontXl:      Math.round(baseFont * 1.36)

    readonly property real spacingXs:  Math.max(4, Math.round(baseFont * 0.30 * compactScale))
    readonly property real spacingSm:  Math.max(6, Math.round(baseFont * 0.50 * compactScale))
    readonly property real spacingMd:  Math.max(8, Math.round(baseFont * 0.78 * compactScale))
    readonly property real spacingLg:  Math.max(10, Math.round(baseFont * 1.00 * compactScale))
    readonly property real spacingXl:  Math.max(12, Math.round(baseFont * 1.35 * compactScale))

    readonly property real iconSm:     Math.round(baseFont * 1.35)
    readonly property real iconMd:     Math.round(baseFont * 1.55)
    readonly property real iconLg:     Math.round(baseFont * 1.85)

    readonly property real controlHSm: Math.round(baseFont * 1.85 * compactScale)
    readonly property real controlHMd: Math.round(baseFont * 2.20 * compactScale)
    readonly property real controlHLg: Math.round(baseFont * 2.70 * compactScale)
    readonly property real sectionH:   Math.round(baseFont * 2.15 * compactScale)
    readonly property real cardHSm:    Math.round(baseFont * 4.00 * compactScale)
    readonly property real cardHMd:    Math.round(baseFont * 4.95 * compactScale)

    readonly property real topBarH:    Math.round(baseFont * (mobile ? 3.55 : 4.00))
    readonly property real bottomBarH: Math.round(baseFont * (mobile ? 3.55 : 4.00))
    readonly property real leftPanelW: Math.round(baseWidth * (mobile ? 21 : 30))
    readonly property real rightPanelW:Math.round(baseWidth * (mobile ? 24 : 31))
    readonly property real tabBarH:    Math.round(baseFont * 3.00 * compactScale)
    readonly property real quickMetricW: Math.round(baseWidth * (mobile ? 8.4 : 10.8))
    readonly property int  radius:     Math.max(6, Math.round(baseFont * 0.48))
    readonly property int  radiusLg:   Math.max(8, Math.round(baseFont * 0.64))

    function toggleTheme() {
        darkMode = !darkMode
    }
}
