import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.components
import qs.config
import qs.services

// Pick the output and input device, and set the volume
Item {
    // A Layout calculates its own implicitWidth from its children, so the fixed
    // width goes on this wrapper, and the layout inside just fills it
    implicitWidth: Appearance.sizes.popoutWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        width: parent.width
        spacing: Appearance.spacing.small

        StyledText {
            text: "Output"
            font.bold: true
        }

        Repeater {
            model: Audio.sinks

            ListItem {
                required property PwNode modelData

                Layout.fillWidth: true
                icon: modelData.description.toLowerCase().includes("headphone") ? "headphones" : "speaker"
                text: modelData.description
                selected: Audio.sink?.id === modelData.id
                onClicked: Audio.setSink(modelData)
            }
        }

        StyledText {
            Layout.topMargin: Appearance.spacing.small
            text: "Input"
            font.bold: true
        }

        Repeater {
            model: Audio.sources

            ListItem {
                required property PwNode modelData

                Layout.fillWidth: true
                icon: "mic"
                text: modelData.description
                selected: Audio.source?.id === modelData.id
                onClicked: Audio.setSource(modelData)
            }
        }

        StyledText {
            Layout.topMargin: Appearance.spacing.small
            text: Audio.muted ? "Volume (muted)" : `Volume ${Math.round(Audio.volume * 100)}%`
            font.bold: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            MaterialIcon {
                text: Audio.muted ? "volume_off" : "volume_up"

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Audio.toggleMute()
                }
            }

            StyledSlider {
                Layout.fillWidth: true
                value: Audio.volume
                onMoved: Audio.setVolume(value)
            }
        }
    }
}
