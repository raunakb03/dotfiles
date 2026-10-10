import QtQuick
import QtQuick.Shapes
import qs.config
import qs.services

// A ring that fills clockwise from the bottom-left to the bottom-right (270°), like a speedometer.
// The value and a label sit in the middle.
Item {
    id: root

    property real value: 0 // 0.0 - 1.0
    property string text   // in the middle, e.g. "42%"
    property string label  // under the text, e.g. "CPU"
    property color colour: Colours.palette.m3primary
    property real thickness: 10

    readonly property real startAngle: 135 // degrees; 0 = 3 o'clock, clockwise
    readonly property real sweep: 270

    implicitWidth: 140
    implicitHeight: 140

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // The empty track
        ShapePath {
            fillColor: "transparent"
            strokeColor: Colours.palette.m3surfaceContainerHighest
            strokeWidth: root.thickness
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.width / 2 - root.thickness / 2
                radiusY: root.height / 2 - root.thickness / 2
                startAngle: root.startAngle
                sweepAngle: root.sweep
            }
        }

        // The filled part
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.colour
            strokeWidth: root.thickness
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.width / 2 - root.thickness / 2
                radiusY: root.height / 2 - root.thickness / 2
                startAngle: root.startAngle
                sweepAngle: root.sweep * Math.max(0.001, Math.min(1, root.animatedValue))
            }
        }
    }

    property real animatedValue: value
    Behavior on animatedValue {
        Anim {}
    }

    Column {
        anchors.centerIn: parent

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.text
            font.pointSize: Appearance.font.size.large
            font.bold: true
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }
    }
}
