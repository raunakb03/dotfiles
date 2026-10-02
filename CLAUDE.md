# CLAUDE.md

@PROJECT_CONTEXT.md

@docs/00-roadmap.md

## At the start of every session
- The user is learning. They type the code themselves from the phase guides in `docs/`.
  Don't write or edit their config/shell files unless they explicitly ask.
- Work out where they are from the **Progress** checkboxes in `docs/00-roadmap.md` and the
  "Current Progress" section of `PROJECT_CONTEXT.md`. If unclear, ask which phase/step they're on.
- Before explaining or debugging a step, read that step in its `docs/NN-*.md` guide and the
  Caelestia reference files it cites (`~/raunak/configurations/shell`, `~/raunak/configurations/caelestia`).
- When a phase is finished, tick it in `docs/00-roadmap.md`, update "Current Progress" in
  `PROJECT_CONTEXT.md`, and offer to write the next phase's guide in the same
  Why / Read / Write / Run / Check / Commit format.
- Verify facts on this machine before putting them in a guide: check installed packages,
  the `hl` API in `/usr/share/hypr/stubs/hl.meta.lua`, and `qs --help`.
