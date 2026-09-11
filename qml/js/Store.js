.pragma library
.import QtQuick.LocalStorage 2.0 as Sql
.import "Dates.js" as Dates

// The history: one row per app and day, in the app's own offline store.

var _db = null

function db() {
    if (_db === null) {
        _db = Sql.LocalStorage.openDatabaseSync("iRepos", "1.0",
                                                "OpenRepos download history",
                                                200000)
        _db.transaction(function (tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS day ("
                          + "slug TEXT, day TEXT, appid TEXT, title TEXT, "
                          + "downloads INTEGER, version TEXT, comments INTEGER, "
                          + "rating INTEGER, votes INTEGER, updated INTEGER, "
                          + "PRIMARY KEY (slug, day))")
            tx.executeSql("CREATE TABLE IF NOT EXISTS ids (slug TEXT PRIMARY KEY, appid TEXT)")
            tx.executeSql("CREATE TABLE IF NOT EXISTS country ("
                          + "slug TEXT, country TEXT, downloads INTEGER, "
                          + "PRIMARY KEY (slug, country))")
        })
    }
    return _db
}

function _all(sql, params, shape) {
    var out = []
    db().readTransaction(function (tx) {
        var rows = tx.executeSql(sql, params || []).rows
        for (var i = 0; i < rows.length; ++i) {
            out.push(shape(rows.item(i)))
        }
    })
    return out
}

// A second run on the same day replaces the row.
function put(slug, record) {
    db().transaction(function (tx) {
        tx.executeSql("INSERT OR REPLACE INTO day VALUES (?,?,?,?,?,?,?,?,?,?)",
                      [slug, Dates.today(), record.appid, record.title, record.downloads,
                       record.version, record.comments, record.rating,
                       record.votes, record.updated])
    })
}

// Only the figure where the day exists, so today's full row keeps its version and rating.
function putHistory(slug, record, points) {
    db().transaction(function (tx) {
        for (var i = 0; i < points.length; ++i) {
            tx.executeSql(
                "INSERT OR IGNORE INTO day (slug, day, appid, title, downloads, "
                + "version, comments, rating, votes, updated) "
                + "VALUES (?,?,?,?,?,'',0,0,0,0)",
                [slug, points[i].day, record.appid, record.title,
                 points[i].downloads])
            tx.executeSql("UPDATE day SET downloads = ? WHERE slug = ? AND day = ?",
                          [points[i].downloads, slug, points[i].day])
        }
    })
}

// Replaced whole: a country that dropped off the site's list drops off here too.
function putCountries(slug, list) {
    db().transaction(function (tx) {
        tx.executeSql("DELETE FROM country WHERE slug = ?", [slug])
        for (var i = 0; i < list.length; ++i) {
            tx.executeSql("INSERT OR REPLACE INTO country VALUES (?,?,?)",
                          [slug, list[i].country, list[i].downloads])
        }
    })
}

function rememberId(slug, appId) {
    db().transaction(function (tx) {
        tx.executeSql("INSERT OR REPLACE INTO ids VALUES (?,?)", [slug, appId])
    })
}

function knownId(slug) {
    var found = _all("SELECT appid FROM ids WHERE slug = ?", [slug],
                     function (row) { return row.appid })
    return found.length > 0 ? found[0] : ""
}

function firstDay() {
    var found = _all("SELECT MIN(day) AS first FROM day", [],
                     function (row) { return row.first || "" })
    return found.length > 0 ? found[0] : ""
}

function dayCount() {
    return _all("SELECT COUNT(DISTINCT day) AS n FROM day", [],
                function (row) { return row.n })[0]
}

// The newest row per app, most downloads first.
function latest() {
    return _all("SELECT d.* FROM day d JOIN (SELECT slug, MAX(day) AS day FROM day "
                + "GROUP BY slug) m ON d.slug = m.slug AND d.day = m.day "
                + "ORDER BY d.downloads DESC", [], function (row) {
        return {
            "slug": row.slug, "day": row.day, "appid": row.appid,
            "title": row.title, "downloads": row.downloads,
            "version": row.version, "comments": row.comments,
            "rating": row.rating, "votes": row.votes, "updated": row.updated
        }
    })
}

function totalDownloads() {
    var sum = 0
    var rows = latest()
    for (var i = 0; i < rows.length; ++i) {
        sum += rows[i].downloads
    }
    return sum
}

// Every running total as { slug: { day: downloads } }.
function cells() {
    var out = {}
    db().readTransaction(function (tx) {
        var rows = tx.executeSql("SELECT slug, day, downloads FROM day").rows
        for (var i = 0; i < rows.length; ++i) {
            var row = rows.item(i)
            if (!out[row.slug]) {
                out[row.slug] = {}
            }
            out[row.slug][row.day] = row.downloads
        }
    })
    return out
}

// { slug: gain } over `from`..`to`; nothing before counts as zero, nothing up to `to` leaves the app out.
function gains(from, to) {
    var out = {}
    var rows = _all("SELECT s.slug AS slug, "
                    + "(SELECT downloads FROM day b WHERE b.slug = s.slug AND b.day < ? "
                    + " ORDER BY b.day DESC LIMIT 1) AS base, "
                    + "(SELECT downloads FROM day e WHERE e.slug = s.slug AND e.day <= ? "
                    + " ORDER BY e.day DESC LIMIT 1) AS upto "
                    + "FROM (SELECT DISTINCT slug FROM day) s",
                    [from || "", to || Dates.today()],
                    function (row) { return row })
    for (var i = 0; i < rows.length; ++i) {
        if (rows[i].upto === null || rows[i].upto === undefined) {
            continue
        }
        var base = (rows[i].base === null || rows[i].base === undefined) ? 0 : rows[i].base
        out[rows[i].slug] = Math.max(0, rows[i].upto - base)
    }
    return out
}

function curve(slug) {
    return _all("SELECT day, downloads FROM day WHERE slug = ? ORDER BY day", [slug],
                function (row) { return { "day": row.day, "downloads": row.downloads } })
}

// Every app's countries since always as { slug: [{ country, downloads }] }, biggest first.
function countryTable() {
    var out = {}
    db().readTransaction(function (tx) {
        var rows = tx.executeSql("SELECT slug, country, downloads FROM country "
                                 + "ORDER BY downloads DESC").rows
        for (var i = 0; i < rows.length; ++i) {
            var row = rows.item(i)
            if (!out[row.slug]) {
                out[row.slug] = []
            }
            out[row.slug].push({ "country": row.country, "downloads": row.downloads })
        }
    })
    return out
}
