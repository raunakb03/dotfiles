pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property QtObject palette: QtObject {
        readonly property color m3surface: "#131317"
        readonly property color m3surfaceContainerLow: "#1c1b1f"
        readonly property color m3surfaceContainer: "#201f23"
        readonly property color m3surfaceContainerHigh: "#2a292e"
        readonly property color m3surfaceContainerHighest: "#353438"
        readonly property color m3onSurface: "#e5e1e7"
        readonly property color m3onSurfaceVariant: "#c8c5d1"
        readonly property color m3outline: "#918f9a"
        readonly property color m3outlineVariant: "#47464f"
        readonly property color m3primary: "#c2c1ff"
        readonly property color m3onPrimary: "#2a2a60"
        readonly property color m3primaryContainer: "#7171ac"
        readonly property color m3onPrimaryContainer: "#ffffff"
        readonly property color m3secondary: "#c6c4e0"
        readonly property color m3secondaryContainer: "#45455c"
        readonly property color m3onSecondaryContainer: "#b4b2ce"
        readonly property color m3tertiary: "#f5b2e0"
        readonly property color m3error: "#ffb4ab"
    }
}
