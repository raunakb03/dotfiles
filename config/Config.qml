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

    FileView {
        path: Quickshell.env("HOME") + "/.config/myshell/shell.json"
        watchChanges: true

        // The file was edited (by you, in an editor): read it again
        onFileChanged: reload()

        // A setting was changed from inside the shell: save it to the file
        onAdapterUpdated: writeAdapter()

        // First run: the file doesn't exist yet, so write one with all the defaults
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
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
