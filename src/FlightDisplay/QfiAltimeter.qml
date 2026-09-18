import QtQuick 2.15

Item {
    width: 2 * radius
    height: 2 * radius

    required property double radius
    property double altitude: 0
    property double pressure: 28
    readonly property double tenThousandFootNeedleRotation: 0.0036 * altitude
    readonly property double thousandFootNeedleRotation: 0.036 * altitude
    readonly property double hundredFootNeedleRotation: 0.36 * (altitude % 1000)

    QfiCustomImage {
        anchors.fill: parent
        source: "QmlFlightInstruments/Images/alt/alt_face_1.svg"
        rotation: {
            var value = pressure

            if (value < 28.0) {
                value = 28.0
            } else if (value > 31.5) {
                value = 31.5
            }

            return (value - 28.0) * 100.0
        }
    }

    QfiCustomImage {
        anchors.fill: parent
        source: "QmlFlightInstruments/Images/alt/alt_face_2.svg"
    }

    QfiCustomImage {
        anchors.fill: parent
        source: "QmlFlightInstruments/Images/alt/alt_face_3.svg"
        rotation: tenThousandFootNeedleRotation
    }

    QfiCustomImage {
        anchors.fill: parent
        source: "QmlFlightInstruments/Images/alt/alt_hand_1.svg"
        rotation: thousandFootNeedleRotation
    }

    QfiCustomImage {
        anchors.fill: parent
        source: "QmlFlightInstruments/Images/alt/alt_hand_2.svg"
        rotation: hundredFootNeedleRotation
    }

    QfiCustomImage {
        anchors.fill: parent
        source: "QmlFlightInstruments/Images/alt/alt_case.svg"
    }
}
