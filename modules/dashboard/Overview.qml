import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

// The first tab: clock and weather | calendar | now playing
RowLayout {
    id: root

    spacing: Appearance.spacing.normal

    // A layout inside a layout stretches by default (Layout.fillWidth is true for layouts),
    // so the two fixed-width columns say no; the media card takes what's left
    ColumnLayout {
        Layout.preferredWidth: 220
        Layout.fillWidth: false
        Layout.fillHeight: true
        spacing: Appearance.spacing.normal

        // Clock
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: clock.implicitHeight + Appearance.padding.large * 2

            Column {
                id: clock

                anchors.centerIn: parent

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Time.format("hh:mm")
                    font.pointSize: 40
                    font.bold: true
                    color: Colours.palette.m3primary
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Time.format("dddd, d MMMM")
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }

        // Weather, small (the Weather tab has the details)
        Card {
            Layout.fillWidth: true
            implicitHeight: weather.implicitHeight + Appearance.padding.normal * 2

            RowLayout {
                id: weather

                anchors.fill: parent
                anchors.margins: Appearance.padding.normal
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    text: Weather.icon
                    font.pointSize: 28
                    color: Colours.palette.m3secondary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        text: Weather.formatTemp(Weather.current?.temp)
                        font.pointSize: Appearance.font.size.large
                        font.bold: true
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Weather.city ? `${Weather.description} · ${Weather.city}` : Weather.description
                        elide: Text.ElideRight
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }
        }
    }

    Card {
        Layout.preferredWidth: 250
        Layout.fillWidth: false
        Layout.fillHeight: true
        implicitHeight: calendar.implicitHeight + Appearance.padding.normal * 2

        Calendar {
            id: calendar

            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
        }
    }

    // Now playing
    Card {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            spacing: Appearance.spacing.small

            Cover {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 120
                Layout.preferredHeight: 120
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Players.active?.trackTitle || "Nothing playing"
                elide: Text.ElideRight
                font.bold: true
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Players.active?.trackArtist || Players.active?.identity || ""
                elide: Text.ElideRight
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3onSurfaceVariant
            }

            Item {
                Layout.fillHeight: true
            }

            MediaControls {
                Layout.alignment: Qt.AlignHCenter
                size: 32
            }
        }
    }
}
