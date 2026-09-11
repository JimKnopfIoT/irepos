import QtQuick 2.0
import Sailfish.Silica 1.0
import "."

// The MouseArea comes first so taps still reach interactive content in the slot.
Rectangle {
    id: card

    property string title
    property string value
    property string unit
    property string note
    property color accent: Tint.cyan
    property bool drilldown: false
    default property alias extra: slot.data

    signal clicked()

    width: parent ? parent.width : implicitWidth
    implicitHeight: column.implicitHeight + 2 * Theme.paddingMedium
    radius: Theme.paddingMedium
    color: pressArea.pressed ? Tint.panelHi : Tint.panel
    border.width: 1
    border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.28)

    MouseArea {
        id: pressArea
        anchors.fill: parent
        enabled: card.drilldown
        onClicked: card.clicked()
    }

    Label {
        visible: card.drilldown
        anchors { top: parent.top; right: parent.right; margins: Theme.paddingMedium }
        text: "›"
        font.pixelSize: Theme.fontSizeLarge
        color: card.accent
    }

    Column {
        id: column

        anchors {
            left: parent.left; right: parent.right; top: parent.top
            margins: Theme.paddingMedium
        }
        spacing: Theme.paddingSmall

        Row {
            width: parent.width
            spacing: Theme.paddingSmall

            Rectangle {
                width: Theme.paddingSmall / 2
                height: titleLabel.height
                radius: width / 2
                color: card.accent
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                id: titleLabel
                text: card.title.toUpperCase()
                font.pixelSize: Theme.fontSizeExtraSmall
                font.letterSpacing: 1.5
                color: Theme.secondaryHighlightColor
            }
        }

        Row {
            spacing: 0

            Label {
                text: card.value
                font.pixelSize: Theme.fontSizeExtraLarge
                color: card.accent
                anchors.baseline: unitLabel.baseline
            }

            Label {
                id: unitLabel
                text: card.unit
                font.pixelSize: Theme.fontSizeSmall
                color: card.accent
            }

            Item {
                width: card.note.length ? Theme.paddingMedium : 0
                height: 1
            }

            Label {
                text: card.note
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                anchors.baseline: unitLabel.baseline
            }
        }

        Item {
            id: slot
            width: parent.width
            height: childrenRect.height
        }
    }
}
