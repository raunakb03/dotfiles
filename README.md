# My Custom Quickshell

A Caelestia-style Wayland desktop built from scratch: a Hyprland Lua config, a
Quickshell (QML) shell, and (from Phase 9) a custom Qt C++ plugin.

## Guide
Start here: **[`docs/00-roadmap.md`](docs/00-roadmap.md)**

| Phase | Guide |
| --- | --- |
| 0: Safety & tooling | [`docs/01-phase0-safety-and-tooling.md`](docs/01-phase0-safety-and-tooling.md) |
| 1: Hyprland in Lua | [`docs/02-phase1-hyprland-lua.md`](docs/02-phase1-hyprland-lua.md) |
| 2: QML fundamentals | [`docs/03-phase2-qml-fundamentals.md`](docs/03-phase2-qml-fundamentals.md) |
| 3: Foundation layer | [`docs/04-phase3-foundation.md`](docs/04-phase3-foundation.md) |
| 4: Wallpaper & theming | [`docs/05-phase4-theming.md`](docs/05-phase4-theming.md) |
| 5: The bar | [`docs/06-phase5-bar.md`](docs/06-phase5-bar.md) |
| 6: Drawers & popouts | [`docs/07-phase6-drawers.md`](docs/07-phase6-drawers.md) |
| 7: Launcher | [`docs/08-phase7-launcher.md`](docs/08-phase7-launcher.md) |
| 8: Notifications, OSD, session | [`docs/09-phase8-notifications-osd-session.md`](docs/09-phase8-notifications-osd-session.md) |
| 9+ | written as each phase is built |

## Project Structure
- `shell.qml`: the main QML entry point for the UI (created in Phase 0, step 0.7).
- `docs/`: the step-by-step guide.
- `PROJECT_CONTEXT.md`: project rules and progress for AI assistants.
- `CLAUDE.md`: loaded automatically by Claude Code; pulls in `PROJECT_CONTEXT.md` and the roadmap.

Related, outside this repo:
- `~/.config/hypr/`: Hyprland Lua config (Phase 1).
- `~/.config/myshell/`: personal overrides.

## How to Run the Shell
```bash
quickshell -c my-first-shell
```

- Logs, from another terminal: `qs log -c my-first-shell -f`
- Stop it: `qs kill -c my-first-shell`
