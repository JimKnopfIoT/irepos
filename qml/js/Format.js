.pragma library

// 1234 → "1.234".
function count(number) {
    var text = String(Math.round(number))
    var out = ""
    for (var i = 0; i < text.length; ++i) {
        if (i > 0 && (text.length - i) % 3 === 0) {
            out += "."
        }
        out += text.charAt(i)
    }
    return out
}

// A round figure at or above `value`, never zero; close steps keep the tallest bar near the top.
function niceCeiling(value) {
    if (!(value > 0)) {
        return 1
    }
    var magnitude = Math.pow(10, Math.floor(Math.log(value) / Math.LN10))
    var steps = [1, 1.2, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10]
    for (var i = 0; i < steps.length; ++i) {
        if (value <= steps[i] * magnitude) {
            return steps[i] * magnitude
        }
    }
    return 10 * magnitude
}

// "+12", "±0", or a dash where nothing is known.
function growth(value) {
    if (value === null || value === undefined) {
        return "—"
    }
    return value > 0 ? ("+" + count(value)) : "±0"
}

// 71.6667 → "71,7", 4 → "4".
function decimal(value) {
    return String(Math.round(value * 10) / 10).replace(".", ",")
}

// Stars gained or lost: "+1", "+0,1", "−0,3", "±0".
function stars(value) {
    var tenths = Math.round(value * 10)
    if (tenths === 0) {
        return "±0"
    }
    return (tenths > 0 ? "+" : "\u2212") + decimal(Math.abs(tenths) / 10)
}

// "2026-09-04" → "04.09.2026".
function date(stamp) {
    var parts = String(stamp).split("-")
    return parts.length === 3 ? (parts[2] + "." + parts[1] + "." + parts[0])
                              : String(stamp)
}

// "04.09.–11.09.2026", the year once where both ends share it.
function range(from, to) {
    if (!to || from === to) {
        return date(from)
    }
    var first = String(from).split("-")
    var last = String(to).split("-")
    if (first.length === 3 && last.length === 3 && first[0] === last[0]) {
        return first[2] + "." + first[1] + ".–" + date(to)
    }
    return date(from) + "–" + date(to)
}

function day(seconds) {
    if (!seconds) {
        return "—"
    }
    return Qt.formatDate(new Date(seconds * 1000), "dd.MM.yyyy")
}
