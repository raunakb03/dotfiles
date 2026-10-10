import QtQuick
import qs.config
import qs.services

MouseArea {
    id: root
    property bool disabled
    property color color: Colours.palette.m3onSurface
    property real radius: parent?.radius ?? 0
    anchors.fill: parent
    enabled: !disabled
    hoverEnabled: true
    cursorShape: disabled ? undefined : Qt.PointingHandCursor
    StyledRect {
        anchors.fill: parent
        radius: root.radius
        color: root.color
        opacity: root.pressed ? 0.12 : root.containsMouse ? 0.08 : 0
        Behavior on opacity {
            Anim {
                duration: Appearance.anim.durations.small
            }
        }
    }
}
