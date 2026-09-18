import QtQuick 2.15

Item {
    width: 2 * radius
    height: 2 * radius

    required property double radius
    property double heading: 0

    QfiCustomImage {
        anchors.fill: parent
        source: "QmlFlightInstruments/Images/hi/hi_face.svg"
        rotation: -heading
    }

    QfiCustomImage {
        anchors.fill: parent
        source: "QmlFlightInstruments/Images/hi/hi_case.svg"
    }
}
