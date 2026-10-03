import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.config
import qs.modules.bar.components
import qs.services

// Caelestia-style vertical bar on the left edge of each screen
PanelWindow {
    id: root

    required property ShellScreen modelData
    readonly property bool onRight: Config.bar.position === "right"

    screen: modelData

    // Glued to top + bottom + one side edge (set in shell.json: bar.position)
    anchors {
        top: true
        bottom: true
        left: !onRight
        right: onRight
    }
    implicitWidth: Appearance.sizes.barInnerWidth + Appearance.padding.small * 2
    color: Colours.palette.m3surface

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
            screen: root.modelData
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
        }
    }
}
