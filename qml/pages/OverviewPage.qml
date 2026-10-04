import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../js/Format.js" as Format

// Fetch status, the period, the blocks, the countries, the bars, then one row per app.
Page {
    id: page

    // What `HomeItem` looks for when it unwinds the stack.
    objectName: "overview"

    allowedOrientations: Orientation.All

    function perUnit(unit) {
        return unit === "year" ? qsTr("Downloads per year")
             : unit === "month" ? qsTr("Downloads per month")
             : unit === "week" ? qsTr("Downloads per week")
                               : qsTr("Downloads per day")
    }

    function openApp(slug) {
        var row = Figures.rowFor(slug)
        if (row) {
            pageStack.push(Qt.resolvedUrl("AppPage.qml"), { "row": row })
        }
    }

    Backdrop { }

    SilicaListView {
        id: list

        anchors.fill: parent
        model: Figures.rows

        PullDownMenu {
            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem {
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
            MenuItem {
                text: qsTr("Countries")
                visible: Figures.countries.length > 0
                onClicked: pageStack.push(Qt.resolvedUrl("CountriesPage.qml"))
            }
            MenuItem {
                text: Figures.busy ? qsTr("Fetching…") : qsTr("Refresh")
                enabled: !Figures.busy && Figures.configured
                onClicked: Figures.refresh()
            }
        }

        header: Column {
            width: list.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("iRepos")
                description: Figures.owner.length > 0 ? Figures.owner : qsTr("no publisher set")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Figures.error.length > 0 ? Tint.red : Theme.highlightColor
                visible: text.length > 0
                text: {
                    if (Figures.busy) {
                        return Figures.expected > 0
                                ? qsTr("Fetching… %1 of %2").arg(Figures.done).arg(Figures.expected)
                                : qsTr("Fetching…")
                    }
                    if (Figures.fetchingCountries) {
                        return qsTr("Fetching countries for %1…").arg(Figures.periodText)
                    }
                    if (Figures.error.length > 0) {
                        return qsTr("Last attempt: %1").arg(Figures.error)
                    }
                    return ""
                }
            }

            // Since always this is the total over every app; a tap picks another period.
            StatCard {
                x: Theme.paddingSmall
                width: parent.width - 2 * Theme.paddingSmall
                title: qsTr("Period · %1").arg(Figures.periodText)
                accent: Tint.violet
                value: Figures.period.length === 0 ? Format.count(Figures.total)
                                                   : Format.growth(Figures.periodGain)
                note: qsTr("%n app(s)", "", Figures.period.length === 0
                                            ? Figures.rows.length
                                            : Figures.periodApps)
                drilldown: true
                onClicked: pageStack.push(Qt.resolvedUrl("PeriodDialog.qml"))
            }

            StatCard {
                x: Theme.paddingSmall
                width: parent.width - 2 * Theme.paddingSmall
                title: page.perUnit(deck.unit)
                accent: Tint.amber
                note: Figures.periodFrom.length > 0
                      ? Format.range(Figures.periodFrom, Figures.periodTo) : ""
                visible: Figures.rows.length > 0

                ChartDeck {
                    id: deck
                    width: parent.width
                    maxHeight: page.height * (page.isPortrait ? 0.52 : 0.8)
                    onTapped: page.openApp(slug)
                }
            }

            StatCard {
                x: Theme.paddingSmall
                width: parent.width - 2 * Theme.paddingSmall
                title: qsTr("Countries · %1").arg(Figures.periodText)
                accent: Tint.cyan
                value: String(Figures.countries.length)
                note: Figures.countries.length > 0
                      ? qsTr("most from %1").arg(Figures.countries[0].country)
                      : ""
                drilldown: true
                visible: Figures.countries.length > 0
                onClicked: pageStack.push(Qt.resolvedUrl("CountriesPage.qml"))

                WorldMap {
                    width: parent.width
                    countries: Figures.countries
                    interactive: true
                    onTapped: {
                        pageStack.push(country.length > 0
                                       ? Qt.resolvedUrl("CountryPage.qml")
                                       : Qt.resolvedUrl("CountriesPage.qml"),
                                       country.length > 0
                                       ? { "country": country } : { })
                    }
                }
            }

            StatCard {
                x: Theme.paddingSmall
                width: parent.width - 2 * Theme.paddingSmall
                title: qsTr("Per app")
                accent: Tint.teal
                note: Figures.periodText
                visible: Figures.periodRows.length > 0

                IsoBars {
                    width: parent.width
                    height: page.isPortrait ? Theme.itemSizeExtraLarge * 2.4
                                            : Theme.itemSizeExtraLarge * 1.8
                    rows: Figures.periodRows
                    onTapped: page.openApp(slug)
                }
            }

            Item {
                width: 1
                height: Theme.paddingLarge
            }
        }

        delegate: AppRow {
            title: modelData.title
            version: modelData.version
            downloads: modelData.downloads
            rating: modelData.rating || 0
            votes: modelData.votes || 0
            shift: Figures.period.length > 0
                   && Figures.shifts[modelData.slug] !== undefined
                   ? Figures.shifts[modelData.slug] : null
            // Since always the gain would repeat the total.
            growth: Figures.period.length > 0
                    && Figures.gains[modelData.slug] !== undefined
                    ? Figures.gains[modelData.slug] : null
            onClicked: pageStack.push(Qt.resolvedUrl("AppPage.qml"), { "row": modelData })
        }

        ViewPlaceholder {
            enabled: Figures.rows.length === 0 && !Figures.busy
            text: Figures.configured ? qsTr("Nothing fetched yet")
                                     : qsTr("No publisher set")
            hintText: Figures.configured
                      ? qsTr("Pull down and refresh.")
                      : qsTr("Enter your OpenRepos name under Settings.")
        }

        VerticalScrollDecorator { }
    }
}
