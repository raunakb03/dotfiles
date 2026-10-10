# dotfiles

Everything is managed with [GNU Stow](https://www.gnu.org/software/stow/): each top-level folder
is a **package** whose contents mirror `$HOME`. `stow <package>` creates symlinks from `$HOME`
into this repo, so the live config *is* the repo. Edit in place, then commit and push here.

| Package | Links | What |
| --- | --- | --- |
| `hypr` | `~/.config/hypr` | Hyprland (Lua config) |
| `quickshell` | `~/.config/quickshell` | my-first-shell: bar, launcher, notifications, lock… (docs inside) |
| `myshell` | `~/.config/myshell` | the shell's `shell.json` + per-machine Hyprland overrides |
| `kitty` | `~/.config/kitty` | terminal (colours come from the wallpaper) |
| `nvim` | `~/.config/nvim` | LazyVim |
| `tmux` | `~/.config/tmux` | tmux (plugins via tpm) |
| `ghostty` | `~/.config/ghostty` | ghostty |
| `zshrc` | `~/.zshrc` | zsh |
| `cscripts` | `~/scripts` | small scripts |
| `autostart` | `~/.config/autostart` | keeps nm-applet from autostarting |

## New machine: one command

On a fresh Arch + Hyprland install, logged in as your user (not root):

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/raunakb03/dotfiles/main/install.sh)
```

`install.sh` does everything below, in order, and is safe to run again:

1. installs `git`, `stow`, `base-devel`, and `yay` (AUR helper) if missing
2. clones this repo to `~/dotfiles` (HTTPS; pushing uses SSH)
3. installs every package in `packages/pacman.txt` and `packages/aur.txt`, plus the
   hardware-specific ones it detects (AMD/Intel microcode, NVIDIA driver)
4. moves any config in the way to `~/.local/share/dotfiles-backup-<date>/`, then stows every package
5. oh-my-zsh + zsh-autosuggestions + zsh-syntax-highlighting, zsh as login shell
6. tmux plugins (tpm)
7. builds the shell's C++ plugin, sets a wallpaper (the default in `wallpapers/`, or your
   collection with `--wallpapers <folder>`), which generates all the colours
8. enables NetworkManager, bluetooth, sddm, fstrim, libvirtd

Options: `--dry-run` (show, change nothing), `--wallpapers <dir>`, `--skip-packages`,
`--skip-services`, `--yes`. Then reboot and pick Hyprland (uwsm) in SDDM.

**The package lists** (`packages/`):

| File | What | Who edits it |
| --- | --- | --- |
| `required.txt` | what the shell and Hyprland config need (Quickshell, fonts, upower, cliphist…) | you, by hand |
| `pacman.txt` / `aur.txt` | everything else you installed | `update.sh` |
| `exclude.txt` | never reinstall these (rofi, waybar…), and hardware-only packages | you, by hand |

After installing or removing something you want on future installs, run `packages/update.sh`
and commit.

**Wallpapers** (~700 MB) aren't in the repo: copy them from a backup with `--wallpapers`.

## New machine: by hand

```sh
sudo pacman -S stow git
git clone git@github.com:raunakb03/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow -t ~ hypr quickshell myshell kitty nvim tmux ghostty zshrc cscripts autostart
```

`stow` refuses to overwrite existing files: move a conflicting `~/.config/<x>` away first.

Then:
- **The shell's C++ plugin** (build output isn't stored):
  `cmake -S ~/.config/quickshell/my-first-shell/engine -B ~/.config/quickshell/my-first-shell/engine/build && cmake --build ~/.config/quickshell/my-first-shell/engine/build`
- **Wallpaper and colours** (generates `hypr/scheme/current.lua` and the app themes):
  `~/.config/quickshell/my-first-shell/scripts/set-wallpaper.py <image>`
- **tmux plugins:** `git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm`,
  then `prefix + I` inside tmux.
- `myshell/.config/myshell/hypr-user.lua` and `hypr-vars.lua` hold this laptop's monitor and
  keyboard settings: adjust for another machine.

## Daily use

```sh
cd ~/dotfiles
git status            # every config change shows up here
git add -A && git commit -m "…" && git push
```

- **New file inside a stowed folder** (e.g. a new nvim plugin file): nothing to do, the whole
  folder is linked.
- **New package:** `mkdir -p foo/.config/foo`, move the config in, `stow -t ~ foo`.
- **Unlink a package:** `stow -t ~ -D foo`.

Not stored on purpose (generated from the wallpaper by `my-first-shell/scripts/themes.py`):
`~/.config/btop`, `~/.config/gtk-{3,4}.0/gtk.css`.
