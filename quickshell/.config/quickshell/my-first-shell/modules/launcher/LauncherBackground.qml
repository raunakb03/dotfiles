import QtQuick
import qs.components
import qs.config
import qs.services

// The launcher's background: rounded at the top, square at the screen edge,
// with curved joins to the bottom edge on both sides (like the popouts against the bar)
Item {
    id: root

    required property Item panel

    readonly property real radius: Math.min(Appearance.rounding.extraLarge, panel.width / 2, panel.height / 2)

    anchors.fill: parent
    visible: panel.height > 0

    StyledRect {
        x: root.panel.x
        y: root.panel.y
        width: root.panel.width
        height: root.panel.height
        color: Colours.palette.m3surface
        topLeftRadius: root.radius
        topRightRadius: root.radius
    }

    // Left of the panel, on the bottom edge
    InvertedCorner {
        size: root.radius
        corner: InvertedCorner.BottomRight
        x: root.panel.x - size
        y: root.panel.y + root.panel.height - size
    }

    // Right of the panel, on the bottom edge
    InvertedCorner {
        size: root.radius
        corner: InvertedCorner.BottomLeft
        x: root.panel.x + root.panel.width
        y: root.panel.y + root.panel.height - size
    }
}
