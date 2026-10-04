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

    Action {
        name: "sidebar"
        description: "Open or close the notification history"
        onPressed: ShellState.toggleSidebar()
    }

    Action {
        name: "session"
        description: "Open or close the power menu"
        onPressed: ShellState.toggleSession()
    }

    Action {
        name: "brightnessUp"
        description: "Screen brightness up"
        onPressed: Brightness.increase()
    }

    Action {
        name: "brightnessDown"
        description: "Screen brightness down"
        onPressed: Brightness.decrease()
    }

    Action {
        name: "mediaToggle"
        description: "Play / pause the active media player"
        onPressed: Players.togglePlaying()
    }

    Action {
        name: "mediaNext"
        description: "Next track"
        onPressed: Players.next()
    }

    Action {
        name: "mediaPrev"
        description: "Previous track"
        onPressed: Players.previous()
    }

    Action {
        name: "mediaStop"
        description: "Stop the active media player"
        onPressed: Players.stop()
    }

    // A shortcut that does something once per key press
    component Action: GlobalShortcut {
        appid: "myshell"
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
