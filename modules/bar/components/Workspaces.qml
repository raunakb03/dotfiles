import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services

// A column of workspace buttons, with a pill that slides to the active one
StyledRect {
    id: root

    required property ShellScreen screen

    readonly property int shown: Config.bar.workspaces.shown
    readonly property int activeId: Hypr.monitorFor(screen)?.activeWorkspace?.id ?? 1

    // Workspaces come in groups of `shown`: with 5, group 1 = 1-5, group 2 = 6-10, ...
    readonly property int groupOffset: Math.floor((activeId - 1) / shown) * shown
    readonly property int activeIndex: (activeId - 1) % shown

    readonly property int buttonSize: Appearance.sizes.barInnerWidth - Appearance.padding.extraSmall * 2

    implicitWidth: Appearance.sizes.barInnerWidth
    implicitHeight: column.implicitHeight + Appearance.padding.extraSmall * 2
    radius: Appearance.rounding.full
    color: Colours.palette.m3surfaceContainer

    // The active-workspace pill, behind the numbers
    StyledRect {
        x: Appearance.padding.extraSmall
        y: Appearance.padding.extraSmall + root.activeIndex * (root.buttonSize + column.spacing)
        width: root.buttonSize
        height: root.buttonSize
        radius: Appearance.rounding.full
        color: Colours.palette.m3primary

        Behavior on y {
            Anim {
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
            }
        }
    }

    Column {
        id: column

        anchors.centerIn: parent
        spacing: Appearance.spacing.extraSmall

        Repeater {
            model: root.shown

            // One button per workspace in the current group
            Item {
                id: button

                required property int index
                readonly property int wsId: root.groupOffset + index + 1
                readonly property bool active: wsId === root.activeId
                readonly property bool occupied: Hypr.isOccupied(wsId)

                implicitWidth: root.buttonSize
                implicitHeight: root.buttonSize

                StyledText {
                    anchors.centerIn: parent
                    text: button.wsId
                    font.pointSize: Appearance.font.size.small
                    font.bold: button.active || button.occupied
                    color: button.active ? Colours.palette.m3onPrimary
                         : button.occupied ? Colours.palette.m3onSurface
                         : Colours.palette.m3outline
                }

                StateLayer {
                    radius: Appearance.rounding.full
                    onClicked: Hypr.focusWorkspace(button.wsId)
                }
            }
        }
    }

    // Scroll over the workspaces to move to the previous/next one
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => Hypr.focusWorkspace(event.angleDelta.y > 0 ? "r-1" : "r+1")
    }
}
