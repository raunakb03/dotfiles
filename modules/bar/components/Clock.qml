import QtQuick
import qs.components
import qs.config
import qs.services

// Hours above minutes, so it fits a narrow vertical bar
Column {
    spacing: 0

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        color: Colours.palette.m3primary
        font.family: Appearance.font.family.mono
        font.bold: true
        text: Time.format("hh")
    }

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        color: Colours.palette.m3primary
        font.family: Appearance.font.family.mono
        text: Time.format("mm")
    }
}
