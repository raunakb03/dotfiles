# Roadmap: Building a Caelestia-style desktop from scratch

This is the master guide. It lists every phase at a glance. Each phase gets its
own detailed guide (`docs/NN-*.md`), written when we start that phase so it
matches what we actually build.

## The rules
- **Nothing is copied or executed from Caelestia.** The two clones below are
  reference material. Read them to see *how* a problem was solved, then write
  your own version, line by line.
  - `~/raunak/configurations/shell`: the Caelestia Quickshell UI (QML) plus a
    C++ plugin.
  - `~/raunak/configurations/caelestia`: the Caelestia dotfiles, including the
    Lua Hyprland config.
- **QML first, C++ later.** Quickshell's built-in modules (Hyprland, Pipewire,
  Mpris, Notifications, UPower, SystemTray, Pam…) do most of the work in plain
  QML. We write C++ in `engine/` only where QML can't do the job well: CPU and
  temperature stats, the audio visualiser, the calculator.
- **Every step is committed.** If something breaks, `git diff` / `git revert`.

## How each phase guide is laid out
Every step in a phase guide has the same parts:

| Part | Meaning |
| --- | --- |
| **Why** | The concept you're about to learn |
| **Read** | The exact Caelestia file(s) to study first |
| **Write** | The code, with each line explained |
| **Run** | The command that shows it working |
| **Check** | What you should see, plus common errors |
| **Commit** | The git command to save the step |

## Where things live

```
~/.config/hypr/                     Hyprland config (Lua), your own git repo
  hyprland.lua                      entry point
  variables.lua                     all tunable defaults
  hyprland/*.lua                    one module per topic
  utils/functions.lua               helpers used by binds/gestures
  scheme/current.lua                colours (generated from the wallpaper in Phase 4)
~/.config/myshell/                  personal overrides (never touched by the repo)
  hypr-vars.lua                     overrides for variables.lua
  hypr-user.lua                     monitors, extra binds, extra rules
  shell.json                        shell settings (Phase 3+)
~/.config/quickshell/my-first-shell/  the shell, your own git repo
  shell.qml                         entry point
  services/ components/ modules/ utils/ config/   (Phase 3+)
  engine/                           your C++ QML plugin (Phase 9+)
  docs/                             this guide
```

---

## Phase 0: Safety & tooling → [`01-phase0-safety-and-tooling.md`](01-phase0-safety-and-tooling.md)
- **Goal:** everything is backed up and under git, the editor understands QML
  and Hyprland Lua, and you know how to see logs.
- **Concepts:** git basics, language servers, Quickshell hot reload and logs.
- **Done when:** both repos have a first commit, `hyprland.conf` is backed up,
  and your editor autocompletes `hl.` and QML types.

## Phase 1: Hyprland in Lua → [`02-phase1-hyprland-lua.md`](02-phase1-hyprland-lua.md)
- **Goal:** the same Hyprland behaviour as Caelestia (gaps, blur, animations,
  window rules, special workspaces, keybinds), written by you in Lua.
- **Read:** `caelestia/hypr/hyprland.lua`, `variables.lua`, `hyprland/*.lua`,
  `utils/functions.lua`.
- **Concepts:** Lua tables, modules and `require`, closures, the `hl.*` API.
- **Done when:** `hyprctl configerrors` is empty, every bind works, and your
  old `hyprland.conf` is no longer loaded. waybar, rofi and hyprpaper still
  run *for now*.

## Phase 2: Quickshell & QML fundamentals → [`03-phase2-qml-fundamentals.md`](03-phase2-qml-fundamentals.md)
- **Goal:** understand what `shell.qml` actually is.
- **Read:** `shell/shell.qml`, `shell/modules/drawers/Drawers.qml`.
- **Concepts:** QML objects, properties and bindings, ids, signals and
  handlers, `Component` vs instance, `ShellRoot`, `PanelWindow`, `Variants`
  over `Quickshell.screens`, `pragma Singleton`, `qs.` imports.
- **Done when:** you've built small exercises (a clock bar on every monitor, a
  singleton shared by two windows) and can explain every line.

## Phase 3: Foundation layer → [`04-phase3-foundation.md`](04-phase3-foundation.md)
- **Goal:** the building blocks every later module relies on.
- **Read:** `shell/components/*.qml`, `shell/utils/Paths.qml`,
  `shell/plugin/src/Caelestia/Config/tokens.hpp` (as a list of values only).
- **Build:**
  - folders `services/ components/ modules/ utils/ config/`
  - a `Config` singleton using `FileView` + `JsonAdapter` on
    `~/.config/myshell/shell.json`
  - `Appearance` tokens: rounding, spacing, padding, font sizes, animation
    durations and curves
  - `StyledRect`, `StyledText`, `MaterialIcon`, `Anim`, `CAnim`, `StateLayer`
- **Install:** `ttf-material-symbols-variable` (official repos), plus the
  Google Sans Flex font file bundled into `assets/fonts/`.
- **Done when:** a test window built only from your components changes live
  when you edit `shell.json`.

## Phase 4: Wallpaper & Material You theming → [`05-phase4-theming.md`](05-phase4-theming.md)
- **Goal:** pick a wallpaper and the whole desktop recolours itself.
- **Read:** `shell/services/Colours.qml`, `shell/utils/Paths.qml`,
  `shell/modules/background/`, `caelestia/hypr/scheme/default.lua`.
- **Build:**
  - `scripts/set-wallpaper.py`: your own script using the `materialyoucolor`
    Python library. It writes `~/.local/state/myshell/{wallpaper,scheme}.json`
    and `~/.config/hypr/scheme/current.lua`
  - `Colours` reads `scheme.json` live. `Wallpaper` + `modules/background/`
    draw the wallpaper (replaces hyprpaper)
  - Hyprland autostarts the shell (`qs -c my-first-shell -n -d`), plus a
    restart bind
