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

## New machine

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
