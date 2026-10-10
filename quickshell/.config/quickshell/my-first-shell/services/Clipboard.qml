pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history, kept by cliphist (started in Hyprland's execs.lua).
// `cliphist list` prints one entry per line: "<id><TAB><preview>", newest first.
Singleton {
    id: root

    property var entries: [] // [{ id, preview }]

    // Read the history again (called each time the launcher shows it)
    function refresh(): void {
        list.running = true;
    }

    // Put an entry back on the clipboard. `cliphist decode <id>` prints the original content
    // (text or image), and wl-copy puts it on the clipboard. The id is a number, so it's safe in sh.
    function copy(id: string): void {
        Quickshell.execDetached(["sh", "-c", `cliphist decode ${id} | wl-copy`]);
    }

    Process {
        id: list

        command: ["cliphist", "list"]
        // StdioCollector gathers everything the command prints, then fires streamFinished
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = text.split("\n").filter(line => line.includes("\t")).map(line => {
                    const tab = line.indexOf("\t");
                    return {
                        id: line.slice(0, tab),
                        preview: line.slice(tab + 1)
                    };
                });
            }
        }
    }
}
