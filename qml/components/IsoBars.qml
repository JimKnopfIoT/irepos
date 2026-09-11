import QtQuick 2.0
import Sailfish.Silica 1.0
import "."
import "../js/Format.js" as Format

Canvas {
    id: chart

    // Store rows; reads title, downloads and slug.
    property var rows: []
    // Just under 1: rounding the axis up to a nice figure already leaves headroom.
    property real headroom: 0.98
    property int ticks: 4

    // slug is "" when the tap misses every block.
    signal tapped(string slug)

    // Layout of the last paint, kept for hit testing in slugAt().
    property real _left: 0
    property real _barWidth: 0
    property real _gap: 0
    property real _floor: 0
    property real _depth: 0

    height: Theme.itemSizeExtraLarge * 2.2
    // Pinned to the item size, or a shrinking Canvas shows a cut-off part of its old surface.
    canvasSize: Qt.size(width, height)
    canvasWindow: Qt.rect(0, 0, width, height)

    onRowsChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var context = getContext("2d")
        context.clearRect(0, 0, width, height)
        if (!rows || rows.length === 0) {
            return
        }

        var count = rows.length
        var tallest = 0
        for (var i = 0; i < count; ++i) {
            if (rows[i].downloads > tallest) {
                tallest = rows[i].downloads
            }
        }
        // At least one download per tick, or the labels would repeat (0, 1, 1, 1).
        var axisTop = Math.max(ticks, Format.niceCeiling(tallest / headroom))

        var font = Theme.fontSizeExtraSmall
        var face = "px \"" + Theme.fontFamily + "\""
        context.font = font + face

        var pad = Theme.paddingSmall
        var widest = 0
        for (var t = 1; t <= ticks; ++t) {
            var mark = context.measureText(Format.count(axisTop * t / ticks))
            if (mark.width > widest) {
                widest = mark.width
            }
        }
        var left = widest + 2 * pad
        if (left >= width) {
            return
        }

        var depth = Math.max(5, Math.round(width / 110))
        var floor = height - pad
        var span = width - left - pad - depth
        var gap = Math.max(2, Math.round(width / 260))
        var barWidth = (span - (count - 1) * gap) / count
        if (barWidth < 3) {
            return
        }

        // Figures are written across if the widest fits, else on end and shrunk to the column.
        var widestFigure = 0
        for (var n = 0; n < count; ++n) {
            var measured = context.measureText(Format.count(rows[n].downloads))
            if (measured.width > widestFigure) {
                widestFigure = measured.width
            }
        }
        // Fit against the pitch, not bar plus depth: the depth exceeds the gap.
        var pitch = barWidth + gap
        var across = widestFigure + 2 <= pitch
        var figureFont = across ? font
                                : Math.max(font * 0.6, Math.min(font, pitch))
        var top = pad + (across ? font * 1.2
                                : widestFigure * figureFont / font + pad)
        var room = floor - top - depth
        if (room <= 0) {
            return
        }
        var lift = room / axisTop

        chart._left = left
        chart._barWidth = barWidth
        chart._gap = gap
        chart._floor = floor
        chart._depth = depth

        // Grid lines on the back wall, shifted up by the block depth.
        context.strokeStyle = Tint.grid
        context.lineWidth = 1
        context.fillStyle = Theme.secondaryColor
        context.textAlign = "right"
        context.textBaseline = "middle"
        for (var step = 1; step <= ticks; ++step) {
            var at = Math.round(floor - room * step / ticks - depth) + 0.5
            context.beginPath()
            context.moveTo(left + depth, at)
            context.lineTo(width - pad, at)
            context.stroke()
            context.fillText(Format.count(axisTop * step / ticks), left - pad, at)
        }

        for (var index = 0; index < count; ++index) {
            var row = rows[index]
            // At least 3 px, so an app with few downloads still shows.
            var barHeight = Math.max(3, row.downloads * lift)
            var bar = left + index * (barWidth + gap)
            var head = floor - barHeight
            var pitch = tallest > 0 ? row.downloads / tallest : 0
            var base = Qt.darker(Tint.forName(row.title), 1 + pitch * 0.7)

            // front
            context.fillStyle = Qt.darker(base, 1.15)
            context.fillRect(bar, head, barWidth, barHeight)
            // right side, sheared upwards
            context.fillStyle = Qt.darker(base, 1.7)
            context.beginPath()
            context.moveTo(bar + barWidth, head)
            context.lineTo(bar + barWidth + depth, head - depth)
            context.lineTo(bar + barWidth + depth, head - depth + barHeight)
            context.lineTo(bar + barWidth, head + barHeight)
            context.closePath()
            context.fill()
            // top
            context.fillStyle = Qt.lighter(base, 1.12)
            context.beginPath()
            context.moveTo(bar, head)
            context.lineTo(bar + depth, head - depth)
            context.lineTo(bar + barWidth + depth, head - depth)
            context.lineTo(bar + barWidth, head)
            context.closePath()
            context.fill()
        }

        for (var name = 0; name < count; ++name) {
            var written = Format.count(rows[name].downloads)
            var high = Math.max(3, rows[name].downloads * lift)
            var middle = left + name * (barWidth + gap) + (barWidth + depth) / 2
            var above = floor - high - depth - 2
            context.fillStyle = Tint.forName(rows[name].title)
            if (across) {
                context.textAlign = "center"
                context.textBaseline = "bottom"
                context.fillText(written, middle, above)
                continue
            }
            context.save()
            context.font = figureFont + face
            context.translate(middle, above)
            context.rotate(-Math.PI / 2)
            context.textAlign = "left"
            context.textBaseline = "middle"
            context.fillText(written, 0, 0)
            context.restore()
        }

        context.strokeStyle = Tint.grid
        context.beginPath()
        context.moveTo(left, floor + 0.5)
        context.lineTo(width - pad, floor + 0.5)
        context.stroke()
    }

    // Hit test by column only, so a short block need not be hit exactly.
    function slugAt(x, y) {
        if (!rows || rows.length === 0 || _barWidth <= 0) {
            return ""
        }
        var step = _barWidth + _gap
        var at = Math.floor((x - _left) / step)
        if (at < 0 || at >= rows.length) {
            return ""
        }
        // Not in the gap between two of them, and not below the ground.
        if (x - _left - at * step > _barWidth + _depth || y > _floor) {
            return ""
        }
        return rows[at].slug || ""
    }

    MouseArea {
        anchors.fill: parent
        onClicked: chart.tapped(chart.slugAt(mouse.x, mouse.y))
    }
}
