import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

// Global shortcuts: named actions Hyprland can trigger with hl.dsp.global("myshell:<name>").
// The keys themselves are bound in ~/.config/hypr/hyprland/keybinds.lua.
//
// Note: after editing this file, restart the shell (Ctrl + Super + Alt + R). A hot reload
// re-creates the shortcuts, but Hyprland keeps the old registrations and the new ones stay deaf.
Scope {
    LauncherShortcut {
        name: "launcher"
        description: "Open or close the launcher"
    }

    LauncherShortcut {
        name: "clipboard"
        description: "Open the launcher on the clipboard history"
        text: ">clip "
    }

    LauncherShortcut {
        name: "keybinds"
        description: "Open the launcher on the keybindings"
        text: ">keys "
    }

    // Toggles the launcher, starting with `text` in the search field.
    // A release-type bind (the Super tap) sends only "released"; `hyprctl dispatch` sends only
    // "pressed"; a normal bind sends both. Toggle on whichever comes first, never twice per press.
    component LauncherShortcut: GlobalShortcut {
        property string text: ""
        property bool handledPress: false

        appid: "myshell"

        onPressed: {
            handledPress = true;
            ShellState.toggleLauncher(text);
        }

        onReleased: {
            if (!handledPress)
                ShellState.toggleLauncher(text);
            handledPress = false;
        }
    }
}
