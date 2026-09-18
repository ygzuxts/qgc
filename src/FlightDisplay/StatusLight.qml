import QtQuick 2.15

import QGroundControl.FlightDisplay

Column {
    id: root

    property string label: ""
    property color accent: textLo
    property color textLo: "#64748b"
    property bool compactLandscape: false
    property bool lightMode: true
    readonly property bool activeLamp: accent !== FlightPalette.statusOff

    width: compactLandscape ? 84 : 98
    spacing: compactLandscape ? 4 : 6

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.compactLandscape ? 30 : 38
        height: width
        radius: width / 2
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#4A4A4C" }
            GradientStop { position: 0.48; color: "#18181A" }
            GradientStop { position: 1.0; color: "#050506" }
        }
        border.color: Qt.rgba(1, 1, 1, 0.20)
        border.width: 2

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 8
            height: width
            radius: width / 2
            opacity: root.activeLamp ? 1.0 : 0.42
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.activeLamp ? Qt.lighter(root.accent, 1.55) : "#3C3C3E" }
                GradientStop { position: 0.45; color: root.activeLamp ? root.accent : "#171719" }
                GradientStop { position: 1.0; color: root.activeLamp ? Qt.darker(root.accent, 1.75) : "#050506" }
            }
            border.color: Qt.rgba(1, 1, 1, root.activeLamp ? 0.38 : 0.10)
        }

        Rectangle {
            x: parent.width * 0.27
            y: parent.height * 0.18
            width: parent.width * 0.22
            height: parent.height * 0.11
            radius: height / 2
            color: Qt.rgba(1, 1, 1, root.activeLamp ? 0.62 : 0.18)
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 18
            height: width
            radius: width / 2
            color: root.activeLamp ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22) : "transparent"
            z: -1
        }
    }

    Text {
        z: 2
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        text: root.label
        color: root.activeLamp ? FlightPalette.textHi : root.textLo
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideNone
        wrapMode: Text.NoWrap
        font.family: FlightPalette.cockpitFont
        font.pixelSize: root.compactLandscape ? 9 : 10
        font.bold: true
    }
}
