import QtQuick
import QtQuick.Shapes
import qs.services

// A square with a quarter circle cut out: the concave curve that joins two straight edges
// meeting at a right angle (e.g. a popout's top edge and the bar's edge).
// `corner` is the square's solid corner, the one touching both edges.
Shape {
    id: root

    enum Corner {
        TopLeft,
        TopRight,
        BottomLeft,
        BottomRight
    }

    property int corner: InvertedCorner.TopLeft
    property real size: 25
    property color color: Colours.palette.m3surface

    readonly property bool isLeft: corner === InvertedCorner.TopLeft || corner === InvertedCorner.BottomLeft
    readonly property bool isTop: corner === InvertedCorner.TopLeft || corner === InvertedCorner.TopRight

    width: size
    height: size
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.color
        strokeWidth: -1

        // Start at the solid corner, go along the horizontal edge, then curve back up/down to the vertical edge
        startX: root.isLeft ? 0 : root.size
        startY: root.isTop ? 0 : root.size

        PathLine {
            x: root.isLeft ? root.size : 0
            y: root.isTop ? 0 : root.size
        }

        PathArc {
            x: root.isLeft ? 0 : root.size
            y: root.isTop ? root.size : 0
            radiusX: root.size
            radiusY: root.size
            // The arc must bulge towards the solid corner
            direction: (root.isLeft === root.isTop) ? PathArc.Counterclockwise : PathArc.Clockwise
        }

        Behavior on fillColor {
            CAnim {}
        }
    }
}
