pragma Singleton
import QtQuick 2.0
import Sailfish.Silica 1.0

QtObject {
    readonly property color cyan:   "#19d2ff"
    readonly property color teal:   "#31e0a0"
    readonly property color green:  "#8ef94a"
    readonly property color amber:  "#ffb44a"
    readonly property color red:    "#ff5a52"
    readonly property color violet: "#b58cff"

    readonly property color ground:    Qt.rgba(1, 1, 1, 0.075)
    readonly property color paneRight: Qt.rgba(1, 1, 1, 0.05)
    readonly property color paneLeft:  Qt.rgba(1, 1, 1, 0.042)

    readonly property color panel:   Qt.rgba(1, 1, 1, 0.045)
    readonly property color panelHi: Qt.rgba(1, 1, 1, 0.09)
    readonly property color grid:    Qt.rgba(1, 1, 1, 0.07)

    readonly property var wheel: [cyan, teal, violet, amber, green, red]

    // Set by Figures via assign(): unique colours need every title known up front.
    property var _seat: ({})
    property int _seats: 0

    // Alphabetical, so an app keeps its colour when the ranking changes.
    function assign(titles) {
        var sorted = titles.slice().sort(function (a, b) {
            var left = String(a).toLowerCase(), right = String(b).toLowerCase()
            return left < right ? -1 : (left > right ? 1 : 0)
        })
        var seat = {}
        for (var i = 0; i < sorted.length; ++i) {
            seat[sorted[i]] = i
        }
        _seat = seat
        _seats = sorted.length
    }

    // Heat ramp for the map; via green, as violet to amber passes through a stray pink.
    readonly property var heatStops: [0.0, 0.35, 0.7, 1.0]
    readonly property var heatColours: [
        Qt.rgba(0.07, 0.255, 0.31, 1),
        Qt.rgba(cyan.r, cyan.g, cyan.b, 1),
        Qt.rgba(green.r, green.g, green.b, 1),
        Qt.rgba(amber.r, amber.g, amber.b, 1)
    ]

    function heat(share) {
        var at = share < 0 ? 0 : (share > 1 ? 1 : share)
        for (var i = 1; i < heatStops.length; ++i) {
            if (at <= heatStops[i]) {
                var low = heatColours[i - 1]
                var high = heatColours[i]
                var reach = heatStops[i] - heatStops[i - 1]
                var t = reach > 0 ? (at - heatStops[i - 1]) / reach : 0
                return Qt.rgba(low.r + (high.r - low.r) * t,
                               low.g + (high.g - low.g) * t,
                               low.b + (high.b - low.b) * t, 1)
            }
        }
        return heatColours[heatColours.length - 1]
    }

    // Even hues with alternating lightness; unassigned names hash into the accents.
    function forName(name) {
        var at = _seat[name]
        if (at !== undefined && _seats > 0) {
            return Qt.hsla(at / _seats, at % 2 === 0 ? 0.72 : 0.60,
                           at % 2 === 0 ? 0.63 : 0.54, 1)
        }
        var sum = 0
        for (var i = 0; i < name.length; ++i) {
            sum = (sum * 31 + name.charCodeAt(i)) % 100003
        }
        return wheel[sum % wheel.length]
    }

    // Never red: downloads cannot shrink.
    function growthColor(value) {
        return value > 0 ? green : Theme.secondaryColor
    }
}
