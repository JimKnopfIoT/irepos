import QtQuick 2.0
import Sailfish.Silica 1.0

// A button for "n units": a tap picks it, the arrows at its end count n down and up.
BackgroundItem {
    id: step

    property string text
    property int count: 1
    property int minimum: 1
    property int maximum: 1
    property bool current: false

    signal picked()

    height: Theme.itemSizeSmall
    onClicked: step.picked()

    Rectangle {
        anchors {
            fill: parent
            leftMargin: Theme.horizontalPageMargin
            rightMargin: Theme.horizontalPageMargin
            topMargin: Theme.paddingSmall / 2
            bottomMargin: Theme.paddingSmall / 2
        }
        radius: Theme.paddingSmall
        color: Theme.rgba(step.current ? Theme.highlightBackgroundColor
                                       : Theme.primaryColor,
                          step.current ? Theme.opacityLow : Theme.opacityFaint)
    }

    Label {
        anchors {
            left: parent.left
            leftMargin: Theme.horizontalPageMargin + Theme.paddingLarge
            verticalCenter: parent.verticalCenter
        }
        color: step.highlighted || step.current ? Theme.highlightColor
                                                : Theme.primaryColor
        text: step.text
    }

    Row {
        anchors {
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
        }
        visible: step.maximum > step.minimum

        IconButton {
            icon.source: "image://theme/icon-m-left"
            enabled: step.count > step.minimum
            onClicked: step.count -= 1
        }

        IconButton {
            icon.source: "image://theme/icon-m-right"
            enabled: step.count < step.maximum
            onClicked: step.count += 1
        }
    }
}
