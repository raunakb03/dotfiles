import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services

// The power menu: lock, log out, suspend, restart, shut down (Ctrl + Alt + Delete).
// Slides out of the bar's edge, vertically centred. Arrow keys + Enter, or click; Escape closes.
Item {
    id: root

    required property bool open
    required property bool barOnRight

    readonly property real padding: Appearance.padding.large
    readonly property real openWidth: column.implicitWidth + padding * 2
    property int current: 0 // the highlighted button (keyboard)

    readonly property var actions: [
        {
            icon: "lock",
            name: "Lock",
            command: ["hyprlock"]
        },
        {
            icon: "logout",
            name: "Log out",
            command: ["hyprctl", "dispatch", "hl.dsp.exit()"]
        },
        {
            icon: "bedtime",
            name: "Suspend",
            command: ["systemctl", "suspend"]
        },
        {
            icon: "restart_alt",
            name: "Restart",
            command: ["systemctl", "reboot"]
        },
        {
            icon: "power_settings_new",
            name: "Shut down",
            command: ["systemctl", "poweroff"]
        }
    ]

    function run(index: int): void {
        ShellState.closeAll();
        Quickshell.execDetached(actions[index].command);
    }

    width: open ? openWidth : 0
    height: column.implicitHeight + padding * 2
    x: barOnRight ? parent.width - Appearance.sizes.barWidth - width : Appearance.sizes.barWidth
    y: (parent.height - height) / 2
    clip: true

    // Every time it opens: start on "Lock" and take the keyboard
    onOpenChanged: {
        if (open) {
            current = 0;
            column.forceActiveFocus();
        }
    }

    Behavior on width {
        Anim {
            easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
        }
    }

    Column {
        id: column

        x: root.barOnRight ? root.padding : root.width - root.openWidth + root.padding
        y: root.padding
        spacing: Appearance.spacing.normal

        Keys.onUpPressed: root.current = (root.current + root.actions.length - 1) % root.actions.length
        Keys.onDownPressed: root.current = (root.current + 1) % root.actions.length
        Keys.onReturnPressed: root.run(root.current)
        Keys.onEnterPressed: root.run(root.current)
        Keys.onEscapePressed: ShellState.closeAll()

        Repeater {
            model: root.actions

            StyledRect {
                id: button

                required property var modelData
                required property int index
                readonly property bool selected: root.current === index

                implicitWidth: Appearance.sizes.sessionButtonSize
                implicitHeight: Appearance.sizes.sessionButtonSize
                radius: selected ? Appearance.rounding.large : Appearance.rounding.full
                color: selected ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh

                Behavior on radius {
                    Anim {
                        duration: Appearance.anim.durations.small
                    }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: button.modelData.icon
                    font.pointSize: Appearance.font.size.extraLarge
                    color: button.selected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                }

                StateLayer {
                    radius: button.radius
                    onClicked: root.run(button.index)
                }

                HoverHandler {
                    onHoveredChanged: if (hovered) root.current = button.index
                }
            }
        }

        // The name of the highlighted action
        StyledText {
            width: Appearance.sizes.sessionButtonSize
            horizontalAlignment: Text.AlignHCenter
            text: root.actions[root.current].name
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }
    }
}
