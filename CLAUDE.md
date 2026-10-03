# CLAUDE.md

@PROJECT_CONTEXT.md

@docs/00-roadmap.md

## Working mode (from Phase 5 on, agreed 2026-10-03)
Claude **implements** each phase and **documents** it so the user can learn from the
docs later. The goal is still understanding, not just a working desktop.

For each phase:
1. **Research first:** read the Caelestia files the roadmap cites
   (`~/raunak/configurations/shell`, `~/raunak/configurations/caelestia`) and verify APIs on
   this machine: `/usr/lib/qt6/qml/Quickshell/**/*.qmltypes`, `/usr/share/hypr/stubs/hl.meta.lua`,
   `qs --help`, installed packages. Reference, don't copy.
2. **Implement in small, logical commits** (one per piece, clear messages), so `git log`
   reads as a step-by-step history. Test each piece: load it in Quickshell (no errors or
   warnings in the log), take screenshots, and run Lua configs through `luac -p` and
   `hyprctl configerrors`.
   - Ask before installing packages; the user runs `sudo pacman` / `yay` themselves.
   - Ask before risky, hard-to-undo changes to `~/.config/hypr`.
3. **Write `docs/NN-phaseX-*.md` as an explanation of what was built**, not as typing
   instructions:
   - goal and final result (with an ASCII sketch or diagram of how the parts connect)
   - each file: what it does, its key lines explained, and the Caelestia file it mirrors
   - "How to change it": the common edits ("to add a widget, edit …")
   - **Try it**: 5–10 minutes of small experiments on the real code (change, break, observe)
   - debugging tips and Common errors; Completion notes (what went wrong while building
     and how it was fixed)
   - a few questions with hidden answers (`<details>`)
4. **Show the result** (what changed, screenshots) and let the user check it on their desktop
   before marking the phase complete.
5. **When complete:** "Status: ✅ completed <date>" banner, Completion notes, tick the phase
   in `docs/00-roadmap.md`, update "Current Progress" in `PROJECT_CONTEXT.md`, link the doc
   from `README.md`, and commit.

Phases 0–4 docs are step-by-step guides the user typed through. Keep them as they are.

## Every session
- Work out where things stand from the **Progress** checkboxes in `docs/00-roadmap.md` and
  "Current Progress" in `PROJECT_CONTEXT.md`. If unclear, ask.
- When the user changes something themselves, or a fix is needed, record it in that phase's
  Completion notes so the docs always match the real setup.
- The shell is autostarted by Hyprland (`qs -c my-first-shell -n`). Logs:
  `qs log -c my-first-shell -f`; restart: `Ctrl + Super + Alt + R`. Fonts or environment
  changes need a restart, not just hot reload. Editing `modules/Shortcuts.qml` also needs a
  restart (hot reload leaves the global shortcut deaf). Restart with a pause:
  `qs kill -c my-first-shell; sleep 0.5; qs -c my-first-shell -n` (without the pause the new
  instance sees the old one, exits because of `-n`, and nothing is left running).
