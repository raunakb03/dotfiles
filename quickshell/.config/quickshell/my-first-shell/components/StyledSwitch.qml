import QtQuick
import QtQuick.Controls.Basic
import qs.config
import qs.services

// A Material-style on/off switch. Use `checked` and `onToggled` like any Qt Switch.
// QtQuick.Controls.Basic is the style that lets us draw our own parts (indicator, background, ...)
Switch {
    id: root

    implicitWidth: 52
    implicitHeight: 32
    padding: 0

    indicator: StyledRect {
        implicitWidth: root.implicitWidth
        implicitHeight: root.implicitHeight
        radius: Appearance.rounding.full
        color: root.checked ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHighest
        border.width: root.checked ? 0 : 2
        border.color: Colours.palette.m3outline

        // The knob: bigger and on the right when on
        StyledRect {
            property real size: root.checked ? 24 : 16

            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - size - 4 : 8
            width: size
            height: size
            radius: Appearance.rounding.full
            color: root.checked ? Colours.palette.m3onPrimary : Colours.palette.m3outline

            Behavior on x {
                Anim {
                    duration: Appearance.anim.durations.small
                }
            }

            Behavior on size {
                Anim {
                    duration: Appearance.anim.durations.small
                }
            }
        }
    }

    background: null
    contentItem: null
}
