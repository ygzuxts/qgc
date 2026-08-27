// SectionTitle.qml
// 面板分区标题，全局复用

import QtQuick

Item {
    id: root
    property string text:  ""
    property var    theme: null

    width:  parent ? parent.width : 100
    height: theme ? theme.sectionH : 36

    Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: theme ? theme.spacingXl : 16
        text: root.text.toUpperCase()
        font.pixelSize: theme ? theme.fontSm : 11
        font.weight: Font.DemiBold
        font.letterSpacing: 0.8
        color: root.theme ? root.theme.text3 : "#9aa3b2"
    }
}
