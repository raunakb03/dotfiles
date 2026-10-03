import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

// One clickable row: icon, text, and optional text on the right. Highlighted when `selected`.
StyledRect {
    id: root

    property string icon
    property string text
    property string trailing
    property bool selected

    signal clicked

    implicitHeight: row.implicitHeight + Appearance.padding.small * 2
    radius: Appearance.rounding.full
    color: selected ? Colours.palette.m3secondaryContainer : "transparent"

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.leftMargin: Appearance.padding.normal
        anchors.rightMargin: Appearance.padding.normal
        spacing: Appearance.spacing.small

        MaterialIcon {
            text: root.icon
            fill: root.selected ? 1 : 0
            color: root.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
            visible: root.icon !== ""
        }

        StyledText {
            Layout.fillWidth: true
            text: root.text
            elide: Text.ElideRight
            color: root.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
        }

        StyledText {
            text: root.trailing
            visible: text !== ""
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    StateLayer {
        onClicked: root.clicked()
    }
}
