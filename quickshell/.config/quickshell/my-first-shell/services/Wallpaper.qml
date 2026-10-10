pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// The current wallpaper's path, from wallpaper.json (written by set-wallpaper.py)
Singleton {
    readonly property string path: adapter.path

    FileView {
        path: Paths.state + "/wallpaper.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter

            property string path
        }
    }
}
