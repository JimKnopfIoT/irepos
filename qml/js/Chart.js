.pragma library
.import "Dates.js" as Dates

// Stored running totals turned into chart columns; no database access in here.

// Positions in `days`, grouped into runs of one calendar unit each.
function _runs(days, unit) {
    var runs = []
    var key = null
    for (var i = 0; i < days.length; ++i) {
        var own = Dates.unitKey(days[i], unit)
        if (own !== key) {
            runs.push({ "first": i, "last": i })
            key = own
        } else {
            runs[runs.length - 1].last = i
        }
    }
    return runs
}

// Downloads per app and column over `from`..`to`; a column is the finest unit that fits `maxColumns`.
function grid(apps, cells, maxColumns, from, to) {
    var empty = { "days": [], "ends": [], "unit": "day", "series": [] }
    if (apps.length === 0 || !from || !to) {
        return empty
    }
    var start = from > to ? to : from
    var days = Dates.calendar(start, to)
    if (days.length === 0) {
        return empty
    }

    var unit = "day"
    var runs = _runs(days, unit)
    var coarser = ["week", "month", "year"]
    for (var u = 0; maxColumns > 0 && runs.length > maxColumns
                    && u < coarser.length; ++u) {
        unit = coarser[u]
        runs = _runs(days, unit)
    }
    var firsts = []
    var lasts = []
    for (var r = 0; r < runs.length; ++r) {
        firsts.push(days[runs[r].first])
        lasts.push(days[runs[r].last])
    }

    var series = []
    for (var s = 0; s < apps.length; ++s) {
        var own = cells[apps[s].slug] || {}

        var before = null
        for (var key in own) {
            if (key < start && (before === null || key > before)) {
                before = key
            }
        }
        var carried = before === null ? null : own[before]
        var opening = carried === null ? 0 : carried

        // A day nobody fetched keeps the last known total.
        var running = []
        for (var f = 0; f < days.length; ++f) {
            if (own[days[f]] !== undefined) {
                carried = own[days[f]]
            }
            running.push(carried)
        }

        // Before an app's first figure a column is null; its first figure counts from zero, as in Store.gains.
        var values = []
        var sum = 0
        for (var v = 0; v < runs.length; ++v) {
            var now = running[runs[v].last]
            if (now === null) {
                values.push(null)
                continue
            }
            var was = runs[v].first > 0 ? running[runs[v].first - 1] : opening
            values.push(Math.max(0, now - (was === null ? 0 : was)))
            sum += values[v]
        }

        // `total` is what the period brought the app, the figure drawn beside its row.
        series.push({
            "slug": apps[s].slug, "title": apps[s].title,
            "total": sum, "values": values
        })
    }
    return { "days": firsts, "ends": lasts, "unit": unit, "series": series }
}

// { slug: [{ country, downloads }] } summed per country, biggest first.
function countryTotals(table) {
    var sums = {}
    for (var slug in table) {
        var list = table[slug] || []
        for (var i = 0; i < list.length; ++i) {
            if (list[i].downloads > 0) {
                sums[list[i].country] = (sums[list[i].country] || 0) + list[i].downloads
            }
        }
    }
    var out = []
    for (var country in sums) {
        out.push({ "country": country, "downloads": sums[country] })
    }
    out.sort(function (a, b) { return b.downloads - a.downloads })
    return out
}

// The apps downloaded in `country`, biggest first, titled from `rows`.
function appsIn(table, rows, country) {
    var out = []
    for (var i = 0; i < rows.length; ++i) {
        var list = table[rows[i].slug] || []
        for (var k = 0; k < list.length; ++k) {
            if (list[k].country === country && list[k].downloads > 0) {
                out.push({ "slug": rows[i].slug, "title": rows[i].title,
                           "downloads": list[k].downloads })
            }
        }
    }
    out.sort(function (a, b) { return b.downloads - a.downloads })
    return out
}

// The curve within `from`..`to`, starting at the last point before the period.
function curve(points, from, to) {
    if (!from) {
        return points
    }
    var out = []
    var before = null
    for (var i = 0; i < points.length; ++i) {
        if (points[i].day < from) {
            before = points[i]
        } else if (!to || points[i].day <= to) {
            out.push(points[i])
        }
    }
    if (before !== null) {
        out.unshift(before)
    }
    return out
}
