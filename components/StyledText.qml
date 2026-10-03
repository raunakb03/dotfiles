import QtQuick
import qs.config
import qs.services

Text {
    renderType: Text.NativeRendering
    textFormat: Text.PlainText
    color: Colours.palette.m3onSurface
    font.family: Appearance.font.family.sans
    font.pointSize: Appearance.font.size.normal
    Behavior on color {
        CAnim {}
    }
}
