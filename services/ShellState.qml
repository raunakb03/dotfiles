pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Shell-wide state that isn't tied to one file: which screen (if any) shows the launcher
Singleton {
    property string launcherScreen: "" // monitor name, e.g. "eDP-1"; "" = closed

    // Open on the monitor that has focus, or close if it's already open
    function toggleLauncher(): void {
        launcherScreen = launcherScreen !== "" ? "" : (Hyprland.focusedMonitor?.name ?? "");
    }

    function closeLauncher(): void {
        launcherScreen = "";
    }
}
