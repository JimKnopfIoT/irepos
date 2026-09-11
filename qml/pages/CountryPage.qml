import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../js/Format.js" as Format

// One country: the map framed on it, and the apps downloaded there.
Page {
    id: page

    // As the site names it.
    property string country: ""

    readonly property var apps: country.length > 0
                                ? Figures.appsIn(country, Figures.countryTable) : []
    readonly property int placed: {
        var sum = 0
        for (var i = 0; i < apps.length; ++i) {
            sum += apps[i].downloads
        }
        return sum
    }
    readonly property int biggest: apps.length > 0 ? apps[0].downloads : 1

    allowedOrientations: Orientation.All

    Backdrop { }

    SilicaListView {
        id: list

        anchors.fill: parent
        model: page.apps

        PullDownMenu {
            HomeItem { }
        }

        header: Column {
            width: list.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: page.country
                description: qsTr("%1 downloads from %n app(s)", "",
                                  page.apps.length)
                             .arg(Format.count(page.placed)) + " · " + Figures.periodText
            }

            WorldMap {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                countries: Figures.countries
                highlight: page.country
                frameHighlight: true
                interactive: true
                onTapped: {
                    if (country.length > 0 && country !== page.country) {
                        pageStack.push(Qt.resolvedUrl("CountryPage.qml"),
                                       { "country": country })
                    }
                }
            }

            Item {
                width: 1
                height: Theme.paddingSmall
            }
        }

        delegate: ListItem {
            id: entry

            contentHeight: Theme.itemSizeSmall
            width: list.width

            readonly property real share:
                page.biggest > 0 ? modelData.downloads / page.biggest : 0
            readonly property color accent: Tint.forName(modelData.title)

            onClicked: {
                var row = Figures.rowFor(modelData.slug)
                if (row) {
                    pageStack.push(Qt.resolvedUrl("AppPage.qml"), { "row": row })
                }
            }

            Rectangle {
                anchors {
                    left: parent.left; verticalCenter: parent.verticalCenter
                    leftMargin: Theme.horizontalPageMargin
                }
                width: Math.max(2, entry.share
                                * (list.width - 2 * Theme.horizontalPageMargin))
                height: Theme.itemSizeSmall - Theme.paddingLarge
                radius: 2
                color: Qt.rgba(entry.accent.r, entry.accent.g, entry.accent.b, 0.18)
            }

            Label {
                anchors {
                    left: parent.left; verticalCenter: parent.verticalCenter
                    leftMargin: Theme.horizontalPageMargin + Theme.paddingMedium
                    right: figure.left; rightMargin: Theme.paddingMedium
                }
                truncationMode: TruncationMode.Fade
                textFormat: Text.PlainText
                text: modelData.title
            }

            Label {
                id: figure

                anchors {
                    right: parent.right; verticalCenter: parent.verticalCenter
                    rightMargin: Theme.horizontalPageMargin
                }
                color: entry.accent
                text: Format.count(modelData.downloads)
            }
        }

        ViewPlaceholder {
            enabled: page.apps.length === 0
            text: qsTr("Nothing from here")
        }

        VerticalScrollDecorator { }
    }
}
