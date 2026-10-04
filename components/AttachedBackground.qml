import QtQuick
import qs.config
import qs.services

// The background of a panel that grows out of an edge: the bar's edge or a screen edge.
// It works out which edges `panel` touches, keeps those sides square, rounds the free
// corners, and adds curved joins ("fillets", see InvertedCorner) where the panel meets an edge.
// Used for the popouts, the launcher, notifications, the sidebar, the OSD and the session menu.
Item {
    id: root

    required property Item panel // positioned in the same coordinates as this item (the window)
    required property bool barOnRight

    readonly property real r: Math.min(Appearance.rounding.extraLarge, panel.width / 2, panel.height / 2)
    readonly property real barEdge: barOnRight ? width - Appearance.sizes.barWidth : Appearance.sizes.barWidth

    readonly property real panelLeft: panel.x
    readonly property real panelRight: panel.x + panel.width
    readonly property real panelTop: panel.y
    readonly property real panelBottom: panel.y + panel.height

    // Which edges the panel touches (1 px tolerance)
    readonly property bool touchLeft: !barOnRight && Math.abs(panelLeft - barEdge) < 1
    readonly property bool touchRight: barOnRight && Math.abs(panelRight - barEdge) < 1
    readonly property bool touchTop: panelTop < 1
    readonly property bool touchBottom: panelBottom > height - 1

    anchors.fill: parent
    visible: panel.visible && panel.width > 0 && panel.height > 0

    StyledRect {
        x: root.panelLeft
        y: root.panelTop
        width: root.panel.width
        height: root.panel.height
        color: Colours.palette.m3surface
        topLeftRadius: root.touchTop || root.touchLeft ? 0 : root.r
        topRightRadius: root.touchTop || root.touchRight ? 0 : root.r
        bottomLeftRadius: root.touchBottom || root.touchLeft ? 0 : root.r
        bottomRightRadius: root.touchBottom || root.touchRight ? 0 : root.r
    }

    // Against the bar on the right: above and below the panel
    InvertedCorner {
        visible: root.touchRight && !root.touchTop
        size: root.r
        corner: InvertedCorner.BottomRight
        x: root.panelRight - size
        y: root.panelTop - size
    }
    InvertedCorner {
        visible: root.touchRight && !root.touchBottom
        size: root.r
        corner: InvertedCorner.TopRight
        x: root.panelRight - size
        y: root.panelBottom
    }

    // Against the bar on the left: above and below the panel
    InvertedCorner {
        visible: root.touchLeft && !root.touchTop
        size: root.r
        corner: InvertedCorner.BottomLeft
        x: root.panelLeft
        y: root.panelTop - size
    }
    InvertedCorner {
        visible: root.touchLeft && !root.touchBottom
        size: root.r
        corner: InvertedCorner.TopLeft
        x: root.panelLeft
        y: root.panelBottom
    }

    // Against the top edge: left and right of the panel
    InvertedCorner {
        visible: root.touchTop && !root.touchLeft
        size: root.r
        corner: InvertedCorner.TopRight
        x: root.panelLeft - size
        y: root.panelTop
    }
    InvertedCorner {
        visible: root.touchTop && !root.touchRight
        size: root.r
        corner: InvertedCorner.TopLeft
        x: root.panelRight
        y: root.panelTop
    }

    // Against the bottom edge: left and right of the panel
    InvertedCorner {
        visible: root.touchBottom && !root.touchLeft
        size: root.r
        corner: InvertedCorner.BottomRight
        x: root.panelLeft - size
        y: root.panelBottom - size
    }
    InvertedCorner {
        visible: root.touchBottom && !root.touchRight
        size: root.r
        corner: InvertedCorner.BottomLeft
        x: root.panelRight
        y: root.panelBottom - size
    }
}
