import QtQuick
import QtQuick.Window

Window {
    id: window
    visible: true
    title:   "UAV GCS"
    minimumWidth:  640
    minimumHeight: 360
    width:  1280
    height: 720
    color:  "#000000"

    FlyViewCustomLayer {
        anchors.fill: parent
    }
}
