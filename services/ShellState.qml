pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Shell-wide state that isn't tied to one file: which screen (if any) shows the launcher
Singleton {
    // Which monitor shows each panel ("" = closed). Panels open on the focused monitor.
    property string launcherScreen: ""
    property string sidebarScreen: ""
    property string sessionScreen: ""
    property string dashboardScreen: ""
    property bool dashboardPinned: false // opened with the key (stays open) rather than by hovering
    property int dashboardTab: 0         // remembered between openings
    property bool keepAwake: false       // "caffeine": the idle steps (Idle.qml) are paused
    property string launcherText: "" // what the launcher's search field starts with (e.g. ">clip ")

    readonly property string focusedScreen: Hyprland.focusedMonitor?.name ?? ""

    // Open on the focused monitor (optionally straight into a mode), or close if open
    function toggleLauncher(text: string): void {
        if (launcherScreen !== "") {
            launcherScreen = "";
            return;
        }
        launcherText = text ?? "";
        launcherScreen = focusedScreen;
    }

    function toggleSidebar(): void {
        sidebarScreen = sidebarScreen !== "" ? "" : focusedScreen;
    }

    function toggleSession(): void {
        sessionScreen = sessionScreen !== "" ? "" : focusedScreen;
    }

    function toggleDashboard(): void {
        if (dashboardScreen !== "" && dashboardPinned) {
            dashboardScreen = "";
            return;
        }
        dashboardPinned = true;
        dashboardScreen = focusedScreen;
    }

    // Hovering the top edge: open until the mouse leaves (see ContentWindow.qml)
    function hoverDashboard(screen: string): void {
        if (dashboardScreen !== "")
            return;
        dashboardPinned = false;
        dashboardScreen = screen;
    }

    function closeLauncher(): void {
        launcherScreen = "";
    }

    // Close everything (e.g. when you click outside the shell)
    function closeAll(): void {
        launcherScreen = "";
        sidebarScreen = "";
        sessionScreen = "";
        dashboardScreen = "";
    }
}
