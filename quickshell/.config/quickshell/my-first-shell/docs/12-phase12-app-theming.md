# Phase 12: App theming

> **Status: ✅ completed 2026-10-04** (checked by you, including the live preview).
> Implemented by Claude. This doc explains what was built so you can understand,
> change and debug it.

## What you got

Changing the wallpaper (launcher → `>wall`) now recolours more than the shell and Hyprland's
borders:

| App | What changes | When |
| --- | --- | --- |
| **kitty** | background, text, cursor, selection, tabs, and the 16 terminal colours | **immediately**, in every open terminal |
| **btop** | box colours, highlights, every graph gradient | next time btop starts |
| **GTK apps** (Nautilus, file dialogs) | window, sidebar, header bar, cards, accent | next time the app starts |

You chose these three (you were asked first, because kitty used your own pick, Kanagawa
Dragon). Neovim and Zen keep their own themes.

```
 wallpaper ──▶ set-wallpaper.py ──▶ scheme.json (59 Material colours) ──▶ shell, Hyprland   (Phase 4)
                                         │
                                         ▼ themes.main()
                                    scripts/themes.py
              ┌──────────────────────────┼────────────────────────────┐
              ▼                          ▼                            ▼
 ~/.local/state/myshell/theme/  ~/.config/btop/themes/     ~/.config/gtk-4.0/gtk.css
   kitty.conf                     myshell.theme            ~/.config/gtk-3.0/gtk.css
   ▲ included by kitty.conf       ▲ color_theme in btop.conf  (GTK reads these by itself)
   + SIGUSR1 → kitty reloads
```

## Files

| File | What it is |
| --- | --- |
| `scripts/themes.py` | Reads `scheme.json`, writes the three apps' theme files |
| `scripts/set-wallpaper.py` | Now ends with `themes.main()` |
| `~/.config/kitty/kitty.conf` | One line changed: `include ~/.local/state/myshell/theme/kitty.conf` (Kanagawa kept, commented). Backup: `kitty.conf.before-myshell` |
| `~/.config/btop/btop.conf` | `color_theme = ".../myshell.theme"` (btop fills in the rest itself) |
| `~/.config/gtk-{3,4}.0/gtk.css` | Created (there were none before); owned by `themes.py` |

Caelestia does this in `caelestia-cli` (Python too) with template files per app:
`caelestia/` app folders, `manifest.toml`.

## The 16 terminal colours

Material You gives *roles* (surface, primary, onSurface…), but a terminal needs **red, green,
yellow, blue, magenta, cyan**, plus black and white, each in a normal and a bright version.
Programs rely on red meaning "error", green "OK", and so on, so these can't simply be
"primary".

`terminal_colours()`:

1. Starts from classic hues (`ANSI_BASE`).
2. **Harmonizes** each towards the wallpaper's main colour: `Blend.harmonize(red, source)`
   turns the hue by at most 15°, so red stays red but leans towards the palette.
3. Sets each one's **chroma** (colourfulness) and **tone** (lightness, 0–100) in the HCT
   colour space. Fixed tones mean every colour is equally readable on the dark background,
   whatever the wallpaper.
   - Normal colours: tone ~70. Bright: ~82.
   - **Yellow** gets tone 82/90 (dark yellow looks olive).
   - **Red** gets 62/74 (light red looks pink). Found by previewing a swatch image.
4. Black and white come from the scheme: color0 = `surfaceContainerHighest`, color7 =
   `onSurfaceVariant`, color8 = `outline`, color15 = `onSurface`.

The rest of the kitty file maps roles directly: `background` = surface, `cursor` = primary,
selection = primaryContainer, tabs, borders…

### Live reload

kitty re-reads its whole config when it receives `SIGUSR1`, so `themes.py` runs
`pkill -USR1 -x kitty`. Your `single_instance yes` means one kitty process owns all the
windows, and they all change at once. (`background_opacity 0.8` and everything else in
`kitty.conf` stay as they are: the generated file only sets colours.)

The theme lives in a `# BEGIN_KITTY_THEME` block, which `kitty +kitten themes` owns. If you
pick a theme with that kitten, it replaces our include. That's a clean way to opt out.

## btop

A btop theme is a list of `theme[name]="#rrggbb"` lines:
- boxes: `cpu_box` = primary, `mem_box` = secondary, `net_box` = tertiary
- highlights: `hi_fg`, `selected_bg`
- graph gradients (`*_start`/`*_mid`/`*_end`), using the terminal colours, so temperature
  goes green → yellow → red

`btop.conf` didn't exist. `themes.py` creates it with just `color_theme`, and btop adds its
other settings when it exits. If the file exists, only the `color_theme` line is replaced.

## GTK: `gtk.css`

GTK reads `~/.config/gtk-4.0/gtk.css` (and `gtk-3.0/gtk.css`) on top of its theme.
libadwaita, the GTK 4 style Nautilus uses, takes its colours from **named colours**, and a
user CSS file can redefine them:

```css
@define-color accent_bg_color #b5c7ed;
@define-color window_bg_color #0d0e12;
@define-color sidebar_bg_color #171a1f;
...
```

- **GTK 4 / libadwaita** apps follow these fully.
- **GTK 3 apps** with the default Adwaita theme only use a few `theme_*` names, so they
  change less. Installing the `adw-gtk-theme` package and selecting it (`gsettings set
  org.gnome.desktop.interface gtk-theme adw-gtk3-dark`) would make GTK 3 apps follow
  completely. Optional; not done.
- GTK doesn't watch this file: **restart the app** to see new colours.

## How to change it

