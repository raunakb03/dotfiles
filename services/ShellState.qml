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

    function closeLauncher(): void {
        launcherScreen = "";
    }

    // Close everything (e.g. when you click outside the shell)
    function closeAll(): void {
        launcherScreen = "";
        sidebarScreen = "";
        sessionScreen = "";
    }
}
