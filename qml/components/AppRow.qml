import QtQuick 2.0
import Sailfish.Silica 1.0
import "."
import "../js/Format.js" as Format

ListItem {
    id: row

    property string title
    property string version
    property int downloads: 0
    property var growth: null
    property real rating: 0
    property int votes: 0
    property var shift: null
    property color accent: Tint.forName(title)

    contentHeight: Theme.itemSizeExtraSmall

    Rectangle {
        id: swatch

        anchors {
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
        }
        width: Theme.paddingMedium
        height: Theme.paddingMedium
        radius: 2
        color: row.accent
    }

    Item {
        id: name

        anchors {
            left: swatch.right
            leftMargin: Theme.paddingMedium
            right: figure.left
            rightMargin: Theme.paddingMedium
            verticalCenter: parent.verticalCenter
        }
        height: titleLabel.height

        Label {
            id: titleLabel

            // Only as wide as the name, so the version follows right behind it.
            width: Math.min(implicitWidth,
                            name.width - (versionLabel.text.length > 0
                                          ? versionLabel.width + Theme.paddingSmall
                                          : 0))
            truncationMode: TruncationMode.Fade
            textFormat: Text.PlainText
            font.pixelSize: Theme.fontSizeSmall
            color: row.highlighted ? Theme.highlightColor : Theme.primaryColor
            text: row.title
        }

        Label {
            id: versionLabel

            x: titleLabel.width + Theme.paddingSmall
            anchors.baseline: titleLabel.baseline
            width: Math.min(implicitWidth, name.width * 0.45)
            truncationMode: TruncationMode.Fade
            textFormat: Text.PlainText
            font.pixelSize: Theme.fontSizeExtraSmall
            color: row.highlighted ? Theme.secondaryHighlightColor
                                   : Theme.secondaryColor
            text: row.version
        }
    }

    Row {
        id: figure

        anchors {
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
        }
        spacing: Theme.paddingSmall

        Label {
            anchors.baseline: number.baseline
            font.pixelSize: Theme.fontSizeExtraSmall
            color: row.shift === null || Math.round(row.shift * 10) === 0
                   ? Theme.secondaryColor
                   : (row.shift > 0 ? Tint.green : Tint.red)
            visible: row.shift !== null && row.votes > 0
            text: row.shift === null ? "" : Format.stars(row.shift)
        }

        Label {
            anchors.baseline: number.baseline
            font.pixelSize: Theme.fontSizeExtraSmall
            color: row.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            visible: row.votes > 0
            text: Format.decimal(row.rating) + " % (" + Format.count(row.votes) + ")"
        }

        Stars {
            anchors.verticalCenter: number.verticalCenter
            height: Math.round(Theme.fontSizeExtraSmall * 0.6)
            rating: row.rating
            color: row.highlighted ? Theme.highlightColor : Tint.amber
            emptyColor: row.highlighted ? Theme.secondaryHighlightColor
                                        : Qt.rgba(1, 1, 1, 0.2)
            visible: row.votes > 0
        }

        Item {
            width: Theme.paddingMedium
            height: 1
            visible: row.votes > 0
        }

        Label {
            anchors.baseline: number.baseline
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Tint.growthColor(row.growth === null ? 0 : row.growth)
            visible: row.growth !== null
            text: Format.growth(row.growth)
        }

        Label {
            id: number
            font.pixelSize: Theme.fontSizeSmall
            color: row.accent
            text: Format.count(row.downloads)
        }
    }
}
