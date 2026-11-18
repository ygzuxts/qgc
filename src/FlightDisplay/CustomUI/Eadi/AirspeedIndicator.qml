import QtQuick

Item {
    width: 300
    height: 300
    clip: false

    property double scaleRatio: 1

    property double airspeed: 0
    property double bugValue: 0
    property bool readingValid: true
    property bool bugVisible: false

    property double maximumAirspeed: 9999
    property double minimumAirspeed: 0
    property double tickmarkStepSize: 5
    property double labelStepSize: 10

    readonly property double pixelPerSpeed: 3

    readonly property int tickmarkCount: (maximumAirspeed - minimumAirspeed) / tickmarkStepSize
    readonly property int visibleTickmarkCount: 175 / (tickmarkStepSize * pixelPerSpeed)

    readonly property int labelCount: (maximumAirspeed - minimumAirspeed) / labelStepSize
    readonly property int visibleLabelCount: 175 / (labelStepSize * pixelPerSpeed)


    property double bugY: 0

    onAirspeedChanged: update()
    onReadingValidChanged: canvas.requestPaint()
    onBugValueChanged: update()

    function update() {

        let tempBugY = pixelPerSpeed * (airspeed - bugValue)

        if (tempBugY < -85.0)
            tempBugY = -85.0
        else if (tempBugY > 85.0)
            tempBugY = 85.0

        bugY = tempBugY

        canvas.requestPaint()
    }

    Canvas {
        id: canvas
        x: 25
        y: 37.5
        width: 40 * scaleRatio
        height: 175 * scaleRatio
        antialiasing: true
        clip: true
        scale: 1 / scaleRatio
        transformOrigin: Item.TopLeft

        onPaint: {
            var ctx = getContext('2d')
            ctx.reset()

            ctx.scale(scaleRatio, scaleRatio)

            ctx.fillStyle = "#343434"
            ctx.fillRect(0, 0, 36, 175)

            if (!readingValid) return
            ctx.translate(0, airspeed * pixelPerSpeed)

            var height = 175

            // White tickmarks
            {
                ctx.strokeStyle = "#ffffff"
                ctx.lineWidth = 1

                let lowestIndex = Math.round((airspeed - minimumAirspeed) / tickmarkStepSize - visibleTickmarkCount / 2)
                let highestIndex = Math.round(lowestIndex + visibleTickmarkCount)

                if (lowestIndex < 0)
                lowestIndex = 0

                for (var i = lowestIndex; i <= highestIndex; i++) {
                    ctx.beginPath()
                    let y = 0.5 * height - i * tickmarkStepSize * pixelPerSpeed
                    ctx.moveTo(30, y)
                    ctx.lineTo(36, y)
                    ctx.stroke()
                }
            }


            // Labels
            {
                ctx.font = "10px 'Open Sans'"
                ctx.textAlign = "right"
                ctx.textBaseline = 'middle'
                ctx.fillStyle = "#ffffff"

                let lowestIndex = Math.round((airspeed - minimumAirspeed) / labelStepSize - visibleLabelCount / 2)
                let highestIndex = Math.round(lowestIndex + visibleLabelCount)

                if (lowestIndex < 0)
                    lowestIndex = 0

                for (var i = lowestIndex; i <= highestIndex; i++) {
                    var valueString = i * labelStepSize
                    var x = 26
                    let y = 0.5 * height - i * labelStepSize * pixelPerSpeed

                    ctx.fillText(valueString.toFixed(0), x, y)
                }
            }

        }
    }

    CustomImage {
        id: bug
        visible: bugVisible
        x: 0
        y: 110
        width: 75
        source: "eadi_asi_bug.svg"
        sourceSize.width: 375
        sourceSize.height: 150
        transform: Translate {
            y: bugY
        }
    }

    CustomImage {
        id: frame
        x: 0
        y: 110
        width: 75
        source: "eadi_asi_frame.svg"
        sourceSize.height: 154
        sourceSize.width: 375
    }

    Text {
        x: 25
        y: 118
        width: 25
        height: 14
        text: readingValid ? airspeed.toFixed(0) : "—"
        font.family: "Open Sans"
        font.pixelSize: 12
        horizontalAlignment: Text.AlignRight
        color: "#ffffff"
        antialiasing: true
    }
}
