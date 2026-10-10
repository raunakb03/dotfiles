import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

// Big cover, track details, a seek bar and the controls, plus a switch for which player to control
RowLayout {
    id: root

    readonly property var player: Players.active

    function formatTime(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    spacing: Appearance.spacing.large

    Cover {
        Layout.preferredWidth: 220
        Layout.preferredHeight: 220
        radius: Appearance.rounding.large
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        StyledText {
            Layout.fillWidth: true
            text: root.player?.trackTitle || "Nothing playing"
            elide: Text.ElideRight
            font.pointSize: Appearance.font.size.large
            font.bold: true
        }

        StyledText {
            Layout.fillWidth: true
            text: root.player?.trackArtist ?? ""
            visible: text !== ""
            elide: Text.ElideRight
            color: Colours.palette.m3secondary
        }

        StyledText {
            Layout.fillWidth: true
            text: root.player?.trackAlbum ?? ""
            visible: text !== ""
            elide: Text.ElideRight
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }

        Item {
            Layout.fillHeight: true
        }

        // Seek bar. Quickshell doesn't push position updates (they'd fire constantly),
        // so a timer asks for them once a second while this tab is visible.
        StyledSlider {
            id: seek

            Layout.fillWidth: true
            visible: root.player?.lengthSupported ?? false
            enabled: root.player?.canSeek ?? false
            value: root.player && root.player.length > 0 ? root.player.position / root.player.length : 0
            onMoved: root.player.position = value * root.player.length
        }

        RowLayout {
            Layout.fillWidth: true
            visible: seek.visible

            StyledText {
                text: root.formatTime(root.player?.position ?? 0)
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3onSurfaceVariant
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                text: root.formatTime(root.player?.length ?? 0)
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        Timer {
            running: root.visible && (root.player?.isPlaying ?? false)
            interval: 1000
            repeat: true
            onTriggered: root.player.positionChanged()
        }

        MediaControls {
            Layout.alignment: Qt.AlignHCenter
            size: 44
        }

        // One chip per player: click to control that one
        Flow {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacing.small
            spacing: Appearance.spacing.small
            visible: Players.list.length > 1

            Repeater {
                model: Players.list

                StyledRect {
                    id: chip

                    required property var modelData
                    readonly property bool current: modelData === root.player

                    implicitWidth: chipLabel.implicitWidth + Appearance.padding.normal * 2
                    implicitHeight: chipLabel.implicitHeight + Appearance.padding.small
                    radius: Appearance.rounding.full
                    color: current ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHigh

                    StyledText {
                        id: chipLabel

                        anchors.centerIn: parent
                        text: chip.modelData.identity
                        font.pointSize: Appearance.font.size.small
                        color: chip.current ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    }

                    StateLayer {
                        onClicked: Players.choose(chip.modelData)
                    }
                }
            }
        }
    }
}
