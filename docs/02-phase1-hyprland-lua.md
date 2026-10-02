# Phase 1: Hyprland in Lua

**Goal:** rebuild Caelestia's Hyprland behaviour (gaps, blur, animations,
window rules, special workspaces, keybinds) as *your own* Lua config, and
understand every line of it.

**Why Lua, why now:** Hyprland 0.56 prints *"You are using the .conf config
format, support for which will be removed in Hyprland 0.57."* The Lua format
is the future, and it's also what Caelestia uses, so you can compare your
files with theirs side by side.

**Reference folder:** `~/raunak/configurations/caelestia/hypr/`

**Prerequisite:** Phase 0 is done (backup, git, packages, `.luarc.json`).

---

## 1.0 How this phase works (read this first)

Hyprland only loads **one entry file**: `~/.config/hypr/hyprland.lua` (or the
old `hyprland.conf`). Everything else is pulled in from there with
`require(...)`.

So we write **all the modules first**. While `hyprland.lua` doesn't exist,
Hyprland keeps using your old `hyprland.conf`, and nothing changes on screen.
The entry file comes **last** (step 1.18). That's the moment you switch over.

Until then, check each file with the Lua compiler in "parse only" mode:
```bash
luac -p ~/.config/hypr/<file>.lua   # prints nothing if the syntax is fine
```

### Load order (what happens at login)
```
hyprland.lua
 ├─ copy scheme/default.lua → scheme/current.lua   (only if missing)
 ├─ require "hypr-vars"      ~/.config/myshell/hypr-vars.lua  → patches variables
 ├─ hl.monitor(...)          default rule for any monitor
 ├─ require "hyprland.env"          ─┐
 ├─ require "hyprland.general"       │  each one does:
 ├─ require "hyprland.input"         │    local vars = require("variables")
 ├─ require "hyprland.misc"          │    hl.config({...}) / hl.bind(...) / ...
 ├─ require "hyprland.animations"    │
 ├─ require "hyprland.decoration"    │
 ├─ require "hyprland.group"         │
 ├─ require "hyprland.execs"         │  (execs, gestures, keybinds also
 ├─ require "hyprland.rules"         │   require "utils.functions")
 ├─ require "hyprland.gestures"      │
 ├─ require "hyprland.keybinds"     ─┘
 └─ require "hypr-user"      ~/.config/myshell/hypr-user.lua  → your extras, last
```

### What changes compared to your old config
This setup uses Caelestia's layout, but **keeps four of your old binds**
(chosen 2026-10-02): terminal, browser, lock and vim-style focus. After the
switch:

| Action | Old bind | New bind | Caelestia default |
| --- | --- | --- | --- |
| Terminal (kitty) | `Super + Return` | `Super + Return` (kept) | `Super + T` |
| Browser (zen) | `Super + B` | `Super + B` (kept) | `Super + W` |
| Lock (hyprlock) | `Super + Escape` | `Super + Escape` (kept) | `Super + L` |
| Focus window | `Super + H/J/K/L` | `Super + H/J/K/L` (kept, arrows removed) | `Super + Arrow keys` |
| File manager (nautilus) | `Super + F` | `Super + E` | `Super + E` |
| Launcher (rofi) | `Super + Space` | tap `Super` on its own | same |
| Fullscreen | (none) | `Super + F` | same |
| Move window | (none) | `Super + Shift + Arrow keys` | same |
| Special workspace | `Super + S` | `Super + S` | same |
| Close window | `Super + Q` | `Super + Q` | same |

Want another old bind back? Every `kb…` name can be changed in
`variables.lua`, or overridden in `~/.config/myshell/hypr-vars.lua`
(step 1.17).

---

## 1.1 Just enough Lua

**Why:** You need about ten Lua ideas for this whole phase. Here they are.

```lua
-- A comment. Lua has no semicolons, and indentation doesn't matter.

local x = 5              -- `local` = visible only in this file/block. Always use it.
local name = "kitty"     -- strings use "..." or '...'
local s = "a" .. "b"     -- `..` joins strings → "ab"; numbers are converted automatically

local t = { gaps = 5, blur = true }   -- a TABLE with named fields (like a dict / JSON object)
print(t.gaps)                         -- 5
local list = { "a", "b", "c" }       -- a table used as a list; indexes start at 1!
print(list[1], #list)                -- "a", 3   (# = length)

for i = 1, 10 do end                  -- numeric loop, 1..10 inclusive
for _, v in ipairs(list) do end       -- loop over a list, in order
for k, v in pairs(t) do end           -- loop over every key/value, any order

if x > 3 and name ~= "foot" then end  -- `~=` means "not equal"
local y = cond and a or b             -- Lua's "ternary": if cond then a else b

local function add(a, b)              -- a function
    return a + b
end

local function make_greeter(who)      -- a function that RETURNS a function (a "closure").
    return function()                 -- The inner function remembers `who`.
        print("hi " .. who)           -- Keybinds use this a lot: "do this LATER, when pressed".
    end
end

-- Modules: a file that ends in `return { ... }` can be loaded with require.
local vars = require("variables")     -- loads ~/.config/hypr/variables.lua
local fn   = require("utils.functions") -- dots become folders: utils/functions.lua
```

**The one Lua fact the whole config depends on:** `require` runs a file
**only once** and caches what it returned. Every later
`require("variables")` gets the **same table**. So if `hyprland.lua`
changes `vars.terminal`, every module sees the change. That's how the
override file (`hypr-vars.lua`) works.

**`hl`** is a global table that Hyprland provides. Everything you ask
Hyprland to do goes through it:
- `hl.config({...})`: set options
- `hl.bind(key, action, flags)`: create a keybind
- `hl.dsp.*`: "dispatchers", actions such as `hl.dsp.exec_cmd("kitty")`
- `hl.dispatch(d)`: run a dispatcher right now
- `hl.window_rule`, `hl.env`, `hl.on(event, function)`, …

The full list, with types, is in `/usr/share/hypr/stubs/hl.meta.lua`. Your
editor reads it through `.luarc.json`.

---

## 1.2 Folder layout

**Read:** `ls -R ~/raunak/configurations/caelestia/hypr`

**Run:**
```bash
cd ~/.config/hypr
mkdir -p hyprland utils scheme
mkdir -p ~/.config/myshell
```

| Path | Holds |
| --- | --- |
| `hyprland/` | one module per topic (general, input, keybinds…) |
| `utils/` | helper functions used by several modules |
| `scheme/` | colours: `default.lua` (yours), `current.lua` (generated) |
| `~/.config/myshell/` | personal overrides, outside the repo |

---

## 1.3 Colours: `scheme/default.lua`

**Why:** Borders, shadows and group bars use Material 3 colour names such as
`primary` and `outline`. In Phase 4 a script generates these from your
wallpaper into `scheme/current.lua`. Until then, `hyprland.lua` copies
`default.lua` → `current.lua` whenever `current.lua` is missing.

**Read:** `caelestia/hypr/scheme/default.lua`. It has about 100 colours. We
only need the 7 that the Hyprland config actually uses.

**Write:** `~/.config/hypr/scheme/default.lua`
```lua
-- Fallback colour scheme (Material 3 tokens, hex without "#").
-- hyprland.lua copies this to current.lua on first start.
-- From Phase 4 on, current.lua is generated from your wallpaper instead.
return {
    primary          = "c2c1ff",
    onPrimary        = "2a2a60",
    secondary        = "c6c4e0",
    outline          = "918f9a",
    onSurfaceVariant = "c8c5d1",
    inversePrimary   = "595992",
    surfaceContainer = "201f23",
}
```
- The file is just `return { ... }`, a module that hands back one table.
- There's no `#` in front of the hex values, because other code adds an alpha
  suffix, e.g. `"rgba(" .. primary .. "e6)"` → `rgba(c2c1ffe6)`.

**Write:** add this line to `~/.config/hypr/.gitignore`. It's a generated
file, so it doesn't belong in git.
```gitignore
scheme/current.lua
```

**Check:** `luac -p scheme/default.lua`

**Commit:** `git add -A && git commit -m "hypr: add fallback colour scheme"`

---

## 1.4 All tunables in one place: `variables.lua`

**Why:** Every number, colour, app and keybind is defined **once**, here.
Modules only *read* these values. To change your terminal or a keybind, you
edit one line, not hunt through ten files.

**Read:** `caelestia/hypr/variables.lua`. Compare it with the version below.
The differences:
- apps you actually have (kitty, zen-browser, nautilus, nvim, pavucontrol)
- a **Temporary tools** block for things our shell will replace later
- `specialApps` replaces Caelestia's JSON config file
- `Adwaita` cursor and `systemctl suspend`

