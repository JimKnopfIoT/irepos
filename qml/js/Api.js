.pragma library

// openrepos.net: the public app API, and the statistics pages a signed-in publisher may read.

var BASE = "https://openrepos.net"

// Qt keeps the session cookie in its own jar and never hands it over; this flag is the only handle.
var _session = false

function signedIn() {
    return _session
}

// A GET, or a POST where `body` is given.
function request(url, onDone, onFail, body) {
    var xhr = new XMLHttpRequest()
    xhr.open(body === undefined ? "GET" : "POST", url)
    xhr.setRequestHeader("User-Agent", "iRepos/1.0 (Sailfish OS)")
    if (body !== undefined) {
        xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
    }
    xhr.onreadystatechange = function () {
        if (xhr.readyState !== XMLHttpRequest.DONE) {
            return
        }
        // Status 0 means the request never got out: offline, DNS or TLS.
        if (xhr.status !== 200) {
            console.warn("iRepos: " + url + " → " + xhr.status)
            onFail(xhr.status === 0 ? "offline" : ("HTTP " + xhr.status))
            return
        }
        onDone(xhr.responseText)
    }
    xhr.send(body)
}

// The name as typed → the numeric user id and the slug the app URLs carry.
function publisher(name, onDone, onFail) {
    request(BASE + "/users/" + encodeURIComponent(name), function (html) {
        var id = /user\/(\d+)/.exec(html)
        var slug = /about="\/users\/([^"]+)"/.exec(html)
        if (!id) {
            onFail("no such publisher")
            return
        }
        onDone({
            "userId": id[1],
            // The profile page appends "#me" to the same attribute.
            "owner": slug ? slug[1].split("#")[0].split("?")[0] : name.toLowerCase()
        })
    }, onFail)
}

// Every app of one publisher as { owner, slug }, over as many listed pages as there are.
function slugs(userId, onDone, onFail) {
    var found = []
    var seen = {}
    function page(index) {
        var suffix = index === 0 ? "" : ("?page=0%2C" + index)
        request(BASE + "/user/" + userId + "/programs" + suffix, function (html) {
            var pattern = /href="\/content\/([^\/"#?]+)\/([^"#?]+)"/g
            var match, fresh = 0
            while ((match = pattern.exec(html)) !== null) {
                var owner = match[1], slug = match[2]
                // The site's own about page.
                if (owner === "basil") {
                    continue
                }
                if (!seen[owner + "/" + slug]) {
                    seen[owner + "/" + slug] = true
                    found.push({ "owner": owner, "slug": slug })
                    fresh += 1
                }
            }
            var more = html.indexOf('title="Go to next page"') >= 0
            if (more && fresh > 0 && index < 20) {
                page(index + 1)
                return
            }
            if (found.length === 0) {
                onFail("no apps listed")
                return
            }
            onDone(found)
        }, onFail)
    }
    page(0)
}

function appId(owner, slug, onDone, onFail) {
    request(BASE + "/content/" + owner + "/" + slug, function (html) {
        var match = /node\/(\d+)/.exec(html)
        if (!match) {
            onFail("no id for " + slug)
            return
        }
        onDone(match[1])
    }, onFail)
}

// "23,792" → 23792; parseInt alone stops at the comma.
function number(value) {
    var text = String(value === undefined || value === null ? "" : value)
            .replace(/,/g, "")
            .replace(/[^0-9.]/g, "")
    var parsed = parseFloat(text)
    return isNaN(parsed) ? 0 : Math.round(parsed)
}

function app(appId, onDone, onFail) {
    request(BASE + "/api/v1/apps/" + appId, function (text) {
        var data
        try {
            data = JSON.parse(text)
        } catch (error) {
            onFail("unreadable answer")
            return
        }
        var pkg = data["package"] || {}
        var built = data["packages"] || {}
        var rating = data["rating"] || {}
        // Sailfish first: that is the package this phone would install.
        var version = (built["sailfish"] || {}).version
                || pkg.version
                || (built["harmattan"] || {}).version
                || ""
        onDone({
            "appid": String(data.appid || appId),
            "title": data.title || "",
            "downloads": number(data.downloads),
            "version": version,
            "comments": number(data.comments_count),
            "rating": number(rating.rating),
            "votes": number(rating.count),
            "updated": number(data.updated)
        })
    }, onFail)
}

