// FlyViewMap.qml
import QtQuick
import QtLocation
import QtPositioning

Item {
    id: root

    property var state: null
    property var theme: null

    Plugin {
        id: mapPlugin
        name: "osm"
        PluginParameter { name: "osm.mapping.cache.directory"; value: Qt.resolvedUrl("./map_cache") }
        PluginParameter { name: "osm.mapping.cache.disk.size"; value: "500" }
    }

    Map {
        id: map
        anchors.fill: parent
        plugin: mapPlugin
        center: QtPositioning.coordinate(23.3054, 113.6846)
        zoomLevel: 15
        copyrightsVisible: false

        activeMapType: {
            for (var i = 0; i < supportedMapTypes.length; i++) {
                if (supportedMapTypes[i].style === MapType.SatelliteMapDay)
                    return supportedMapTypes[i]
            }
            return supportedMapTypes[0]
        }

        // ── 拖动平移 ──
        DragHandler {
            id: dragHandler
            target: null
            onTranslationChanged: {
                var dx = translation.x - (previousTranslation ? previousTranslation.x : translation.x)
                var dy = translation.y - (previousTranslation ? previousTranslation.y : translation.y)
                map.pan(-dx, -dy)
                previousTranslation = translation
            }
            property var previousTranslation: null
            onActiveChanged: if (!active) previousTranslation = null
        }

        // ── 滚轮缩放 ──
        WheelHandler {
            id: wheelHandler
            target: null
            onWheel: function(event) {
                var delta = event.angleDelta.y
                if (delta > 0)
                    map.zoomLevel = Math.min(map.maximumZoomLevel, map.zoomLevel + 0.5)
                else
                    map.zoomLevel = Math.max(map.minimumZoomLevel, map.zoomLevel - 0.5)
            }
        }

        // ── 双指捏合缩放（触屏）──
        PinchHandler {
            id: pinchHandler
            target: null
            property real startZoom: map.zoomLevel
            onActiveChanged: if (active) startZoom = map.zoomLevel
            onScaleChanged: {
                map.zoomLevel = Math.max(map.minimumZoomLevel,
                                Math.min(map.maximumZoomLevel,
                                         startZoom + Math.log2(activeScale)))
            }
        }

        // 航点
        MapItemView {
            model: ListModel {
                ListElement { wpLat: 23.3060; wpLon: 113.6840; wpName: "WP01" }
                ListElement { wpLat: 23.3066; wpLon: 113.6850; wpName: "WP02" }
                ListElement { wpLat: 23.3061; wpLon: 113.6860; wpName: "WP03" }
                ListElement { wpLat: 23.3054; wpLon: 113.6846; wpName: "HOME" }
            }
            delegate: MapQuickItem {
                coordinate: QtPositioning.coordinate(model.wpLat, model.wpLon)
                anchorPoint.x: 10; anchorPoint.y: 10
                sourceItem: Rectangle {
                    width: 60; height: 22; radius: 4
                    color: root.theme ? root.theme.surface : "#fff"
                    border.color: root.theme ? root.theme.blueBorder : "#000066"
                    border.width: 1
                    Text {
                        anchors.centerIn: parent; text: model.wpName
                        font.pixelSize: 10; font.weight: Font.Medium
                        color: root.theme ? root.theme.blue : "#000066"
                    }
                }
            }
        }

        // 飞机图标
        MapQuickItem {
            coordinate: QtPositioning.coordinate(23.3054, 113.6846)
            anchorPoint.x: 12; anchorPoint.y: 12
            sourceItem: Text {
                text: "✈"; font.pixelSize: 22
                color: root.theme ? root.theme.blue : "#000066"
                rotation: root.state ? root.state.heading : 0
            }
        }
    }

    // 坐标信息栏
    Rectangle {
        anchors.top: parent.top; anchors.right: parent.right
        anchors.topMargin: 8; anchors.rightMargin: 8
        height: 28; radius: 6
        color: root.theme ? root.theme.overlaySurface : Qt.rgba(1,1,1,0.85)
        border.color: root.theme ? root.theme.border : "#e4e8ed"
        border.width: 1
        implicitWidth: _cr.implicitWidth + 24
        Row {
            id: _cr; anchors.centerIn: parent; spacing: 8
            Text { text: "23.3054°N  113.6846°E"; font.pixelSize: 11; color: root.theme ? root.theme.text2 : "#5a6272" }
            Rectangle { width: 1; height: 14; color: root.theme ? root.theme.border : "#e4e8ed"; anchors.verticalCenter: parent.verticalCenter }
            Text { text: qsTr("Altitude 87m"); font.pixelSize: 11; color: root.theme ? root.theme.text2 : "#5a6272" }
            Rectangle { width: 1; height: 14; color: root.theme ? root.theme.border : "#e4e8ed"; anchors.verticalCenter: parent.verticalCenter }
            Text { text: qsTr("Level ") + Math.round(map.zoomLevel); font.pixelSize: 11; color: root.theme ? root.theme.text3 : "#9aa3b2" }
        }
    }

    // 缩放按钮
    Column {
        anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.rightMargin: 12; anchors.bottomMargin: 12
        spacing: 4

        Repeater {
            model: ["+", "−"]
            delegate: Rectangle {
                width: 32; height: 32; radius: 6
                color: _ma.containsMouse ? (root.theme ? root.theme.blueL : "#E6E6F0") : (root.theme ? root.theme.overlaySurfaceStrong : Qt.rgba(1,1,1,0.9))
                border.color: root.theme ? root.theme.border : "#e4e8ed"
                border.width: 1
                Text { anchors.centerIn: parent; text: modelData; font.pixelSize: 18; font.weight: Font.Light; color: root.theme ? root.theme.text2 : "#5a6272" }
                MouseArea {
                    id: _ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (index === 0) map.zoomLevel = Math.min(map.maximumZoomLevel, map.zoomLevel + 1)
                        else            map.zoomLevel = Math.max(map.minimumZoomLevel, map.zoomLevel - 1)
                    }
                }
            }
        }
    }

    // 地图来源
    Text {
        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 4
        text: "© OpenStreetMap contributors"; font.pixelSize: 9
        color: Qt.rgba(0,0,0,0.35)
    }
}
