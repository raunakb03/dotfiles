pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Every Hyprland keybind that has a description (the 4th argument of create_bind() in
// ~/.config/hypr/hyprland/keybinds.lua), as readable rows: { keys: "SUPER + Return", description: "Apps: terminal" }.
// It replaces the rofi cheat sheet (the old ~/.config/hypr/scripts/keybinds.py).
Singleton {
    id: root

    property var rows: []

    // Modifier bits in a bind's `modmask`
    readonly property var mods: [[64, "SUPER"], [4, "CTRL"], [8, "ALT"], [1, "SHIFT"]]

    // Friendlier names for keys that read badly
    readonly property var keyNames: ({
            "mouse:272": "Left click",
            "mouse:273": "Right click",
            "mouse_down": "Scroll down",
            "mouse_up": "Scroll up",
            "slash": "/",
            "comma": ",",
            "period": ".",
            "minus": "-",
            "equal": "=",
            "backslash": "\\",
            "return": "Return",
            "escape": "Escape",
            "space": "Space",
            "tab": "Tab",
            "left": "Left",
            "right": "Right",
            "up": "Up",
            "down": "Down",
            "xf86monbrightnessup": "Brightness Up key",
            "xf86monbrightnessdown": "Brightness Down key",
            "xf86audioplay": "Play key",
            "xf86audiopause": "Pause key",
            "xf86audionext": "Next key",
            "xf86audioprev": "Previous key",
            "xf86audiostop": "Stop key",
            "xf86audiomute": "Mute key",
            "xf86audiomicmute": "Mic Mute key",
            "xf86audioraisevolume": "Volume Up key",
            "xf86audiolowervolume": "Volume Down key"
        })

    function refresh(): void {
        binds.running = true;
    }

    function label(bind: var): string {
        if ((bind.key === "SUPER_L" || bind.key === "SUPER_R") && bind.release)
            return "SUPER (tap)"; // a release bind on Super itself = tap Super on its own
        let key = keyNames[bind.key.toLowerCase()] ?? bind.key;
        if (key.length === 1)
            key = key.toUpperCase();
        const names = mods.filter(([bit]) => bind.modmask & bit).map(([, name]) => name);
        return [...names, key].join(" + ");
    }

    function parse(json: string): void {
        // Group keys by description, in the order the binds were created
        const actions = new Map();
        for (const bind of JSON.parse(json)) {
            if (!bind.description)
                continue;
            if (!actions.has(bind.description))
                actions.set(bind.description, []);
            const keys = actions.get(bind.description);
            const key = label(bind);
            if (!keys.includes(key))
                keys.push(key);
        }

        // Collapse numbered series ("go to workspace 1" … "10", each "<mods> + <digit>")
        // into one row: "<mods> + 1…0"
        const out = [];
        const series = new Map(); // "Workspaces: go to workspace " -> its row
        for (const [description, keys] of actions) {
            const num = description.match(/^(.*?)(\d+)$/);
            const digit = keys.length === 1 ? keys[0].match(/^(.*) \+ (\d)$/) : null;
            if (num && digit) {
                const [, prefix, n] = num;
                const [, keyPrefix, d] = digit;
                if (series.has(prefix)) {
                    const row = series.get(prefix);
                    row.keys = `${row.keyPrefix} + ${row.firstDigit}…${d}`;
                    row.description = `${prefix}${row.first}–${n}`;
                } else {
                    const row = {
                        keys: keys[0],
                        description,
                        keyPrefix,
                        firstDigit: d,
                        first: n
                    };
                    series.set(prefix, row);
                    out.push(row);
                }
                continue;
            }
            for (const key of keys) // one row per key combination
                out.push({
                    keys: key,
                    description
                });
        }
        rows = out;
    }

    Process {
        id: binds

        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }
}
