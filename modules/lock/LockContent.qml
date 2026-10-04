import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services
import qs.utils

// What the lock screen looks like: the blurred wallpaper, a big clock, you, and the password field
Item {
    id: root

    required property var lock // Lock.qml: buffer, message, checking, handleKey(), shake()
    property var screen

    readonly property UPowerDevice battery: UPower.displayDevice

    focus: true
    Keys.onPressed: event => {
        root.lock.handleKey(event);
        event.accepted = true;
    }

    // Wallpaper, blurred and darkened
    Image {
        id: wallpaper

        anchors.fill: parent
        source: Wallpaper.path ? "file://" + Wallpaper.path : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: root.width / 2 // it gets blurred anyway: half size is plenty and faster
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        blurEnabled: true
        blur: 1
        blurMax: 64
        brightness: -0.25
    }

    // Everything else fades and slides in
    Item {
        id: content

        anchors.fill: parent
        opacity: 0
        scale: 0.96

        Component.onCompleted: {
            opacity = 1;
            scale = 1;
        }

        Behavior on opacity {
            Anim {
                duration: Appearance.anim.durations.large
            }
        }
        Behavior on scale {
            Anim {
                duration: Appearance.anim.durations.large
                easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Appearance.spacing.normal

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Time.format("hh:mm")
                font.pointSize: 96
                font.bold: true
                color: Colours.palette.m3primary
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: Appearance.spacing.large * 2
                text: Time.format("dddd, d MMMM")
                font.pointSize: Appearance.font.size.large
                color: Colours.palette.m3onSurface
            }

            // You: ~/.face if you have one, else an icon
            ClippingRectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 96
                implicitHeight: 96
                radius: Appearance.rounding.full
                color: Colours.palette.m3primaryContainer

                // Only point the Image at ~/.face if it exists (otherwise Qt logs a warning)
                FileView {
                    id: faceFile

                    property bool exists: false

                    path: `${Paths.home}/.face`
                    printErrors: false
                    onLoaded: exists = true
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: face.status !== Image.Ready
                    text: "person"
                    fill: 1
                    font.pointSize: 40
                    color: Colours.palette.m3onPrimaryContainer
                }

                Image {
                    id: face

                    anchors.fill: parent
                    source: faceFile.exists ? `file://${Paths.home}/.face` : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: Appearance.spacing.normal
                text: Quickshell.env("USER")
                font.pointSize: Appearance.font.size.larger
                font.bold: true
            }

            // The password field
            StyledRect {
                id: field

                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 320
                implicitHeight: 52
                radius: Appearance.rounding.full
                color: Qt.alpha(Colours.palette.m3surfaceContainer, 0.9)
                border.width: 2
                border.color: root.lock.failed ? Colours.palette.m3error : root.lock.checking ? Colours.palette.m3primary : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Appearance.padding.large
                    anchors.rightMargin: Appearance.padding.normal
                    spacing: Appearance.spacing.small

                    MaterialIcon {
                        text: root.lock.checking ? "hourglass_top" : "lock"
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    // Placeholder, or one dot per character (the text itself is never drawn)
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.lock.buffer.length === 0
                            text: root.lock.checking ? "Checking…" : "Enter password"
                            color: Colours.palette.m3outline
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right // newest dot on the right; old ones scroll off the left
                            spacing: 6

                            Repeater {
                                model: root.lock.buffer.length

                                StyledRect {
                                    implicitWidth: 10
                                    implicitHeight: 10
                                    radius: 5
                                    color: Colours.palette.m3onSurface
                                }
                            }
                        }
                    }

                    IconButton {
                        icon: "arrow_forward"
                        size: 36
                        filled: true
                        disabled: root.lock.buffer.length === 0 || root.lock.checking
                        onClicked: root.lock.submit()
                    }
                }

                // Wrong password: shake left and right
                SequentialAnimation {
                    id: shakeAnim

                    loops: 2
                    NumberAnimation {
                        target: field
                        property: "Layout.leftMargin"
                        to: 20
                        duration: 50
                    }
                    NumberAnimation {
                        target: field
                        property: "Layout.leftMargin"
                        to: -20
                        duration: 100
                    }
                    NumberAnimation {
                        target: field
                        property: "Layout.leftMargin"
                        to: 0
                        duration: 50
                    }
                }

                Connections {
                    target: root.lock

                    function onShake(): void {
                        shakeAnim.restart();
                    }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 360
                Layout.preferredHeight: implicitHeight
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: root.lock.message
                opacity: text !== "" ? 1 : 0
                color: Colours.palette.m3error

                Behavior on opacity {
                    Anim {}
                }
            }
        }

        // Bottom: battery and what's playing
        RowLayout {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: Appearance.padding.large * 2
            spacing: Appearance.spacing.large * 2

            Row {
                visible: root.battery.isLaptopBattery
                spacing: Appearance.spacing.small

                MaterialIcon {
                    text: root.battery.state === UPowerDeviceState.Charging ? "battery_charging_full" : "battery_full"
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: `${Math.round(root.battery.percentage * 100)}%`
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            Row {
                visible: Players.active?.isPlaying ?? false
                spacing: Appearance.spacing.small

                MaterialIcon {
                    text: "music_note"
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: `${Players.active?.trackTitle ?? ""}${Players.active?.trackArtist ? " · " + Players.active.trackArtist : ""}`
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, 400)
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }
}
