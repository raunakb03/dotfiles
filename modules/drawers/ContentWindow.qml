import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.components
import qs.config
import qs.modules.bar
import qs.modules.bar.popouts
import qs.modules.launcher
import qs.modules.notifications
import qs.modules.osd
import qs.modules.session
import qs.modules.sidebar
import qs.services

// One transparent, full-screen window per monitor. It draws the frame, the bar and the
// popouts, but only takes mouse input where they actually are (`mask`); everywhere else,
// clicks go straight through to the windows below.
PanelWindow {
    id: root

    readonly property bool barOnRight: Config.bar.position === "right"
    readonly property bool launcherOpen: ShellState.launcherScreen === screen?.name
    readonly property bool sidebarOpen: ShellState.sidebarScreen === screen?.name
    readonly property bool sessionOpen: ShellState.sessionScreen === screen?.name

    WlrLayershell.namespace: "myshell-drawers"
    // Fullscreen windows are drawn above the Top layer. While a panel is showing, move up to
    // Overlay (above everything) so it also shows over a fullscreen app. (The bar comes along
    // for that moment: it's in the same window.)
    readonly property bool panelShowing: launcherOpen || sidebarOpen || sessionOpen || popups.height > 0 || osd.width > 0
    WlrLayershell.layer: panelShowing ? WlrLayer.Overlay : WlrLayer.Top
    // The launcher, the session menu and the Wi-Fi password field need the keyboard;
    // otherwise never take it
    WlrLayershell.keyboardFocus: popouts.locked || launcherOpen || sessionOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
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

        Region {
            item: popups
        }

        Region {
            item: sidebar
        }

        Region {
            item: session
        }
        // (the OSD is display-only: clicks go through it)
    }

    // While the launcher, sidebar or session menu is open, clicking outside this window closes it
    HyprlandFocusGrab {
        active: root.launcherOpen || root.sidebarOpen || root.sessionOpen
        windows: [root]
        onCleared: ShellState.closeAll()
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

        AttachedBackground {
            panel: popups
            barOnRight: root.barOnRight
        }

        AttachedBackground {
            panel: sidebar
            barOnRight: root.barOnRight
        }

        AttachedBackground {
            panel: osd
            barOnRight: root.barOnRight
        }

        AttachedBackground {
            panel: session
            barOnRight: root.barOnRight
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

    Popups {
        id: popups

        // Only on the focused monitor, and not while the history is open
        visible: ShellState.focusedScreen === root.screen?.name && !root.sidebarOpen
        barOnRight: root.barOnRight
    }

    Sidebar {
        id: sidebar

        open: root.sidebarOpen
        barOnRight: root.barOnRight
    }

    Osd {
        id: osd

        open: OsdState.visible && OsdState.screen === root.screen?.name
        barOnRight: root.barOnRight
    }

    Session {
        id: session

        open: root.sessionOpen
        barOnRight: root.barOnRight
    }
}
