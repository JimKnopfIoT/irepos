.pragma library

// Days are "YYYY-MM-DD" on the local clock.

function _two(number) {
    return (number < 10 ? "0" : "") + number
}

function stamp(date) {
    return date.getFullYear() + "-" + _two(date.getMonth() + 1)
            + "-" + _two(date.getDate())
}

// Noon, so a summer-time change cannot shift the date.
function parse(day) {
    var parts = String(day).split("-")
    return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]), 12)
}

function today() {
    return stamp(new Date())
}

function dayBack(back) {
    var at = new Date()
    at.setDate(at.getDate() - back)
    return stamp(at)
}

// First day of `months` calendar months ending today; a missing 31st becomes the month's last day.
function monthsBack(months) {
    var now = new Date()
    var year = now.getFullYear()
    var month = now.getMonth() - months
    while (month < 0) {
        month += 12
        year -= 1
    }
    var last = new Date(year, month + 1, 0).getDate()
    var at = new Date(year, month, Math.min(now.getDate(), last))
    at.setDate(at.getDate() + 1)
    return stamp(at)
}

// Every day from `from` to `to`, both included; counted in UTC so DST cannot drop a day.
function calendar(from, to) {
    var out = []
    var at = Date.parse(from + "T00:00:00Z")
    var end = Date.parse(to + "T00:00:00Z")
    if (isNaN(at) || isNaN(end)) {
        return out
    }
    while (at <= end && out.length < 4000) {
        var date = new Date(at)
        out.push(date.getUTCFullYear() + "-" + _two(date.getUTCMonth() + 1)
                 + "-" + _two(date.getUTCDate()))
        at += 86400000
    }
    return out
}

// The day itself, its week's Monday, its month or its year.
function unitKey(day, unit) {
    if (unit === "month") {
        return day.substring(0, 7)
    }
    if (unit === "year") {
        return day.substring(0, 4)
    }
    if (unit === "week") {
        var at = new Date(Date.parse(day + "T00:00:00Z"))
        at.setUTCDate(at.getUTCDate() - (at.getUTCDay() + 6) % 7)
        return at.toISOString().substring(0, 10)
    }
    return day
}