| I want to… | Edit |
| --- | --- |
| Kanagawa back in kitty | `kitty.conf`: swap the two `include` lines (or restore `kitty.conf.before-myshell`) |
| Stop theming an app | remove its call in `main()` of `themes.py` (and delete its generated file) |
| More/less colourful terminal colours | the chroma numbers in `terminal_colours()` |
| Different kitty role choices (e.g. tabs) | the `kitty()` function |
| Theme another app | a new function that writes its file from `c` (colours) / `term`, called from `main()` |
| Regenerate without changing wallpaper | `python3 ~/.config/quickshell/my-first-shell/scripts/themes.py` |

## Try it (10 minutes)

1. Pick a very different wallpaper with `>wall` and watch your terminal change.
2. In `themes.py` set `background #{c['surface']}` to `#{c['primaryContainer']}`, run
   `themes.py`, and see the terminal change. Put it back.
3. Run `kitty +kitten themes`, preview a theme, then quit without applying (Esc). Read the
   `BEGIN_KITTY_THEME` block in `kitty.conf` again: untouched.
4. A quick colour check in the terminal: `printf '\e[31mred \e[32mgreen \e[33myellow \e[34mblue\e[0m\n'`
5. Open Nautilus, change wallpaper, and see that Nautilus doesn't change until you reopen it.

## Debugging

- **Terminal didn't change:** is the include line active in `kitty.conf`? Does
  `~/.local/state/myshell/theme/kitty.conf` exist? Try `pkill -USR1 -x kitty` by hand.
- **btop ignores the theme:** `grep color_theme ~/.config/btop/btop.conf` should show the
  full path. Press Esc in btop → Options → Color theme to see what it loaded.
- **GTK app unchanged:** restart it. GTK 3 apps change only partly (see above).
- **Wallpaper change fails with an import error:** `set-wallpaper.py` imports `themes`
  from its own folder. Keep the two files together.

## Completion notes

- **Your choices:** kitty, GTK and btop. Neovim and Zen left alone.
- **kitty:** only the include line changed. A copy of the original is in
  `kitty.conf.before-myshell`.
- **First palette:** yellow came out olive and red pinkish. Fixed with per-colour tones,
  checked on a swatch image.
- **Test windows:** the btop/Nautilus test windows were opened floating and closed by window
  address. A first attempt with `pkill -f` matched its own command line, again.
- **Tested:** the full `set-wallpaper.py` run on the current wallpaper, kitty recoloured live,
  btop and Nautilus screenshotted with the new colours.
- **Not done:** `adw-gtk-theme` for full GTK 3 theming (a package to install), and Qt apps
  (none in use).

## Live preview in the wallpaper picker (added after your check)

Your request: the colours should change while you *browse* wallpapers, not only when you pick
one, and go back if you don't pick anything.

- **`set-wallpaper.py`:**
  - `--preview <image>` writes that image's colours (shell, Hyprland, kitty, btop, GTK) but
    leaves `wallpaper.json`, the actual wallpaper, alone.
  - `--restore` writes the current wallpaper's colours again.
  - A preview takes ~0.2 s.
- **`Launcher.qml`:** `previewTarget` is the thumbnail under the mouse (`hoveredWallpaper`,
  from a `HoverHandler` in `WallpaperItem`), or the one you moved to with ← / → / Tab
  (`keyboardWallpaper`).
  - Just *opening* the picker previews nothing.
  - When the target becomes empty (mouse off the thumbnails, picker closed, `>wall` erased),
    the colours go back.
- **`Wallpapers.preview(path)`:** one 150 ms debounce for both directions.
  - Gliding across thumbnails only previews where you stop.
  - The tiny gap between two thumbnails doesn't trigger a restore in between.
- **One script at a time:** all runs go through a single `Process`. A request that arrives
  while one is running waits, and only the newest waiting one is kept, so a slow preview can
  never land after your final choice.
- **Choosing** (Enter or click) calls `set()`, which cancels any pending preview and clears
  `previewing`, so the picker closing afterwards doesn't restore the old colours.
- **GTK apps** still only pick up colours when they start, so a preview doesn't reach an
  already-open Nautilus.

**Bugs found while building it:**
- Selecting the *current* wallpaper on open was tried first and dropped: inside
  `onTextChanged`, `mode` still had its old value, and ListView resets `currentIndex` to 0 when
  a new model arrives. "Preview only what you point at" is simpler and avoids both.
- In testing, synthetic pointer warps didn't produce hover events while the launcher's focus
  grab was active. The preview/restore logic was therefore tested by feeding the hover value
  in directly (a scratch-only change): open → unchanged, hover → preview, glide → only the
  final one, off → restored, close → restored.

## Check it

- [x] Your terminal looks right (readable colours, `ls --color`, git diff colours)
- [x] Change the wallpaper: terminal follows right away
- [x] btop and Nautilus follow after reopening
- [x] Happy to keep this instead of Kanagawa (or swap back, see above)

## Questions

<details><summary>1. Why not use "primary" as the terminal's blue?</summary>

Terminal programs need six distinct hues with fixed meanings (red = error…). Material roles
are mostly one hue family, so a wallpaper-blue scheme would have no red at all. Harmonizing
keeps the six hues and just nudges them.
</details>

<details><summary>2. Why does kitty change instantly but Nautilus not?</summary>

kitty re-reads its config on SIGUSR1 and `themes.py` sends it. GTK reads `gtk.css` only when
an app starts.
</details>

<details><summary>3. What happens if you run <code>kitty +kitten themes</code> and apply a theme?</summary>

It rewrites the `BEGIN_KITTY_THEME … END_KITTY_THEME` block, replacing our include, so kitty
stops following the wallpaper until you put the include back.
</details>