**Write:** `~/.config/hypr/variables.lua`
```lua
local scheme = require("scheme.current")

return {
    ------------------
    ---- HYPRLAND ----
    ------------------

    -- Apps
    terminal                   = "kitty",
    browser                    = "zen-browser",
    editor                     = "kitty -e nvim",
    fileExplorer               = "nautilus",
    audioSettings              = "pavucontrol",

    -- Temporary tools: each one is replaced by our own shell in a later phase
    barCmd                     = "waybar",                                      -- Phase 5
    wallpaperCmd               = "hyprpaper",                                   -- Phase 4
    launcherCmd                = "pkill rofi || rofi -show drun",               -- Phase 7
    clipboardCmd               = "pkill rofi || cliphist list | rofi -dmenu | cliphist decode | wl-copy", -- Phase 7
    lockCmd                    = "hyprlock",                                    -- Phase 10

    -- Touchpad
    touchpadDisableTyping      = true,
    touchpadScrollFactor       = 0.3,
    gestureFingers             = 3,
    workspaceSwipeFingers      = 4,
    gestureFingersMore         = 4,

    -- Blur
    blurEnabled                = true,
    blurSpecialWs              = false,
    blurPopups                 = true,
    blurInputMethods           = true,
    blurSize                   = 8,
    blurPasses                 = 2,
    blurXray                   = false,

    -- Shadow
    shadowEnabled              = true,
    shadowRange                = 15,
    shadowRenderPower          = 4,
    shadowColour               = "rgba(" .. scheme.inversePrimary .. "10)",

    -- Gaps
    workspaceGaps              = 20,
    windowGapsIn               = 5,
    windowGapsOut              = 10,
    singleWindowGapsOut        = 20,

    -- Window styling
    windowOpacity              = 0.95,
    windowRounding             = 15,
    windowBorderSize           = 1,
    activeWindowBorderColour   = "rgba(" .. scheme.primary .. "e6)",
    inactiveWindowBorderColour = "rgba(" .. scheme.onSurfaceVariant .. "11)",

    -- Misc
    volumeStep                 = 10,
    volumeMax                  = 100,
    cursorTheme                = "Adwaita",
    cursorSize                 = 24,
    sleepCmd                   = "systemctl suspend",

    -- Apps that live on each special workspace (used by utils/functions.lua)
    --   match   = window fields that must contain these strings
    --   command = started if no matching window exists
    --   move    = pull matching windows onto the special workspace
    specialApps                = {
        sysmon        = {
            btop = { match = { class = "btop" }, command = "kitty --class btop -T btop btop" },
        },
        music         = {
            spotify = { match = { class = "Spotify" }, move = true },
        },
        communication = {
            discord = { match = { class = "discord" }, move = true },
        },
        todo          = {},
    },

    ------------------
    ---- KEYBINDS ----
    ------------------

    -- Modifier only: the actual binds are mod + 0-9
    kbGoToWs                   = "SUPER",
    kbGoToWsGroup              = "CTRL + SUPER",
    kbMoveWinToWs              = "SUPER + ALT",
    kbMoveWinToWsGroup         = "CTRL + SUPER + ALT",

    -- Everything below can be one string or a list of strings

    -- Workspaces
    kbMoveWinToWsSpecial       = { "SUPER + ALT + S", "CTRL + SUPER + SHIFT + Up" },
    kbMoveWinFromWsSpecial     = "CTRL + SUPER + SHIFT + Down",
    kbMoveWinToWsNext          = { "SUPER + ALT + mouse_down", "SUPER + ALT + Page_Down", "CTRL + SUPER + SHIFT + Right" },
    kbMoveWinToWsPrev          = { "SUPER + ALT + mouse_up", "SUPER + ALT + Page_Up", "CTRL + SUPER + SHIFT + Left" },
    kbNextWs                   = { "SUPER + mouse_down", "CTRL + SUPER + Right", "SUPER + Page_Down" },
    kbPrevWs                   = { "SUPER + mouse_up", "CTRL + SUPER + Left", "SUPER + Page_Up" },
    kbNextWsGroup              = "CTRL + SUPER + mouse_down",
    kbPrevWsGroup              = "CTRL + SUPER + mouse_up",

    -- Window groups
    kbWindowCycleNext          = "ALT + TAB",
    kbWindowCyclePrev          = "SHIFT + ALT + TAB",
    kbWindowGroupCycleNext     = "CTRL + ALT + TAB",
    kbWindowGroupCyclePrev     = "CTRL + SHIFT + ALT + TAB",
    kbUngroup                  = "SUPER + U",
    kbToggleGroup              = "SUPER + Comma",
    kbGroupLockActive          = "SUPER + SHIFT + Comma",

    -- Window actions
    kbWindowDecreaseWidth      = { "SUPER + Minus", "SUPER + ALT + Left" },
    kbWindowIncreaseWidth      = { "SUPER + Equal", "SUPER + ALT + Right" },
    kbWindowDecreaseHeight     = { "SUPER + SHIFT + Minus", "SUPER + ALT + Up" },
    kbWindowIncreaseHeight     = { "SUPER + SHIFT + Equal", "SUPER + ALT + Down" },
    kbMoveWindow               = "SUPER + Z",
    kbResizeWindow             = "SUPER + X",
    kbCenterWindow             = "CTRL + SUPER + Backslash",
    kbNormalizeWindow          = "CTRL + SUPER + ALT + Backslash",
    kbWindowPip                = "SUPER + ALT + Backslash",
    kbPinWindow                = "SUPER + P",
    kbWindowFullscreen         = "SUPER + F",
    kbWindowBorderedFullscreen = "SUPER + ALT + F",
    kbToggleWindowFloating     = "SUPER + ALT + Space",
    kbCloseWindow              = "SUPER + Q",

    -- Focus windows (vim style: H = left, J = down, K = up, L = right)
    kbFocusLeft                = "SUPER + H",
    kbFocusDown                = "SUPER + J",
    kbFocusUp                  = "SUPER + K",
    kbFocusRight               = "SUPER + L",

    -- Special workspace toggles
    kbSpecialWs                = "SUPER + S",
    kbSystemMonitorWs          = "CTRL + SHIFT + Escape",
    kbMusicWs                  = "SUPER + M",
    kbCommunicationWs          = "SUPER + D",
    kbTodoWs                   = "SUPER + R",

    -- Apps
    kbTerminal                 = "SUPER + Return",
    kbBrowser                  = "SUPER + B",
    kbEditor                   = "SUPER + C",
    kbFileExplorer             = "SUPER + E",
    kbAudioSettings            = "CTRL + ALT + V",

    -- Utilities
    kbScreenshot               = "Print",
    kbScreenshotRegion         = "SUPER + SHIFT + S",
    kbColorPicker              = "SUPER + SHIFT + C",

    -- Media
    kbMediaToggle              = "CTRL + SUPER + Space",
    kbMediaNext                = "CTRL + SUPER + Equal",
    kbMediaPrev                = "CTRL + SUPER + Minus",
    kbMediaStop                = "CTRL + SUPER + Backspace",
    kbVolumeMute               = "SUPER + SHIFT + M",

    -- Misc
    kbLauncher                 = "SUPER + SUPER_L",
    kbExit                     = "CTRL + SUPER + ALT + Delete",
    kbLock                     = "SUPER + Escape",
    kbSleep                    = "SUPER + SHIFT + L",
    kbClipboard                = "SUPER + V",
}
```

