import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// One app in the launcher: icon, name, and its description
Item {
    id: root

    required property DesktopEntry modelData
    // iconPath(name, true) returns "" when no installed icon theme has that icon
    readonly property string iconSource: Quickshell.iconPath(modelData.icon, true)

    signal activated

    implicitHeight: Appearance.sizes.launcherItemHeight

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Appearance.padding.normal
        anchors.right: parent.right
        anchors.rightMargin: Appearance.padding.normal
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.normal

        // App icons come from the icon theme; iconPath finds the file for a name like "firefox"
        IconImage {
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: 36
            visible: root.iconSource !== ""
            source: root.iconSource
        }

        // No icon installed for this app: show a generic one instead of a "missing image" pattern
        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            horizontalAlignment: Text.AlignHCenter
            visible: root.iconSource === ""
            text: "apps"
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
            }

            StyledText {
                width: parent.width
                text: root.modelData.comment || root.modelData.genericName
                visible: text !== ""
                elide: Text.ElideRight
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
