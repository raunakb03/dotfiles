import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// Icons of apps running in the background (Discord, Steam, nm-applet, ...)
StyledRect {
    id: root

    implicitWidth: Appearance.sizes.barInnerWidth
    implicitHeight: column.implicitHeight + Appearance.padding.small * 2
    visible: SystemTray.items.values.length > 0
    radius: Appearance.rounding.full
    color: Colours.palette.m3surfaceContainer

    Column {
        id: column

        anchors.centerIn: parent
        spacing: Appearance.spacing.small

        Repeater {
            model: SystemTray.items

            MouseArea {
                id: item

                required property SystemTrayItem modelData

                implicitWidth: Appearance.font.size.normal * 1.6
                implicitHeight: implicitWidth
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor

                onClicked: event => {
                    if (event.button === Qt.LeftButton)
                        modelData.activate();
                    else if (modelData.hasMenu)
                        // Show the app's own menu beside the bar, on the side facing the screen
                        modelData.display(QsWindow.window, mapToItem(null, Config.bar.position === "right" ? 0 : width, 0).x, mapToItem(null, 0, 0).y);
                    else
                        modelData.secondaryActivate();
                }

                IconImage {
                    anchors.fill: parent
                    source: item.modelData.icon
                }
            }
        }
    }
}
