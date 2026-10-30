// PageSettings.qml  换皮系统设置页：导航换皮，内容复用 QGC 原版设置页
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.AppSettings
import QGroundControl.Palette
import QGroundControl.ScreenTools

Rectangle {
    id: root

    property var state: null
    property var theme: null
    property var appSettings: QGroundControl.settingsManager ? QGroundControl.settingsManager.appSettings : null
    property int selectedIndex: 0
    property string selectedUrl: "qrc:/qml/QGroundControl/AppSettings/GeneralSettings.qml"
    signal closeRequested()

    readonly property bool pageDark: theme ? !!theme.darkMode : false
    readonly property color brandColor: qgcPal.brandingPurple
    readonly property color brandHoverColor: Qt.rgba(brandColor.r, brandColor.g, brandColor.b, pageDark ? 0.28 : 0.10)
    readonly property color bgColor: pageDark ? "#05070c" : "#ffffff"
    readonly property color navColor: pageDark ? "#030509" : "#f8fafc"
    readonly property color cardColor: pageDark ? "#0b0f18" : "#ffffff"
    readonly property color lineColor: pageDark ? "#253044" : "#d7e2f0"
    readonly property color textColor: pageDark ? "#e5edf8" : "#111827"
    readonly property color subTextColor: pageDark ? "#9aa7bc" : "#8a97aa"
    readonly property color hoverColor: brandHoverColor
    readonly property color blueColor: brandColor
    readonly property real pageScale: theme ? theme.uiScale : 1
    readonly property bool compactLayout: ScreenTools.isMobile || root.width < 1000
    readonly property real navWidth: compactLayout ? Math.max(112, Math.min(170, root.width * 0.18)) : Math.max(220, Math.min(270, root.width * 0.22))

    color: bgColor

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    SettingsPagesModel { id: settingsPagesModel }

    function _paletteValueIsDark(value) {
        return value === true || value === 1 || value === "1" || String(value).toLowerCase() === "true"
    }

    function _syncQgcPalette() {
        if (root.appSettings && root.appSettings.indoorPalette && root.theme) {
            root.appSettings.indoorPalette.rawValue = root.theme.darkMode ? 1 : 0
        }
    }

    function _syncThemeFromQgcPalette() {
        if (root.appSettings && root.appSettings.indoorPalette && root.theme) {
            root.theme.darkMode = root._paletteValueIsDark(root.appSettings.indoorPalette.rawValue)
        }
    }

    Component.onCompleted: root._syncQgcPalette()

    Connections {
        target: root.theme
        function onDarkModeChanged() {
            root._syncQgcPalette()
        }
    }

    Connections {
        target: root.appSettings && root.appSettings.indoorPalette ? root.appSettings.indoorPalette : null
        function onRawValueChanged() {
            root._syncThemeFromQgcPalette()
        }
    }

    function _sourceName(name) {
        var names = ["General", "Fly View", "Plan View", "Video", "Telemetry", "NTRIP",
                     "ADSB Server", "Comm Links", "Maps", "PX4 Log Transfer", "Remote ID",
                     "Console", "Help", "Mock Link", "Debug", "Palette Test"]
        for (var i = 0; i < names.length; ++i) {
            if (name === names[i] || name === qsTranslate("SettingsPagesModel", names[i])) {
                return names[i]
            }
        }
        return String(name)
    }

    function _titleFor(name) {
        switch (_sourceName(name)) {
        case "General": return qsTr("General")
        case "Fly View": return qsTr("Fly View")
        case "Plan View": return qsTr("Plan View")
        case "Video": return qsTr("Video")
        case "Telemetry": return qsTr("Telemetry")
        case "ADSB Server": return qsTr("ADSB Server")
        case "Comm Links": return qsTr("Comm Links")
        case "Maps": return qsTr("Maps")
        case "PX4 Log Transfer": return qsTr("PX4 Log Transfer")
        case "Remote ID": return qsTr("Remote ID")
        case "Console": return qsTr("Console")
        case "Help": return qsTr("Help")
        case "Mock Link": return qsTr("Mock Link")
        case "Debug": return qsTr("Debug")
        case "Palette Test": return qsTr("Palette Test")
        default: return String(name)
        }
    }

    function _descFor(name) {
        switch (_sourceName(name)) {
        case "General": return qsTr("Language, interface and common paths")
        case "Fly View": return qsTr("Flight display, toolbar and map tracking")
        case "Plan View": return qsTr("Mission planning, uploads and files")
        case "Video": return qsTr("Video source, display and recording")
        case "Telemetry": return qsTr("MAVLink and telemetry logging")
        case "ADSB Server": return qsTr("ADSB SBS server connection")
        case "Comm Links": return qsTr("Serial, UDP and TCP connections")
        case "Maps": return qsTr("Map providers, types and cache")
        case "PX4 Log Transfer": return qsTr("Flight controller log download and management")
        case "Remote ID": return qsTr("Remote identification settings")
        case "Console": return qsTr("Application messages and output")
        case "Help": return qsTr("Version, documentation and support")
        case "Mock Link": return qsTr("Simulated links for debugging")
        case "Debug": return qsTr("Debugging tools and diagnostics")
        case "Palette Test": return qsTr("Palette test page")
        default: return ""
        }
    }

    function _selectPage(index, url) {
        selectedIndex = index
        selectedUrl = String(url)
    }

    WheelHandler {
        target: null
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(event) { event.accepted = true }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        propagateComposedEvents: false
    }

    component NavItem: Rectangle {
        id: navItem
        property string title: ""
        property string pageUrl: ""
        property int pageIndex: 0
        property bool pageVisibleState: true
        readonly property bool selected: root.selectedIndex === pageIndex

        width: parent ? parent.width : 0
        height: pageVisibleState ? Math.round((root.compactLayout ? 42 : 48) * root.pageScale) : 0
        visible: pageVisibleState
        radius: 6
        color: selected ? root.blueColor : (navMouse.containsMouse ? root.hoverColor : "transparent")

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Math.round((root.compactLayout ? 8 : 14) * root.pageScale)
            anchors.rightMargin: Math.round((root.compactLayout ? 8 : 12) * root.pageScale)
            spacing: Math.round((root.compactLayout ? 6 : 10) * root.pageScale)

            Text {
                text: "•"
                font.pixelSize: Math.max(14, Math.round(18 * root.pageScale))
                font.weight: Font.Bold
                color: selected ? "#ffffff" : Qt.rgba(root.brandColor.r, root.brandColor.g, root.brandColor.b, root.pageDark ? 0.55 : 0.35)
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: navItem.title
                font.pixelSize: Math.max(12, Math.round((root.compactLayout ? 13 : 15) * root.pageScale))
                font.weight: selected ? Font.Bold : Font.Medium
                color: selected ? "#ffffff" : root.textColor
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root._selectPage(navItem.pageIndex, navItem.pageUrl)
        }
    }

    Row {
        anchors.fill: parent

        Rectangle {
            width: root.navWidth
            height: parent.height
            color: root.navColor

            Rectangle {
                anchors.right: parent.right
                width: 1
                height: parent.height
                color: root.lineColor
            }

            Column {
                anchors.fill: parent
                anchors.margins: Math.round((root.compactLayout ? 10 : 18) * root.pageScale)
                spacing: Math.round((root.compactLayout ? 10 : 14) * root.pageScale)

                Rectangle {
                    width: parent.width
                    height: Math.round(48 * root.pageScale)
                    radius: Math.round(8 * root.pageScale)
                    color: backMouse.containsMouse ? root.hoverColor : root.bgColor
                    border.width: 1
                    border.color: root.lineColor

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Back")
                        font.pixelSize: Math.max(12, Math.round(15 * root.pageScale))
                        color: root.pageDark ? "#E6E6F0" : root.brandColor
                    }

                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }

                Text {
                    text: qsTr("System Settings")
                    font.pixelSize: Math.max(16, Math.round((root.compactLayout ? 18 : 22) * root.pageScale))
                    font.weight: Font.Bold
                    color: root.textColor
                }

                Flickable {
                    width: parent.width
                    height: parent.height - y
                    contentWidth: width
                    contentHeight: navColumn.implicitHeight
                    clip: true

                    Column {
                        id: navColumn
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: settingsPagesModel

                            NavItem {
                                title: root._titleFor(name)
                                pageUrl: url
                                pageIndex: index
                                pageVisibleState: pageVisible()
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width - root.navWidth
            height: parent.height
            color: root.bgColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Math.round((root.compactLayout ? 12 : 24) * root.pageScale)
                spacing: Math.round((root.compactLayout ? 10 : 16) * root.pageScale)

                Column {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: {
                            var item = settingsPagesModel.get(root.selectedIndex)
                            return item ? root._titleFor(item.name) : qsTr("General")
                        }
                        font.pixelSize: Math.max(20, Math.round(24 * root.pageScale))
                        font.weight: Font.Bold
                        color: root.textColor
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: {
                            var item = settingsPagesModel.get(root.selectedIndex)
                            return item ? root._descFor(item.name) : ""
                        }
                        font.pixelSize: Math.max(12, Math.round(14 * root.pageScale))
                        color: root.subTextColor
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 0
                    radius: Math.round(10 * root.pageScale)
                    color: root.cardColor
                    border.width: 1
                    border.color: root.lineColor
                    clip: true

                    // Original settings pages own their scrolling. Give them the
                    // actual viewport instead of nesting a second Flickable.
                    Loader {
                        id: originalSettingsLoader
                        anchors.fill: parent
                        anchors.margins: Math.round((root.compactLayout ? 4 : 16) * root.pageScale)
                        source: root.selectedUrl
                    }
                }
            }
        }
    }
}
