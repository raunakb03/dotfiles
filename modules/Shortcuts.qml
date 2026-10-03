import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

// Global shortcuts: named actions Hyprland can trigger with hl.dsp.global("myshell:<name>").
// The keys themselves are bound in ~/.config/hypr/hyprland/keybinds.lua.
//
// Note: after editing this file, restart the shell (Ctrl + Super + Alt + R). A hot reload
// re-creates the shortcut, but Hyprland keeps the old registration and the new one stays deaf.
Scope {
    GlobalShortcut {
        // The Super-tap bind fires on key *release*, so Hyprland sends only "released".
        // `hyprctl dispatch 'hl.dsp.global(...)'` sends only "pressed". A press-type bind sends
        // both. Toggle on whichever comes first, but never twice for one key press.
        property bool handledPress: false

        appid: "myshell"
        name: "launcher"
        description: "Open or close the launcher"

        onPressed: {
            handledPress = true;
            ShellState.toggleLauncher();
        }

        onReleased: {
            if (!handledPress)
                ShellState.toggleLauncher();
            handledPress = false;
        }
    }
}
