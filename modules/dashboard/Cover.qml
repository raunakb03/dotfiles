import QtQuick
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// The active player's album art (or a music note if there's none)
ClippingRectangle {
    id: root

    radius: Appearance.rounding.normal
    color: Colours.palette.m3surfaceContainerHigh

    MaterialIcon {
        anchors.centerIn: parent
        visible: art.status !== Image.Ready
        text: "music_note"
        font.pointSize: Math.max(1, root.width * 0.3)
        color: Colours.palette.m3onSurfaceVariant
    }

    Image {
        id: art

        anchors.fill: parent
        source: Players.active?.trackArtUrl ?? ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: width * 2 // sharp on scaled screens
        sourceSize.height: height * 2
    }
}
