import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../js/Dates.js" as Dates
import "../js/Format.js" as Format

// Picks the period: n days, weeks, months or years back, since always, or two days off the calendar.
Dialog {
    id: dialog

    // Set by a quick pick; empty while the calendar decides.
    property string unit: ""
    property int count: 1
    property string from: ""
    property string to: ""

    readonly property int years: {
        var first = Figures.firstDay.length > 0 ? Number(Figures.firstDay.substring(0, 4))
                                                : new Date().getFullYear()
        return Math.max(1, Math.min(10, new Date().getFullYear() - first + 1))
    }

    allowedOrientations: Orientation.All
    canAccept: unit.length > 0 || from.length > 0

    function quick(unit, count) {
        dialog.unit = unit
        dialog.count = count
        dialog.accept()
    }

    // First tap starts the stretch, second ends it, a third starts over.
    function pick(day) {
        dialog.unit = ""
        if (dialog.from.length === 0 || dialog.to.length > 0) {
            dialog.from = day
            dialog.to = ""
        } else if (day < dialog.from) {
            dialog.to = dialog.from
            dialog.from = day
        } else {
            dialog.to = day
        }
    }

    Component.onCompleted: {
        if (Figures.period === "range") {
            dialog.from = Figures.fromDay
            dialog.to = Figures.toDay
            calendar.date = Dates.parse(Figures.toDay)
        }
    }

    onAccepted: {
        if (dialog.unit.length > 0 || dialog.from.length === 0) {
            Figures.setPeriod(dialog.unit === "always" ? "" : dialog.unit, dialog.count)
        } else {
            Figures.setRange(dialog.from, dialog.to.length > 0 ? dialog.to : dialog.from)
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        Column {
            id: content

            width: parent.width
            spacing: Theme.paddingSmall

            DialogHeader {
                title: qsTr("Period")
                acceptText: qsTr("Apply")
            }

            Repeater {
                model: [
                    { "unit": "day", "maximum": 7 },
                    { "unit": "week", "maximum": 4 },
                    { "unit": "month", "maximum": 12 },
                    { "unit": "year", "maximum": dialog.years }
                ]

                StepButton {
                    width: parent.width
                    minimum: 1
                    maximum: modelData.maximum
                    count: Figures.period === modelData.unit
                           ? Math.min(Figures.periodCount, modelData.maximum) : 1
                    current: Figures.period === modelData.unit
                    text: Figures.unitText(modelData.unit, count)
                    onPicked: dialog.quick(modelData.unit, count)
                }
            }

            StepButton {
                width: parent.width
                current: Figures.period === ""
                text: Figures.unitText("", 1)
                onPicked: dialog.quick("always", 1)
            }

            SectionHeader { text: qsTr("From – to") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: dialog.from.length > 0 ? Theme.highlightColor
                                              : Theme.secondaryColor
                text: dialog.from.length > 0
                      ? Format.range(dialog.from, dialog.to)
                      : qsTr("Tap the first day, then the last.")
            }

            DatePicker {
                id: calendar

                // Square cells across a turned screen would be taller than the screen.
                width: Math.min(parent.width, Screen.width)
                anchors.horizontalCenter: parent.horizontalCenter
                daysVisible: true

                delegate: Component {
                    MouseArea {
                        id: cell

                        width: calendar.cellWidth
                        height: calendar.cellHeight

                        readonly property string day:
                            Dates.stamp(new Date(model.year, model.month - 1, model.day, 12))
                        readonly property bool inside:
                            dialog.from.length > 0 && day >= dialog.from
                            && day <= (dialog.to.length > 0 ? dialog.to : dialog.from)
                        readonly property bool edge: day === dialog.from || day === dialog.to

                        Rectangle {
                            anchors {
                                fill: parent
                                topMargin: Theme.paddingSmall / 2
                                bottomMargin: Theme.paddingSmall / 2
                            }
                            visible: cell.inside
                            radius: cell.edge ? height / 2 : 0
                            color: Theme.rgba(Theme.highlightBackgroundColor,
                                              cell.edge ? Theme.opacityHigh
                                                        : Theme.opacityLow)
                        }

                        Label {
                            anchors.centerIn: parent
                            text: model.day.toLocaleString()
                            font.bold: cell.day === Dates.today()
                            color: cell.pressed || cell.inside
                                   ? Theme.highlightColor
                                   : (model.month === model.primaryMonth
                                      ? Theme.primaryColor : Theme.secondaryColor)
                        }

                        onClicked: dialog.pick(cell.day)
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
