import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.config
import qs.modules.bar.components
import qs.modules.bar.popouts
import qs.services

// Caelestia-style vertical bar. Since Phase 6 it's not a window of its own: it lives inside
// the drawer window (modules/drawers/ContentWindow.qml), which also draws its background.
Item {
    id: root

    required property ShellScreen screen
    required property PopoutState popouts

    implicitWidth: Appearance.sizes.barWidth

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: Appearance.padding.normal
        anchors.bottomMargin: Appearance.padding.normal
        spacing: Appearance.spacing.normal

        OsIcon {
            Layout.alignment: Qt.AlignHCenter
        }

        Workspaces {
            Layout.alignment: Qt.AlignHCenter
            screen: root.screen
        }

        ActiveWindow {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true // take all the space left over
        }

        Tray {
            Layout.alignment: Qt.AlignHCenter
        }

        Clock {
            Layout.alignment: Qt.AlignHCenter
        }

        StatusIcons {
            Layout.alignment: Qt.AlignHCenter
            popouts: root.popouts
        }
    }
}
