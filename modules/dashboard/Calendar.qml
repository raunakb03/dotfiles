import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

// This month's calendar, today highlighted. The arrows (or scrolling) change the month.
ColumnLayout {
    id: root

    property int month: Time.date.getMonth()
    property int year: Time.date.getFullYear()

    function shift(months: int): void {
        const d = new Date(year, month + months, 1);
        month = d.getMonth();
        year = d.getFullYear();
    }

    spacing: Appearance.spacing.small

    RowLayout {
        Layout.fillWidth: true

        IconButton {
            icon: "chevron_left"
            size: 28
            onClicked: root.shift(-1)
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Qt.formatDate(new Date(root.year, root.month, 1), "MMMM yyyy")
            font.bold: true

            // Click the title to go back to this month
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.month = Time.date.getMonth();
                    root.year = Time.date.getFullYear();
                }
            }
        }

        IconButton {
            icon: "chevron_right"
            size: 28
            onClicked: root.shift(1)
        }
    }

    // "Mo Tu We …", starting on the locale's first day of the week
    DayOfWeekRow {
        Layout.fillWidth: true
        locale: grid.locale
        delegate: StyledText {
            required property string shortName

            horizontalAlignment: Text.AlignHCenter
            text: shortName.slice(0, 2)
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    // Qt's MonthGrid lays out the 6 weeks; we only draw each day
    MonthGrid {
        id: grid

        Layout.fillWidth: true
        month: root.month
        year: root.year
        spacing: 2

        delegate: Item {
            id: day

            required property var model // { day, month, today, … }

            implicitWidth: 30
            implicitHeight: 30

            StyledRect {
                anchors.centerIn: parent
                width: 28
                height: 28
                radius: Appearance.rounding.full
                color: day.model.today ? Colours.palette.m3primary : "transparent"
            }

            StyledText {
                anchors.centerIn: parent
                text: day.model.day
                font.pointSize: Appearance.font.size.smaller
                // Days from the previous/next month are dimmed
                color: day.model.today ? Colours.palette.m3onPrimary : day.model.month === root.month ? Colours.palette.m3onSurface : Colours.palette.m3outline
            }
        }
    }

    // Scroll over the calendar to change the month
    WheelHandler {
        onWheel: event => root.shift(event.angleDelta.y > 0 ? -1 : 1)
    }
}
