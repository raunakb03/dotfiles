import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services

PanelWindow {
    id: root

    required property ShellScreen modelData

    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 36
    color: Colours.palette.m3surface

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Appearance.padding.normal
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.small

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            color: Colours.palette.m3onSurfaceVariant
            text: "desktop_windows"
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.smaller
            text: root.modelData.name
        }
    }

    StyledRect {
        anchors.centerIn: parent
        implicitWidth: clockRow.implicitWidth + Appearance.padding.normal * 2
        implicitHeight: clockRow.implicitHeight + Appearance.padding.small
        radius: Appearance.rounding.full
        color: Colours.palette.m3surfaceContainerHigh

        // Grow/shrink smoothly when the text gets longer/shorter
        Behavior on implicitWidth {
            Anim {}
        }

        StateLayer {
            onClicked: Config.bar.showSeconds = !Config.bar.showSeconds
        }

        Row {
            id: clockRow

            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                color: Colours.palette.m3primary
                fill: 1
                text: "schedule"
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                color: Colours.palette.m3primary
                font.family: Appearance.font.family.mono
                text: Time.format(Config.bar.showSeconds ? "hh:mm:ss" : "hh:mm")
            }
        }
    }

    Row {
        visible: Config.bar.showDate
        anchors.right: parent.right
        anchors.rightMargin: Appearance.padding.normal
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.small

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: "calendar_month"
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Time.format("dddd d MMMM")
        }
    }
}
