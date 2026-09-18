import QtQuick 2.15
import Qt5Compat.GraphicalEffects

Item {
    width: 2 * radius
    height: 2 * radius

    required property double radius
    property double roll: 0
    property double pitch: 0
    readonly property double maxPitch: 30
    readonly property double faceNativeSize: 620
    readonly property double faceScale: 0.84
    readonly property double pixelPerDegree: 3.0

    property double deltaFaceX: 0
    property double deltaFaceY: 0

    onRollChanged: update()
    onPitchChanged: update()
    Component.onCompleted: update()

    function update() {
        var tempPitch = pitch
        if (tempPitch < -maxPitch) {
            tempPitch = -maxPitch
        }
        if (tempPitch > maxPitch) {
            tempPitch = maxPitch
        }

        deltaFaceX = (face.width / faceNativeSize) * pixelPerDegree * tempPitch * Math.sin(Math.PI * roll / 180.0)
        deltaFaceY = (face.height / faceNativeSize) * pixelPerDegree * tempPitch * Math.cos(Math.PI * roll / 180.0)
    }

    QfiCustomImage {
        anchors.fill: parent
        source: "QmlFlightInstruments/Images/ai/ai_back.svg"
        rotation: -roll
    }

    Item {
        id: faceClip
        anchors.centerIn: parent
        width: parent.width * faceScale
        height: parent.height * faceScale
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: faceClip.width
                height: faceClip.height
                radius: width / 2
            }
        }

        QfiCustomImage {
            id: face
            anchors.fill: parent
            source: "QmlFlightInstruments/Images/ai/ai_face_extended.svg"

            transform: [
                Rotation {
                    origin.x: 0.5 * face.width
                    origin.y: 0.5 * face.height
                    axis {
                        x: 0
                        y: 0
                        z: 1
                    }
                    angle: -roll
                },

                Translate {
                    x: deltaFaceX
                    y: deltaFaceY
                }
            ]
        }
    }

    QfiCustomImage {
        anchors.fill: parent
        source: "QmlFlightInstruments/Images/ai/ai_ring.svg"
        rotation: -roll
    }

    QfiCustomImage {
        anchors.fill: parent
        source: "QmlFlightInstruments/Images/ai/ai_case.svg"
    }
}
