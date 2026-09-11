pragma Singleton
import QtQuick 2.0
import Nemo.Configuration 1.0
import "."
import "../js/Api.js" as Api
import "../js/Chart.js" as Chart
import "../js/Dates.js" as Dates
import "../js/Format.js" as Format
import "../js/Store.js" as Store

// Shared state, and the only thing that talks to the network.
QtObject {
    id: data

    property string userId: userIdSetting.value
    // Older versions stored "#me" behind the name.
    property string owner: String(ownerSetting.value).split("#")[0]
    readonly property bool configured: userId.length > 0 && owner.length > 0

    // The login itself is kept by `credentials` (src/credentials.cpp).
    property bool signedIn: false
    property bool signingIn: false
    readonly property string login: credentials.login
    readonly property bool canSignIn: credentials.stored

    property var rows: []
    // Countries of the period: per app, and summed over all of them.
    property var countryTable: ({})
    property var countries: []
    property bool fetchingCountries: false
    // Per run, keyed "from|to": the site answers any period, but slowly.
    property var _countryCache: ({})
    // The statistics filter form's hidden fields; valid for the whole session.
    property var _form: null
    property string firstDay: ""
    property int total: 0
    property int days: 0

    // "" is since always; otherwise "day", "week", "month" or "year" times periodCount, or "range".
    property string period: ""
    property int periodCount: 1
    property string fromDay: ""
    property string toDay: ""
    property string periodFrom: ""
    property string periodTo: ""
    readonly property string periodText: period === "range" ? Format.range(fromDay, toDay)
                                                            : unitText(period, periodCount)

    property var gains: ({})
    property var periodGain: null
    property int periodApps: 0
    property var periodRows: []
    property var history: ({ "days": [], "ends": [], "unit": "day", "series": [] })
    property var wholeHistory: ({ "days": [], "ends": [], "unit": "day", "series": [] })

    property bool busy: false
    property int done: 0
    property int expected: 0
    property string error: ""

    property QtObject _userIdSetting: ConfigurationValue {
        id: userIdSetting
        key: "/apps/irepos/userId"
        defaultValue: ""
    }

    property QtObject _ownerSetting: ConfigurationValue {
        id: ownerSetting
        key: "/apps/irepos/owner"
        defaultValue: ""
    }

    // The publisher as stored while the package was called harbour-irepos, read once to move it.
    property QtObject _oldUserIdSetting: ConfigurationValue {
        id: oldUserIdSetting
        key: "/apps/harbour-irepos/userId"
        defaultValue: ""
    }

    property QtObject _oldOwnerSetting: ConfigurationValue {
        id: oldOwnerSetting
        key: "/apps/harbour-irepos/owner"
        defaultValue: ""
    }

    // Plain-text login of 0.1.0-18 and older, only read to move it into `credentials`.
    property QtObject _loginSetting: ConfigurationValue {
        id: loginSetting
        key: "/apps/harbour-irepos/login"
        defaultValue: ""
    }

    property QtObject _secretSetting: ConfigurationValue {
        id: secretSetting
        key: "/apps/harbour-irepos/secret"
        defaultValue: ""
    }

    Component.onCompleted: {
        data._movePublisher()
        data._moveLogin()
    }

    function setPublisher(newUserId, newOwner) {
        userIdSetting.value = newUserId
        ownerSetting.value = newOwner
    }

    function findPublisher(name, onDone, onFail) {
        Api.publisher(name, function (found) {
            data.setPublisher(found.userId, found.owner)
            onDone(found.owner)
            data.refresh()
        }, onFail)
    }

    // onSettled(ok, publisher or reason, kept); the login is kept only once the site accepted it.
    function signIn(name, password, onSettled) {
        if (data.signingIn) {
            return
        }
        data.signingIn = true
        data.error = ""
        data._form = null
        Api.signIn(name, password, function (who) {
            data.signingIn = false
            data.signedIn = true
            var kept = credentials.store(name, password)
            if (who.userId.length > 0 && who.owner.length > 0) {
                data.setPublisher(who.userId, who.owner)
            }
            if (onSettled) {
                onSettled(true, who.owner, kept)
            }
            data.refresh()
        }, function (reason) {
            data.signingIn = false
            data.signedIn = false
            data.error = reason
            if (onSettled) {
                onSettled(false, reason)
            }
        })
    }

    function signOut() {
        credentials.forget()
        data.signedIn = false
        Api.signOut(function () {})
    }

    function _movePublisher() {
        var oldId = String(oldUserIdSetting.value)
        if (oldId.length === 0) {
            return
        }
        if (String(userIdSetting.value).length === 0) {
            data.setPublisher(oldId, String(oldOwnerSetting.value))
        }
        oldUserIdSetting.value = ""
        oldOwnerSetting.value = ""
    }

    // The plain copy is emptied only once the secrets storage has taken it.
    function _moveLogin() {
        var name = String(loginSetting.value)
        var password = String(secretSetting.value)
        if (password.length === 0) {
            return
        }
        if (!credentials.stored && name.length > 0
                && !credentials.store(name, password)) {
            return
        }
        secretSetting.value = ""
        loginSetting.value = ""
    }

    function unitText(unit, count) {
        switch (unit) {
        case "day":
            return qsTr("%n day(s)", "", count)
        case "week":
            return qsTr("%n week(s)", "", count)
        case "month":
            return qsTr("%n month(s)", "", count)
        case "year":
            return qsTr("%n year(s)", "", count)
        }
        return qsTr("since always")
    }

    function setPeriod(unit, count) {
        data.fromDay = ""
        data.toDay = ""
        data.periodCount = Math.max(1, count || 1)
        data.period = unit
        data.reload()
    }

    function setRange(from, until) {
        if (from > until) {
            var swap = from
            from = until
            until = swap
        }
        data.fromDay = from
        data.toDay = until
        data.period = "range"
        data.reload()
    }

    // Counted back from today with today in it: one week is today and the six days before.
    function _range() {
        var today = Dates.today()
        var n = Math.max(1, data.periodCount)
        switch (data.period) {
        case "day":
            return { "from": Dates.dayBack(n - 1), "to": today }
        case "week":
            return { "from": Dates.dayBack(7 * n - 1), "to": today }
        case "month":
            return { "from": Dates.monthsBack(n), "to": today }
        case "year":
            return { "from": Dates.monthsBack(12 * n), "to": today }
        case "range":
            return { "from": data.fromDay, "to": data.toDay }
        }
        return { "from": data.firstDay, "to": today }
    }

    function reload() {
        data.rows = Store.latest()
        var titles = []
        for (var i = 0; i < data.rows.length; ++i) {
            titles.push(data.rows[i].title)
        }
        // Before anything draws: colours are spread over all titles at once.
        Tint.assign(titles)
        data.firstDay = Store.firstDay()
        data.total = Store.totalDownloads()
        data.days = Store.dayCount()

        var range = data._range()
        data.periodFrom = range.from
        data.periodTo = range.to
        var cells = Store.cells()
        data.history = Chart.grid(data.rows.slice(0, 8), cells, 10, range.from, range.to)
        data.wholeHistory = Chart.grid(data.rows, cells, 31, range.from, range.to)
        data._showCountries(range.from, range.to)

        var gained = Store.gains(range.from, range.to)
        var sum = 0
        var known = false
        var active = 0
        var cut = []
        for (var r = 0; r < data.rows.length; ++r) {
            var row = data.rows[r]
            if (gained[row.slug] === undefined) {
                continue
            }
            sum += gained[row.slug]
            known = true
            if (gained[row.slug] > 0) {
                active += 1
            }
            cut.push({ "slug": row.slug, "title": row.title,
                       "downloads": gained[row.slug] })
        }
        cut.sort(function (a, b) { return b.downloads - a.downloads })
        data.gains = gained
        data.periodGain = known ? sum : null
        data.periodApps = active
        data.periodRows = cut
    }

    // Since always the stored totals; any other period's countries come from the site.
    function _showCountries(from, to) {
        var table = data.period === "" ? Store.countryTable()
                                       : data._countryCache[from + "|" + to]
        if (table === undefined) {
            table = {}
            data._fetchCountries(from, to)
        }
        data.countryTable = table
        data.countries = Chart.countryTotals(table)
    }

    function _fetchCountries(from, to) {
        if (!data.signedIn || data.busy || data.fetchingCountries) {
            return
        }
        data.fetchingCountries = true
        var table = {}
        var apps = data.rows.slice()
        function next(i) {
            if (i >= apps.length) {
                data._countryCache[from + "|" + to] = table
                data.fetchingCountries = false
                // The period may have changed meanwhile; that one is fetched next.
                data._showCountries(data.periodFrom, data.periodTo)
                return
            }
            var appId = Store.knownId(apps[i].slug)
            if (appId.length === 0) {
                next(i + 1)
                return
            }
            data._withForm(appId, function (form) {
                Api.statsFor(appId, form, from, to, function (result) {
                    table[apps[i].slug] = result.countries
                    next(i + 1)
                }, function (reason) {
                    data._lostForm(reason)
                    next(i + 1)
                })
            }, function () {
                next(i + 1)
            })
        }
        next(0)
    }

    function _withForm(appId, onForm, onFail) {
        if (data._form !== null) {
            onForm(data._form)
            return
        }
        Api.stats(appId, function (result) {
            data._form = result.form
            onForm(result.form)
        }, function (reason) {
            data._lostForm(reason)
            onFail(reason)
        })
    }

    // A lost session is reported once; the run goes on with public figures.
    function _lostForm(reason) {
        data._form = null
        if (reason === "HTTP 403") {
            data.signedIn = false
            data.error = "signed out"
        }
    }

    function refresh() {
        if (busy || !configured) {
            return
        }
        busy = true
        error = ""
        done = 0
        expected = 0
        data._countryCache = ({})

        // A refused sign-in still leaves every public figure to be had.
        if (!signedIn && canSignIn) {
            data._form = null
            Api.signIn(credentials.login, credentials.password(), function (who) {
                data.signedIn = true
                if (who.userId.length > 0 && who.owner.length > 0) {
                    data.setPublisher(who.userId, who.owner)
                }
                data._collect()
            }, function (reason) {
                data.signedIn = false
                data.error = reason
                data._collect()
            })
            return
        }
        data._collect()
    }

    function _collect() {
        Api.slugs(data.userId, function (slugs) {
            data.expected = slugs.length
            data._step(slugs, 0)
        }, function (reason) {
            data.error = reason
            data.busy = false
        })
    }

    // One app at a time, so somebody else's server gets no burst.
    function _step(slugs, index) {
        if (index >= slugs.length) {
            data.busy = false
            data.reload()
            return
        }
        var entry = slugs[index]
        var slug = entry.slug

        function onward(reason) {
            if (reason) {
                data.error = reason
            }
            data.done = index + 1
            if (data.done % 4 === 0) {
                data.reload()
            }
            data._step(slugs, index + 1)
        }

        function withId(appId) {
            Store.rememberId(slug, appId)
            Api.app(appId, function (record) {
                Store.put(slug, record)
                if (!data.signedIn) {
                    onward("")
                    return
                }
                // Filtered from 2010 on: unfiltered, the site shows only the last month.
                function fetchStats(retry) {
                    data._withForm(appId, function (form) {
                        Api.statsFor(appId, form, "2010-01-01", Dates.today(), function (extra) {
                            Store.putHistory(slug, record, extra.history)
                            Store.putCountries(slug, extra.countries)
                            onward("")
                        }, function (reason) {
                            data._lostForm(reason)
                            if (retry && reason === "filter refused") {
                                fetchStats(false)
                            } else {
                                onward("")
                            }
                        })
                    }, function () {
                        onward("")
                    })
                }
                fetchStats(true)
            }, onward)
        }

        var known = Store.knownId(slug)
        if (known.length > 0) {
            withId(known)
            return
        }
        Api.appId(entry.owner, slug, withId, onward)
    }

    function curveFor(slug, from, until) {
        return Chart.curve(Store.curve(slug), from, until)
    }

    function countriesFor(slug) {
        return data.countryTable[slug] || []
    }

    // `table` is Figures.countryTable, passed so a binding re-runs when it changes.
    function appsIn(country, table) {
        return Chart.appsIn(table || data.countryTable, data.rows, country)
    }

    function rowFor(slug) {
        for (var i = 0; i < data.rows.length; ++i) {
            if (data.rows[i].slug === slug) {
                return data.rows[i]
            }
        }
        return null
    }

    function titleFor(slug) {
        var row = rowFor(slug)
        return row ? row.title : slug
    }

    function pageUrl(slug) {
        return Api.pageUrl(data.owner, slug)
    }
}
