import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

// Volume and brightness, as two vertical bars sliding out of the bar's edge (vertically
// centred) when either changes. Display only: it takes no mouse input.
Item {
    id: root

    required property bool open
    required property bool barOnRight

    readonly property real padding: Appearance.padding.normal
    readonly property real openWidth: content.implicitWidth + padding * 2

    width: open ? openWidth : 0
    height: content.implicitHeight + padding * 2
    x: barOnRight ? parent.width - Appearance.sizes.barWidth - width : Appearance.sizes.barWidth
    y: (parent.height - height) / 2
    clip: true

    Behavior on width {
        Anim {
            easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
        }
    }

    RowLayout {
        id: content

        // Fixed against the bar, so it slides out of it
        x: root.barOnRight ? root.padding : root.width - root.openWidth + root.padding
        y: root.padding
        spacing: Appearance.spacing.normal

        Level {
            value: Audio.muted ? 0 : Audio.volume
            icon: Audio.muted ? "volume_off" : Audio.volume < 0.33 ? "volume_mute" : Audio.volume < 0.66 ? "volume_down" : "volume_up"
        }

        Level {
            value: Brightness.value
            icon: Brightness.value < 0.33 ? "brightness_low" : Brightness.value < 0.66 ? "brightness_medium" : "brightness_high"
        }
    }

    // A vertical pill filled from the bottom, with an icon at the bottom
    component Level: StyledRect {
        id: level

        property real value  // 0.0 - 1.0
        property string icon

        implicitWidth: Appearance.sizes.barInnerWidth + Appearance.padding.small
        implicitHeight: Appearance.sizes.osdHeight
        radius: Appearance.rounding.full
        color: Colours.palette.m3surfaceContainerHigh

        StyledRect {
            anchors.bottom: parent.bottom
            width: parent.width
            // Never smaller than a circle, so the icon always sits on the fill
            height: Math.max(parent.width, parent.height * Math.min(1, level.value))
            radius: Appearance.rounding.full
            color: Colours.palette.m3primary

            Behavior on height {
                Anim {
                    duration: Appearance.anim.durations.small
                }
            }
        }

        MaterialIcon {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: (parent.width - height) / 2
            anchors.horizontalCenter: parent.horizontalCenter
            text: level.icon
            fill: 1
            color: Colours.palette.m3onPrimary
        }
    }
}