// One POST; the answer is the publisher's own page, which names who was let in.
function signIn(name, password, onDone, onFail) {
    var body = "name=" + encodeURIComponent(name)
            + "&pass=" + encodeURIComponent(password)
            + "&form_id=user_login"
            + "&op=" + encodeURIComponent("Log in")
    request(BASE + "/user", function (html) {
        if (html.indexOf("/user/logout") < 0) {
            _session = false
            onFail(_rejection(html))
            return
        }
        _session = true
        var uid = /\/user\/(\d+)\/edit/.exec(html)
        var slug = /about="\/users\/([^"#?]+)"/.exec(html)
        onDone({
            "userId": uid ? uid[1] : "",
            "owner": slug ? slug[1].split("#")[0].split("?")[0] : ""
        })
    }, function (reason) {
        _session = false
        onFail(reason)
    }, body)
}

function _rejection(html) {
    if (html.indexOf("unrecognized username or password") >= 0) {
        return "wrong name or password"
    }
    if (html.indexOf("temporarily blocked") >= 0) {
        return "too many attempts - wait, then try again"
    }
    return "sign-in refused"
}

function signOut(onDone) {
    _session = false
    request(BASE + "/user/logout", onDone, onDone)
}

// The Google Charts settings block, ended by counting braces outside quoted text.
function _charts(html) {
    var mark = html.indexOf("\"chart\":{")
    if (mark < 0) {
        return null
    }
    var start = mark + 8
    var depth = 0
    var quoted = false
    for (var i = start; i < html.length; ++i) {
        var letter = html.charAt(i)
        if (quoted) {
            if (letter === "\\") {
                i += 1
            } else if (letter === "\"") {
                quoted = false
            }
            continue
        }
        if (letter === "\"") {
            quoted = true
        } else if (letter === "{") {
            depth += 1
        } else if (letter === "}") {
            depth -= 1
            if (depth === 0) {
                try {
                    return JSON.parse(html.substring(start, i + 1))
                } catch (error) {
                    return null
                }
            }
        }
    }
    return null
}

// History, countries and the filter form's hidden fields of one statistics page.
function _parse(html) {
    var charts = _charts(html)
    var overall = charts ? charts["chartOverall"] : null
    if (!overall) {
        return null
    }
    var days = overall["header"] || []
    var totals = (overall["rows"] || [[]])[0] || []
    var history = []
    for (var d = 0; d < days.length; ++d) {
        history.push({ "day": String(days[d]), "downloads": number(totals[d]) })
    }
    var geo = charts["chartGeo"] || {}
    var names = geo["header"] || []
    var counts = (geo["rows"] || [[]])[0] || []
    var countries = []
    for (var c = 0; c < names.length; ++c) {
        countries.push({ "country": String(names[c]), "downloads": number(counts[c]) })
    }
    var form = html.substring(Math.max(0, html.indexOf('id="openrepos-stats-form"')))
    var build = /name="form_build_id" value="([^"]*)"/.exec(form)
    var token = /name="form_token" value="([^"]*)"/.exec(form)
    return {
        "history": history, "countries": countries,
        "form": { "build": build ? build[1] : "", "token": token ? token[1] : "" }
    }
}

// The page as the site shows it first (the last month); only the owner may read it.
function stats(appId, onDone, onFail) {
    request(BASE + "/node/" + appId + "/stats", function (html) {
        var parsed = _parse(html)
        if (!parsed) {
            onFail("no statistics for " + appId)
            return
        }
        onDone(parsed)
    }, onFail)
}

// "2026-09-05" → "05.09.2026", the format of the site's date picker.
function _siteDay(day) {
    var parts = String(day).split("-")
    return parts.length === 3 ? parts[2] + "." + parts[1] + "." + parts[0] : String(day)
}

// The statistics of `from`..`to`; the form token is per session, so one page's form serves every app.
function statsFor(appId, form, from, to, onDone, onFail) {
    var first = _siteDay(from)
    var body = "period_type=custom"
            + "&custom_from=" + encodeURIComponent(first)
            + "&custom_to=" + encodeURIComponent(_siteDay(to))
            + "&package=all&country=0&op=Filter&form_id=openrepos_stats_form"
            + "&form_build_id=" + encodeURIComponent(form.build)
            + "&form_token=" + encodeURIComponent(form.token)
    request(BASE + "/node/" + appId + "/stats", function (html) {
        var parsed = _parse(html)
        // A refused filter falls back to the default month; the echoed start day tells them apart.
        if (!parsed || html.indexOf('name="custom_from" value="' + first + '"') < 0) {
            onFail("filter refused")
            return
        }
        onDone(parsed)
    }, onFail, body)
}

function pageUrl(owner, slug) {
    return BASE + "/content/" + owner + "/" + slug
}
