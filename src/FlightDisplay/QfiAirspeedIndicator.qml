import QtQuick 2.15

Item {
    width: 2 * radius
    height: 2 * radius

    required property double radius
    property double airspeed: 0
    property double angle: 0

    onAirspeedChanged: update()

    function update() {
        angle = airspeed

        if (angle < 0.0) {
            angle = 0.0
        } else if (angle > 235.0) {
            angle = 235.0
        }

        if (angle < 40.0) {
            angle = 0.9 * angle
        } else if (angle < 70.0) {
            angle = 36.0 + 1.8 * (angle - 40.0)
        } else if (angle < 130.0) {
            angle = 90.0 + 2.0 * (angle - 70.0)
        } else if (angle < 160.0) {
            angle = 210.0 + 1.8 * (angle - 130.0)
        } else {
            angle = 264.0 + 1.2 * (angle - 160.0)
        }
    }

    QfiCustomImage {
        anchors.fill: parent
        source: "QmlFlightInstruments/Images/asi/asi_face.svg"
    }

    QfiCustomImage {
        anchors.fill: parent
        source: "QmlFlightInstruments/Images/asi/asi_case.svg"
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.245
        width: parent.width * 0.34
        height: parent.height * 0.08
        radius: height * 0.16
        color: "#171717"
        opacity: 0.94
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.44
        width: parent.width * 0.26
        height: parent.height * 0.11
        radius: height * 0.15
        color: "#171717"
        opacity: 0.92
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.555
        width: parent.width * 0.27
        height: parent.height * 0.07
        radius: height * 0.16
        color: "#171717"
        opacity: 0.94
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.445
        text: "m/s"
        color: "white"
        font.pixelSize: Math.round(parent.width * 0.075)
        font.bold: true
    }

    QfiCustomImage {
        anchors.fill: parent
        source: "QmlFlightInstruments/Images/asi/asi_hand.svg"
        rotation: angle
    }
}
