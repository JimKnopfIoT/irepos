import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../js/Format.js" as Format

// One app: its figure and curve over the period, its details and its countries.
Page {
    id: page

    property var row: null

    readonly property color accent: row ? Tint.forName(row.title) : Tint.cyan
    property var countries: []
    readonly property int mostFromOne: countries.length > 0 ? countries[0].downloads : 1

    function readCountries() {
        page.countries = row ? Figures.countriesFor(row.slug) : []
    }

    Component.onCompleted: page.readCountries()

    Connections {
        target: Figures
        onCountriesChanged: page.readCountries()
    }

    allowedOrientations: Orientation.All

    Backdrop { }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        PullDownMenu {
            MenuItem {
                text: qsTr("Open on OpenRepos")
                visible: page.row !== null
                onClicked: Qt.openUrlExternally(Figures.pageUrl(page.row.slug))
            }
            MenuItem {
                text: qsTr("Refresh")
                enabled: !Figures.busy
                onClicked: Figures.refresh()
            }
            HomeItem { }
        }

        Column {
            id: content

            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: page.row ? page.row.title : ""
                description: page.row ? page.row.version : ""
            }

            StatCard {
                x: Theme.paddingSmall
                width: parent.width - 2 * Theme.paddingSmall
                title: qsTr("Downloads")
                accent: page.accent
                value: page.row ? Format.count(page.row.downloads) : "—"

                // The period arguments make the binding re-run when the period changes.
                Curve {
                    width: parent.width
                    accent: page.accent
                    points: page.row ? Figures.curveFor(page.row.slug,
                                                        Figures.periodFrom,
                                                        Figures.periodTo)
                                     : []
                }
            }

            StatCard {
                x: Theme.paddingSmall
                width: parent.width - 2 * Theme.paddingSmall
                title: qsTr("Countries")
                accent: page.accent
                value: String(page.countries.length)
                note: page.countries.length > 0
                      ? qsTr("most from %1").arg(page.countries[0].country)
                      : ""
                drilldown: true
                visible: page.countries.length > 0
                onClicked: pageStack.push(Qt.resolvedUrl("CountriesPage.qml"),
                                          { "slug": page.row ? page.row.slug : "" })

                WorldMap {
                    width: parent.width
                    countries: page.countries
                    interactive: true
                    onTapped: {
                        if (country.length > 0) {
                            pageStack.push(Qt.resolvedUrl("CountryPage.qml"),
                                           { "country": country })
                        }
                    }
                }
            }

            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingMedium

                DetailItem {
                    label: qsTr("Period")
                    value: {
                        var growth = page.row ? Figures.gains[page.row.slug] : undefined
                        return growth === undefined
                                ? "—"
                                : qsTr("%1 · %2").arg(Format.growth(growth))
                                                 .arg(Figures.periodText)
                    }
                }

                DetailItem {
                    label: qsTr("Rating")
                    value: page.row && page.row.votes > 0
                           ? qsTr("%1 % from %2 votes").arg(page.row.rating).arg(page.row.votes)
                           : qsTr("none yet")
                }

                DetailItem {
                    label: qsTr("Comments")
                    value: page.row ? String(page.row.comments) : "—"
                }

                DetailItem {
                    label: qsTr("Updated")
                    value: page.row ? Format.day(page.row.updated) : "—"
                }

                DetailItem {
                    label: qsTr("Read on")
                    value: page.row ? page.row.day : "—"
                }
            }

            SectionHeader {
                text: qsTr("Countries")
                visible: page.countries.length > 0
            }

            Column {
                width: parent.width
                visible: page.countries.length > 0

                Repeater {
                    model: page.countries

                    BackgroundItem {
                        id: place

                        width: parent.width
                        height: Theme.itemSizeExtraSmall

                        onClicked: pageStack.push(Qt.resolvedUrl("CountryPage.qml"),
                                                  { "country": modelData.country })

                        Rectangle {
                            anchors {
                                left: parent.left
                                leftMargin: Theme.horizontalPageMargin
                                verticalCenter: parent.verticalCenter
                            }
                            width: Math.max(2, modelData.downloads / page.mostFromOne
                                            * (place.width - 2 * Theme.horizontalPageMargin))
                            height: Theme.itemSizeExtraSmall - Theme.paddingLarge
                            radius: 2
                            color: Qt.rgba(page.accent.r, page.accent.g, page.accent.b, 0.16)
                        }

                        Label {
                            anchors {
                                left: parent.left
                                leftMargin: Theme.horizontalPageMargin + Theme.paddingMedium
                                right: fromHere.left
                                rightMargin: Theme.paddingMedium
                                verticalCenter: parent.verticalCenter
                            }
                            truncationMode: TruncationMode.Fade
                            textFormat: Text.PlainText
                            font.pixelSize: Theme.fontSizeSmall
                            color: place.highlighted ? Theme.highlightColor : Theme.primaryColor
                            text: modelData.country
                        }

                        Label {
                            id: fromHere

                            anchors {
                                right: parent.right
                                rightMargin: Theme.horizontalPageMargin
                                verticalCenter: parent.verticalCenter
                            }
                            font.pixelSize: Theme.fontSizeSmall
                            color: page.accent
                            text: Format.count(modelData.downloads)
                        }
                    }
                }
            }

            Item {
                width: 1
                height: Theme.paddingLarge
            }
        }

        VerticalScrollDecorator { }
    }
}
