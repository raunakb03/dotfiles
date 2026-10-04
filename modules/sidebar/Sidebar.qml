import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.modules.notifications
import qs.services

// The notification history, sliding out of the bar's edge at full height (Super + N)
Item {
    id: root

    required property bool open
    required property bool barOnRight

    readonly property real padding: Appearance.padding.large
    readonly property real openWidth: Appearance.sizes.notificationWidth + padding * 2

    width: open ? openWidth : 0
    height: parent.height
    x: barOnRight ? parent.width - Appearance.sizes.barWidth - width : Appearance.sizes.barWidth
    y: 0
    clip: true

    Behavior on width {
        Anim {
            easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
        }
    }

    ColumnLayout {
        // Anchored to the bar side, so the content slides out of the bar
        x: root.barOnRight ? root.padding : root.width - root.openWidth + root.padding
        y: root.padding
        width: Appearance.sizes.notificationWidth
        height: parent.height - root.padding * 2
        spacing: Appearance.spacing.normal

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: "Notifications"
                font.pointSize: Appearance.font.size.large
                font.bold: true
            }

            // Keep awake ("caffeine"): pauses the idle lock / screen off / suspend (modules/Idle.qml)
            IconButton {
                icon: "coffee"
                size: 32
                filled: ShellState.keepAwake
                onClicked: ShellState.keepAwake = !ShellState.keepAwake
            }

            // Do not disturb: new notifications go straight to this history, no popups
            MaterialIcon {
                text: Notifs.dnd ? "notifications_off" : "notifications_active"
                color: Notifs.dnd ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }

            StyledSwitch {
                checked: Notifs.dnd
                onToggled: Notifs.dnd = checked
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: Notifs.dnd ? "Do not disturb is on: no popups" : `${Notifs.list.length} notification${Notifs.list.length === 1 ? "" : "s"}`
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.small
        }

        ListView {
            id: list

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Appearance.spacing.small
            model: Notifs.list

            delegate: NotificationCard {
                required property var modelData

                width: list.width
                entry: modelData
                inHistory: true
            }

            // Smoothly close the gap when a notification is dismissed
            displaced: Transition {
                Anim {
                    property: "y"
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: Notifs.list.length === 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: "No notifications"
            color: Colours.palette.m3onSurfaceVariant
        }

        // Clear all
        StyledRect {
            Layout.alignment: Qt.AlignRight
            visible: Notifs.list.length > 0
            implicitWidth: clearRow.implicitWidth + Appearance.padding.large * 2
            implicitHeight: clearRow.implicitHeight + Appearance.padding.small * 2
            radius: Appearance.rounding.full
            color: Colours.palette.m3secondaryContainer

            Row {
                id: clearRow

                anchors.centerIn: parent
                spacing: Appearance.spacing.small

                MaterialIcon {
                    text: "clear_all"
                    color: Colours.palette.m3onSecondaryContainer
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Clear all"
                    color: Colours.palette.m3onSecondaryContainer
                }
            }

            StateLayer {
                onClicked: Notifs.clearAll()
            }
        }
    }
}
