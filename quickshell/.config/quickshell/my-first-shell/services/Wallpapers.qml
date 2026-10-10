pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.config
import qs.utils
import "../utils/fuzzy.js" as Fuzzy

// The images in the wallpaper folder (shell.json: paths.wallpaperDir), searchable,
// and setting one as the wallpaper (which also regenerates the colours)
Singleton {
    id: root

    // "~/Pictures/Wallpapers" -> "/home/you/Pictures/Wallpapers"
    readonly property string dir: Config.paths.wallpaperDir.replace(/^~/, Paths.home)
    property var all: [] // file paths

    function search(query: string): var {
        return Fuzzy.filter(query.trim(), all, path => path.split("/").pop());
    }

    // Set the wallpaper (and its colours) for real
    function set(path: string): void {
        previewTimer.stop();
        previewing = false; // so the picker closing afterwards doesn't restore the old colours
        run([path]);
    }

    // The wallpaper picker calls this whenever the wallpaper you're on changes: a path shows
    // that wallpaper's colours (without changing the wallpaper), "" goes back to the current
    // wallpaper's colours. It waits a moment, so gliding across thumbnails only previews
    // where you stop, and the short gap between two thumbnails doesn't restore in between.
    property bool previewing: false // colours on screen are a preview, not the wallpaper's
    property string previewPath: ""

    function preview(path: string): void {
        previewPath = path;
        previewTimer.restart();
    }

    Timer {
        id: previewTimer

        interval: 150
        onTriggered: {
            if (root.previewPath) {
                root.previewing = true;
                root.run(["--preview", root.previewPath]);
            } else if (root.previewing) {
                root.previewing = false;
                root.run(["--restore"]);
            }
        }
    }

    // set-wallpaper.py runs go through one Process, one at a time. A request that arrives while
    // one is running waits, and only the newest waiting request is kept, so a slow preview can
    // never finish after (and overwrite) your final choice.
    property var queued: null

    function run(args: var): void {
        if (script.running) {
            queued = args;
            return;
        }
        script.command = [Quickshell.shellPath("scripts/set-wallpaper.py"), ...args];
        script.running = true;
    }

    Process {
        id: script

        onExited: {
            if (root.queued) {
                const next = root.queued;
                root.queued = null;
                root.run(next);
            }
        }
    }

    // Lists a folder's files as a model; we copy the paths into a plain array for searching
    FolderListModel {
        id: folder

        folder: "file://" + root.dir
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
        showDirs: false
        sortField: FolderListModel.Name

        onStatusChanged: if (status === FolderListModel.Ready) root.reload()
        onCountChanged: root.reload()
    }

    function reload(): void {
        const paths = [];
        for (let i = 0; i < folder.count; i++)
            paths.push(folder.get(i, "filePath"));
        all = paths;
    }
}
