import QtQuick 2.0
import Sailfish.Silica 1.0
import "."
import "../js/Format.js" as Format

// Downloads per app and column as blocks on an isometric floor: columns run right, apps run back.
Item {
    id: chart

    // Chart.grid output; a null value draws no block.
    property var history: ({ "days": [], "ends": [], "series": [] })
    property int ticks: 4
    // Scale on the left and dates along the front; the per-app figures on the right are always drawn.
    property bool axes: false
    // Just under 1: rounding the axis up already leaves headroom.
    property real headroom: 0.98
    // Pinch and drag; off where the surrounding view needs the drags.
    property bool interactive: false

    property real zoom: 1
    property real panX: 0
    property real panY: 0
    readonly property real maxZoom: 6

    height: Theme.itemSizeExtraLarge * 2.2
    clip: true

    onHistoryChanged: sheet.requestPaint()
    onAxesChanged: sheet.requestPaint()
    onWidthChanged: sheet.requestPaint()
    onHeightChanged: sheet.requestPaint()
    onZoomChanged: sheet.requestPaint()
    onPanXChanged: sheet.requestPaint()
    onPanYChanged: sheet.requestPaint()

    // slug is "" when the tap misses every block.
    signal tapped(string slug)

    // Layout of the last paint, kept for hit testing.
    property real _originX: 0
    property real _originY: 0
    property real _side: 0
    property real _stepU: 0
    property real _stepV: 0
    property real _lift: 0
    readonly property real _inset: 0.12
    // cos 30° and sin 30°.
    readonly property real _cos: 0.8660254
    readonly property real _sin: 0.5

    function _inHull(hull, x, y) {
        var hit = false
        for (var i = 0, j = hull.length - 2; i < hull.length; j = i, i += 2) {
            var xi = hull[i], yi = hull[i + 1]
            var xj = hull[j], yj = hull[j + 1]
            if ((yi > y) !== (yj > y)
                    && x < (xj - xi) * (y - yi) / (yj - yi) + xi) {
                hit = !hit
            }
        }
        return hit
    }

    // Tests each block's six-cornered outline, front to back.
    function slugAt(x, y) {
        var days = (history && history.days) || []
        var series = (history && history.series) || []
        if (days.length === 0 || series.length === 0 || _side <= 0) {
            return ""
        }
        var scale = zoom
        function px(u, v) {
            return (_originX + (u - v) * _cos) * scale - panX
        }
        function py(u, v, z) {
            return (_originY + (u + v) * _sin - z) * scale - panY
        }
        for (var deep = days.length + series.length - 2; deep >= 0; --deep) {
            for (var ix = 0; ix < days.length; ++ix) {
                var iy = deep - ix
                if (iy < 0 || iy >= series.length) {
                    continue
                }
                var value = (series[iy].values || [])[ix]
                if (value === null || value === undefined || value <= 0) {
                    continue
                }
                var u0 = (ix + _inset) * _stepU
                var u1 = (ix + 1 - _inset) * _stepU
                var v0 = (iy + _inset) * _stepV
                var v1 = (iy + 1 - _inset) * _stepV
                var high = value * _lift
                if (_inHull([px(u0, v0), py(u0, v0, high),
                             px(u1, v0), py(u1, v0, high),
                             px(u1, v0), py(u1, v0, 0),
                             px(u1, v1), py(u1, v1, 0),
                             px(u0, v1), py(u0, v1, 0),
                             px(u0, v1), py(u0, v1, high)], x, y)) {
                    return series[iy].slug || ""
                }
            }
        }
        return ""
    }

    function hold() {
        var mostX = width * (zoom - 1)
        var mostY = height * (zoom - 1)
        panX = panX < 0 ? 0 : (panX > mostX ? mostX : panX)
        panY = panY < 0 ? 0 : (panY > mostY ? mostY : panY)
    }

    function reset() {
        zoom = 1
        panX = 0
        panY = 0
    }

    // "2026-09-07" → "07.09.".
    function _shortDay(day) {
        var parts = String(day).split("-")
        return parts.length === 3 ? (parts[2] + "." + parts[1] + ".") : String(day)
    }

    Canvas {
      id: sheet

      anchors.fill: parent
      // Pinned to the item size, or a shrinking Canvas shows a cut-off part of its old surface.
      canvasSize: Qt.size(width, height)
      canvasWindow: Qt.rect(0, 0, width, height)

      onWidthChanged: requestPaint()
      onHeightChanged: requestPaint()

      onPaint: {
        var context = getContext("2d")
        context.clearRect(0, 0, width, height)

        var days = (history && history.days) || []
        var ends = (history && history.ends) || []
        var series = (history && history.series) || []
        if (days.length === 0 || series.length === 0) {
            return
        }

        var tallest = 0
        for (var s = 0; s < series.length; ++s) {
            var own = series[s].values || []
            for (var d = 0; d < own.length; ++d) {
                if (own[d] > tallest) {
                    tallest = own[d]
                }
            }
        }
        // At least one download per tick, or the labels would repeat (0, 1, 1, 1).
        var axisTop = Math.max(ticks, Format.niceCeiling(tallest / headroom))

        var font = Theme.fontSizeExtraSmall
        var face = "px \"" + Theme.fontFamily + "\""
        context.font = font + face

        var pad = Theme.paddingSmall
        var top = pad
        var bottom = axes ? font * 2.0 : pad
        var left = pad
        if (axes && tallest > 0) {
            var widest = 0
            for (var t = 1; t <= ticks; ++t) {
                var mark = context.measureText(Format.count(axisTop * t / ticks))
                if (mark.width > widest) {
                    widest = mark.width
                }
            }
            left = widest + 2 * pad
        }
        var widestTotal = 0
        for (var w = 0; w < series.length; ++w) {
            var run = context.measureText(Format.count(series[w].total || 0))
            if (run.width > widestTotal) {
                widestTotal = run.width
            }
        }
        var right = widestTotal + 2 * pad
        var usable = width - left - right

        // The floor stays square; its projection is always √3 wide for every 1 it is tall.
        var side = Math.min(usable / (2 * _cos), (height - top - bottom) * 0.66)
        var room = height - top - bottom - side
        if (side <= 0 || room <= 0) {
            return
        }

        var originX = left + usable / 2
        var originY = height - bottom - side
        var stepU = side / days.length
        var stepV = side / series.length
        var lift = room / axisTop

        chart._originX = originX
        chart._originY = originY
        chart._side = side
        chart._stepU = stepU
        chart._stepV = stepV
        chart._lift = lift

        var scale = chart.zoom
        function px(u, v) {
            return (originX + (u - v) * _cos) * scale - chart.panX
        }
        function py(u, v, z) {
            return (originY + (u + v) * _sin - z) * scale - chart.panY
        }
        function face4(corners, fill, stroke) {
            context.beginPath()
            context.moveTo(corners[0], corners[1])
            for (var i = 2; i < corners.length; i += 2) {
                context.lineTo(corners[i], corners[i + 1])
            }
            context.closePath()
            if (fill) {
                context.fillStyle = fill
                context.fill()
            }
            if (stroke) {
                context.strokeStyle = stroke
                context.stroke()
            }
        }
        function line(fromX, fromY, toX, toY) {
            context.beginPath()
            context.moveTo(fromX, fromY)
            context.lineTo(toX, toY)
            context.stroke()
        }

        context.lineWidth = 1

        face4([px(0, 0), py(0, 0, 0),
               px(side, 0), py(side, 0, 0),
               px(side, 0), py(side, 0, room),
               px(0, 0), py(0, 0, room)], Tint.paneRight, "")
        face4([px(0, 0), py(0, 0, 0),
               px(0, side), py(0, side, 0),
               px(0, side), py(0, side, room),
               px(0, 0), py(0, 0, room)], Tint.paneLeft, "")
        face4([px(0, 0), py(0, 0, 0),
               px(side, 0), py(side, 0, 0),
               px(side, side), py(side, side, 0),
               px(0, side), py(0, side, 0)], Tint.ground, "")

        context.strokeStyle = Tint.grid

        for (var tick = 1; tick <= ticks; ++tick) {
            var z = room * tick / ticks
            line(px(side, 0), py(side, 0, z), px(0, 0), py(0, 0, z))
            line(px(0, 0), py(0, 0, z), px(0, side), py(0, side, z))
        }

        // Floor grid only where cells are wide enough not to read as hatching.
        if (stepU * scale > 8) {
            for (var gu = 1; gu < days.length; ++gu) {
                line(px(gu * stepU, 0), py(gu * stepU, 0, 0),
                     px(gu * stepU, side), py(gu * stepU, side, 0))
            }
        }
        if (stepV * scale > 8) {
            for (var gv = 1; gv < series.length; ++gv) {
                line(px(0, gv * stepV), py(0, gv * stepV, 0),
                     px(side, gv * stepV), py(side, gv * stepV, 0))
            }
        }

        line(px(0, 0), py(0, 0, 0), px(0, 0), py(0, 0, room))
        line(px(side, 0), py(side, 0, 0), px(side, 0), py(side, 0, room))
        line(px(0, side), py(0, side, 0), px(0, side), py(0, side, room))

        // Painting in order of column + row index is all the hidden-surface removal this angle needs.
        var inset = _inset
        var outlined = stepU * scale > 10 && stepV * scale > 10
        for (var depth = 0; depth <= days.length + series.length - 2; ++depth) {
            for (var ix = 0; ix < days.length; ++ix) {
                var iy = depth - ix
                if (iy < 0 || iy >= series.length) {
                    continue
                }
                var value = (series[iy].values || [])[ix]
                if (value === null || value === undefined || value <= 0) {
                    continue
                }

                var u0 = (ix + inset) * stepU
                var u1 = (ix + 1 - inset) * stepU
                var v0 = (iy + inset) * stepV
                var v1 = (iy + 1 - inset) * stepV
                var high = value * lift
                var pitch = tallest > 0 ? value / tallest : 0
                var base = Qt.darker(Tint.forName(series[iy].title), 1 + pitch * 0.7)
                var edge = outlined ? Qt.darker(base, 2.2) : ""

                face4([px(u1, v0), py(u1, v0, high),
                       px(u1, v1), py(u1, v1, high),
                       px(u1, v1), py(u1, v1, 0),
                       px(u1, v0), py(u1, v0, 0)], Qt.darker(base, 1.6), edge)
                face4([px(u0, v1), py(u0, v1, high),
                       px(u1, v1), py(u1, v1, high),
                       px(u1, v1), py(u1, v1, 0),
                       px(u0, v1), py(u0, v1, 0)], base, edge)
                face4([px(u0, v0), py(u0, v0, high),
                       px(u1, v0), py(u1, v0, high),
                       px(u1, v1), py(u1, v1, high),
                       px(u0, v1), py(u0, v1, high)], Qt.lighter(base, 1.2), edge)
            }
        }

        // Each app's figure for the period beside its row, shrunk to the row spacing and kept in the frame.
        var rowGap = stepV * _sin * scale
        var rowFont = Math.min(font, Math.max(font * 0.45, rowGap * 0.9))
        context.font = rowFont + face
        context.textAlign = "left"
        context.textBaseline = "middle"
        for (var name = 0; name < series.length; ++name) {
            var at = (name + 0.5) * stepV
            var figure = Format.count(series[name].total || 0)
            var x = Math.min(px(side, at) + pad * _cos,
                             width - context.measureText(figure).width - 2)
            context.fillStyle = Tint.forName(series[name].title)
            context.fillText(figure, x, py(side, at, 0) + pad * _sin)
        }
        context.font = font + face

        if (!axes) {
            return
        }

        context.strokeStyle = Tint.grid
        context.fillStyle = Theme.secondaryColor
        context.textAlign = "right"
        context.textBaseline = "middle"
        for (var step = 1; tallest > 0 && step <= ticks; ++step) {
            var markZ = room * step / ticks
            var markX = px(0, side)
            var markY = py(0, side, markZ)
            line(markX, markY, markX - pad, markY)
            context.fillText(Format.count(axisTop * step / ticks), markX - pad - 2, markY)
        }

        // First and last day of the period under the two front corners.
        context.textBaseline = "top"
        context.textAlign = "center"
        context.fillText(_shortDay(days[0]), px(0, side), py(0, side, 0) + pad)
        var last = ends.length > 0 ? ends[ends.length - 1] : days[days.length - 1]
        if (last !== days[0]) {
            context.fillText(_shortDay(last), px(side, side), py(side, side, 0) + pad)
        }
      }
    }

    PinchArea {
        anchors.fill: parent
        enabled: chart.interactive

        property real fromZoom: 1
        property real fromPanX: 0
        property real fromPanY: 0

        onPinchStarted: {
            fromZoom = chart.zoom
            fromPanX = chart.panX
            fromPanY = chart.panY
        }
        onPinchUpdated: {
            var next = fromZoom * pinch.scale
            next = next < 1 ? 1 : (next > chart.maxZoom ? chart.maxZoom : next)
            // Keeps the point under the fingers where it is.
            chart.panX = (fromPanX + pinch.startCenter.x) * next / fromZoom
                         - pinch.center.x
            chart.panY = (fromPanY + pinch.startCenter.y) * next / fromZoom
                         - pinch.center.y
            chart.zoom = next
            chart.hold()
        }

        // One area for pan and tap: two would each eat the other's gesture.
        MouseArea {
            anchors.fill: parent
            // Steals the drag only when zoomed in, so the page still scrolls at full view.
            preventStealing: chart.interactive && chart.zoom > 1

            property real lastX: 0
            property real lastY: 0
            property bool shifted: false

            onPressed: {
                lastX = mouse.x
                lastY = mouse.y
                shifted = false
            }
            onPositionChanged: {
                if (!chart.interactive || chart.zoom <= 1) {
                    return
                }
                chart.panX -= mouse.x - lastX
                chart.panY -= mouse.y - lastY
                lastX = mouse.x
                lastY = mouse.y
                shifted = true
                chart.hold()
            }
            onClicked: {
                if (!shifted) {
                    chart.tapped(chart.slugAt(mouse.x, mouse.y))
                }
            }
            onDoubleClicked: {
                if (chart.interactive) {
                    chart.reset()
                }
            }
        }
    }
}
