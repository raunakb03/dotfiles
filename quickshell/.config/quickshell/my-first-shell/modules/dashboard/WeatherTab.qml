import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

// Now, the next 12 hours, and the week
ColumnLayout {
    id: root

    spacing: Appearance.spacing.normal

    // Now
    Card {
        Layout.fillWidth: true
        implicitHeight: now.implicitHeight + Appearance.padding.large * 2

        RowLayout {
            id: now

            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.large

            MaterialIcon {
                text: Weather.icon
                font.pointSize: 48
                color: Colours.palette.m3secondary
            }

            ColumnLayout {
                spacing: 0

                StyledText {
                    text: Weather.formatTemp(Weather.current?.temp)
                    font.pointSize: 32
                    font.bold: true
                }

                StyledText {
                    text: Weather.description
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            Item {
                Layout.fillWidth: true
            }

            // Details, two columns
            GridLayout {
                columns: 2
                columnSpacing: Appearance.spacing.large
                rowSpacing: Appearance.spacing.small

                Detail {
                    icon: "location_on"
                    text: Weather.city || "--"
                }
                Detail {
                    icon: "thermostat"
                    text: `Feels ${Weather.formatTemp(Weather.current?.feelsLike)}`
                }
                Detail {
                    icon: "humidity_percentage"
                    text: `${Weather.current?.humidity ?? "--"}%`
                }
                Detail {
                    icon: "air"
                    text: `${Math.round(Weather.current?.wind ?? 0)} km/h`
                }
                Detail {
                    icon: "wb_twilight"
                    text: Weather.sunrise || "--"
                }
                Detail {
                    icon: "bedtime"
                    text: Weather.sunset || "--"
                }
            }

            IconButton {
                Layout.alignment: Qt.AlignTop
                icon: "refresh"
                size: 32
                disabled: Weather.loading
                onClicked: Weather.refresh()
            }
        }
    }

    // Next 12 hours
    Card {
        Layout.fillWidth: true
        implicitHeight: hours.implicitHeight + Appearance.padding.normal * 2
        visible: Weather.hourly.length > 0

        RowLayout {
            id: hours

            anchors.fill: parent
            anchors.margins: Appearance.padding.normal

            Repeater {
                model: Weather.hourly

                Forecast {
                    required property var modelData
                    required property int index

                    upper: index === 0 ? "Now" : modelData.time
                    icon: Weather.iconFor(modelData.code, true)
                    lower: Weather.formatTemp(modelData.temp)
                }
            }
        }
    }

    // This week
    Card {
        Layout.fillWidth: true
        implicitHeight: days.implicitHeight + Appearance.padding.normal * 2
        visible: Weather.daily.length > 0

        RowLayout {
            id: days

            anchors.fill: parent
            anchors.margins: Appearance.padding.normal

            Repeater {
                model: Weather.daily

                Forecast {
                    required property var modelData
                    required property int index

                    upper: index === 0 ? "Today" : Qt.formatDate(modelData.date, "ddd")
                    icon: Weather.iconFor(modelData.code, true)
                    lower: `${Weather.formatTemp(modelData.max)} ${Weather.formatTemp(modelData.min)}`
                }
            }
        }
    }

    component Detail: Row {
        property alias icon: detailIcon.text
        property alias text: detailText.text

        spacing: Appearance.spacing.small

        MaterialIcon {
            id: detailIcon

            color: Colours.palette.m3onSurfaceVariant
        }

        StyledText {
            id: detailText

            anchors.verticalCenter: parent.verticalCenter
        }
    }

    component Forecast: ColumnLayout {
        property string upper
        property string icon
        property string lower

        Layout.fillWidth: true
        spacing: 2

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: parent.upper
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: parent.icon
            font.pointSize: Appearance.font.size.large
            color: Colours.palette.m3secondary
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: parent.lower
            font.pointSize: Appearance.font.size.small
        }
    }
}
