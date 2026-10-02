#!/usr/bin/env python3
"""Keybind cheat sheet (Super + /): every Hyprland bind that has a description,
one key combination per row, shown in rofi.

    keybinds.py            open the list in rofi
    keybinds.py --print    just print the rows (for testing)

Descriptions come from the 4th argument of create_bind() in hyprland/keybinds.lua.
"""

import html
import json
import re
import subprocess
import sys

# Monospace font for the key column, so the descriptions line up
KEY_FONT = "JetBrainsMono Nerd Font"

# Layout overrides for THIS menu only. Colours and fonts still come from
# ~/.config/rofi/config.rasi, whose 4-column icon grid would cut every row off.
ROFI_THEME = """
window       { width: 75%; }
prompt       { padding: 0.5% 32px 0% 0%; }
listview     { columns: 1; lines: 15; scrollbar: false; }
element      { orientation: horizontal; padding: 6px 12px; }
element-text { horizontal-align: 0; }
"""

# Modifier bits in `modmask` (from the Wayland/XKB modifier order)
MODS = [(64, "SUPER"), (4, "CTRL"), (8, "ALT"), (1, "SHIFT")]

# Friendlier names for keys that read badly
KEY_NAMES = {
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
    "xf86audiolowervolume": "Volume Down key",
}


def key_label(bind):
    mods = [name for bit, name in MODS if bind["modmask"] & bit]
    key = bind["key"]

    # A bind on SUPER_L itself with `release` = "tap Super on its own"
    if key in ("SUPER_L", "SUPER_R") and bind["release"]:
        return "SUPER (tap)"

    key = KEY_NAMES.get(key.lower(), key)
    if len(key) == 1:
        key = key.upper()
    return " + ".join(mods + [key])


def main():
    binds = json.loads(subprocess.run(["hyprctl", "binds", "-j"], capture_output=True, text=True).stdout)

    # Group keys by description, keeping the order the binds were created in
    actions = {}
    for bind in binds:
        desc = bind.get("description", "")
        if not desc:
            continue
        keys = actions.setdefault(desc, [])
        label = key_label(bind)
        if label not in keys:
            keys.append(label)

    # Collapse numbered series ("go to workspace 1" … "go to workspace 10", each
    # bound to one "<mods> + <digit>") into a single line: "<mods> + 1…0"
    lines = []
    series = {}  # "go to workspace " -> index in lines
    for desc, keys in actions.items():
        m = re.fullmatch(r"(.*?)(\d+)", desc)
        if m and len(keys) == 1 and re.fullmatch(r".* \+ \d", keys[0]):
            prefix, num = m.groups()
            key_prefix, digit = keys[0].rsplit(" + ", 1)
            if prefix in series:
                entry = lines[series[prefix]]
                entry["last"], entry["last_digit"] = num, digit
                continue
            series[prefix] = len(lines)
            lines.append({"prefix": prefix, "first": num, "last": num,
                          "key_prefix": key_prefix, "first_digit": digit, "last_digit": digit})
            continue
        lines.append({"keys": keys, "desc": desc})

    # One row per key combination, so long rows never get cut off
    rows = []
    for line in lines:
        if "keys" in line:
            rows += [(key, line["desc"]) for key in line["keys"]]
        elif line["first"] == line["last"]:
            rows.append((f"{line['key_prefix']} + {line['first_digit']}", f"{line['prefix']}{line['first']}"))
        else:
            rows.append((f"{line['key_prefix']} + {line['first_digit']}…{line['last_digit']}",
                         f"{line['prefix']}{line['first']}–{line['last']}"))

    # Pad every key to the same width (in a monospace font) so descriptions form a column
    width = max(len(key) for key, _ in rows) + 3
    text = "\n".join(
        f'<span font_family="{KEY_FONT}"><b>{html.escape(key.ljust(width))}</b></span>{html.escape(desc)}'
        for key, desc in rows
    )

    if "--print" in sys.argv:
        print(text)
        return

    subprocess.run(
        ["rofi", "-dmenu", "-i", "-markup-rows", "-no-show-icons",
         "-p", "Keybinds", "-theme-str", ROFI_THEME],
        input=text, text=True, stdout=subprocess.DEVNULL,
    )


if __name__ == "__main__":
    main()
