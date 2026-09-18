import QtQuick 2.15

Item {
    width: 2 * radius
    height: 2 * radius

    required property double radius
    property double turnRate: 0
    property double slipSkid: 0

    QfiCustomImage {
        anchors.fill: parent
        source: "QmlFlightInstruments/Images/tc/tc_back.svg"
    }

    QfiCustomImage {
        id: ball
        anchors.fill: parent
        source: "QmlFlightInstruments/Images/tc/tc_ball.svg"
        transform: Rotation {
            origin.x: 0.5 * ball.width
            origin.y: -36 / 240 * ball.height
            axis {
                x: 0
                y: 0
                z: 1
            }
            angle: slipSkid
        }
    }

    QfiCustomImage {
        anchors.fill: parent
        source: "QmlFlightInstruments/Images/tc/tc_face_1.svg"
    }

    QfiCustomImage {
        anchors.fill: parent
        source: "QmlFlightInstruments/Images/tc/tc_face_2.svg"
    }

    QfiCustomImage {
        anchors.fill: parent
        source: "QmlFlightInstruments/Images/tc/tc_mark.svg"
        rotation: (turnRate / 3.0) * 20.0
    }

    QfiCustomImage {
        anchors.fill: parent
        source: "QmlFlightInstruments/Images/tc/tc_case.svg"
    }
}
