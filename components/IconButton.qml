import QtQuick
import qs.config
import qs.services

// A round button with a Material icon. `filled` uses the primary colour (e.g. play/pause).
StyledRect {
    id: root

    property alias icon: label.text
    property bool filled: false
    property bool disabled: false
    property real size: 40

    signal clicked

    implicitWidth: size
    implicitHeight: size
    radius: Appearance.rounding.full
    color: filled ? Colours.palette.m3primary : "transparent"
    opacity: disabled ? 0.4 : 1

    MaterialIcon {
        id: label

        anchors.centerIn: parent
        fill: root.filled ? 1 : 0
        font.pointSize: root.size * 0.4
        color: root.filled ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
    }

    StateLayer {
        disabled: root.disabled
        color: root.filled ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
        onClicked: root.clicked()
    }
}
