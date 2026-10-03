# Custom Quickshell Project Context

## 🎯 Goal
Build a Caelestia-style Wayland desktop from scratch: the Hyprland config (Lua), a
**Quickshell** shell (QML), and a custom **Qt/C++ plugin** where QML isn't enough.
Every line is written and understood by me. Nothing is installed or run from Caelestia.

The [Caelestia Shell](https://github.com/caelestia-dots/shell) and
[Caelestia dots](https://github.com/caelestia-dots/caelestia) are cloned at
`~/raunak/configurations/shell` and `~/raunak/configurations/caelestia` **as reference only**.

## 🤖 Instructions for AI Assistants
When assisting with this project, strictly follow these rules:
1. **No pre-built engines:** Do not suggest installing `caelestia-shell`/`caelestia-cli` or
   relying on Caelestia's compiled `qs.services` / `Caelestia.*` modules.
2. **QML first, C++ where needed:** Use Quickshell's built-in modules (Hyprland, Pipewire,
   Mpris, Notifications, UPower, SystemTray, Pam, Io…) in QML. Write our own C++ in
   `engine/` only where QML can't do the job well (e.g. CPU/sensor stats, audio visualiser,
   calculator). All CMake, C++ and QML is written from scratch in this repository.
3. **Reference, don't copy:** Read the Caelestia clones to see how they solved a problem,
   then write our own version and explain it.
4. **Step-by-step:** Introduce concepts one small piece at a time. Explain the *why*
   alongside the *how*. Follow the step format in `docs/00-roadmap.md`.
5. **The guide lives in `docs/`:** `docs/00-roadmap.md` is the master plan. Each phase gets
   its own `docs/NN-*.md`, written when that phase starts. Tick off progress in the roadmap.
6. **Execution Command:** `quickshell -c my-first-shell` (logs: `qs log -c my-first-shell -f`).
   Once a C++ plugin exists (Phase 9), the command gains a `QML2_IMPORT_PATH=...` prefix.
   Keep it documented in `README.md`.
7. **Documentation:** Always update `README.md` whenever the build process, directory
   structure, or run commands change.

## 📁 Related locations
- `~/.config/hypr/`: Hyprland Lua config (own git repo), built in Phase 1
- `~/.config/myshell/`: personal overrides (`hypr-vars.lua`, `hypr-user.lua`, later `shell.json`)

## 📊 Current Progress
- [x] Project reset to a clean start on 2026-09-30: only `docs/`, `README.md`,
      `PROJECT_CONTEXT.md`. An earlier C++ experiment (`MyEngine`/`SystemInfo`) is archived
      at `~/my-first-shell-old/` (not part of this repo).
- [x] Roadmap plus guides for Phase 0 and Phase 1 written
- [x] Phase 0: Safety & tooling (done 2026-10-02; backup at `~/raunak/dotfiles/hypr-backup-2026-10-02`)
- [x] Phase 1: Hyprland in Lua (done 2026-10-02; fixes recorded in the guide's Completion notes)
- [x] Phase 2: Quickshell & QML fundamentals (done 2026-10-03; `shell.qml` + `modules/bar/Bar.qml` + `services/Time.qml`)
- [x] Phase 3: Foundation layer (done 2026-10-03; Colours/Appearance/Config singletons, components/, shell.json at ~/.config/myshell/)
- [x] Phase 4: Wallpaper & Material You theming (done 2026-10-03; set-wallpaper.py, live Colours, Background; hyprpaper retired; shell autostarted by Hyprland: login check pending)
- [ ] Phase 5: The bar (next up; guide not written yet)

## 🗺️ Roadmap
See [`docs/00-roadmap.md`](docs/00-roadmap.md).
