// PageSettings.qml  换皮系统设置页：导航换皮，内容复用 QGC 原版设置页
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.AppSettings
import QGroundControl.Palette

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
    readonly property real navWidth: Math.max(220, Math.min(270, root.width * 0.22))

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

    function _titleFor(name) {
        switch (String(name)) {
        case "General": return "通用"
        case "Fly View": return "飞行界面"
        case "Plan View": return "任务规划"
        case "Video": return "视频"
        case "Telemetry": return "遥测"
        case "ADSB Server": return "ADSB 服务"
        case "Comm Links": return "通信链路"
        case "Maps": return "地图"
        case "PX4 Log Transfer": return "PX4 日志传输"
        case "Remote ID": return "远程识别"
        case "Console": return "控制台"
        case "Help": return "帮助"
        case "Mock Link": return "模拟链路"
        case "Debug": return "调试"
        case "Palette Test": return "调色板测试"
        default: return String(name)
        }
    }

    function _descFor(name) {
        switch (String(name)) {
        case "General": return "语言、界面和常用路径"
        case "Fly View": return "飞行界面显示、工具栏和地图跟随设置"
        case "Plan View": return "规划、上传和任务文件设置"
        case "Video": return "视频源、显示和录制设置"
        case "Telemetry": return "MAVLink 和遥测保存设置"
        case "ADSB Server": return "ADSB SBS 服务器连接设置"
        case "Comm Links": return "串口、UDP、TCP 通信连接"
        case "Maps": return "地图源、地图类型和缓存设置"
        case "PX4 Log Transfer": return "飞控日志下载和管理"
        case "Remote ID": return "远程识别信息设置"
        case "Console": return "应用消息和运行输出"
        case "Help": return "版本、文档和支持信息"
        case "Mock Link": return "调试用模拟链路"
        case "Debug": return "调试工具和诊断"
        case "Palette Test": return "调色板测试页面"
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
        height: pageVisibleState ? 48 : 0
        visible: pageVisibleState
        radius: 6
        color: selected ? root.blueColor : (navMouse.containsMouse ? root.hoverColor : "transparent")

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 12
            spacing: 10

            Text {
                text: "•"
                font.pixelSize: 18
                font.weight: Font.Bold
                color: selected ? "#ffffff" : Qt.rgba(root.brandColor.r, root.brandColor.g, root.brandColor.b, root.pageDark ? 0.55 : 0.35)
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: navItem.title
                font.pixelSize: 15
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
                anchors.margins: 18
                spacing: 14

                Rectangle {
                    width: parent.width
                    height: 48
                    radius: 8
                    color: backMouse.containsMouse ? root.hoverColor : root.bgColor
                    border.width: 1
                    border.color: root.lineColor

                    Text {
                        anchors.centerIn: parent
                        text: "返回"
                        font.pixelSize: 15
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
                    text: "系统设置"
                    font.pixelSize: 22
                    font.weight: Font.Bold
                    color: root.textColor
                }

                Text {
                    width: parent.width
                    text: "原版 QGC 设置项，当前页面只更换外观容器。"
                    font.pixelSize: 12
                    color: root.subTextColor
                    wrapMode: Text.WordWrap
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

            Column {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                Column {
                    width: parent.width
                    spacing: 6

                    Text {
                        text: {
                            var item = settingsPagesModel.get(root.selectedIndex)
                            return item ? root._titleFor(item.name) : "通用"
                        }
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        color: root.textColor
                    }

                    Text {
                        text: {
                            var item = settingsPagesModel.get(root.selectedIndex)
                            return item ? root._descFor(item.name) : ""
                        }
                        font.pixelSize: 14
                        color: root.subTextColor
                    }
                }

                Rectangle {
                    width: parent.width
                    height: parent.height - 58
                    radius: 10
                    color: root.cardColor
                    border.width: 1
                    border.color: root.lineColor
                    clip: true

                    Loader {
                        id: originalSettingsLoader
                        anchors.fill: parent
                        anchors.margins: 16
                        source: root.selectedUrl
                    }
                }
            }
        }
    }
}
