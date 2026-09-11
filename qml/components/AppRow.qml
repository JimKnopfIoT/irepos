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
