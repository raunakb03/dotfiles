import QtQuick
import qs.config

// Animates a colour change smoothly instead of jumping
ColorAnimation {
    duration: Appearance.anim.durations.slowEffects
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.anim.curves.effects
}
