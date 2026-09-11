import QtQuick 2.0
import Sailfish.Silica 1.0
import "."
import "../js/World.js" as World

Item {
    id: map

    // [{ country, downloads }], empty unless signed in.
    property var countries: []

    // Keep off inside a flickable: both would take the same drags.
    property bool interactive: false

    property string highlight: ""
    property bool frameHighlight: false

    // Inhabited latitudes only: Tierra del Fuego to Svalbard, no Antarctica.
    readonly property real _south: -58
    readonly property real _north: 84

    // zoom 1 is the whole world; pan is the frame's top left in scaled pixels.
    property real zoom: 1
    property real panX: 0
    property real panY: 0
    readonly property real maxZoom: 8

    height: width * (_north - _south) / 360
    clip: true

    onZoomChanged: sheet.requestPaint()
    onPanXChanged: sheet.requestPaint()
    onPanYChanged: sheet.requestPaint()
    onCountriesChanged: sheet.requestPaint()
    onHighlightChanged: {
        sheet.requestPaint()
        if (frameHighlight) {
            frame(highlight)
        }
    }
    onWidthChanged: {
        sheet.requestPaint()
        if (frameHighlight) {
            frame(highlight)
        }
    }

    function frame(name) {
        var at = World.INDEX[name]
        if (at === undefined || width <= 0) {
            reset()
            return
        }
        var shape = World.SHAPES[at]
        var leastX = 1e9, mostX = -1e9, leastY = 1e9, mostY = -1e9
        for (var r = 0; r < shape.length; ++r) {
            var ring = shape[r]
            for (var t = 0; t < ring.length; t += 2) {
                if (ring[t] < leastX) { leastX = ring[t] }
                if (ring[t] > mostX) { mostX = ring[t] }
                if (ring[t + 1] < leastY) { leastY = ring[t + 1] }
                if (ring[t + 1] > mostY) { mostY = ring[t + 1] }
            }
        }
        var span = _north - _south
        var fromX = (leastX / World.SCALE + 180) / 360
        var toX = (mostX / World.SCALE + 180) / 360
        var fromY = (_north - mostY / World.SCALE) / span
        var toY = (_north - leastY / World.SCALE) / span
        var wide = Math.max(0.001, toX - fromX)
        var tall = Math.max(0.001, toY - fromY)
        // The country fills 60% of the frame, leaving neighbours for context.
        var next = 0.6 / Math.max(wide, tall)
        zoom = next < 1 ? 1 : (next > maxZoom ? maxZoom : next)
        panX = (fromX + toX) / 2 * width * zoom - width / 2
        panY = (fromY + toY) / 2 * height * zoom - height / 2
        hold()
    }

    // country is "" for sea or a country without downloads.
    signal tapped(string country)

    // Outline index -> name; where several names share an outline, the biggest wins.
    function _named() {
        var out = {}
        var best = {}
        for (var i = 0; i < countries.length; ++i) {
            var at = World.INDEX[countries[i].country]
            if (at === undefined) {
                continue
            }
            if (best[at] === undefined || countries[i].downloads > best[at]) {
                best[at] = countries[i].downloads
                out[at] = countries[i].country
            }
        }
        return out
    }

    // Screen to outline units; the inverse is inlined in onPaint for speed.
    function _lonAt(x) {
        return ((x + panX) / (width * zoom) * 360 - 180) * World.SCALE
    }
    function _latAt(y) {
        return (_north - (y + panY) / (height * zoom) * (_north - _south))
                * World.SCALE
    }

    // Even-odd ray casting.
    function _inside(ring, x, y) {
        var hit = false
        for (var i = 0, j = ring.length - 2; i < ring.length; j = i, i += 2) {
            var xi = ring[i], yi = ring[i + 1]
            var xj = ring[j], yj = ring[j + 1]
            if ((yi > y) !== (yj > y)
                    && x < (xj - xi) * (y - yi) / (yj - yi) + xi) {
                hit = !hit
            }
        }
        return hit
    }

    function countryAt(x, y) {
        var named = _named()
        var lon = _lonAt(x), lat = _latAt(y)
        var key
        for (key in named) {
            var outlines = World.SHAPES[key]
            for (var o = 0; o < outlines.length; ++o) {
                if (_inside(outlines[o], lon, lat)) {
                    return named[key]
                }
            }
        }

        // No direct hit: take the nearest within a finger's reach, tiny countries are narrower.
        var reach = Theme.itemSizeExtraSmall / 2
        var closest = "", best = reach * reach
        for (key in named) {
            var shape = World.SHAPES[key]
            var leastX = 1e9, mostX = -1e9, leastY = 1e9, mostY = -1e9
            for (var r = 0; r < shape.length; ++r) {
                var ring = shape[r]
                for (var t = 0; t < ring.length; t += 2) {
                    if (ring[t] < leastX) { leastX = ring[t] }
                    if (ring[t] > mostX) { mostX = ring[t] }
                    if (ring[t + 1] < leastY) { leastY = ring[t + 1] }
                    if (ring[t + 1] > mostY) { mostY = ring[t + 1] }
                }
            }
            var awayX = (lon - (leastX + mostX) / 2) / World.SCALE
            var awayY = (lat - (leastY + mostY) / 2) / World.SCALE
            awayX = awayX / 360 * width * zoom
            awayY = awayY / (_north - _south) * height * zoom
            var away = awayX * awayX + awayY * awayY
            if (away < best) {
                best = away
                closest = named[key]
            }
        }
        return closest
    }

    // Clamps the pan so the frame never leaves the picture.
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

    Canvas {
      id: sheet

      anchors.fill: parent
      // Pinned to the item size, or a shrinking Canvas keeps its old surface and shows a cut-off part.
      canvasSize: Qt.size(width, height)
      canvasWindow: Qt.rect(0, 0, width, height)

      onWidthChanged: requestPaint()
      onHeightChanged: requestPaint()

      onPaint: {
        var context = getContext("2d")
        context.clearRect(0, 0, width, height)

        // Summed per outline: several reported names can map to one country.
        var weight = {}
        var most = 0
        for (var i = 0; i < countries.length; ++i) {
            var at = World.INDEX[countries[i].country]
            if (at === undefined) {
                continue
            }
            weight[at] = (weight[at] || 0) + countries[i].downloads
            if (weight[at] > most) {
                most = weight[at]
            }
        }

        var scale = World.SCALE
        var span = map._north - map._south
        var wide = width * map.zoom
        var tall = height * map.zoom
        function px(x) {
            return (x / scale + 180) / 360 * wide - map.panX
        }
        function py(y) {
            return (map._north - y / scale) / span * tall - map.panY
        }

        var empty = Qt.rgba(1, 1, 1, 0.06)
        var lit = map.highlight.length > 0 ? World.INDEX[map.highlight] : undefined
        context.lineWidth = 1

        for (var c = 0; c < World.SHAPES.length; ++c) {
            var outlines = World.SHAPES[c]
            var value = weight[c] || 0
            // Log scale: one country dominates, so a linear one would leave the rest blank.
            var share = (value > 0 && most > 0)
                    ? Math.log(1 + value) / Math.log(1 + most)
                    : -1
            var shade = share >= 0 ? Tint.heat(share) : empty
            context.fillStyle = shade
            // Darker edge: a light one would make small countries look brighter than they are.
            context.strokeStyle = share >= 0 ? Qt.darker(shade, 1.6)
                                             : Tint.grid

            for (var o = 0; o < outlines.length; ++o) {
                var ring = outlines[o]

                // Skip rings wholly below the sheet (Antarctica would smear) or outside the frame.
                var top = -900
                var leastX = 1e9, mostX = -1e9, leastY = 1e9, mostY = -1e9
                for (var t = 0; t < ring.length; t += 2) {
                    if (ring[t + 1] > top) {
                        top = ring[t + 1]
                    }
                    var atX = px(ring[t]), atY = py(ring[t + 1])
                    if (atX < leastX) { leastX = atX }
                    if (atX > mostX) { mostX = atX }
                    if (atY < leastY) { leastY = atY }
                    if (atY > mostY) { mostY = atY }
                }
                if (top < map._south * scale) {
                    continue
                }
                if (mostX < 0 || leastX > width || mostY < 0 || leastY > height) {
                    continue
                }

                context.beginPath()
                context.moveTo(px(ring[0]), py(ring[1]))
                for (var p = 2; p < ring.length; p += 2) {
                    context.lineTo(px(ring[p]), py(ring[p + 1]))
                }
                context.closePath()
                context.fill()
                context.stroke()

                if (lit !== undefined && c === lit) {
                    context.save()
                    context.lineWidth = 3
                    context.strokeStyle = Theme.highlightColor
                    context.stroke()
                    context.restore()
                }
            }
        }
      }
    }

    PinchArea {
        anchors.fill: parent
        enabled: map.interactive

        property real fromZoom: 1
        property real fromPanX: 0
        property real fromPanY: 0

        onPinchStarted: {
            fromZoom = map.zoom
            fromPanX = map.panX
            fromPanY = map.panY
        }
        onPinchUpdated: {
            var next = fromZoom * pinch.scale
            next = next < 1 ? 1 : (next > map.maxZoom ? map.maxZoom : next)
            // Keep the point under the fingers fixed while zooming.
            map.panX = (fromPanX + pinch.startCenter.x) * next / fromZoom
                       - pinch.center.x
            map.panY = (fromPanY + pinch.startCenter.y) * next / fromZoom
                       - pinch.center.y
            map.zoom = next
            map.hold()
        }

        // One area for pan and tap: with two, the one on top would eat the other's gesture.
        MouseArea {
            anchors.fill: parent
            // Steal only when zoomed in: at full view the drag belongs to the page's scroll.
            preventStealing: map.interactive && map.zoom > 1

            property real lastX: 0
            property real lastY: 0
            property bool shifted: false

            onPressed: {
                lastX = mouse.x
                lastY = mouse.y
                shifted = false
            }
            onPositionChanged: {
                if (!map.interactive || map.zoom <= 1) {
                    return
                }
                map.panX -= mouse.x - lastX
                map.panY -= mouse.y - lastY
                lastX = mouse.x
                lastY = mouse.y
                shifted = true
                map.hold()
            }
            onClicked: {
                if (!shifted) {
                    map.tapped(map.countryAt(mouse.x, mouse.y))
                }
            }
            onDoubleClicked: {
                if (map.interactive) {
                    map.reset()
                }
            }
        }
    }
}
