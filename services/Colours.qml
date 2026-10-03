pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    // Starts as a fixed dark palette. load() overwrites these with the
    // colours generated from the wallpaper (scheme.json).
    readonly property QtObject palette: QtObject {
        property color m3surface: "#131317"
        property color m3surfaceContainerLow: "#1c1b1f"
        property color m3surfaceContainer: "#201f23"
        property color m3surfaceContainerHigh: "#2a292e"
        property color m3surfaceContainerHighest: "#353438"
        property color m3onSurface: "#e5e1e7"
        property color m3onSurfaceVariant: "#c8c5d1"
        property color m3outline: "#918f9a"
        property color m3outlineVariant: "#47464f"
        property color m3primary: "#c2c1ff"
        property color m3onPrimary: "#2a2a60"
        property color m3primaryContainer: "#7171ac"
        property color m3onPrimaryContainer: "#ffffff"
        property color m3secondary: "#c6c4e0"
        property color m3secondaryContainer: "#45455c"
        property color m3onSecondaryContainer: "#b4b2ce"
        property color m3tertiary: "#f5b2e0"
        property color m3error: "#ffb4ab"
    }

    // scheme.json has {"colours": {"primary": "9dcfd9", ...}}
    function load(text: string): void {
        const scheme = JSON.parse(text);

        for (const [name, hex] of Object.entries(scheme.colours)) {
            const prop = "m3" + name; // "primary" -> "m3primary"
            if (root.palette.hasOwnProperty(prop))
                root.palette[prop] = "#" + hex;
        }
    }

    FileView {
        path: Paths.state + "/scheme.json"
        watchChanges: true

        onFileChanged: reload()
        onLoaded: root.load(text())
    }
}
