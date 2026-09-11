import QtQuick 2.0
import Sailfish.Silica 1.0
import "."

Canvas {
    id: curve

    // [{ day, downloads }], oldest first.
    property var points: []
    property color accent: Tint.cyan

    readonly property bool enoughDays: points && points.length >= 2

    height: Theme.itemSizeSmall
    onPointsChanged: requestPaint()
    onWidthChanged: requestPaint()
    onAccentChanged: requestPaint()

    onPaint: {
        var context = getContext("2d")
        context.clearRect(0, 0, width, height)
        if (!enoughDays) {
            return
        }
        var low = points[0].downloads
        var high = low
        for (var i = 1; i < points.length; ++i) {
            low = Math.min(low, points[i].downloads)
            high = Math.max(high, points[i].downloads)
        }
        var span = (high - low) || 1
        var step = width / (points.length - 1)
        var pad = 2

        function pointY(value) {
            return height - pad - (value - low) / span * (height - 2 * pad)
        }

        context.beginPath()
        context.moveTo(0, height)
        for (var index = 0; index < points.length; ++index) {
            context.lineTo(index * step, pointY(points[index].downloads))
        }
        context.lineTo(width, height)
        context.closePath()
        context.fillStyle = Qt.rgba(accent.r, accent.g, accent.b, 0.16)
        context.fill()

        context.beginPath()
        for (var again = 0; again < points.length; ++again) {
            var x = again * step
            var y = pointY(points[again].downloads)
            if (again === 0) {
                context.moveTo(x, y)
            } else {
                context.lineTo(x, y)
            }
        }
        context.strokeStyle = accent
        context.lineWidth = 2
        context.lineJoin = "round"
        context.stroke()
    }

    Label {
        anchors.centerIn: parent
        visible: !curve.enoughDays
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.secondaryColor
        text: qsTr("Curve from the second day")
    }
}
