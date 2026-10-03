pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Shell-wide state that isn't tied to one file: which screen (if any) shows the launcher
Singleton {
    property string launcherScreen: "" // monitor name, e.g. "eDP-1"; "" = closed
    property string launcherText: ""   // what the search field starts with when it opens (e.g. ">clip ")

    // Open on the monitor that has focus (optionally straight into a mode), or close if open
    function toggleLauncher(text: string): void {
        if (launcherScreen !== "") {
            launcherScreen = "";
            return;
        }
        launcherText = text ?? "";
        launcherScreen = Hyprland.focusedMonitor?.name ?? "";
    }

    function closeLauncher(): void {
        launcherScreen = "";
    }
}
