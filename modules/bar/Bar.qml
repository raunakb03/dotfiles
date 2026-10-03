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

    StyledText {
        anchors.left: parent.left
        anchors.leftMargin: Appearance.padding.normal
        anchors.verticalCenter: parent.verticalCenter
        color: Colours.palette.m3onSurfaceVariant
        font.pointSize: Appearance.font.size.smaller
        text: root.modelData.name
    }

    StyledRect {
        anchors.centerIn: parent
        implicitWidth: clock.implicitWidth + Appearance.padding.normal * 2
        implicitHeight: clock.implicitHeight + Appearance.padding.small
        radius: Appearance.rounding.full
        color: Colours.palette.m3surfaceContainerHigh

        StyledText {
            id: clock

            anchors.centerIn: parent
            color: Colours.palette.m3primary
            font.family: Appearance.font.family.mono
            text: Time.time
        }
    }

    StyledText {
        anchors.right: parent.right
        anchors.rightMargin: Appearance.padding.normal
        anchors.verticalCenter: parent.verticalCenter
        text: Time.format("dddd d MMMM")
    }
}
