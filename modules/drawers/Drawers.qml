import QtQuick
import Quickshell

// Per monitor: the drawer window (frame + bar + popouts) and the windows that reserve its space
Variants {
    model: Quickshell.screens

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
