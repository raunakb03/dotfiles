# Phase 4: Wallpaper & Material You theming

> **Status: ✅ completed 2026-10-03.** See [Completion notes](#completion-notes)
> at the end. One check is still open: autostart after a fresh login.

**Goal:** pick a wallpaper and the whole desktop recolours itself to match:
your bar fades to the new colours, and Hyprland's window borders follow.
And your shell draws the wallpaper itself, replacing hyprpaper.

```
set-wallpaper.py ~/raunak/Wallpapers/blue-flowers.jpg
        │
        ├─▶ ~/.local/state/myshell/wallpaper.json ──▶ Wallpaper.qml ──▶ Background (draws it)
        ├─▶ ~/.local/state/myshell/scheme.json    ──▶ Colours.qml   ──▶ every StyledText/StyledRect (fade)
        └─▶ ~/.config/hypr/scheme/current.lua     ──▶ Hyprland auto-reload ──▶ borders, shadows, group bars
```

New and changed files:
```
my-first-shell/
├── scripts/set-wallpaper.py          NEW  wallpaper → colour scheme (Python)
├── utils/Paths.qml                   NEW  where the shell's files live
├── services/Colours.qml              CHANGED  reads scheme.json instead of fixed colours
├── services/Wallpaper.qml            NEW  reads wallpaper.json
├── modules/background/Background.qml NEW  draws the wallpaper
└── shell.qml                         CHANGED  adds Background {}
~/.config/hypr/                       CHANGED  hyprpaper out, shell autostart in
```

**Prerequisite:** Phase 3 done (`Colours`, `Appearance`, `Config`, components).

**Reference:**
- `~/raunak/configurations/shell/services/Colours.qml`
- `~/raunak/configurations/shell/modules/background/`
- `~/raunak/configurations/shell/utils/Paths.qml`
- Caelestia's colour generation lives in its separate CLI
  (`caelestia-cli`, not cloned). It uses the same Python library we'll use.

---

## 4.0 How Material You colours work, and installing the library

**Why:** "Material You" (Material 3's dynamic colour) takes **one** colour
from an image and builds a whole palette from it: ~60 named roles (`primary`,
`surface`, `onSurface`, `surfaceContainerHigh`…) with guaranteed contrast
between each "X" and "onX". That's why Phase 3 used role names: the roles
stay the same, only their values change.

How a wallpaper becomes a palette:
1. **Quantize:** reduce the image's thousands of colours to ~128 representative ones.
2. **Score:** rank them by how good they'd be as a theme colour (vivid enough, common enough). The winner is the **source colour**.
3. **Scheme:** from the source colour, compute tones for every role using
   **HCT** (hue, chroma, tone), a colour space designed so "tone 90" looks
   equally light whatever the hue. Different *scheme variants* use the hue
   differently. We use **Tonal Spot**, the Android/Caelestia default: calm,
   with the source hue as the accent.

The Python library **materialyoucolor** implements all of this. It's the
same one Caelestia's CLI depends on, along with Pillow (images).

**Run:**
```bash
yay -S python-materialyoucolor
```
It's from the AUR. `yay` shows you the PKGBUILD first, so read it: it's a
short build recipe that compiles the library. It pulls in `python-pillow`
from the official repos.

**Check:**
```bash
python3 -c "import materialyoucolor, PIL; print('ok')"
```

---

## 4.1 The colour script: `scripts/set-wallpaper.py`

**Why:** One command that does everything for a wallpaper change. It
writes three small files, and everything else (shell, Hyprland) *watches*
those files and reacts. Nothing needs to "tell" anyone. The same pattern as
`shell.json`.

**Run first:**
```bash
mkdir -p ~/.config/quickshell/my-first-shell/scripts
```

**Write:** `scripts/set-wallpaper.py` (new file)
```python
#!/usr/bin/env python3
"""Set the wallpaper and generate a Material 3 colour scheme from it.

    set-wallpaper.py <image>

Writes three files:
    ~/.local/state/myshell/wallpaper.json   the image path    -> read by the shell's Wallpaper service
    ~/.local/state/myshell/scheme.json      the colours       -> read by the shell's Colours service
    ~/.config/hypr/scheme/current.lua       the same colours  -> read by Hyprland (borders, shadows)
"""

import json
import os
import sys
from pathlib import Path

from materialyoucolor.dynamiccolor.material_dynamic_colors import MaterialDynamicColors
from materialyoucolor.hct import Hct
from materialyoucolor.quantize import QuantizeCelebi
from materialyoucolor.scheme.scheme_tonal_spot import SchemeTonalSpot
from materialyoucolor.score.score import Score
from PIL import Image

HOME = Path.home()
STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "myshell"
HYPR_SCHEME = Path(os.environ.get("XDG_CONFIG_HOME", HOME / ".config")) / "hypr/scheme/current.lua"


def source_colour(image_path: Path) -> int:
    """Find the wallpaper's most suitable main colour, as an ARGB integer."""
    image = Image.open(image_path).convert("RGB")
    image.thumbnail((128, 128))  # a small copy is much faster and has the same colours

    # Every pixel as an (r, g, b) tuple, row by row
    width, height = image.size
    pixels = [image.getpixel((x, y)) for y in range(height) for x in range(width)]

    # Group the pixels into at most 128 colours, then rank them by how good they'd be as a theme colour
    colours = QuantizeCelebi(pixels, 128)
    return Score.score(colours)[0]


def generate_scheme(source: int, dark: bool = True) -> dict[str, str]:
    """Build every Material 3 colour role from the main colour, as "rrggbb" strings."""
    scheme = SchemeTonalSpot(Hct.from_int(source), dark, 0.0)

    colours = {}
    roles = MaterialDynamicColors()
    for role in roles.all_colors:
        argb = role.get_argb(scheme)
        colours[role.name] = f"{argb & 0xFFFFFF:06x}"  # drop the alpha byte
    return colours


def write_atomically(path: Path, text: str) -> None:
    """Write to a temporary file, then rename it over the real one.

    A rename is instant, so programs watching the file never read a half-written version.
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(text)
    tmp.replace(path)


def to_lua(colours: dict[str, str]) -> str:
    lines = ["-- Generated by set-wallpaper.py. Don't edit: it's overwritten on every wallpaper change.", "return {"]
    lines += [f'    {name} = "{hex_value}",' for name, hex_value in colours.items()]
    lines.append("}")
    return "\n".join(lines) + "\n"


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit(f"usage: {sys.argv[0]} <image>")

    image_path = Path(sys.argv[1]).expanduser().resolve()
    if not image_path.is_file():
        sys.exit(f"not a file: {image_path}")

    source = source_colour(image_path)
    colours = generate_scheme(source)

    write_atomically(STATE_DIR / "wallpaper.json", json.dumps({"path": str(image_path)}, indent=4) + "\n")
    write_atomically(STATE_DIR / "scheme.json",
                     json.dumps({"source": f"{source & 0xFFFFFF:06x}", "mode": "dark", "colours": colours}, indent=4) + "\n")
    write_atomically(HYPR_SCHEME, to_lua(colours))

    print(f"wallpaper: {image_path}")
    print(f"main colour: #{source & 0xFFFFFF:06x}, primary: #{colours['primary']}")


if __name__ == "__main__":
    main()
```

**Then make it executable:**
```bash
chmod +x ~/.config/quickshell/my-first-shell/scripts/set-wallpaper.py
```

**How it works:**
- `source_colour()`:
  - `Image.open(...).convert("RGB")`: load any image format, drop transparency.
  - `image.thumbnail((128, 128))`: shrink to at most 128×128 *first*. Your
    wallpapers are millions of pixels, but the colours of 16 000 pixels are
    the same, and it takes a fraction of a second instead of minutes.
  - `getpixel((x, y))` for every pixel gives a list of `(r, g, b)` tuples.
  - `QuantizeCelebi(pixels, 128)`: at most 128 representative colours,
    with how many pixels each covers.
  - `Score.score(...)[0]`: the best theme colour, as one integer
    `0xAARRGGBB`.
- `generate_scheme()`:
  - `SchemeTonalSpot(Hct.from_int(source), dark, 0.0)`: the scheme. `True` =
    dark mode, `0.0` = standard contrast.
  - `MaterialDynamicColors().all_colors`: every role (`primary`,
    `surface`…). `role.get_argb(scheme)` computes that role's colour *for
    this scheme*.
  - `f"{argb & 0xFFFFFF:06x}"`: `& 0xFFFFFF` drops the alpha byte, and
    `:06x` formats as 6 hex digits, e.g. `9dcfd9`, the same format as your
    `scheme/default.lua`.
- `write_atomically()`: writes `file.tmp`, then **renames** it over the real
  file. Renaming is instant, so Quickshell and Hyprland (which watch these
  files) never see a half-written file.
- **Paths follow the XDG spec:** `XDG_STATE_HOME` (default `~/.local/state`)
  is for data a program *generates*, `XDG_CONFIG_HOME` (`~/.config`) for
  settings you *write*. The `os.environ.get(..., default)` reads the variable
  if set.
- `to_lua()`: the same colours as a Lua table, so Hyprland's
  `require("scheme.current")` can read them.
- `if __name__ == "__main__": main()`: run `main()` only when executed as a
  script, not when imported.

**Run:**
```bash
~/.config/quickshell/my-first-shell/scripts/set-wallpaper.py ~/raunak/Wallpapers/japan-alley.png
```
```
wallpaper: /home/rb003/raunak/Wallpapers/japan-alley.png
main colour: #1e6d79, primary: #9dcfd9
```

**Check, three things:**
1. `cat ~/.local/state/myshell/scheme.json`: `"source"`, `"mode"`, and 59
   `"colours"`.
2. `head ~/.config/hypr/scheme/current.lua`: the same colours as Lua.
3. **Look at your focused window's border.** It changed colour within a
   couple of seconds. Hyprland watches `scheme/current.lua` (it's
   `require`d by `variables.lua`) and reloaded by itself. The border, the
   shadow tint and the group bars all come from it (Phase 1).

**Try it:** run it with `~/raunak/Wallpapers/blue-flowers.jpg` and watch
the border change again.

**Commit:** `git add -A && git commit -m "phase4: colour scheme script"`

---

## 4.2 Where files live: `utils/Paths.qml`

**Why:** Several services now need `~/.local/state/myshell/…`. Rather than
building that path in each file, one singleton defines it. Caelestia does
the same in `shell/utils/Paths.qml` (read it, especially `state`).

**Run first:**
```bash
mkdir -p ~/.config/quickshell/my-first-shell/utils
```

**Write:** `utils/Paths.qml` (new file)
```qml
pragma Singleton

import QtQuick
import Quickshell

// Where the shell keeps its files, following the XDG base directory spec
Singleton {
    readonly property string home: Quickshell.env("HOME")

    // Settings you edit: ~/.config/myshell
    readonly property string config: (Quickshell.env("XDG_CONFIG_HOME") || `${home}/.config`) + "/myshell"

    // State the shell/scripts generate: ~/.local/state/myshell
    readonly property string state: (Quickshell.env("XDG_STATE_HOME") || `${home}/.local/state`) + "/myshell"
}
```

- `Quickshell.env("XDG_STATE_HOME") || …`: if the variable isn't set, `||`
  falls back to the default, exactly like the Python script, so both agree
  on where the files are.
- `` `${home}/.config` ``: a JavaScript **template string**. `${…}` inserts a
  value.

**Try it (optional tidy-up):** in `config/Config.qml`, replace
`path: Quickshell.env("HOME") + "/.config/myshell/shell.json"` with
`path: Paths.config + "/shell.json"` and add `import qs.utils`.

**Commit:** `git add -A && git commit -m "phase4: paths"`

---

## 4.3 Live colours: `services/Colours.qml`

**Why:** Phase 3's palette was fixed. Now it starts with the same fixed
values and then **overwrites** them from `scheme.json`, and again every
time the file changes.

**Read:** `shell/services/Colours.qml`, the `load()` function and the
`FileView` at the bottom. Ours is the same idea without Caelestia's
transparency and light/dark extras.

**Write:** `services/Colours.qml` (replace the whole file)
```qml
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
```

**What changed from Phase 3:**
- The palette properties are no longer `readonly`, because `load()` assigns
  them. They have no bindings, so assigning is safe (step 2.3).
- `JSON.parse(text)` turns the file into a JavaScript object.
- `Object.entries(scheme.colours)` gives `[name, hex]` pairs:
  `["primary", "9dcfd9"]`, `["surface", "0a0f10"]`…
- `"m3" + name`: the file says `primary`, the palette says `m3primary`.
- `root.palette.hasOwnProperty(prop)`: only copy roles our palette
  declares. The file has 59, and we use 18. Add more to the palette when you
  need them.
- `palette[prop] = "#" + hex`: `palette[prop]` is property access by a
  name stored in a variable (the same as `palette.m3primary` when `prop` is
  `"m3primary"`).
- `FileView` + `onLoaded: root.load(text())`: `loaded` fires after every
  successful (re)load. `watchChanges` + `onFileChanged: reload()` re-reads
  when the script writes a new scheme.
- No file yet? `FileView` logs a warning and the fixed defaults stay. Same
  as before.

**Run:** save. The bar's accent colour switches to the wallpaper's (teal for
`japan-alley`).

**Try it, the payoff:**
```bash
~/.config/quickshell/my-first-shell/scripts/set-wallpaper.py ~/raunak/Wallpapers/blue-flowers.jpg
```
The bar **fades** to the new colours. That's `Behavior on color { CAnim {} }`
from Phase 3 in action, and why the `CAnim` bug mattered. Your window
border changes at the same time.

**Commit:** `git add -A && git commit -m "phase4: live colours"`

---

## 4.4 Drawing the wallpaper: `Wallpaper` service + `Background`

**Why:** Caelestia draws its own wallpaper. That way the shell knows
exactly which image is shown (for the wallpaper picker in Phase 7) and can
animate changes. A **layer-shell** window on the *background* layer sits
below all normal windows. That's all a wallpaper is.

**Read:** `shell/modules/background/Background.qml` (the window:
`WlrLayershell.layer`, `exclusionMode`, `anchors`) and `Wallpaper.qml`
(Caelestia's version crossfades between images).

**Write:** `services/Wallpaper.qml` (new file)
```qml
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
```

- `JsonAdapter { property string path }` maps `{"path": "…"}` in
  `wallpaper.json`. Like `Config.qml`, but read-only: there's no
  `onAdapterUpdated: writeAdapter()`, because only the script writes this
  file.
- `readonly property string path: adapter.path`: the public, read-only view.

**Run first:**
```bash
mkdir -p ~/.config/quickshell/my-first-shell/modules/background
```

**Write:** `modules/background/Background.qml` (new file)
```qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// The wallpaper: one full-screen window per monitor, on the layer below all windows
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: root

        required property ShellScreen modelData

        screen: modelData

        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "myshell-background"
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Shown until the image has loaded, or if there's no wallpaper yet
        color: Colours.palette.m3surfaceContainer

        Image {
            anchors.fill: parent
            source: Wallpaper.path ? "file://" + Wallpaper.path : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            retainWhileLoading: true

            // Decode at screen size, not at the image's full size (saves a lot of memory)
            sourceSize.width: root.width * root.modelData.devicePixelRatio
            sourceSize.height: root.height * root.modelData.devicePixelRatio
        }
    }
}
```

- `Variants` over screens again: one wallpaper window per monitor, the same
  pattern as the bar.
- `WlrLayershell.layer: WlrLayer.Background`: the bottom-most of the four
  layers (Background → Bottom → *normal windows* → Top → Overlay). Your bar
  is on Top by default.
- `WlrLayershell.namespace: "myshell-background"`: the layer's name, the
  `namespace` that `hyprctl layers` shows and that Hyprland layer rules
  match (step 4.5).
- `exclusionMode: ExclusionMode.Ignore`: don't reserve screen space (the bar
  *does*, so windows don't cover it). The wallpaper must not push windows
  around.
- **All four anchors:** stretched over the whole screen.
- `fillMode: Image.PreserveAspectCrop`: fill the screen, cropping edges
  rather than stretching. Like hyprpaper's `fit_mode = cover`.
- `asynchronous: true`: decode the image in the background, so the shell
  doesn't freeze on a big file.
- `retainWhileLoading: true`: keep showing the old image until the new one
  is ready, so there's no flash of plain colour when switching.
- `sourceSize`: decode the image **at screen resolution**. Your
  `hyprlock.png` is 5248×3712. Decoding it full size wastes ~80 MB of
  memory, so screen size is plenty. `devicePixelRatio` (1.33 on your
  laptop) converts logical size to real pixels so it stays sharp.

**Write:** `shell.qml`
```qml
import QtQuick
import Quickshell
import qs.modules.background
import qs.modules.bar

ShellRoot {
    settings.watchFiles: true

    Background {}

    Variants {
        model: Quickshell.screens

        Bar {}
    }
}
```

- `Background {}` comes **first**. Order in the file doesn't decide the
  layer (that's `WlrLayershell.layer`), but reading top to bottom, back to
  front, keeps it clear.

**Run:** go to an empty workspace. You still see your wallpaper, but it's
now **two** wallpapers: your shell's, on top of hyprpaper's. Prove it:
```bash
~/.config/quickshell/my-first-shell/scripts/set-wallpaper.py ~/raunak/Wallpapers/blue-flowers.jpg
```
The wallpaper switches to the flowers (hyprpaper would still show the
alley) **and** the colours follow.

**Commit:** `git add -A && git commit -m "phase4: wallpaper"`

---

## 4.5 Hyprland: retire hyprpaper, autostart the shell

**Why:** hyprpaper is now redundant. And since your shell draws the
wallpaper, it must start at login. Until now you started it by hand.
Caelestia's `execs.lua` starts its shell the same way (`caelestia shell -d`).

Edit these four files in `~/.config/hypr/`:

**`variables.lua`:** replace the hyprpaper line:
```lua
    wallpaperCmd               = "hyprpaper",                                   -- Phase 4
```
with:
```lua
    shellCmd                   = "qs -c my-first-shell -n -d",                 -- our own shell (draws the wallpaper)
```
and add, below `kbShowKeybinds`:
```lua
    kbRestartShell             = "CTRL + SUPER + ALT + R",
```
- `-d` = **daemonize**: run in the background, detached from any terminal.
- `-n` = **no duplicate**: if it's already running, don't start a second
  one.

**`hyprland/execs.lua`:** replace:
```lua
    hl.exec_cmd(vars.wallpaperCmd)    -- Phase 4
```
with:
```lua

    -- Our shell (bar, wallpaper, ...)
    hl.exec_cmd(vars.shellCmd)
```

**`hyprland/keybinds.lua`:** below the `kbShowKeybinds` bind, add:
```lua

-- Restart our shell (if it crashed, or after installing fonts)
create_bind(vars.kbRestartShell, hl.dsp.exec_cmd("qs kill -c my-first-shell; " .. vars.shellCmd), release,
    "Utilities: restart the shell")
```
- `release`: fire on key *release*. Restarting while keys are still held
  can leave them "stuck" in the new instance. Caelestia uses `release` for
  the same bind.
- Remember Phase 3's font lesson: this is the "restart Quickshell" button.

**`hyprland/rules.lua`:** at the end of the layer rules, add:
```lua

-- Our shell: the wallpaper fades in instead of sliding
hl.layer_rule({ match = { namespace = "myshell-background" }, animation = "fade" })
```
Without it, Hyprland's `layersIn` animation would *slide* the wallpaper in
from an edge at login.

**Run:**
```bash
cd ~/.config/hypr
luac -p variables.lua hyprland/execs.lua hyprland/keybinds.lua hyprland/rules.lua
hyprctl configerrors                 # empty (Hyprland already auto-reloaded)
pkill hyprpaper                      # stop it now; nothing starts it any more
git rm hyprpaper.conf                # no longer needed (it stays in git history)
git add -A && git commit -m "hypr: shell draws the wallpaper; retire hyprpaper; autostart shell"
```

**Your new workflow:** from now on the shell runs in the background,
started by Hyprland.
- **Logs:** `qs log -c my-first-shell -f` (as before).
- **Hot reload** still works on save.
- **Restart:** `Ctrl + Super + Alt + R`.
- **Debug in a terminal:** run `qs kill -c my-first-shell` first, then
  `quickshell -c my-first-shell`. Otherwise you get two bars.

**Check:** log out and back in:
- the wallpaper fades in, drawn by your shell (`hyprctl layers` lists
  `myshell-background`, and no `hyprpaper`)
- your bar is there, with the wallpaper's colours
- `Ctrl + Super + Alt + R` makes the bar blink away and come back
- the `Super + /` cheat sheet lists "restart the shell"

---

## 4.6 Compare with Caelestia

1. Caelestia's `Colours.load()` has `name.startsWith("term") ? name : \`m3${name}\``.
   What are the `term…` colours for?
2. Caelestia's `Wallpaper.qml` uses `CachingImage` and creates a new image
   object for every source change. What does that give it that our single
   `Image` doesn't?
3. Where does Caelestia keep `scheme.json`, and why the *state* directory
   rather than `~/.config`?
4. materialyoucolor has several scheme *variants* besides Tonal Spot (look in
   its `scheme/` folder: `scheme_vibrant.py`, `scheme_fruit_salad.py`,
   `scheme_monochrome.py`…), and Caelestia's CLI lets you pick one. Which line
   in your script would you change to try `SchemeVibrant`?

<details>
<summary>Answers</summary>

1. **Terminal colours** (`term0`–`term15`, the 16 ANSI colours) generated
   to match the scheme. The CLI uses them to theme terminals and `btop`.
   That's our optional Phase 12.
2. A **crossfade**. With two image objects alive at once, the new one can
   fade in *over* the old one. With one `Image`, `retainWhileLoading` only
   avoids a blank flash. (`CachingImage` also loads images through
   Caelestia's C++ image cache, which keeps resized copies under `~/.cache`,
   so they load faster next time.)
3. `~/.local/state/caelestia/scheme.json` (see `Paths.state`). It's
   **generated** data that the program rewrites, not settings you edit. The
   XDG spec puts that in *state*. Keeping it out of `~/.config` also keeps it
   out of dotfile repos.
4. The `SchemeTonalSpot(...)` call in `generate_scheme()`, plus its import:
   `from materialyoucolor.scheme.scheme_vibrant import SchemeVibrant`, then
   `scheme = SchemeVibrant(Hct.from_int(source), dark, 0.0)`.

</details>

---

## Phase 4 done when
- [x] `set-wallpaper.py <image>` changes the wallpaper, the bar colours
      (with a fade) and the Hyprland borders
- [x] hyprpaper is gone (`pgrep hyprpaper` prints nothing after a fresh
      login) and `hyprpaper.conf` is deleted
- [ ] After a fresh login the shell starts by itself with your last
      wallpaper and colours
- [x] `Ctrl + Super + Alt + R` restarts the shell
- [ ] You can explain: source colour → scheme → roles, the file-watching
      pattern, atomic writes, and the four layer-shell layers
- [ ] One commit per step

---

## Completion notes

What was actually done, and where it differs from the steps above:

- **Steps 4.0–4.3 typed by you, 4.4–4.5 implemented by Claude** at your
  request ("getting bored of doing this myself"). The code is identical to
  the guide, so read 4.4 and 4.5 to understand what was added.
- **"The colours aren't changing"** (step 4.3): they were. Both test
  wallpapers were blue, so they gave nearly the same palette
  (`blue-flowers` → primary `#a1cde0`, `japan-alley` → `#9dcfd9`). Tonal
  Spot also turns every source colour into a soft pastel. Wallpapers that
  give clearly different results: `berries-1.jpg` (peach `#f3bb91`),
  `artificial-valley.jpg` (olive `#cec98c`), `black-hole.png` (pink
  `#e0bbe1`).
- **Verified 2026-10-03:**
  - The running shell hot-reloaded `Background` with no errors, and draws
    `japan-alley.png` (screenshot of an empty workspace).
  - `hyprctl layers` shows `myshell-background` and no hyprpaper.
  - The Hyprland border follows `scheme/current.lua` (`e69dcfd9`).
  - `hyprctl configerrors` is empty: 129 binds, no duplicates. The restart
    bind is registered.
- **Still to check on your next login:** the shell starts by itself (the
  `hyprland.start` autostart only runs at login). Until then, your shell is
  the one you started in tmux window 4. After the next login, stop starting
  it by hand.
- **Not done (optional):** the 4.2 tidy-up of `Config.qml` to use
  `Paths.config`.
- **Commits:** `my-first-shell`: "colour scheme script", "paths and live
  colours", "wallpaper". `~/.config/hypr`: "shell draws the wallpaper;
  retire hyprpaper; autostart shell" (`hyprpaper.conf` deleted, still in git
  history).

## Common errors

| Symptom / message | Likely cause |
| --- | --- |
| `ModuleNotFoundError: No module named 'materialyoucolor'` | Library not installed (4.0), or the script is run with a different Python (e.g. inside a venv) |
| `Permission denied` running the script | Forgot `chmod +x` |
| `Read of …/scheme.json failed: File does not exist` | Expected until you run the script once |
| Colours change but **don't fade** | `CAnim` isn't a `ColorAnimation` (Phase 3 completion notes) |
| Wallpaper stays plain grey | `wallpaper.json` missing (run the script), or the image path in it no longer exists |
| Two bars after logging in | You also started `quickshell -c my-first-shell` in a terminal. `qs kill -c my-first-shell` and use the restart bind |
| Borders didn't change colour | `hyprctl configerrors`, and check `scheme/current.lua` was written (`head` it) |
| Wallpaper slides in from the side at login | The `myshell-background` layer rule is missing (4.5) |

Next: **Phase 5: The bar.** Its guide is written when we start it.
