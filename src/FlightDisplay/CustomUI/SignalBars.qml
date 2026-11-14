// SignalBars.qml
// 信号强度柱状显示，可复用

import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    property string label:     qsTr("Up")
    property int    activeBars: 5
    property int    totalBars:  6
    property color  barColor:  "#16a34a"
    property string value:     ""
    property var    theme:     null

    spacing: 6

    Text {
        text: root.label
        font.pixelSize: 10
        color: root.theme ? root.theme.text3 : "#9aa3b2"
        Layout.preferredWidth: 20
        Layout.alignment: Qt.AlignBottom
    }

    Row {
        spacing: 3
        Layout.alignment: Qt.AlignBottom

        Repeater {
            model: root.totalBars
            delegate: Rectangle {
                width: 4
                height: (index + 1) * 3
                anchors.bottom: parent.bottom
                radius: 2
                color: index < root.activeBars
                       ? root.barColor
                       : (root.theme ? root.theme.border : "#e4e8ed")
                opacity: index < root.activeBars ? 0.85 : 1
            }
        }
    }

    Text {
        text: root.value
        font.pixelSize: 11
        font.weight: Font.Medium
        color: root.barColor
        Layout.alignment: Qt.AlignBottom
        visible: root.value !== ""
    }
}
