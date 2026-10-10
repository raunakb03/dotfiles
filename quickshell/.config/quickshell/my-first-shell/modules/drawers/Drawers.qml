import QtQuick
import Quickshell
import qs.config

// Per monitor: the drawer window (frame + bar + popouts) and the windows that reserve its space
Variants {
    // Wait for shell.json before creating anything. Otherwise the windows start with the
    // default settings (bar on the left, 10 px frame), Hyprland reserves space for those,
    // and the reservation isn't released when the real settings arrive a moment later.
    model: Config.loaded ? Quickshell.screens : []

    Scope {
        id: scope

        required property ShellScreen modelData

        Exclusions {
            screen: scope.modelData
        }

        ContentWindow {
            screen: scope.modelData
        }
    }
}
