import QtQuick 2.0
import Sailfish.Silica 1.0
import "."
import "../js/Format.js" as Format

// The blocks over the period, two views a swipe apart.
Column {
    id: deck

    property real maxHeight: Screen.height / 2
    readonly property int currentIndex: view.currentIndex
    readonly property string unit: view.currentItem ? view.currentItem.unit : "day"

    signal tapped(string slug)

    spacing: Theme.paddingSmall

    Component {
        id: wholeSlide
        Iso3D {
            apps: Figures.rows
            cells: Figures.cells
            from: Figures.periodFrom
            to: Figures.periodTo
            axes: true
            interactive: true
        }
    }

    // The same period for the biggest eight, held at a glance's worth of columns.
    Component {
        id: topSlide
        Iso3D {
            apps: Figures.rows.slice(0, 8)
            cells: Figures.cells
            from: Figures.periodFrom
            to: Figures.periodTo
            columns: 10
        }
    }

    SlideshowView {
        id: view

        width: parent.width
        // An isometric floor needs nearly as much height as width.
        height: Math.min(Math.round(width * 0.92), deck.maxHeight)
        itemWidth: width
        itemHeight: height
        clip: true
        model: 2

        delegate: Item {
            width: view.itemWidth
            height: view.itemHeight

            readonly property string unit: slide.item ? slide.item.history.unit : "day"

            Loader {
                id: slide
                anchors.fill: parent
                sourceComponent: index === 1 ? topSlide : wholeSlide
            }

            Connections {
                target: slide.item
                onTapped: deck.tapped(slug)
            }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.paddingSmall

        Repeater {
            model: 2

            Rectangle {
                width: Theme.paddingSmall
                height: width
                radius: width / 2
                color: index === view.currentIndex ? Tint.amber : Tint.grid
            }
        }
    }

    // Without a session the history starts on the install day; empty floor before it means "unknown".
    Label {
        width: parent.width
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.secondaryColor
        visible: !Figures.signedIn && Figures.firstDay.length > 0
                 && Figures.periodFrom < Figures.firstDay
        text: qsTr("Nothing is known before %1: not signed in, "
                   + "the history starts the day this was "
                   + "installed. Signed in, the site hands over "
                   + "every day it has.").arg(Format.date(Figures.firstDay))
    }
}
