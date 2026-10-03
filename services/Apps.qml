pragma Singleton

import QtQuick
import Quickshell
import "../utils/fuzzy.js" as Fuzzy

// Installed applications (from their .desktop files), searchable and launchable
Singleton {
    // Every app that wants to be shown in menus, A to Z
    readonly property var all: DesktopEntries.applications.values
        .filter(app => !app.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    function search(query: string): var {
        // Match on the name first; generic name ("Web Browser") and keywords help too
        return Fuzzy.filter(query.trim(), all, app => `${app.name} ${app.genericName} ${app.keywords.join(" ")}`);
    }

    function launch(app: DesktopEntry): void {
        if (app.runInTerminal)
            Quickshell.execDetached(["kitty", ...app.command]); // e.g. btop, nvim
        else
            app.execute();
    }
}
