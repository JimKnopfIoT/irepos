import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../js/Format.js" as Format

// The countries on the map, then as a list with their figures.
Page {
    id: page

    // Empty for all apps together, otherwise one app's slug.
    property string slug: ""

    readonly property var rows: slug.length > 0 ? (Figures.countryTable[slug] || [])
                                                : Figures.countries
    readonly property string subject: slug.length > 0 ? Figures.titleFor(slug) : ""
    readonly property int placed: {
        var sum = 0
        for (var i = 0; i < rows.length; ++i) {
            sum += rows[i].downloads
        }
        return sum
    }
    readonly property int biggest: rows.length > 0 ? rows[0].downloads : 1

    allowedOrientations: Orientation.All

    Backdrop { }

    SilicaListView {
        id: list

        anchors.fill: parent
        model: page.rows

        PullDownMenu {
            HomeItem { }
        }

        header: Column {
            width: list.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: page.subject.length > 0 ? page.subject : qsTr("Countries")
                description: qsTr("%1 downloads placed in %n country(s)", "",
                                  page.rows.length)
                             .arg(Format.count(page.placed)) + " · " + Figures.periodText
            }

            ComboBox {
                width: parent.width
                label: qsTr("Application")
                currentIndex: {
                    if (page.slug.length === 0) {
                        return 0
                    }
                    for (var i = 0; i < Figures.rows.length; ++i) {
                        if (Figures.rows[i].slug === page.slug) {
                            return i + 1
                        }
                    }
                    return 0
                }

                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("All apps")
                        onClicked: page.slug = ""
                    }

                    Repeater {
                        model: Figures.rows

                        MenuItem {
                            text: modelData.title
                            onClicked: page.slug = modelData.slug
                        }
                    }
                }
            }

            WorldMap {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                countries: page.rows
                interactive: true
                onTapped: {
                    if (country.length > 0) {
                        pageStack.push(Qt.resolvedUrl("CountryPage.qml"),
                                       { "country": country })
                    }
                }
            }

            // The shading scale, from few to the biggest country.
            Item {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: bar.height + scale.height + Theme.paddingSmall

                Row {
                    id: bar

                    width: parent.width

                    Repeater {
                        model: 32

                        Rectangle {
                            width: bar.width / 32
                            height: Theme.paddingMedium
                            color: Tint.heat(index / 31)
                        }
                    }
                }

                Item {
                    id: scale

                    anchors { left: parent.left; right: parent.right; top: bar.bottom }
                    height: least.height

                    Label {
                        id: least
                        anchors.left: parent.left
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: qsTr("few")
                    }

                    Label {
                        anchors.right: parent.right
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: Format.count(page.biggest)
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: qsTr("Pinch to zoom, drag to move, double tap back out. "
                           + "Tap a country for the applications downloaded "
                           + "there. Shading is by order of magnitude, not by "
                           + "share: one country usually holds most of the "
                           + "downloads, and on a straight scale the rest "
                           + "would all look empty. City states and small "
                           + "islands keep their figures below but are too "
                           + "small to draw at this scale.")
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

            onClicked: pageStack.push(Qt.resolvedUrl("CountryPage.qml"),
                                      { "country": modelData.country })

            Rectangle {
                anchors {
                    left: parent.left; verticalCenter: parent.verticalCenter
                    leftMargin: Theme.horizontalPageMargin
                }
                width: Math.max(2, entry.share
                                * (list.width - 2 * Theme.horizontalPageMargin))
                height: Theme.itemSizeSmall - Theme.paddingLarge
                radius: 2
                color: Qt.rgba(Tint.cyan.r, Tint.cyan.g, Tint.cyan.b, 0.16)
            }

            Label {
                anchors {
                    left: parent.left; verticalCenter: parent.verticalCenter
                    leftMargin: Theme.horizontalPageMargin + Theme.paddingMedium
                    right: figure.left; rightMargin: Theme.paddingMedium
                }
                truncationMode: TruncationMode.Fade
                textFormat: Text.PlainText
                text: modelData.country
            }

            Label {
                id: figure

                anchors {
                    right: parent.right; verticalCenter: parent.verticalCenter
                    rightMargin: Theme.horizontalPageMargin
                }
                color: Tint.cyan
                text: Format.count(modelData.downloads)
            }
        }

        ViewPlaceholder {
            enabled: page.rows.length === 0
            text: qsTr("Nothing to place yet")
            hintText: Figures.signedIn
                      ? qsTr("Pull down and refresh.")
                      : qsTr("Only a signed-in publisher is told which "
                             + "countries the downloads came from.")
        }

        VerticalScrollDecorator { }
    }
}
