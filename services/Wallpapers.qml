pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
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

    function set(path: string): void {
        Quickshell.execDetached([Quickshell.shellPath("scripts/set-wallpaper.py"), path]);
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
