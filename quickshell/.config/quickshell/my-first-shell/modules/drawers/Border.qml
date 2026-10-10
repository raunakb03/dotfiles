import QtQuick
import QtQuick.Shapes
import qs.components
import qs.services

// The frame around the screen: the whole screen filled in the surface colour,
// minus a rounded rectangle in the middle (where the windows are).
Shape {
    id: root

    required property bool barOnRight
    required property real barWidth
    required property real thickness
    required property real rounding

    // The "hole": everything except the bar on one side and the thin border on the others
    readonly property real innerX: barOnRight ? thickness : barWidth
    readonly property real innerY: thickness
    readonly property real innerWidth: width - barWidth - thickness
    readonly property real innerHeight: height - thickness * 2

    preferredRendererType: Shape.CurveRenderer // smooth, anti-aliased curves

    ShapePath {
        fillColor: Colours.palette.m3surface
        strokeWidth: -1 // no outline
        // Odd-even: an area inside BOTH rectangles counts as "outside", so the inner one becomes a hole
        fillRule: ShapePath.OddEvenFill

        PathRectangle {
            x: 0
            y: 0
            width: root.width
            height: root.height
        }

        PathRectangle {
            x: root.innerX
            y: root.innerY
            width: root.innerWidth
            height: root.innerHeight
            radius: root.rounding
        }

        Behavior on fillColor {
            CAnim {}
        }
    }
}
