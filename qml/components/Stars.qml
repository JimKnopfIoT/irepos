import QtQuick 2.0

Canvas {
    id: stars

    property real rating: 0
    property color color: "white"
    property color emptyColor: Qt.rgba(1, 1, 1, 0.25)
    property real gap: Math.round(height * 0.15)

    width: 5 * height + 4 * gap

    onRatingChanged: requestPaint()
    onColorChanged: requestPaint()
    onEmptyColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function outline(ctx, left, size) {
        var cx = left + size / 2
        var cy = size * 0.53
        var outer = size / 2
        var inner = outer * 0.45
        ctx.beginPath()
        for (var i = 0; i < 10; ++i) {
            var radius = i % 2 === 0 ? outer : inner
            var angle = -Math.PI / 2 + i * Math.PI / 5
            var x = cx + radius * Math.cos(angle)
            var y = cy + radius * Math.sin(angle)
            if (i === 0) {
                ctx.moveTo(x, y)
            } else {
                ctx.lineTo(x, y)
            }
        }
        ctx.closePath()
    }

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        var size = height
        // The store gives percent; 100 % is five full stars.
        var filled = Math.max(0, Math.min(5, rating / 20))
        for (var i = 0; i < 5; ++i) {
            var left = i * (size + gap)
            outline(ctx, left, size)
            ctx.fillStyle = emptyColor
            ctx.fill()
            var share = Math.max(0, Math.min(1, filled - i))
            if (share > 0) {
                ctx.save()
                ctx.beginPath()
                ctx.rect(left, 0, size * share, size)
                ctx.clip()
                outline(ctx, left, size)
                ctx.fillStyle = color
                ctx.fill()
                ctx.restore()
            }
        }
    }
}
