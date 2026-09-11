import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../js/Format.js" as Format

CoverBackground {
    Backdrop { }

    Column {
        anchors.centerIn: parent
        width: parent.width - 2 * Theme.paddingLarge
        spacing: Theme.paddingSmall

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            font.letterSpacing: 1.5
            color: Theme.secondaryHighlightColor
            text: qsTr("DOWNLOADS")
        }

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeHuge
            color: Tint.cyan
            text: Format.count(Figures.total)
        }

        // Hidden for "since always", where it would repeat the total.
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            truncationMode: TruncationMode.Fade
            font.pixelSize: Theme.fontSizeSmall
            color: Tint.growthColor(Figures.periodGain === null ? 0 : Figures.periodGain)
            visible: Figures.period.length > 0
            text: qsTr("%1 · %2").arg(Format.growth(Figures.periodGain))
                                 .arg(Figures.periodText)
        }

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            text: qsTr("%n app(s)", "", Figures.rows.length)
        }
    }

    CoverActionList {
        CoverAction {
            iconSource: "image://theme/icon-cover-refresh"
            onTriggered: Figures.refresh()
        }
    }
}
