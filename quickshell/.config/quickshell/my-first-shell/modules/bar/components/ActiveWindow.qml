import QtQuick
import qs.components
import qs.config
import qs.services

// The focused window's title, written vertically. Fills the free space in the bar.
Item {
    id: root

    implicitWidth: label.implicitHeight

    StyledText {
        id: label

        anchors.centerIn: parent
        rotation: 90

        // Rotated, so the text's *width* runs along the bar's height
        width: Math.min(implicitWidth, root.height)
        elide: Text.ElideRight
        color: Colours.palette.m3onSurfaceVariant
        text: Hypr.activeTitle || "Desktop"
    }
}
