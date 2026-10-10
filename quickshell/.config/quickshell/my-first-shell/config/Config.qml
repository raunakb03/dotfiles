pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Shortcuts, so other files can write Config.bar.showSeconds
    property alias appearance: adapter.appearance
    property alias bar: adapter.bar
    property alias border: adapter.border
    property alias paths: adapter.paths
    property alias services: adapter.services
    property alias idle: adapter.idle

    // False until shell.json has been read (or found missing). Until then every value above
    // is a default. Anything that must not start with defaults waits for this (see Drawers.qml).
    property bool loaded: false

    FileView {
        path: Quickshell.env("HOME") + "/.config/myshell/shell.json"
        watchChanges: true

        // The file was edited (by you, in an editor): read it again
        onFileChanged: reload()

        // A setting was changed from inside the shell: save it to the file
        onAdapterUpdated: writeAdapter()

        onLoaded: root.loaded = true

        // First run: the file doesn't exist yet, so write one with all the defaults
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
            root.loaded = true; // nothing to wait for: the defaults are the settings
        }

        // The shape of shell.json, with default values
        JsonAdapter {
            id: adapter

            property JsonObject appearance: JsonObject {
                property real roundingScale: 1
                property real spacingScale: 1
                property real paddingScale: 1
                property real fontScale: 1
                property real animDurationScale: 1
            }

            // When you're away (seconds; 0 = never)
            property JsonObject idle: JsonObject {
                property int lockAfter: 300       // 5 min
                property int screenOffAfter: 330  // 30 s after locking
                property int suspendAfter: 900    // 15 min
                property bool inhibitWhenPlaying: true // nothing happens while media plays
            }

            // Data the shell fetches
            property JsonObject services: JsonObject {
                property string weatherLocation: "" // a city ("Pune") or "lat,lon"; empty = guess from your IP
                property bool useFahrenheit: false
            }

            property JsonObject paths: JsonObject {
                property string wallpaperDir: "~/Pictures/Wallpapers" // for the launcher's wallpaper picker
            }

            // The frame around the screen
            property JsonObject border: JsonObject {
                property int thickness: 10 // pixels, on the sides without the bar
                property int rounding: 25  // corner radius of the inner edge
            }

            property JsonObject bar: JsonObject {
                property bool showSeconds: true
                property bool showDate: true
                property string position: "left" // which screen edge: "left" or "right"

                property JsonObject workspaces: JsonObject {
                    property int shown: 5 // how many workspace buttons per group
                }
            }
        }
    }
}
