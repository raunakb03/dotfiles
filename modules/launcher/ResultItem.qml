import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// One row in the launcher's list: an app, a clipboard entry, a keybind or a mode.
// `modelData` is a plain object made by Launcher.qml:
//   { name, detail, image (icon file or ""), icon (Material name), activate() }
Item {
    id: root

    required property var modelData

    signal activated

    implicitHeight: Appearance.sizes.launcherItemHeight

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Appearance.padding.normal
        anchors.right: parent.right
        anchors.rightMargin: Appearance.padding.normal
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.normal

        // An app's icon from the icon theme…
        IconImage {
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: 36
            visible: root.modelData.image !== ""
            source: root.modelData.image
        }

        // …or a Material icon (also the fallback when an app has no installed icon)
        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            horizontalAlignment: Text.AlignHCenter
            visible: root.modelData.image === ""
            text: root.modelData.icon
            font.pointSize: Appearance.font.size.large
            color: Colours.palette.m3onSurfaceVariant
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 36 - parent.spacing

            StyledText {
                width: parent.width
                text: root.modelData.name
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            StyledText {
                width: parent.width
                text: root.modelData.detail
                visible: text !== ""
                elide: Text.ElideRight
                maximumLineCount: 1
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    StateLayer {
        radius: Appearance.rounding.full
        onClicked: root.activated()
    }
}
