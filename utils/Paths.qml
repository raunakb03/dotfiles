pragma Singleton

import QtQuick
import Quickshell

// Where the shell keeps its files, following the XDG base directory spec
Singleton {
    readonly property string home: Quickshell.env("HOME")

    // Settings you edit: ~/.config/myshell
    readonly property string config: (Quickshell.env("XDG_CONFIG_HOME") || `${home}/.config`) + "/myshell"

    // State the shell/scripts generate: ~/.local/state/myshell
    readonly property string state: (Quickshell.env("XDG_STATE_HOME") || `${home}/.local/state`) + "/myshell"
}
