// FlyViewRightPanel.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property var state: null
    property var theme: null
    property int currentTab: 0
    property var openCustomPlanShell: null
    property real backgroundOpacity: 1.0

    readonly property color _baseBackgroundColor: theme ? theme.surface : "#ffffff"
    color: Qt.rgba(_baseBackgroundColor.r, _baseBackgroundColor.g, _baseBackgroundColor.b, backgroundOpacity)

    WheelHandler {
        target: null
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(event) {
            event.accepted = true
        }
    }

    Rectangle {
        anchors.left: parent.left
        width: 1
        height: parent.height
        color: root.theme ? root.theme.border : "#e4e8ed"
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: theme ? theme.controlHLg + theme.spacingMd : 46
            color: "transparent"

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: root.theme ? root.theme.border : "#e4e8ed"
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: theme ? theme.spacingLg : 14
                anchors.verticalCenter: parent.verticalCenter
                text: "起降"
                font.pixelSize: theme ? theme.fontXl : 18
                font.weight: Font.DemiBold
                color: root.theme ? root.theme.text : "#111827"
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: takeoffPage.implicitHeight
            flickableDirection: Flickable.VerticalFlick
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            PageTakeoff {
                id: takeoffPage
                width: parent.width
                state: root.state
                theme: root.theme
            }
        }
    }
}
