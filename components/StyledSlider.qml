import QtQuick
import QtQuick.Controls.Basic
import qs.config
import qs.services

// A Material-style slider: a filled track up to the handle, an empty track after it.
// Use `value` (0-1) and `onMoved` like any Qt Slider.
Slider {
    id: root

    implicitHeight: 24
    padding: 0

    background: Item {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: 8

        // Filled part
        StyledRect {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: Appearance.rounding.full
            color: Colours.palette.m3primary
        }

        // Empty part
        StyledRect {
            x: root.visualPosition * parent.width
            width: parent.width - x
            height: parent.height
            radius: Appearance.rounding.full
            color: Colours.palette.m3secondaryContainer
        }
    }

    handle: StyledRect {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        implicitWidth: 6
        implicitHeight: root.implicitHeight
        radius: Appearance.rounding.full
        color: Colours.palette.m3primary
    }
}
