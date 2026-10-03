# Phase 7: Launcher

> **Status: 🔍 built 2026-10-03. Waiting for your check** (see [Check it](#check-it)).
> Implemented by Claude. This doc explains what was built so you can understand,
> change and debug it.

## What you got

**Tap Super** (press and release it on its own) and the launcher slides up from the
bottom edge of the screen, replacing rofi:

```
                 ┌─────────────────────────────────────────────┐
                 │  ⓑ btop++          Resource monitor …        │
                 │  ᛒ Bluetooth       Configure Bluetooth …     │   apps, A→Z, growing upwards
                 │  ▦ Anki            An intelligent …          │   (best match at the bottom)
                 │ ▌◎ Zen Browser     A fast, private … ▐◀──── highlighted = Enter launches it
                 │ ╭─────────────────────────────────────────╮ │
                 │ │ 🔍 zen▏                                  │ │   type to filter (fuzzy)
                 │ ╰─────────────────────────────────────────╯ │
 ────────────────┘                                             └──────────────── screen edge
```

| You type | You get |
| --- | --- |
| nothing | every app, A→Z |
| `zen`, `zn`, `brow` | apps whose name (or generic name / keywords) contain those letters **in order**, best match first |
| `>wall` | a horizontal strip of wallpaper thumbnails from `~/raunak/Wallpapers` |
| `>wall ber` | wallpapers whose file name matches `ber` |

| Key | Action |
| --- | --- |
| `Enter` | launch the highlighted app / set the highlighted wallpaper (and its colours) |
| `↑` / `↓` | move through apps |
| `←` / `→` | move through wallpapers (`>wall` mode) |
| `Tab` / `Shift+Tab` | next / previous in either mode |
| `Esc`, or click anywhere outside | close |
| Super tap again | close |

## How it fits together

```
 Super tap ── keybinds.lua: hl.dsp.global("myshell:launcher")
                   │
                   ▼
 modules/Shortcuts.qml   GlobalShortcut { appid: "myshell"; name: "launcher" }
                   │ onPressed
                   ▼
 services/ShellState.qml   launcherScreen = "eDP-1" (the focused monitor) / ""
                   │
                   ▼ ContentWindow: launcherOpen = (launcherScreen === my screen)
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │ modules/drawers/ContentWindow.qml (same window as the bar and popouts)        │
 │   keyboardFocus: OnDemand while open          ← can receive typing              │
 │   HyprlandFocusGrab: click outside → close                                      │
 │   mask: + Region { item: launcher }           ← clickable while open            │
 │   LauncherBackground (in the shadow layer)    ← same look as popouts            │
 │   Launcher ── search text ──▶ Apps.search(q)       (services/Apps.qml)          │
 │                          └──▶ Wallpapers.search(q) (services/Wallpapers.qml)    │
 │                                 both use utils/fuzzy.js                          │
 └─────────────────────────────────────────────────────────────────────────────┘
```

## Files

| File | What it does | Caelestia equivalent |
| --- | --- | --- |
| `modules/Shortcuts.qml` | the `myshell:launcher` global shortcut | `modules/Shortcuts.qml` |
| `services/ShellState.qml` | which monitor shows the launcher | `services/ShellState.qml` (per-screen `ScreenState`) |
| `services/Apps.qml` | installed apps: list, search, launch | `modules/launcher/services/Apps.qml` |
| `services/Wallpapers.qml` | images in the wallpaper folder: list, search, set | `services/Wallpapers.qml` |
| `utils/fuzzy.js` | our own fuzzy matching | `utils/scripts/fuzzysort.js` (a third-party library) + `Searcher.qml` |
| `modules/launcher/Launcher.qml` | the panel: lists, search field, keys | `modules/launcher/Content.qml` + `ContentList.qml` + `AppList.qml` + `WallpaperList.qml` |
| `modules/launcher/AppItem.qml` | one app row | `modules/launcher/items/AppItem.qml` |
| `modules/launcher/WallpaperItem.qml` | one wallpaper thumbnail | `modules/launcher/items/WallpaperItem.qml` |
| `modules/launcher/LauncherBackground.qml` | background + curved joins to the bottom edge | part of `drawers/ContentWindow.qml` (blob) |
| `modules/drawers/ContentWindow.qml` | + launcher, keyboard focus, focus grab, mask | `drawers/ContentWindow.qml` |
| `config/Config.qml` | + `paths.wallpaperDir` | `Config.paths.wallpaperDir` |
| `~/.config/hypr/hyprland/keybinds.lua` | Super tap → `hl.dsp.global("myshell:launcher")` | `caelestia/hypr/hyprland/keybinds.lua` |
| `~/.config/myshell/shell.json` | `"paths": { "wallpaperDir": "~/raunak/Wallpapers" }` | `~/.config/caelestia/shell.json` |

---

## Global shortcuts: how a key in Hyprland reaches the shell

```qml
GlobalShortcut { appid: "myshell"; name: "launcher"; onPressed: ShellState.toggleLauncher() }
```
```lua
create_bind(vars.kbLauncher, hl.dsp.global("myshell:launcher"), release-for-Super-tap, …)
```
- A **global shortcut** is a named action that an app registers with the compositor.
  `hl.dsp.global("appid:name")` triggers it. Check what's registered with
  `hyprctl globalshortcuts` (it shows `myshell:launcher -> Open or close the launcher`).
- **Why not run a command,** like rofi did? The launcher lives *inside* the running
  shell. The keybind must reach that process, and a global shortcut is the direct
  line. (The alternative, `qs ipc call …`, starts a new process every time.)
- The bind keeps the **release** flag from Phase 1, so Super + T etc. don't open it.

## Which screen? `ShellState.qml`

```qml
property string launcherScreen: ""
function toggleLauncher() { launcherScreen = launcherScreen !== "" ? "" : (Hyprland.focusedMonitor?.name ?? "") }
```
Each monitor has its own drawer window, and each asks
`ShellState.launcherScreen === screen.name`. So the launcher opens only where your
focus is. Caelestia keeps a whole per-screen state object (`ScreenState`) for this.
One string is enough for us.

## Keyboard focus: `OnDemand` + focus grab

```qml
WlrLayershell.keyboardFocus: popouts.locked || launcherOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
HyprlandFocusGrab { active: root.launcherOpen; windows: [root]; onCleared: ShellState.closeLauncher() }
```
- A layer-shell surface (our drawer window) gets **no keyboard at all** unless it asks.
  `None` the rest of the time means the shell never steals your typing. `OnDemand`
  while the launcher is open means it can receive keys once it's focused.
- `search.forceActiveFocus()` (in `onOpenChanged`) puts the text cursor in the field.
- **`HyprlandFocusGrab`** tells Hyprland "until the user clicks outside these windows,
  focus belongs to them". When you click anywhere else, `onCleared` fires, and that
  closes the launcher. That's how a click outside closes it.

## Fuzzy search: `utils/fuzzy.js`

```js
.pragma library
function score(query, text) { … }      // -1 = no match, higher = better
function filter(query, items, textOf) { … }
```
- **A plain JavaScript file** imported into QML with
  `import "../utils/fuzzy.js" as Fuzzy`, then called as `Fuzzy.filter(…)`.
  `.pragma library` makes one shared copy instead of one per importing file.
- **Matching:** every letter of the query must appear in the text, *in order* (a
  "subsequence"): `zn` matches **Z**e**n**.
- **Scoring:** +1 per letter, +3 when letters are consecutive, +2 at the start of a
  word, +10 if the text *starts with* the query, minus a little for long names. The
  rules are simple enough to read and tune.
- Caelestia uses **fuzzysort**, a ~700-line third-party library with smarter scoring.
  Ours is ~40 lines you can fully understand. If results ever feel off, tune the
  bonuses here.

## Apps: `services/Apps.qml`

```qml
readonly property var all: DesktopEntries.applications.values.filter(app => !app.noDisplay).sort(…)
```
- **`DesktopEntries`** (Quickshell) reads every `.desktop` file in
  `/usr/share/applications` and `~/.local/share/applications`. That's how every
  Linux launcher finds apps. `noDisplay` apps (helpers, background services) are
  hidden.
- The search text includes the generic name and keywords, so `browser` finds Zen
  even though "browser" isn't in its name.
- `launch()`: `app.execute()` for normal apps. Apps marked `Terminal=true` (btop, nvim)
  are run inside `kitty`.

**Icons:** `Quickshell.iconPath(name, true)` looks the name up in your icon themes and
returns `""` if nothing is found. Your system only has the **Adwaita** and **hicolor**
themes, so a few apps (Avahi, network config, hwloc) have no icon. They get a Material
`apps` icon instead of Qt's magenta checkerboard. For full coverage, install an icon
theme (Caelestia uses `papirus-icon-theme`) and set it in Phase 12.

## Wallpapers: `services/Wallpapers.qml`

```qml
FolderListModel { folder: "file://" + root.dir; nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]; … }
```
- **`FolderListModel`** (`Qt.labs.folderlistmodel`) lists a folder's files and updates
  when files are added or removed. We copy the paths into a plain array (`all`) so the
  fuzzy filter can work on it.
- `dir` comes from `shell.json` (`paths.wallpaperDir`), with a leading `~` expanded.
  Change the folder and the picker follows, live.
- `set(path)` runs your Phase 4 script with `Quickshell.execDetached([...])`. It
  writes `wallpaper.json` and `scheme.json`, and the shell already watches both. The
  launcher doesn't need to know anything about colours.

## The panel: `Launcher.qml`

- **Same slide technique as the popouts:** `height` animates from 0, `clip: true`, and
  the content is anchored to the **bottom**, so it rises out of the screen edge.
- **Two lists, one visible:** `wallpaperMode` (`text.startsWith(">wall")`) decides
  which. `currentList` points at the visible one, so Enter and Tab work the same in
  both.
- **App list** uses `verticalLayoutDirection: ListView.BottomToTop`, so the best match
  sits right above the search field (where your eyes are). That's why **↑ = next**.
- **The highlight** is a `highlight:` component, a pill the `ListView` moves to
  `currentIndex` by itself. `onTextChanged` resets to index 0, the best match.
- **Wallpaper strip:** `highlightRangeMode: StrictlyEnforceRange` with
  `preferredHighlightBegin/End` keeps the selected thumbnail in the **centre** while
  the strip scrolls.
- **Thumbnails** (`WallpaperItem.qml`) are decoded at ~1.5× thumbnail size
  (`sourceSize`) and asynchronously. Your wallpapers are up to 5000 px wide, and full
  decoding would use gigabytes. `ClippingRectangle` (Quickshell.Widgets) rounds the
  corners, which a plain `Rectangle` can't do for its children.
- `item.activated()`: each delegate has an `activated` signal, so Enter (keyboard) and
  click (mouse) run the same code.

---

## How to change it

| I want to… | Edit |
| --- | --- |
| use another wallpaper folder | `"paths": { "wallpaperDir": "…" }` in `~/.config/myshell/shell.json` (live) |
| show more or fewer apps at once | `Math.min(count, 7)` in `Launcher.qml` |
| a wider launcher, bigger rows or thumbnails | `launcherWidth`, `launcherItemHeight`, `wallpaperWidth/Height` in `config/Appearance.qml` |
| change the `>wall` prefix | `startsWith(">wall")` and `slice(5)` in `Launcher.qml` |
| hide an app from the launcher | add `NoDisplay=true` to a copy of its `.desktop` file in `~/.local/share/applications/` |
| a different terminal for terminal apps | `"kitty"` in `services/Apps.qml` |
| tune search ranking | the bonuses in `utils/fuzzy.js` |
| open with another key | `kbLauncher` in `~/.config/hypr/variables.lua` (e.g. `"SUPER + Space"`, fires on press then) |

## Try it (10 minutes)

1. **Fuzzy:** tap Super and type `zn`, `brow`, `blue`. Watch the order change as you type.
2. **Keywords:** type `browser`. Zen appears although its name doesn't contain it.
3. **Wallpapers:** type `>wall`, use ← →, then type `>wall ber` and press Enter. The
   wallpaper and all the colours change.
4. **Closing:** open it, then click on a window. It closes (the focus grab).
5. **Tune ranking:** in `utils/fuzzy.js`, change the `+10` "starts with" bonus to `0`,
   then type `b`. Compare the order and undo.
6. **Read the shortcut:** run `hyprctl globalshortcuts`, then trigger it from a terminal
   with `hyprctl dispatch 'hl.dsp.global("myshell:launcher")'`.

## Debugging

- **Super does nothing:** `hyprctl globalshortcuts` must list `myshell:launcher`. If not,
  the shell isn't running, or `Shortcuts {}` is missing from `shell.qml`. If it's listed
  but nothing happens, restart the shell (`Ctrl + Super + Alt + R`): a hot reload of
  `Shortcuts.qml` leaves the shortcut deaf.
- **Is the shell running?** `qs list --all` shows the instance and its process ID.
  `coredumpctl list` shows crashes.
- **Opens but you can't type:** keyboard focus. Check `keyboardFocus` in
  `ContentWindow.qml` and that `search.forceActiveFocus()` runs.
- **Opens on the wrong monitor:** `ShellState` uses `Hyprland.focusedMonitor`. Check
  with `hyprctl monitors` which is focused.
- **No wallpapers:** the message shows the folder it looked in. Check
  `paths.wallpaperDir`, and that the files end in `.jpg/.jpeg/.png/.webp`.
- **A missing app:** `ls /usr/share/applications ~/.local/share/applications | grep -i name`.
  No `.desktop` file means no launcher entry.

## Common errors

| Symptom | Cause |
| --- | --- |
| Magenta/black checkerboard icon | `IconImage` given a name no icon theme has. Use `iconPath(name, true)` and a fallback |
| Launcher stays open after clicking elsewhere | `HyprlandFocusGrab` inactive, or `windows` doesn't include the drawer window |
| Typing goes to the app behind | `keyboardFocus` still `None` |
| Two launchers on two monitors | Comparing with something other than the focused monitor's name |
| Works from `hyprctl dispatch` but not from the key | Handling only `onPressed`. A release-type bind sends only `onReleased` |
| No shell after pressing the restart key | No pause between `qs kill` and starting with `-n` |
| Shell feels slow scrolling wallpapers | `sourceSize` missing on the thumbnail `Image` (decoding full-size images) |

## Completion notes

Built and tested on 2026-10-03:
- **Typing couldn't be automated** (Hyprland's `send_shortcut` targets app windows, not
  the shell). Tested with a **test-only copy** whose search field was pre-filled from an
  environment variable: empty → all apps, `zen` → Zen Browser first,
  `>wall ber` → berries-2/berries-1 thumbnails. The live launcher was opened via
  `hyprctl dispatch 'hl.dsp.global("myshell:launcher")'` and screenshotted.
- **Missing icons:** Avahi (3 apps), "Advanced Network Configuration" and hwloc showed
  Qt's checkerboard. Fixed with `iconPath(…, true)` + a Material fallback.
- **Empty wallpaper results** left a blank gap, and the "not found" message overflowed.
  The strip now hides when empty, and the message wraps.
- **Test-setup lesson:** with a fake `HOME`, `~` in `wallpaperDir` pointed to the fake
  home. Tests used an absolute path.
- **Hot reload and a new folder** (`modules/launcher/`): needed one extra save, as in
  Phase 6.
- **"Pressing Super does nothing"** (your first check). Two separate causes:
  1. **Hot reload breaks global shortcuts.** Editing `Shortcuts.qml` re-creates the
     `GlobalShortcut`, but Hyprland keeps the old registration and the new object never
     receives anything. Even `hyprctl dispatch 'hl.dsp.global(...)'` stopped working until
     a **full restart**. Now noted at the top of `Shortcuts.qml`.
  2. **Release-type binds send only "released".** The Super-tap bind has the `release`
     flag, so Hyprland sends the shortcut a *released* event only, while `hyprctl dispatch`
     sends only *pressed*. The first version reacted to `onPressed` only, so it worked from
     the terminal but not from the key. **Fix:** toggle on whichever event comes first
     (`handledPress` flag), never twice per key press. Caelestia toggles on `onReleased`
     for the same reason.
- **"Quickshell has crashed" dialog** during the restarts. `coredumpctl` showed a
  SIGSEGV in Quickshell's own Wayland clean-up while the **original process of a `-d`
  (daemonize) start was exiting**. That's a Quickshell 0.3.1 bug, not our QML, and the
  background copy kept running. **Fix:** `shellCmd` no longer uses `-d` (Hyprland already
  runs it in the background).
- **The shell vanished after a restart:** `qs kill` returns before the old instance has
  exited. The new one, started with `-n` (no duplicates), saw it still running and quit.
  **Fix:** the restart bind now runs `qs kill …; sleep 0.5; qs …`. Verified with three
  restarts in a row: one instance each time, no new crash dumps, shortcut registered.
- **Still on rofi:** the clipboard history (`Super + V`) and the keybind cheat sheet
  (`Super + /`). The `rofi` layer rule stays for them. Moving clipboard history into the
  launcher (a `>clip` mode) is a natural follow-up.

Commits (`my-first-shell`):
1. "fuzzy search, Apps/Wallpapers/ShellState services, launcher sizes, wallpaperDir setting"
2. "launcher (apps + wallpaper picker), global shortcut, keyboard focus and focus grab"

`~/.config/hypr`: "Super tap opens the shell's launcher instead of rofi", "start the shell
without -d", "restart bind waits for the old shell to exit".
Also `my-first-shell`: "launcher shortcut: handle release-only events".

## Check it

- [ ] Tapping Super opens the launcher, and tapping again closes it; Super + T etc. still don't open it
- [ ] You can type straight away (the cursor is in the search field)
- [ ] ↑/↓ move the highlight, Enter launches the app, and the launcher closes
- [ ] Esc closes it, and clicking outside closes it
- [ ] `>wall`: ←/→ move, Enter sets the wallpaper and the colours change
- [ ] Clicking an app or a thumbnail works too

## Questions

1. Why does the launcher need keyboard focus but the popouts don't (except for the password field)?
2. What's the difference between `hl.dsp.exec_cmd("rofi …")` and `hl.dsp.global("myshell:launcher")`?
3. Why is the app list drawn bottom-to-top, and what does that change about the arrow keys?
4. Why does setting a wallpaper from the launcher not need any code about colours?

<details>
<summary>Answers</summary>

1. Popouts are used with the mouse. The launcher is used by **typing**, and a
   layer-shell surface only gets keyboard input when it asks (`keyboardFocus`).
   Asking only while open keeps the shell from stealing your keys.
2. `exec_cmd` starts a **new program** each time. `global` sends a named signal to an
   **already running** program that registered that name. The launcher is part of the
   running shell, so it needs the second.
3. So the best match sits right next to the search field. Index 0 is at the bottom, so
   moving "up" the screen means *increasing* the index. ↑ calls `incrementCurrentIndex()`.
4. The shell already watches `scheme.json` (Phase 4). The launcher only runs
   `set-wallpaper.py`, which writes the files, and `Colours` reacts by itself. Each part
   does one job, connected through files.

</details>
