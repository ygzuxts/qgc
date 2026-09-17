import QtQuick 2.15

Column {
    id: root

    property string label: ""
    property color accent: textLo
    property color textLo: "#64748b"
    property bool compactLandscape: false
    property bool lightMode: true

    // Keep mode names readable on narrow Android layouts instead of eliding them.
    width: compactLandscape ? 96 : 112
    spacing: compactLandscape ? 3 : 7

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.compactLandscape ? 20 : 26
        height: width
        radius: width / 2
        color: root.lightMode ? Qt.rgba(0.9, 0.94, 0.98, 0.92) : Qt.rgba(0.02, 0.04, 0.07, 0.92)
        border.color: root.lightMode ? Qt.rgba(0.38, 0.45, 0.55, 0.20) : Qt.rgba(1, 1, 1, 0.16)
        border.width: 1

        Rectangle {
            anchors.centerIn: parent
            width: root.compactLandscape ? 15 : 18
            height: width
            radius: width / 2
            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, root.lightMode ? 0.34 : 0.42)
        }

        Rectangle {
            anchors.centerIn: parent
            width: root.compactLandscape ? 12 : 14
            height: width
            radius: width / 2
            color: root.accent
            border.color: Qt.rgba(1, 1, 1, root.lightMode ? 0.60 : 0.34)
            border.width: 1
        }

        Rectangle {
            x: root.compactLandscape ? 7 : 8
            y: root.compactLandscape ? 5 : 6
            width: root.compactLandscape ? 5 : 6
            height: root.compactLandscape ? 3 : 4
            radius: 2
            color: Qt.rgba(1, 1, 1, root.lightMode ? 0.62 : 0.46)
        }

        Rectangle {
            anchors.centerIn: parent
            width: root.compactLandscape ? 26 : 34
            height: width
            radius: width / 2
            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, root.lightMode ? 0.16 : 0.22)
            z: -1
        }
    }

    Text {
        z: 2
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        text: root.label
        color: root.accent
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideNone
        wrapMode: Text.NoWrap
        font.pixelSize: root.compactLandscape ? 12 : 14
        font.bold: true
    }
}
