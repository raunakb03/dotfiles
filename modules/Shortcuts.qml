import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

// Global shortcuts: named actions Hyprland can trigger with hl.dsp.global("myshell:<name>").
// The keys themselves are bound in ~/.config/hypr/hyprland/keybinds.lua.
Scope {
    GlobalShortcut {
        appid: "myshell"
        name: "launcher"
        description: "Open or close the launcher"
        onPressed: ShellState.toggleLauncher()
    }
}
