import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../js/Build.js" as Build
import "../js/Format.js" as Format

Page {
    id: page

    allowedOrientations: Orientation.All

    Backdrop { }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        PullDownMenu {
            HomeItem { }
        }

        Column {
            id: content

            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("About")
                description: qsTr("iRepos")
            }

            SectionHeader { text: qsTr("This build") }

            DetailItem {
                label: qsTr("Version")
                value: Build.VERSION + "-" + Build.RELEASE
            }

            DetailItem {
                label: qsTr("Built")
                value: Build.BUILT
            }

            SectionHeader { text: qsTr("This publisher") }

            DetailItem {
                label: qsTr("Publisher")
                value: Figures.owner.length > 0 ? Figures.owner : "—"
            }

            DetailItem {
                label: qsTr("Publisher id")
                value: Figures.userId.length > 0 ? Figures.userId : "—"
            }

            DetailItem {
                label: qsTr("Session")
                value: Figures.signedIn ? qsTr("signed in") : qsTr("not signed in")
            }

            SectionHeader { text: qsTr("What is stored") }

            DetailItem {
                label: qsTr("Apps")
                value: String(Figures.rows.length)
            }

            DetailItem {
                label: qsTr("Days of history")
                value: String(Figures.days)
            }

            DetailItem {
                label: qsTr("Downloads")
                value: Format.count(Figures.total)
            }

            DetailItem {
                label: qsTr("Countries")
                value: Figures.countries.length > 0
                       ? String(Figures.countries.length)
                       : qsTr("sign in to see")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: qsTr("The download figures of your own OpenRepos "
                           + "applications. Everything fetched is kept on this "
                           + "device and nowhere else; nothing is sent anywhere "
                           + "but to openrepos.net.")
            }

            Item {
                width: 1
                height: Theme.paddingLarge
            }
        }

        VerticalScrollDecorator { }
    }
}
