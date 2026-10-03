import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.modules.bar
import qs.modules.bar.popouts
import qs.modules.launcher
import qs.services

// One transparent, full-screen window per monitor. It draws the frame, the bar and the
// popouts, but only takes mouse input where they actually are (`mask`); everywhere else,
// clicks go straight through to the windows below.
PanelWindow {
    id: root

    readonly property bool barOnRight: Config.bar.position === "right"
    readonly property bool launcherOpen: ShellState.launcherScreen === screen?.name

    WlrLayershell.namespace: "myshell-drawers"
    WlrLayershell.layer: WlrLayer.Top
    // The launcher and the Wi-Fi password field need the keyboard; otherwise never take it
    WlrLayershell.keyboardFocus: popouts.locked || launcherOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore // the Exclusions windows reserve the space instead

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    // The parts of the window that receive mouse input
    mask: Region {
        Region {
            item: bar
        }

        Region {
            item: wrapper
        }

        Region {
            item: launcher
        }
    }

    // While the launcher is open, clicking anywhere outside this window closes it
    HyprlandFocusGrab {
        active: root.launcherOpen
        windows: [root]
        onCleared: ShellState.closeLauncher()
    }

    PopoutState {
        id: popouts
    }

    // Everything painted in the surface colour, as one layer so it gets one soft shadow
    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.7)
            blurMax: 15
        }

        Border {
            anchors.fill: parent
            barOnRight: root.barOnRight
            barWidth: Appearance.sizes.barWidth
            thickness: Config.border.thickness
            rounding: Config.border.rounding
        }

        Background {
            wrapper: wrapper
            barOnRight: root.barOnRight
        }

        LauncherBackground {
            panel: launcher
        }
    }

    Bar {
        id: bar

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: root.barOnRight ? undefined : parent.left
        anchors.right: root.barOnRight ? parent.right : undefined
        screen: root.screen
        popouts: popouts
    }

    Wrapper {
        id: wrapper

        popouts: popouts
        barOnRight: root.barOnRight
    }

    Launcher {
        id: launcher

        open: root.launcherOpen
        // Centred in the part of the screen the bar doesn't cover
        centreX: root.barOnRight ? (root.width - Appearance.sizes.barWidth) / 2 : Appearance.sizes.barWidth + (root.width - Appearance.sizes.barWidth) / 2
    }
}