- **Done when:** `set-wallpaper.py <image>` changes the wallpaper, fades the
  bar to new colours, and Hyprland borders follow automatically.

## Phase 5: The bar
- **Goal:** Caelestia's vertical bar.
- **Read:** `shell/modules/bar/Bar.qml`, `BarWrapper.qml`, `components/**`.
- **Build:** OS icon, workspaces (`Quickshell.Hyprland`), active window, tray
  (`Services.SystemTray`), clock, status icons (`Services.Pipewire`,
  `Services.UPower`, `nmcli` via `Process`, `Quickshell.Bluetooth`), and a
  power button.
- **Done when:** the bar replaces waybar (remove waybar from `execs.lua`).

## Phase 6: Drawers architecture (the Caelestia look)
- **Goal:** the rounded screen border with panels that grow out of the edges.
- **Read:** `shell/modules/drawers/*` (`ContentWindow`, `Panels`,
  `Interactions`, `Regions`, `Exclusions`), `shell/modules/bar/popouts/`.
- **Concepts:** one transparent full-screen layer window per screen, input
  masks (click-through), exclusive zones, hover detection at screen edges,
  shape masking, state machines for open/closed panels.
- **Build:** the border frame, then the bar popouts (audio, network,
  bluetooth, battery, tray menu).
- **Done when:** hovering a bar icon opens its popout from the bar edge, and
  clicks outside the panels reach the windows below.

## Phase 7: Launcher
- **Read:** `shell/modules/launcher/**`, `shell/utils/Searcher.qml`,
  `shell/utils/scripts/fuzzysort.js`.
- **Build:** app list from `DesktopEntries` with fuzzy search, `>` actions,
  the wallpaper picker (calls the Phase 4 script), and a `GlobalShortcut`
  bound to Super press-and-release.
- **Done when:** rofi is gone from `variables.lua`.

## Phase 8: Notifications, sidebar, OSD, session menu
- **Read:** `shell/services/Notifs.qml`, `shell/modules/notifications/`,
  `shell/modules/sidebar/`, `shell/modules/osd/`, `shell/modules/session/`,
  `shell/services/Brightness.qml`.
- **Build:** a `NotificationServer` with popups plus sidebar history, a
  volume/brightness OSD, and the power menu.
- **Done when:** `notify-send` shows your popup, and the volume keys show your
  OSD.

## Phase 9: Dashboard + first real C++ service
- **Read:** `shell/modules/dashboard/**`, `shell/services/Players.qml`,
  `shell/services/Weather.qml`, `shell/plugin/src/Caelestia/Services/`.
- **Build:** media controls (`Services.Mpris`), weather, calendar, and the
  performance tab. CPU, memory and temperatures come from **your own C++
  class** in a new `engine/` plugin (reads `/proc/stat`, `/proc/meminfo`,
  lm_sensors). Along the way you'll learn CMake, `qt6_add_qml_module`,
  `Q_OBJECT`/`QML_ELEMENT`/`Q_PROPERTY`, and loading a local plugin with
  `QML2_IMPORT_PATH`. Reference: `shell/plugin/CMakeLists.txt`,
  `shell/plugin/cmake/qml-module.cmake`.
- **Done when:** the dashboard opens from the top edge and CPU usage updates
  live.

## Phase 10: Lock screen & idle
- **Read:** `shell/modules/lock/**`, `shell/modules/IdleMonitors.qml`,
  `shell/services/IdleInhibitor.qml`.
- **Build:** `WlSessionLock` + `Services.Pam`, `IdleMonitor`s (dim → lock →
  screen off → suspend), and an idle inhibitor.
- **Done when:** hyprlock is gone, and the lock screen survives a shell crash
  (`misc.allow_session_lock_restore`).

## Phase 11: Utilities & polish
- **Read:** `shell/modules/areapicker/`, `shell/services/Recorder.qml`,
  `shell/services/GameMode.qml`, `shell/modules/utilities/`,
  `shell/plugin/src/Caelestia/Components/visualiserbars.cpp`,
  `shell/plugin/src/Caelestia/qalculator.cpp`.
- **Build:** screenshot area picker (grim + swappy), screen recorder, game
  mode, toasts, the cava visualiser and qalculate in C++. Optional: a
  Nexus-style settings app.

## Phase 12 (optional): App theming
- **Read:** `caelestia/foot`, `fish`, `starship.toml`, `btop`, and the
  gtk/qt sections of `caelestia/manifest.toml`.
- **Build:** templates filled by `scheme.py` so terminal, prompt, btop and
  GTK/Qt apps follow the wallpaper colours.

---

## Progress
- [x] Phase 0: Safety & tooling (2026-10-02)
- [x] Phase 1: Hyprland in Lua (2026-10-02)
- [x] Phase 2: QML fundamentals (2026-10-03)
- [x] Phase 3: Foundation layer (2026-10-03)
- [ ] Phase 4: Theming
- [ ] Phase 5: Bar
- [ ] Phase 6: Drawers
- [ ] Phase 7: Launcher
- [ ] Phase 8: Notifications / OSD / session
- [ ] Phase 9: Dashboard + C++
- [ ] Phase 10: Lock & idle
- [ ] Phase 11: Utilities
- [ ] Phase 12: App theming (optional)

> **Quickshell version note:** Caelestia's README asks for `quickshell-git`.
> You have the stable 0.3.1 package. Stay on stable until a phase needs a
> git-only feature. Its guide will say so explicitly and explain the switch.