**Line by line (the parts that aren't self-explanatory):**
- `local scheme = require("scheme.current")`: loads the colours from 1.3, so
  colours below can be built from them.
- `editor = "kitty -e nvim"`: nvim runs inside a terminal, so we start kitty
  and tell it (`-e`) to execute nvim.
- `launcherCmd = "pkill rofi || rofi -show drun"`: a *toggle*. If rofi is
  running, `pkill` succeeds and `||` stops there (closes it). If not, `pkill`
  fails, so `rofi` starts. `drun` = the "desktop apps" mode.
- `clipboardCmd`: `cliphist list` prints history → `rofi -dmenu` lets you
  pick one line → `cliphist decode` turns it back into the original content
  → `wl-copy` puts it on the clipboard.
- `gestureFingers = 3`, `workspaceSwipeFingers = 4`: 3-finger swipes
  open/close special workspaces, and 4-finger horizontal swipes change
  workspace (your old config used 3 for workspaces).
- `blur*`: blur the background behind see-through windows. `size` = radius,
  `passes` = how many times (more = smoother but slower). `xray = false`
  means floating windows blur what's under them, not just the wallpaper.
- `shadowColour = "rgba(" .. scheme.inversePrimary .. "10)"`: builds e.g.
  `rgba(59599210)`. The last two hex digits are the alpha: `10` ≈ 6%
  opacity, a faint tinted glow.
- `workspaceGaps`: space between workspaces while swiping. `windowGapsIn`:
  between windows. `windowGapsOut`: between windows and the screen edge.
- `windowOpacity = 0.95`: every window is 95% opaque, so the blur shows
  through a little. This is a big part of the Caelestia look.
- `activeWindowBorderColour`: `e6` alpha ≈ 90%. Inactive borders use `11` ≈
  7%, almost invisible.
- `volumeMax = 100`: the volume keys can't push past 100%.
- `specialApps`: a table of tables. `specialApps.sysmon.btop.match.class`
  is `"btop"`. Step 1.12 explains how it's used.
- `kb*` strings: `"SUPER + T"` is the new Lua bind syntax. `mouse_down` /
  `mouse_up` are the scroll wheel. `mouse:272` / `mouse:273` are the left and
  right buttons. `SUPER_L` is the left Super key used *as a key*, not as a
  modifier.
- A `kb` value can be a **list**, `{ "SUPER + Minus", "SUPER + ALT + Left" }`,
  which means "both of these do the same thing".

**Check:** `luac -p variables.lua`

**Commit:** `git add -A && git commit -m "hypr: add variables"`

---

## 1.5 Environment variables: `hyprland/env.lua`

**Why:** Apps read environment variables at startup to decide things like
"use Wayland or X11?" and "which cursor?". Hyprland sets them for every app
it launches.

**Read:** `caelestia/hypr/hyprland/env.lua`. We drop `QT_QPA_PLATFORMTHEME`
for now, because the Qt theming tool it needs comes in Phase 12.

**Write:** `~/.config/hypr/hyprland/env.lua`
```lua
local vars = require("variables")

-- Themes
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("XCURSOR_THEME", vars.cursorTheme)
hl.env("XCURSOR_SIZE", vars.cursorSize)

-- Toolkit backends
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland,x11,windows")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- XDG specifications
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Others
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")
```

| Line | Meaning |
| --- | --- |
| `QT_WAYLAND_DISABLE_WINDOWDECORATION=1` | Qt apps don't draw their own title bars (Hyprland has none either) |
| `QT_AUTO_SCREEN_SCALE_FACTOR=1` | Qt apps follow your 1.33 screen scale |
| `XCURSOR_THEME` / `XCURSOR_SIZE` | the cursor for apps (Hyprland's own is set in `execs.lua`) |
| `GDK_BACKEND=wayland,x11` | GTK apps: try Wayland, fall back to X11 |
| `QT_QPA_PLATFORM=wayland;xcb` | same for Qt (`xcb` = X11). Qt uses `;` as the separator |
| `SDL_VIDEODRIVER` | same for SDL (games) |
| `CLUTTER_BACKEND=wayland` | same for Clutter (some GNOME apps) |
| `ELECTRON_OZONE_PLATFORM_HINT=auto` | Electron apps (VS Code, Discord) use Wayland when they can, which means sharp text at 1.33 scale |
| `XDG_CURRENT_DESKTOP` etc. | tells portals (screen sharing, file pickers) which desktop is running |
| `_JAVA_AWT_WM_NONREPARENTING=1` | fixes blank/grey windows in Java apps on tiling WMs |

**Check / Commit:**
`luac -p hyprland/env.lua && git add -A && git commit -m "hypr: env"`

---

## 1.6 Layout, gaps, borders: `hyprland/general.lua`

**Read:** `caelestia/hypr/hyprland/general.lua`. We leave out its
`scrolling` block, which only matters if you switch `layout` to
`"scrolling"`.

**Write:** `~/.config/hypr/hyprland/general.lua`
```lua
local vars = require("variables")

hl.config({
    general = {
        layout          = "dwindle",
        allow_tearing   = false,

        gaps_workspaces = vars.workspaceGaps,
        gaps_in         = vars.windowGapsIn,
        gaps_out        = vars.windowGapsOut,
        border_size     = vars.windowBorderSize,

        col             = {
            active_border   = vars.activeWindowBorderColour,
            inactive_border = vars.inactiveWindowBorderColour,
        },
    },

    dwindle = {
        preserve_split = true,
        smart_split    = false,
        smart_resizing = true,
    },
})
```
- `hl.config({ general = { ... } })`: nested tables mirror the option
  names. `general.col.active_border` here is the `general:col.active_border`
  option from the Hyprland wiki.
- `layout = "dwindle"`: each new window splits the focused one in half,
  alternating direction (a binary-tree tiling).
- `allow_tearing = false`: tearing is only allowed for windows with the
  `immediate` rule (games, in `rules.lua`).
- `preserve_split`: a split keeps its direction even when you resize.
- `smart_split = false`: the split direction does **not** follow the mouse
  position.
- `smart_resizing = true`: resizing moves the nearest edge, which feels more
  natural.

**Check / Commit:** `luac -p hyprland/general.lua`, then commit.

---

## 1.7 Keyboard, touchpad, cursor: `hyprland/input.lua`

**Read:** `caelestia/hypr/hyprland/input.lua`

**Write:** `~/.config/hypr/hyprland/input.lua`
```lua
local vars = require("variables")

hl.config({
    input = {
        kb_layout          = "us",
        numlock_by_default = false,
        repeat_delay       = 250,
        repeat_rate        = 35,
        focus_on_close     = 1,

        touchpad           = {
            natural_scroll       = true,
            disable_while_typing = vars.touchpadDisableTyping,
            scroll_factor        = vars.touchpadScrollFactor,
        },
    },

    binds = {
        scroll_event_delay = 0,
    },

    cursor = {
        hotspot_padding = 1,
    },
})
```
- `repeat_delay = 250`: ms before a held key starts repeating.
  `repeat_rate = 35`: repeats per second. Snappier than the defaults
  (600 / 25).
- `focus_on_close = 1`: when a window closes, focus the window under the
  mouse, not the previously focused one.
- `natural_scroll = true`: "phone style" two-finger scrolling (content
  follows your fingers). Your old config had this **off**. If you prefer
  that, override it in `hypr-user.lua` (step 1.17).
- `scroll_factor = 0.3`: touchpad scrolling at 30% speed.
- `scroll_event_delay = 0`: scroll-wheel binds (`Super + scroll` to change
  workspace) react to every notch.
- `hotspot_padding = 1`: 1px padding at screen edges for cursor hit-testing.

Your `kb_options = ctrl:nocaps` (Caps Lock → Ctrl) is machine-specific, so
it goes in `hypr-user.lua`, not here.

---

## 1.8 Misc behaviour: `hyprland/misc.lua`

**Read:** `caelestia/hypr/hyprland/misc.lua`

**Write:** `~/.config/hypr/hyprland/misc.lua`
```lua
local scheme = require("scheme.current")

hl.config({
    misc = {
        animate_manual_resizes       = false,
        animate_mouse_windowdragging = false,

        disable_hyprland_logo        = true,
        force_default_wallpaper      = 0,

        on_focus_under_fullscreen    = 2,
        allow_session_lock_restore   = true,
        middle_click_paste           = false,
        focus_on_activate            = true,
        session_lock_xray            = true,

        mouse_move_enables_dpms      = true,
        key_press_enables_dpms       = true,

        background_color             = "rgb(" .. scheme.surfaceContainer .. ")",
    },

    debug = {
        error_position = 1,
    },
})
```
- `animate_*`: no animation while you drag or resize with the mouse, so the
  window sticks to the cursor instead of lagging behind.
- `disable_hyprland_logo`, `force_default_wallpaper = 0`: no anime mascot
  or logo behind your wallpaper.
- `on_focus_under_fullscreen = 2`: if a new window opens while another is
  fullscreen, the fullscreen one un-fullscreens.
- `allow_session_lock_restore`: if the lock screen crashes, you can restart
  it instead of being stuck. We need this in Phase 10.
- `middle_click_paste = false`: no accidental pastes when you middle-click.
- `focus_on_activate`: when an app asks for focus (e.g. a link opens in zen),
  give it focus.
- `session_lock_xray`: the lock screen can show the (blurred) desktop behind
  it.
- `*_enables_dpms`: moving the mouse or pressing a key wakes the screen.
- `background_color`: the colour behind everything, visible before the
  wallpaper loads.
- `debug.error_position = 1`: show config errors at the **bottom** of the
  screen.

---

## 1.9 Animations: `hyprland/animations.lua`

**Why:** This is where most of the Caelestia *feel* comes from. The curves
are Material 3 motion curves.

**Read:** `caelestia/hypr/hyprland/animations.lua`

**Write:** `~/.config/hypr/hyprland/animations.lua`
```lua
hl.config({
    animations = {
        enabled = true,
    },
})

-- Animation curves
hl.curve("specialWorkSwitch", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("emphasizedAccel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("emphasizedDecel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("standard", { type = "bezier", points = { { 0.2, 0 }, { 0, 1 } } })

-- Animation configs
hl.animation({ leaf = "layersIn", enabled = true, speed = 5, bezier = "emphasizedDecel", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 4, bezier = "emphasizedAccel", style = "slide" })
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 5, bezier = "standard" })

hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "emphasizedDecel" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "emphasizedAccel" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 6, bezier = "standard" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "standard" })

hl.animation({
    leaf    = "specialWorkspace",
    enabled = true,
    speed   = 4,
    bezier  = "specialWorkSwitch",
    style   = "slidefadevert 15%"
})
hl.animation({ leaf = "fade", enabled = true, speed = 6, bezier = "standard" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 6, bezier = "standard" })
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "standard" })
```
- **A bezier curve** describes *how* a value moves from start to end over
  time. The two points are the curve's control handles. Paste
  `0.05, 0.7, 0.1, 1` into <https://cubic-bezier.com> to see it.
  - `emphasizedDecel`: starts fast, glides to a stop. Used for things
    *appearing*.
  - `emphasizedAccel`: starts slow, speeds away. Used for things
    *disappearing*.
  - `standard`: a balanced ease for moves and fades.
- `leaf`: which animation. Hyprland has a tree of them: `windows` →
  `windowsIn`, `windowsOut`, `windowsMove`, and so on.
- `speed`: the duration in units of 100 ms. `5` = 500 ms, and smaller is
  faster.
- `style`: `slide` = slide in from the nearest edge. `slidefadevert 15%` =
  slide vertically 15% while fading. That's the special-workspace drop-down.
- `layersIn`/`layersOut` animate *layer surfaces*: bars, launchers, and later
  your shell's panels.

---

## 1.10 Blur, shadow, rounding: `hyprland/decoration.lua`

**Read:** `caelestia/hypr/hyprland/decoration.lua`

**Write:** `~/.config/hypr/hyprland/decoration.lua`
```lua
local vars = require("variables")

hl.config({
    decoration = {
        rounding = vars.windowRounding,

        blur = {
            enabled           = vars.blurEnabled,
            xray              = vars.blurXray,
            special           = vars.blurSpecialWs,
            ignore_opacity    = true,
            new_optimizations = true,
            popups            = vars.blurPopups,
            input_methods     = vars.blurInputMethods,
            size              = vars.blurSize,
            passes            = vars.blurPasses,
        },

        shadow = {
            enabled      = vars.shadowEnabled,
            range        = vars.shadowRange,
            render_power = vars.shadowRenderPower,
            color        = vars.shadowColour,
        },
    },
})
```
- `rounding`: corner radius in px (15, versus your old 1).
- `ignore_opacity = true`: blur still applies even though windows are 95%
  opaque. Without it, blur would fade out with the opacity.
- `new_optimizations`: cheaper blur. Keep it on.
- `special = false`: special workspaces don't blur the workspace behind them
  (saves GPU).
- `popups` / `input_methods`: also blur right-click menus and IME
  candidate windows.
- `shadow.render_power = 4`: how quickly the shadow fades (1–4, and 4 = sharp
  falloff).

---

## 1.11 Window groups (tabs): `hyprland/group.lua`

**Why:** A *group* stacks several windows into one tile with a tab bar. Try
it after the switch: `Super + Comma` groups, and `Alt + Tab` cycles.

**Read:** `caelestia/hypr/hyprland/group.lua`

**Write:** `~/.config/hypr/hyprland/group.lua`
```lua
local scheme = require("scheme.current")
local vars   = require("variables")

hl.config({
    group = {
        col = {
            border_active          = vars.activeWindowBorderColour,
            border_inactive        = vars.inactiveWindowBorderColour,
            border_locked_active   = vars.activeWindowBorderColour,
            border_locked_inactive = vars.inactiveWindowBorderColour,
        },
        groupbar = {
            font_family               = "JetBrains Mono NF",
            font_size                 = 15,
            gradients                 = true,
            gradient_round_only_edges = false,
            gradient_rounding         = 5,
            height                    = 25,
            indicator_height          = 0,
            gaps_in                   = 3,
            gaps_out                  = 3,
            text_color                = "rgb(" .. scheme.onPrimary .. ")",
            col                       = {
                active          = "rgba(" .. scheme.primary .. "d4)",
                inactive        = "rgba(" .. scheme.outline .. "d4)",
                locked_active   = "rgba(" .. scheme.primary .. "d4)",
                locked_inactive = "rgba(" .. scheme.secondary .. "d4)",
            },
        },
    },
})
```
- Group borders reuse the normal window border colours.
- `groupbar`: the tab strip. `gradients = true` draws each tab as a filled,
  rounded pill (the "gradient" is the fill). `indicator_height = 0` hides the
  thin underline.
- `text_color = onPrimary`: Material rule. Text on a `primary` background uses
  `onPrimary`, so it always contrasts.
- A **locked** group can't gain or lose windows (`Super + Shift + Comma`).
  Its inactive tabs use `secondary` so you can tell it apart.
- `"JetBrains Mono NF"` comes from `ttf-jetbrains-mono-nerd`, which is
  already installed.

**Commit** steps 1.7–1.11 together if you like:
`git add -A && git commit -m "hypr: input, misc, animations, decoration, group"`

---

## 1.12 Helper functions: `utils/functions.lua`

**Why:** Some binds need *logic*, not just "run this command". Examples:
- "go to workspace 3 **of the current group of ten**"
- "open the music workspace, and start Spotify if it isn't running"

Those functions live here and are shared by `keybinds.lua`, `gestures.lua`
and `execs.lua`.

**Read:** `caelestia/hypr/utils/functions.lua`. Our version is smaller:
Caelestia reads the special-workspace apps from a JSON file (`cli.json`,
parsed by `utils/json.lua`). We keep them in `variables.specialApps`, so we
need no JSON parser.

**Write:** `~/.config/hypr/utils/functions.lua`
```lua
local vars = require("variables")

--------------------
---- Workspaces ----
--------------------

-- Workspaces are grouped in tens: group 1 = 1-10, group 2 = 11-20, ...
-- action: "focus" or "move". range: "group" to jump between groups.
local function wsaction(action, range, i)
    return function()
        local activews = hl.get_active_workspace()
        if activews then
            local id = activews.id
            local s  = (i - 1) * 10 + (id % 10)            -- same slot, group i
            local t  = math.floor((id - 1) / 10) * 10 + i  -- slot i, same group
            local z  = (range == "group") and s or t

            if action == "move" then
                return hl.dispatch(hl.dsp.window.move({ workspace = z }))
            else
                return hl.dispatch(hl.dsp.focus({ workspace = z }))
            end
        end
    end
end

-----------------
---- Resizing ----
-----------------

-- Size as a percentage of the active monitor, e.g. (55, 70) = 55% x 70%
local function resize_by_screen(x, y)
    local screen = hl.get_active_monitor()
    if screen and type(screen.width) == "number" and type(screen.height) == "number" then
        if not (x == 0 and y == 0) then
            local w = (x and x > 0) and math.floor(screen.width * x / 100) or screen.width
            local h = (y and y > 0) and math.floor(screen.height * y / 100) or screen.height
            return { x = w, y = h, relative = false }
        end
    end
end

-- Grow/shrink the active window by a percentage of its own size
local function resize_active_window(x, y)
    return function()
        local win = hl.get_active_window()
        if win and win.size then
            local w = win.size.x * (x / 100)
            local h = win.size.y * (y / 100)
            hl.dispatch(hl.dsp.window.resize({ x = w, y = h, relative = true }))
        end
    end
end

-- Actions that shrink `win` to a quarter of the screen height and park it
-- in the bottom-right corner (used for picture-in-picture)
local function move_actions(win)
    local screen = hl.get_active_monitor()

    if screen and screen.width and screen.height and win and win.size then
        local monitor_height = screen.height / screen.scale
        local monitor_width  = screen.width / screen.scale

        local scale_factor   = (monitor_height / 4) / win.size.y

        local x_resize       = math.floor(math.max(200, win.size.x * scale_factor))
        local y_resize       = math.floor(math.max(150, win.size.y * scale_factor))

        local offset         = math.min(monitor_width, monitor_height) * 0.03

        local move_x         = math.floor(screen.x + monitor_width - x_resize - offset)
        local move_y         = math.floor(screen.y + monitor_height - y_resize - offset)

        return {
            hl.dsp.window.resize({ x = x_resize, y = y_resize, window = win }),
            hl.dsp.window.move({ x = move_x, y = move_y, relative = false, window = win }),
        }
    end
end

-- If window[field] matches `pattern`, run `actions` on it, then resize it
local function resizer(window, pattern, x_percent, y_percent, actions, exact, field)
    local value = window and window[field or "title"]
    if value and string.find(value, pattern, 1, exact) then
        for _, action in ipairs(actions) do
            hl.dispatch(action)
        end

        -- window = ... targets THIS window, not whichever one has focus
        local size = resize_by_screen(x_percent, y_percent)
        if size then
            size.window = window
            hl.dispatch(hl.dsp.window.resize(size))
        end
        hl.dispatch(hl.dsp.window.set_prop({ prop = "keep_aspect_ratio", value = "true", window = window }))
    end
end

---------------------------------
---- Special workspace toggle ----
---------------------------------

-- True if every field in `rule` is contained in the same field of `window`
local function window_matches(window, rule)
    for key, expected in pairs(rule) do
        local actual = window[key]
        if actual == nil or not string.find(tostring(actual), expected, 1, true) then
            return false
        end
    end
    return true
end

-- Make sure the apps of a special workspace are there:
-- start them if missing, or pull stray windows in
local function place_apps(apps, name)
    local target = "special:" .. name

    for _, app in pairs(apps) do
        local found = {}
        for _, window in ipairs(hl.get_windows() or {}) do
            if window_matches(window, app.match) then
                table.insert(found, window)
            end
        end

        if #found == 0 then
            if app.command then
                hl.dispatch(hl.dsp.exec_cmd(app.command, { workspace = target }))
            end
        elseif app.move then
            for _, window in ipairs(found) do
                local ws = window.workspace and window.workspace.name
                if ws ~= target then
                    hl.dispatch(hl.dsp.window.move({ window = window, workspace = target, follow = false }))
                end
            end
        end
    end
end

-- Returns a function that opens/closes special workspace `name`.
-- "specialws" means: close whichever special is open, or open "special".
local function toggle(name)
    return function()
        local active = hl.get_active_special_workspace()

        if name == "specialws" then
            local target = active and active.name:gsub("^special:", "") or "special"
            return hl.dispatch(hl.dsp.workspace.toggle_special(target))
        end

        local already_open = active and active.name == "special:" .. name

        if not already_open then
            hl.dispatch(hl.dsp.focus({ workspace = "special:" .. name }))
        end

        place_apps(vars.specialApps[name] or {}, name)

        if already_open then
            hl.dispatch(hl.dsp.workspace.toggle_special(name))
        end
    end
end

return {
    wsaction             = wsaction,
    resize_by_screen     = resize_by_screen,
    resize_active_window = resize_active_window,
    move_actions         = move_actions,
    resizer              = resizer,
    toggle               = toggle,
}
```

**How it works:**
- **Everything returns a function** (`return function() ... end`). A keybind
  needs *something to run later*. `fn.wsaction("focus", "", 3)` doesn't
  switch workspace. It *builds* a function that will, when the key is
  pressed. Inside, it reads the active workspace **at press time**. That's
  why it has to be a closure and not a precomputed value.
- **`wsaction` maths**, with the active workspace `id = 13` (group 2, slot 3):
  - `Super + 5` → `t = floor(12/10)*10 + 5 = 15`: slot 5 of **this** group.
  - `Ctrl + Super + 1` (range `"group"`) →
    `s = (1-1)*10 + (13 % 10) = 3`: slot 3 of **group 1**.
- `hl.get_active_monitor()` / `hl.get_active_window()` return tables whose
  fields are listed in `hl.meta.lua` (`HL.Monitor`, `HL.Window`).
- `screen.width / screen.scale`: monitor sizes are in real pixels, while
  window positions use *scaled* (logical) pixels. At 1.33 scale, 1920 px is
  1440 logical pixels wide.
- `string.find(value, pattern, 1, exact)`: Lua patterns look like regex but
  aren't. `%-` is an escaped `-`, and `[- ]` means "a dash or a space".
  `exact = true` turns patterns off (plain substring search).
- `window_matches`: `{ class = "btop" }` matches when `window.class`
  *contains* `"btop"`. The `1, true` makes it a plain substring search.
- `toggle`'s order matters:
  1. focus the special workspace first
  2. start or move the apps (they appear *on* it)
  3. if it was already open, hide it
- `active.name:gsub(...)` removes the `special:` prefix: `"special:music"`
  → `"music"`.
- The final `return { ... }` is the module's public interface. Local
  functions not listed there (`window_matches`, `place_apps`) stay private.

---

## 1.13 Autostart: `hyprland/execs.lua`

**Read:** `caelestia/hypr/hyprland/execs.lua`

**Write:** `~/.config/hypr/hyprland/execs.lua`
```lua
local vars = require("variables")
local fn   = require("utils.functions")

-- Runs once, when Hyprland starts (NOT on `hyprctl reload`)
hl.on("hyprland.start", function()
    -- Keyring and auth
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    -- Clipboard history
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Auto delete trash 30 days old
    hl.exec_cmd("trash-empty 30")

    -- Cursors
    hl.exec_cmd("hyprctl setcursor " .. vars.cursorTheme .. " " .. vars.cursorSize)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme " .. vars.cursorTheme)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size " .. vars.cursorSize)

    -- Forward bluetooth headphone buttons to MPRIS
    hl.exec_cmd("mpris-proxy")

    -- TEMPORARY: replaced by our own shell in later phases
    hl.exec_cmd(vars.barCmd)          -- Phase 5
    hl.exec_cmd(vars.wallpaperCmd)    -- Phase 4
    hl.exec_cmd("playerctld daemon")  -- Phase 8 (media keys use playerctl until then)
end)

-- Picture-in-picture windows: shrink and park them in the bottom-right corner
local function apply_resizer_rules(win)
    local pip_actions = fn.move_actions(win) or {}
    fn.resizer(win, "Picture[- ]in[- ][Pp]icture", 0, 0, pip_actions, false)
end

hl.on("window.title", apply_resizer_rules)
hl.on("window.open", apply_resizer_rules)
```
- `hl.on(event, function)`: run a function when something happens. Event
  names are in `hl.meta.lua` under `HL.EventName`.
- `"hyprland.start"`: fires once per login. That's the Lua version of
  `exec-once`. **It does not re-run on `hyprctl reload`.** To test changes
  here, log out and back in.
- `hl.exec_cmd(...)` runs a shell command right away. Compare
  `hl.dsp.exec_cmd(...)`, which *builds a dispatcher* to run later, for
  binds.
- `--components=secrets`: only start the password vault part of the keyring.
- The polkit agent is the "enter your password" dialog apps use to get root.
- `wl-paste --watch cliphist store`: every time the clipboard changes, pipe
  it to `cliphist`. There are two lines, one for text and one for images.
- `mpris-proxy`: Bluetooth headphone play/pause buttons control your media
  players.
- The PiP handler runs on `window.open` **and** `window.title`, because
  browsers often rename a window to "Picture-in-Picture" *after* opening it.
- Caelestia also starts `gammastep` (night light) and the `geoclue` agent.
  Neither is installed, so they're left out. Add them later if you want
  night light.

---

## 1.14 Window, workspace and layer rules: `hyprland/rules.lua`

**Why:** Rules change how specific windows behave: float this dialog, make
that app opaque, send btop to its own special workspace.

**Idea: tags.** Instead of repeating "float + size + centre" for twenty
apps, rules *tag* windows (`float_60_70`), and then **one** rule per tag says
what the tag does. Tag definitions must come **after** all tagging rules,
because Hyprland evaluates rules in order.

**Read:** `caelestia/hypr/hyprland/rules.lua`. We keep its structure and
trim the app lists to apps you might have. `kitty` replaces `foot` in the
opaque list.

**Write:** `~/.config/hypr/hyprland/rules.lua`
```lua
local vars = require("variables")

-- Give the "tag" to every window matching one of `matches`.
-- With `field`, matches is a list of strings for that field (e.g. "class").
-- Without it, matches is a list of full match tables.
local function tagged_rule(tag, matches, field)
    for _, match in ipairs(matches) do
        if field then
            match = { [field] = match }
        end
        hl.window_rule({ match = match, tag = "+" .. tag })
    end
end

-- Say what a tag actually does
local function create_tag(tag, rules)
    local rule = { match = { tag = tag } }
    for k, v in pairs(rules) do
        rule[k] = v
    end
    hl.window_rule(rule)
end


----------------------
---- Window rules ----
----------------------

-- Ignore "maximize me" requests from apps (kitty sends one when it opens),
-- so new windows tile normally
hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })

-- Every non-fullscreen window is slightly see-through (blur shows behind it)
hl.window_rule({ match = { fullscreen = false }, opacity = vars.windowOpacity .. " override" })

-- Centre floating windows (not xwayland: its popups are windows too)
hl.window_rule({ match = { float = true, xwayland = false }, center = true })

-- Picture in picture (resizing is done in execs.lua)
hl.window_rule({
    match             = { title = "Picture(-| )in(-| )[Pp]icture" },
    move              = "(monitor_w*0.98-window_w) (monitor_h*0.97-window_h)",
    pin               = true,
    float             = true,
    keep_aspect_ratio = true,
})


----------------------
---- Tagged rules ----
----------------------

-- Apps that handle their own transparency, or must never be see-through
tagged_rule("opaque", {
    "kitty",                         -- Terminal (set background_opacity in kitty.conf instead)
    "org.quickshell",                -- Quickshell
    "feh|imv|swappy",                -- Image viewers
    "krita|gimp|inkscape|darktable", -- Image editors
    "blender|godot",                 -- 3D editors
}, "class")

-- Floating apps
tagged_rule("float", {
    "yad|zenity",                       -- Dialogs
    "wev",                              -- Input detector
    "org.gnome.FileRoller|file-roller", -- Archive manager
    "blueman-manager",                  -- Bluetooth GUI
    "feh|imv|swappy",                   -- Image viewers
    "org.quickshell",                   -- Quickshell
}, "class")
tagged_rule("float", {
    "File (Operation|Upload)( Progress)?", -- File copy/move progress
    ".* Properties",                       -- File properties
    'Rename ".*"',                         -- File renaming
}, "title")

-- Sized floaters: 60% x 70% of the monitor
tagged_rule("float_60_70", {
    "(Select|Open)( a)? (File|Folder)(s)?", -- File dialogs
    "Save As",                              -- Save dialogs
}, "title")
tagged_rule("float_60_70", {
    "org.pulseaudio.pavucontrol|com.saivert.pwvucontrol", -- Audio control
}, "class")

-- 70% x 80%
tagged_rule("float_70_80", { "org.gnome.Settings" }, "class")

-- Games
tagged_rule("game", {
    "steam_app_[0-9]+",  -- Steam games
    "steam_app_default", -- Lutris games
    "gamescope",         -- Gamescope
}, "class")

-- Xwayland popups (menus of X11 apps)
tagged_rule("xwl_popup", {
    { xwayland = true, title = "win[0-9]+" },
    { xwayland = true, title = "",         class = "", initial_title = "", initial_class = "" },
})

-- Apps that belong on special workspaces
tagged_rule("system_monitor", { "btop" }, "class")
tagged_rule("music_player", { "Spotify" }, "class")
tagged_rule("music_player", { "Spotify|Spotify Free" }, "initial_title")
tagged_rule("communication_app", { "discord|vesktop|equibop" }, "class")


-------------------------
---- Tag definitions ----
-------------------------
-- These must come after every rule that adds a tag

create_tag("opaque", { opaque = true })
create_tag("float", { float = true })
create_tag("float_60_70", { float = true, size = "(monitor_w*0.6) (monitor_h*0.7)", center = true })
create_tag("float_70_80", { float = true, size = "(monitor_w*0.7) (monitor_h*0.8)", center = true })
create_tag("game", { opaque = true, immediate = true, idle_inhibit = "always" })
create_tag("xwl_popup", {
    no_dim    = true,
    no_shadow = true,
    no_blur   = true,
    opaque    = true,
    rounding  = math.min(10, vars.windowRounding),
})
create_tag("system_monitor", { workspace = "special:sysmon" })
create_tag("music_player", { workspace = "special:music" })
create_tag("communication_app", { workspace = "special:communication" })


-------------------------
---- Workspace rules ----
-------------------------

-- A lone tiled window (or a lone fullscreen one) gets bigger outer gaps
hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = vars.singleWindowGapsOut })
hl.workspace_rule({ workspace = "f[1]s[false]", gaps_out = vars.singleWindowGapsOut })


---------------------
---- Layer rules ----
---------------------

hl.layer_rule({ match = { namespace = "hyprpicker" }, animation = "fade" })              -- Colour picker
hl.layer_rule({ match = { namespace = "selection" }, animation = "fade" })               -- slurp
hl.layer_rule({ match = { namespace = "rofi" }, animation = "popin 80%", blur = true })  -- TEMPORARY until Phase 7
```
- `match = { [field] = match }`: `[field]` uses the *value* of `field` as
  the key. With `field = "class"`, this builds `{ class = "kitty" }`.
  (Caelestia does the same thing in three lines.)
- `suppress_event = "maximize"` (not in Caelestia; added 2026-10-02): some
  apps, including kitty, ask to be **maximized** when they open. Without
  this rule, every new kitty covered the whole workspace (`fullscreen: 1` in
  `hyprctl clients`) while the other windows tiled invisibly behind it. Your
  old `hyprland.conf` had the same rule. Caelestia doesn't need it because
  foot never asks. Maximizing by hand (`Super + Alt + F`) still works.
- `tag = "+" .. tag`: `+name` *adds* the tag. A bare `name` would toggle it.
- Match strings are **regexes**: `"feh|imv|swappy"` = any of the three.
  `[0-9]+` = one or more digits.
- `opacity = "0.95 override"`: `override` means "exactly 0.95", not
  "multiply the window's own opacity by 0.95".
- Find a window's `class` and `title`: run `hyprctl clients` and look at the
  `class:` and `title:` lines.
- `size = "(monitor_w*0.6) (monitor_h*0.7)"`: expressions are allowed inside
  rule values.
- `game` tag: `immediate = true` allows tearing (lower input lag), and
  `idle_inhibit = "always"` keeps the screen from sleeping mid-game.
- **Workspace selectors:** `w[tv1]` = "has exactly 1 tiled, visible window".
  `f[1]` = "has a fullscreen (maximised) window". `s[false]` = "not a
  special workspace". So a single window gets 20 px gaps instead of 10.
- **Layer rules** apply to *layer surfaces* (overlays that aren't normal
  windows). `namespace` is the name the program gives its overlay. List them
  with `hyprctl layers`.

---

## 1.15 Touchpad gestures: `hyprland/gestures.lua`

**Read:** `caelestia/hypr/hyprland/gestures.lua`

**Write:** `~/.config/hypr/hyprland/gestures.lua`
```lua
local vars = require("variables")
local fn   = require("utils.functions")

hl.config({
    gestures = {
        workspace_swipe_distance                 = 700,
        workspace_swipe_cancel_ratio             = 0.15,
        workspace_swipe_min_speed_to_force       = 5,
        workspace_swipe_direction_lock           = true,
        workspace_swipe_direction_lock_threshold = 10,
        workspace_swipe_create_new               = true,
    },
})

hl.gesture({ fingers = vars.workspaceSwipeFingers, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = vars.gestureFingers, direction = "up", action = "special", workspace_name = "special" })
hl.gesture({ fingers = vars.gestureFingers, direction = "down", action = fn.toggle("specialws") })
hl.gesture({
    fingers   = vars.gestureFingersMore,
    direction = "down",
    action    = function()
        hl.exec_cmd(vars.sleepCmd)
    end,
})
```
- `workspace_swipe_distance = 700`: how far (px) you swipe for one full
  workspace.
- `cancel_ratio = 0.15`: letting go before 15% snaps back.
  `min_speed_to_force = 5`: a quick flick switches anyway.
- `direction_lock`: once a swipe starts horizontally, vertical movement is
  ignored.
- `create_new`: swiping past the last workspace creates a new one.
- 4 fingers horizontal = change workspace. 3 up = open the "special" scratch
  workspace. 3 down = close whatever special is open. **4 down = suspend.**
- `action` can be a built-in name (`"workspace"`, `"special"`) **or your own
  Lua function**.

---

## 1.16 Keybinds: `hyprland/keybinds.lua`

**Read:** `caelestia/hypr/hyprland/keybinds.lua`. Caelestia's binds call
`hl.dsp.global("caelestia:launcher")` and similar, which are *global
shortcuts* its shell listens for. We have no shell yet, so those binds run
temporary commands (rofi, hyprlock, grim, playerctl, brightnessctl). In later
phases we switch them to our own `hl.dsp.global("myshell:...")`.

**Write:** `~/.config/hypr/hyprland/keybinds.lua`
```lua
local vars = require("variables")
local fn   = require("utils.functions")

---------------------------
---- Bind helpers ----
---------------------------

-- Flags
local locked           = { locked = true }    -- also works on the lock screen
local mouse            = { mouse = true }     -- hold-and-drag mouse bind
local release          = { release = true }   -- fires when the key is released
local repeating        = { repeating = true } -- repeats while held
local locked_repeating = { locked = true, repeating = true }

-- "SUPER + Mouse_Down" -> "super+mouse_down" so binds can be compared
local function normalise_keybind(key)
    return key:gsub("%s+", ""):lower()
end

-- A usable bind is a string with at least one non-space character
local function valid_keybind(key)
    return type(key) == "string" and key:match("%S") ~= nil
end

-- Scroll-wheel binds must not repeat; key binds should
local function repeating_unless_mouse(key)
    return not normalise_keybind(key):find("mouse", 1, true) and repeating or nil
end

-- Turn "a" or {"a", {"b", "c"}} into the flat list {"a", "b", "c"}
local function flatten_keybinds(keybinds, keys)
    keys = keys or {}

    if type(keybinds) == "table" then
        for _, keybind in pairs(keybinds) do
            flatten_keybinds(keybind, keys)
        end
    elseif valid_keybind(keybinds) then
        keys[#keys + 1] = keybinds
    end

    return keys
end

-- Bind every key in `keybinds` to `action`.
-- `flags` is a table, or a function that picks flags per key.
local function create_bind(keybinds, action, flags)
    local get_flags = type(flags) == "function" and flags or function()
        return flags
    end

    for _, key in ipairs(flatten_keybinds(keybinds)) do
        hl.bind(key, action, get_flags(key))
    end
end

-- ("SUPER", 1) -> "SUPER + 1"
local function extend_keybind(base, suffix)
    return valid_keybind(base) and base .. " + " .. suffix or nil
end

-------------------
---- Launcher ----
-------------------

-- Tapping Super alone opens the launcher, so it must fire on *release*
-- (otherwise Super + T would open the launcher too)
local launcher_default = normalise_keybind("SUPER + SUPER_L")
create_bind(
    vars.kbLauncher,
    hl.dsp.exec_cmd(vars.launcherCmd),
    function(key)
        return normalise_keybind(key) == launcher_default and release or nil
    end
)

---------------
---- Misc ----
---------------

create_bind(vars.kbLock, hl.dsp.exec_cmd(vars.lockCmd))
create_bind(vars.kbExit, hl.dsp.exit())
create_bind(vars.kbSleep, hl.dsp.exec_cmd(vars.sleepCmd), locked)
create_bind(vars.kbClipboard, hl.dsp.exec_cmd(vars.clipboardCmd))

--------------------
---- Workspaces ----
--------------------

for i = 1, 10 do
    local key = i % 10 -- workspace 10 is on key 0
    create_bind(extend_keybind(vars.kbGoToWs, key), fn.wsaction("focus", "", i))
    create_bind(extend_keybind(vars.kbMoveWinToWs, key), fn.wsaction("move", "", i))
    create_bind(extend_keybind(vars.kbGoToWsGroup, key), fn.wsaction("focus", "group", i))
    create_bind(extend_keybind(vars.kbMoveWinToWsGroup, key), fn.wsaction("move", "group", i))
end

create_bind(vars.kbPrevWs, hl.dsp.focus({ workspace = "-1" }), repeating_unless_mouse)
create_bind(vars.kbNextWs, hl.dsp.focus({ workspace = "+1" }), repeating_unless_mouse)
create_bind(vars.kbPrevWsGroup, hl.dsp.focus({ workspace = "-10" }), repeating_unless_mouse)
create_bind(vars.kbNextWsGroup, hl.dsp.focus({ workspace = "+10" }), repeating_unless_mouse)

create_bind(vars.kbMoveWinToWsNext, hl.dsp.window.move({ workspace = "+1" }), repeating_unless_mouse)
create_bind(vars.kbMoveWinToWsPrev, hl.dsp.window.move({ workspace = "-1" }), repeating_unless_mouse)

create_bind(vars.kbMoveWinToWsSpecial, hl.dsp.window.move({ workspace = "special:special" }))
create_bind(vars.kbMoveWinFromWsSpecial, hl.dsp.window.move({ workspace = "e+0" }))

-----------------------
---- Window groups ----
-----------------------

create_bind(vars.kbWindowCycleNext, hl.dsp.window.cycle_next(), repeating)
create_bind(vars.kbWindowCyclePrev, hl.dsp.window.cycle_next({ next = false }), repeating)
create_bind(vars.kbWindowGroupCycleNext, hl.dsp.group.next(), repeating)
create_bind(vars.kbWindowGroupCyclePrev, hl.dsp.group.prev(), repeating)
create_bind(vars.kbToggleGroup, hl.dsp.group.toggle())
create_bind(vars.kbUngroup, hl.dsp.window.move({ out_of_group = true }))
create_bind(vars.kbGroupLockActive, hl.dsp.group.lock_active())

------------------------
---- Window actions ----
------------------------

create_bind(vars.kbFocusLeft, hl.dsp.focus({ direction = "left" }))
create_bind(vars.kbFocusDown, hl.dsp.focus({ direction = "down" }))
create_bind(vars.kbFocusUp, hl.dsp.focus({ direction = "up" }))
create_bind(vars.kbFocusRight, hl.dsp.focus({ direction = "right" }))

for _, dir in ipairs({ "left", "right", "up", "down" }) do
    create_bind("SUPER + SHIFT + " .. dir, hl.dsp.window.move({ direction = dir }))
end

create_bind(vars.kbWindowDecreaseWidth, fn.resize_active_window(-10, 0), repeating)
create_bind(vars.kbWindowIncreaseWidth, fn.resize_active_window(10, 0), repeating)
create_bind(vars.kbWindowDecreaseHeight, fn.resize_active_window(0, -10), repeating)
create_bind(vars.kbWindowIncreaseHeight, fn.resize_active_window(0, 10), repeating)

create_bind({ vars.kbMoveWindow, "SUPER + mouse:272" }, hl.dsp.window.drag(), mouse)
create_bind({ vars.kbResizeWindow, "SUPER + mouse:273" }, hl.dsp.window.resize(), mouse)
create_bind(vars.kbCenterWindow, hl.dsp.window.center())
create_bind(vars.kbNormalizeWindow, function()
    hl.dispatch(hl.dsp.window.resize(fn.resize_by_screen(55, 70)))
    hl.dispatch(hl.dsp.window.center())
end)
create_bind(vars.kbWindowPip, function()
    local a = hl.get_active_window()
    if a then
        local pip = fn.move_actions(a) or {}
        if not a.floating then table.insert(pip, 1, hl.dsp.window.float()) end
        table.insert(pip, hl.dsp.window.pin({ action = "on", window = "address:" .. a.address }))

        for _, x in ipairs(pip) do
            hl.dispatch(x)
        end
    end
end)
create_bind(vars.kbPinWindow, hl.dsp.window.pin())
create_bind(vars.kbWindowFullscreen, hl.dsp.window.fullscreen({ mode = "fullscreen" }))
create_bind(vars.kbWindowBorderedFullscreen, hl.dsp.window.fullscreen({ mode = "maximized" }))
create_bind(vars.kbToggleWindowFloating, hl.dsp.window.float())
create_bind(vars.kbCloseWindow, hl.dsp.window.close())

-----------------------------------
---- Special workspace toggles ----
-----------------------------------

create_bind(vars.kbSpecialWs, fn.toggle("specialws"))
create_bind(vars.kbSystemMonitorWs, fn.toggle("sysmon"))
create_bind(vars.kbMusicWs, fn.toggle("music"))
create_bind(vars.kbCommunicationWs, fn.toggle("communication"))
create_bind(vars.kbTodoWs, fn.toggle("todo"))

--------------
---- Apps ----
--------------

create_bind(vars.kbTerminal, hl.dsp.exec_cmd(vars.terminal))
create_bind(vars.kbBrowser, hl.dsp.exec_cmd(vars.browser))
create_bind(vars.kbEditor, hl.dsp.exec_cmd(vars.editor))
create_bind(vars.kbFileExplorer, hl.dsp.exec_cmd(vars.fileExplorer))
create_bind(vars.kbAudioSettings, hl.dsp.exec_cmd(vars.audioSettings))

-------------------
---- Utilities ----
-------------------

-- TEMPORARY screenshots (Phase 11 replaces these with the shell's area picker)
create_bind(vars.kbScreenshot, hl.dsp.exec_cmd("grim - | wl-copy"), locked)
create_bind(vars.kbScreenshotRegion, hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))
create_bind(vars.kbColorPicker, hl.dsp.exec_cmd("hyprpicker -a"))

-------------------------------
---- Brightness and media ----
-------------------------------

-- TEMPORARY: Phase 8 routes these through the shell so it can show an OSD
create_bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), locked_repeating)
create_bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), locked_repeating)

create_bind({ vars.kbMediaToggle, "XF86AudioPlay", "XF86AudioPause" }, hl.dsp.exec_cmd("playerctl play-pause"), locked)
create_bind({ vars.kbMediaNext, "XF86AudioNext" }, hl.dsp.exec_cmd("playerctl next"), locked)
create_bind({ vars.kbMediaPrev, "XF86AudioPrev" }, hl.dsp.exec_cmd("playerctl previous"), locked)
create_bind({ vars.kbMediaStop, "XF86AudioStop" }, hl.dsp.exec_cmd("playerctl stop"), locked)

----------------
---- Volume ----
----------------

create_bind({ vars.kbVolumeMute, "XF86AudioMute" }, hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), locked)
create_bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), locked)
create_bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd(
        "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l " ..
        (vars.volumeMax / 100) .. " @DEFAULT_AUDIO_SINK@ " .. vars.volumeStep .. "%+"
    ),
    locked_repeating
)
create_bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd(
        "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. vars.volumeStep .. "%-"
    ),
    locked_repeating
)
```

**How it works:**
- **`hl.bind(key, action, flags)`** is the only real call. Everything else
  is a helper that feeds it:
  - `flatten_keybinds` lets any `kb…` value be a string *or* a (nested) list.
  - `valid_keybind` skips empty strings, so setting `kbTodoWs = ""` in
    `hypr-vars.lua` **disables** that bind.
  - `create_bind` calls `hl.bind` once per key. `flags` can also be a
    *function* that picks flags per key, as the launcher and
    `repeating_unless_mouse` do.
- **Actions** come in two kinds:
  - a dispatcher, e.g. `hl.dsp.exec_cmd("kitty")` or
    `hl.dsp.window.close()`, which Hyprland runs when the key is pressed
  - a plain Lua `function() ... end`, where you call `hl.dispatch(...)`
    yourself and can do several things in order (see `kbNormalizeWindow`)
- `key:gsub("%s+", ""):lower()`: `%s+` = "one or more spaces" (Lua
  pattern), replaced by nothing, then lower-cased.
- `repeating_unless_mouse`: holding `Super + Page_Down` should keep going,
  but a scroll wheel sends its own stream of events and must not repeat.
- **The launcher trick:** `SUPER + SUPER_L` with `release` means "Super was
  pressed and released with nothing else in between". Only the default
  launcher key gets the `release` flag. If you change `kbLauncher` to
  something like `SUPER + Space`, it fires on press instead.
- `i % 10`: `%` is modulo, so for `i = 10` we get key `0`.
- **Focus vs move:** Caelestia binds both in one loop over the arrow keys.
  Here focus has its own `kbFocus…` variables (your vim-style H/J/K/L), so
  only *moving* windows stays in the arrow-key loop. To also move with
  `Super + Shift + H/J/K/L`, you'd first have to move `kbSleep` off
  `Super + Shift + L`.
- `workspace = "e+0"`: `e` = "existing/open workspaces on this monitor",
  `+0` = the current one. It moves a window *out* of the special workspace
  onto the normal one behind it.
- `hl.dsp.window.fullscreen({ mode = "maximized" })`: fills the screen but
  keeps gaps, border and bar ("bordered fullscreen").
- `locked` binds (volume, brightness, media, sleep) keep working while the
  screen is locked.
- `wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 10%+`: `-l` = limit
  (1.0 = 100%). `@DEFAULT_AUDIO_SINK@` = the current output device. The
  command first unmutes (`set-mute … 0`), so volume-up works while muted.
- `grim -g "$(slurp)" - | wl-copy`: `slurp` lets you drag a rectangle and
  prints its geometry. `grim -g` screenshots that area to stdout (`-`), and
  `wl-copy` puts the image on the clipboard.

**Check:** `luac -p hyprland/keybinds.lua`

**Commit:** `git add -A && git commit -m "hypr: helpers, execs, rules, gestures, keybinds"`

---

## 1.17 Personal overrides: `~/.config/myshell/`

**Why:** Keep *machine-specific* things (this laptop's monitor, your Caps
Lock habit) and experiments separate from the main config.
- `hypr-vars.lua` changes **values** from `variables.lua`.
- `hypr-user.lua` adds **anything else**. It loads last, so it wins.

**Read:** the "Configuring" section of `caelestia/README.md`.

**Write:** `~/.config/myshell/hypr-user.lua`
```lua
-- Laptop screen: 1920x1080 @ 144 Hz, scaled to 1.33 (from my old hyprland.conf)
hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@144",
    position = "0x0",
    scale    = 1.333333,
})

-- Caps Lock acts as Ctrl
hl.config({
    input = {
        kb_options = "ctrl:nocaps",
    },
})
```
- `output = "eDP-1"`: your built-in panel (`hyprctl monitors` shows the
  name). A rule for a named output beats the catch-all `output = ""` rule in
  `hyprland.lua`.
- `mode = "1920x1080@144"`: resolution and refresh rate. Your panel supports
  144 Hz.
- `scale = 1.333333`: 4/3, which your old config wrote as 1.33.

**Write:** `~/.config/myshell/hypr-vars.lua`. It starts empty.
`hyprland.lua` would create it anyway, but writing it yourself shows the
idea:
```lua
return {
    -- Examples (uncomment to use):
    -- kbFileExplorer = "SUPER + F",   -- my old file manager bind (then move kbWindowFullscreen too!)
    -- windowRounding = 10,
}
```

If you want your old non-natural touchpad scrolling back, add this to
`hypr-user.lua`:
```lua
hl.config({ input = { touchpad = { natural_scroll = false } } })
```

**Check:** `luac -p ~/.config/myshell/*.lua`

---

## 1.18 The entry file, and switching over: `hyprland.lua`

**Why:** This file ties everything together. **Creating it is the switch.**
Do this step when you have ten quiet minutes, and remember the TTY escape
hatch (Phase 0, step 0.1).

**Read:** `caelestia/hypr/hyprland.lua`. Ours differs only in the override
folder (`~/.config/myshell` instead of `~/.config/caelestia`).

**Write:** `~/.config/hypr/hyprland.lua`
```lua
local home     = os.getenv("HOME")
local hypr     = home .. "/.config/hypr"
local user_dir = home .. "/.config/myshell"
package.path   = package.path .. ";" .. user_dir .. "/?.lua"

-- Create a file if it doesn't exist, optionally with initial content
local function maybe_create(file, content)
    local f = io.open(file)

    if f then
        f:close()
        return
    end

    f = io.open(file, "w")
    if f then
        if content then f:write(content) end
        f:close()
    end
end

-- Copy src to dst, but only if dst doesn't already exist
local function maybe_copy(src, dst)
    local out = io.open(dst)
    if out then
        out:close()
        return
    end

    local input = io.open(src, "r")
    if not input then return end

    out = io.open(dst, "w")
    if out then
        out:write(input:read("*a"))
        out:close()
    end
    input:close()
end

-- Colours: use the fallback scheme until Phase 4 generates one
maybe_copy(hypr .. "/scheme/default.lua", hypr .. "/scheme/current.lua")

-- Personal overrides for variables.lua
maybe_create(user_dir .. "/hypr-vars.lua", "return {}\n")
local overrides = require("hypr-vars")
if type(overrides) == "table" then
    local vars = require("variables")
    for k, v in pairs(overrides) do
        vars[k] = v
    end
end

-- Default monitor rule: any monitor, best mode, placed automatically
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-- Modules
require("hyprland.env")
require("hyprland.general")
require("hyprland.input")
require("hyprland.misc")
require("hyprland.animations")
require("hyprland.decoration")
require("hyprland.group")
require("hyprland.execs")
require("hyprland.rules")
require("hyprland.gestures")
require("hyprland.keybinds")

-- Personal config, loaded last so it can override anything above
maybe_create(user_dir .. "/hypr-user.lua")
require("hypr-user")
```
- `package.path`: the list of places `require` searches, as `?`-templates
  separated by `;`. Hyprland already includes `~/.config/hypr/?.lua`. We add
  `~/.config/myshell/?.lua`, so `require("hypr-vars")` finds our override
  file.
- `io.open(file)` returns a handle if the file exists, or `nil` if not.
  That's how `maybe_create`/`maybe_copy` test for existence. `"w"` = open for
  writing. `read("*a")` = read everything.
- **The override loop** is the heart of the design. `require("variables")`
  returns the cached table (see 1.1), and we overwrite its fields *before*
  any module reads them.
- Order matters: `hypr-vars` → modules → `hypr-user`. Values first, then
  everything that uses them, then your final word.

**Before switching:** check the whole tree for syntax errors in one go.
```bash
cd ~/.config/hypr
for f in hyprland.lua variables.lua scheme/default.lua hyprland/*.lua utils/*.lua ~/.config/myshell/*.lua; do
    luac -p "$f" || echo "FIX: $f"
done
```
No output = all good.

**Switch:**
```bash
cd ~/.config/hypr
git add -A
git mv hyprland.conf hyprland.conf.old     # keep it, but make sure Hyprland only sees the Lua file
git commit -m "hypr: switch to Lua config"
```
Now **log out and log back in**. A full restart is needed because the
`hyprland.start` autostart only runs at login.

**Check (right after logging in):**
```bash
hyprctl configerrors                     # should print nothing / "no errors"
hyprctl getoption general:gaps_out       # 10 → proves the Lua config is the one loaded
ls ~/.config/hypr/scheme/current.lua     # created by maybe_copy
```
There should be no "You are using the .conf config format" warning any more.

**If it goes wrong:** Hyprland shows the errors in a bar at the bottom, with
file and line number. Fix the file, then `hyprctl reload`. If the session is
unusable, go to a TTY (`Ctrl + Alt + F3`) and roll back:
```bash
cd ~/.config/hypr
mv hyprland.lua hyprland.lua.broken
mv hyprland.conf.old hyprland.conf
```
Then log in again, and you're back on the old config. Read the errors, fix,
and try again.

---

## 1.19 Test everything

Go through this list after the switch and tick each item. Anything that
fails → `hyprctl configerrors`, then check the matching step.

**Look & feel**
- [ ] Rounded corners (15 px), 1 px tinted border on the focused window
- [ ] Windows slightly see-through with blur behind them (kitty stays opaque)
- [ ] Windows slide/fade in and out; workspaces slide
- [ ] A single window on a workspace has larger outer gaps

**Autostart** (this login)
- [ ] waybar and your wallpaper are there (still the temporary tools)
- [ ] `pgrep -a cliphist` or `pgrep -af "wl-paste"` shows two watchers
- [ ] `pgrep -a polkit-gnome` is running

**Binds**
- [ ] Tap `Super` alone → rofi opens. Tap again → it closes
- [ ] `Super + Return` kitty · `Super + B` zen · `Super + E` nautilus · `Super + C` nvim
- [ ] `Super + 1…0` switch workspace · `Super + Alt + 1…0` move window
- [ ] `Super + scroll` next/previous workspace
- [ ] `Super + H/J/K/L` focus (and `Super + Arrows` do nothing) · `Super + Shift + Arrows` move window
- [ ] `Super + F` fullscreen · `Super + Alt + F` maximise · `Super + Alt + Space` float
- [ ] `Super + Z` + drag moves · `Super + X` + drag resizes (or `Super` + left/right mouse button)
- [ ] `Super + Comma` makes a group (tab bar appears) · `Alt + Tab` cycles through it
- [ ] `Super + S` opens/closes the special workspace
- [ ] `Ctrl + Shift + Escape` opens btop on its own special workspace (starts it the first time)
- [ ] `Super + V` clipboard history · `Super + Shift + S` region screenshot → paste it somewhere
- [ ] Volume, mute, brightness and media keys work
- [ ] `Super + Escape` locks (hyprlock)

**Gestures** (touchpad)
- [ ] 4-finger horizontal swipe changes workspace
- [ ] 3-finger up opens the special workspace, 3-finger down closes it

**Commit** any fixes, then tick Phase 1 in `docs/00-roadmap.md`. 🎉

---

## Common errors

| Symptom | Likely cause |
| --- | --- |
| `module 'variables' not found` | File is in the wrong folder or has a typo in its name. Check `ls ~/.config/hypr` |
| `module 'hypr-vars' not found` | `~/.config/myshell` doesn't exist, so `maybe_create` couldn't write the file. Run `mkdir -p ~/.config/myshell` |
| `attempt to concatenate a nil value (field 'xyz')` | A module uses `vars.xyz` or `scheme.xyz` that isn't defined. Check the spelling in `variables.lua` / `scheme/default.lua` |
| Colours don't change after editing `scheme/default.lua` | `current.lua` already exists and is only copied once. Delete `scheme/current.lua` and reload |
| Autostart change has no effect | `hyprland.start` only runs at login. Log out and in |
| A bind does nothing | Run `hyprctl binds` and look for it. Check for a clash with another bind |
| An app ignores a window rule | Check its real class with `hyprctl clients` |

Next: **Phase 2: Quickshell & QML fundamentals.** Its guide is written when
we start it.
