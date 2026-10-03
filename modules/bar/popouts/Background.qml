import QtQuick
import qs.components
import qs.config
import qs.services

// The popout's background, drawn in the surface colour so it looks like part of the frame.
// Rounded on the screen side, square on the bar side, with two curved "fillets" where it meets the bar.
Item {
    id: root

    required property Item wrapper
    required property bool barOnRight

    readonly property real radius: Math.min(Config.border.rounding, wrapper.width / 2, wrapper.height / 2)
    readonly property real barEdge: barOnRight ? wrapper.x + wrapper.width : wrapper.x

    anchors.fill: parent
    visible: wrapper.width > 0

    StyledRect {
        x: root.wrapper.x
        y: root.wrapper.y
        width: root.wrapper.width
        height: root.wrapper.height
        color: Colours.palette.m3surface

        topLeftRadius: root.barOnRight ? root.radius : 0
        bottomLeftRadius: root.barOnRight ? root.radius : 0
        topRightRadius: root.barOnRight ? 0 : root.radius
        bottomRightRadius: root.barOnRight ? 0 : root.radius
    }

    // Above the popout, against the bar
    InvertedCorner {
        size: root.radius
        corner: root.barOnRight ? InvertedCorner.BottomRight : InvertedCorner.BottomLeft
        x: root.barOnRight ? root.barEdge - size : root.barEdge
        y: root.wrapper.y - size
    }

    // Below the popout, against the bar
    InvertedCorner {
        size: root.radius
        corner: root.barOnRight ? InvertedCorner.TopRight : InvertedCorner.TopLeft
        x: root.barOnRight ? root.barEdge - size : root.barEdge
        y: root.wrapper.y + root.wrapper.height
    }
}
