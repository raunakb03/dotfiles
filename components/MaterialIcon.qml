import QtQuick
import qs.config

StyledText {
    id: root
    property real fill: 0
    property int grade: -25

    font.family: Appearance.font.family.material
    font.pointSize: Appearance.font.size.larger
    font.variableAxes: ({
            FILL: root.fill,
            GRAD: root.grade
        })
}
