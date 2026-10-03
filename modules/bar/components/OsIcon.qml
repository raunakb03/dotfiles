import QtQuick
import QtQuick.Effects
import qs.config
import qs.services

// The distro logo, recoloured to the theme's primary colour
Item {
    implicitWidth: Appearance.sizes.barInnerWidth
    implicitHeight: Appearance.sizes.barInnerWidth

    Image {
        id: logo

        anchors.centerIn: parent
        width: parent.width * 0.75
        height: width
        source: "file:///usr/share/pixmaps/archlinux-logo.svg"
        sourceSize: Qt.size(width * 2, height * 2) // render the SVG sharp
        visible: false // drawn by the effect below instead
    }

    // Recolour: turn the logo into a single-colour shape in m3primary
    MultiEffect {
        anchors.fill: logo
        source: logo
        colorization: 1
        colorizationColor: Colours.palette.m3primary
    }
}
