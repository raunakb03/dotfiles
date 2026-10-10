#!/usr/bin/env bash
# Set up this whole desktop on a fresh Arch + Hyprland install.
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/raunakb03/dotfiles/main/install.sh)
#   or, with the repo already cloned:   ~/dotfiles/install.sh
#
# Options:
#   --dry-run            print what would happen, change nothing
#   --wallpapers <dir>   copy your wallpaper collection from <dir> (e.g. a USB drive)
#   --skip-packages      don't install packages (only dotfiles and setup)
#   --skip-services      don't enable system services
#   -y, --yes            don't ask before starting
#
# Safe to run again: installed packages are skipped, existing links are kept, and any existing
# config that's in the way is moved to ~/.local/share/dotfiles-backup-<date>/, never deleted.

set -euo pipefail

REPO_HTTPS="https://github.com/raunakb03/dotfiles.git"
REPO_SSH="git@github.com:raunakb03/dotfiles.git"
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
# Stow packages (top-level folders of the repo that mirror $HOME)
PACKAGES=(hypr quickshell myshell kitty nvim tmux ghostty zshrc cscripts autostart)
SYSTEM_SERVICES=(NetworkManager.service bluetooth.service sddm.service fstrim.timer libvirtd.service)

DRY_RUN=0 SKIP_PACKAGES=0 SKIP_SERVICES=0 ASSUME_YES=0 WALLPAPER_SOURCE=""
BACKUP="$HOME/.local/share/dotfiles-backup-$(date +%Y-%m-%d_%H%M%S)"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --skip-packages) SKIP_PACKAGES=1 ;;
        --skip-services) SKIP_SERVICES=1 ;;
        --wallpapers) WALLPAPER_SOURCE="${2:?--wallpapers needs a folder}"; shift ;;
        -y | --yes) ASSUME_YES=1 ;;
        -h | --help) sed -n '2,17p' "$0"; exit 0 ;;
        *) echo "unknown option: $1 (see --help)"; exit 1 ;;
    esac
    shift
done

# ── helpers ────────────────────────────────────────────────────────────────────────────────

bold=$'\e[1m' green=$'\e[32m' yellow=$'\e[33m' red=$'\e[31m' reset=$'\e[0m'
step() { echo; echo "${bold}${green}==>${reset}${bold} $*${reset}"; }
info() { echo "    $*"; }
warn() { echo "${yellow}  ! $*${reset}"; }
die() { echo "${red}error: $*${reset}" >&2; exit 1; }

# Run a command, or only print it with --dry-run
run() {
    if ((DRY_RUN)); then
        echo "    [dry-run] $*"
    else
        "$@"
    fi
}

# Move something out of the way into the backup folder (keeping its path below $HOME)
backup() {
    local path="$1" rel="${1#"$HOME"/}"
    info "backing up ~/$rel → ${BACKUP/#$HOME/\~}/$rel"
    run mkdir -p "$(dirname "$BACKUP/$rel")"
    run mv "$path" "$BACKUP/$rel"
}

# Lines of a list file, without comments and blank lines
list() { grep -vE '^\s*(#|$)' "$1" || true; }

# ── checks ─────────────────────────────────────────────────────────────────────────────────

[[ $EUID -ne 0 ]] || die "run this as your normal user (it uses sudo where needed), not as root"
command -v pacman >/dev/null || die "this script is for Arch Linux (pacman not found)"

echo "${bold}Dotfiles setup${reset} for $USER"
info "repo:     $DOTFILES"
info "packages: $( ((SKIP_PACKAGES)) && echo skipped || echo "official + AUR from packages/*.txt")"
((DRY_RUN)) && info "${yellow}dry run: nothing will be changed${reset}"
if ((!ASSUME_YES && !DRY_RUN)); then
    read -rp "Continue? [Y/n] " answer
    [[ "${answer:-y}" =~ ^[Yy]$ ]] || exit 0
fi

# Ask for the sudo password once, and keep it alive while the script runs
if ((!DRY_RUN)) && ((!SKIP_PACKAGES || !SKIP_SERVICES)); then
    sudo -v
    while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
fi

# ── 1. base tools ──────────────────────────────────────────────────────────────────────────

if ((!SKIP_PACKAGES)); then
    step "Base tools (git, stow, base-devel)"
    run sudo pacman -Syu --needed --noconfirm git stow base-devel
fi

# ── 2. the dotfiles repo ───────────────────────────────────────────────────────────────────

step "Dotfiles repo"
if [[ -d "$DOTFILES/.git" ]]; then
    info "already cloned; pulling the latest"
    run git -C "$DOTFILES" pull --ff-only || warn "couldn't pull (local changes?); using what's there"
else
    # HTTPS works without an SSH key; pushing uses SSH once you've added your key to GitHub
    run git clone "$REPO_HTTPS" "$DOTFILES"
    run git -C "$DOTFILES" remote set-url --push origin "$REPO_SSH"
fi

# ── 3. packages ────────────────────────────────────────────────────────────────────────────

if ((!SKIP_PACKAGES)); then
    step "AUR helper (yay)"
    if command -v yay >/dev/null; then
        info "yay is installed"
    else
        tmp=$(mktemp -d)
        run git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
        if ((DRY_RUN)); then info "[dry-run] (cd $tmp/yay-bin && makepkg -si --noconfirm)"; else (cd "$tmp/yay-bin" && makepkg -si --noconfirm); fi
        rm -rf "$tmp"
    fi

    step "Hardware-specific packages"
    hardware=()
    grep -q AuthenticAMD /proc/cpuinfo && hardware+=(amd-ucode)
    grep -q GenuineIntel /proc/cpuinfo && hardware+=(intel-ucode)
    lspci 2>/dev/null | grep -qi 'nvidia' && hardware+=(nvidia-open-dkms libva-nvidia-driver)
    info "detected: ${hardware[*]:-nothing extra}"

    step "Official packages (packages/pacman.txt)"
    # Only names that exist in the repos: one unknown name would make pacman refuse everything
    mapfile -t wanted < <(list "$DOTFILES/packages/pacman.txt"; printf '%s\n' "${hardware[@]}")
    mapfile -t available < <(comm -12 <(printf '%s\n' "${wanted[@]}" | sort -u) <(pacman -Slq | sort -u))
    missing=$(comm -23 <(printf '%s\n' "${wanted[@]}" | sort -u) <(printf '%s\n' "${available[@]}" | sort -u) | tr '\n' ' ')
    [[ -n "${missing// /}" ]] && warn "not in the official repos any more, skipped: $missing"
    info "${#available[@]} packages (already installed ones are skipped)"
    run sudo pacman -S --needed --noconfirm "${available[@]}"

    step "AUR packages (packages/aur.txt)"
    mapfile -t aur < <(list "$DOTFILES/packages/aur.txt")
    info "${aur[*]}"
    run yay -S --needed --noconfirm --answerclean None --answerdiff None "${aur[@]}" ||
        warn "some AUR packages failed; run: yay -S --needed ${aur[*]}"
fi

command -v stow >/dev/null || ((DRY_RUN)) || die "stow isn't installed (run without --skip-packages, or: sudo pacman -S stow)"

# ── 4. link the dotfiles ───────────────────────────────────────────────────────────────────

step "Linking dotfiles with stow"
for pkg in "${PACKAGES[@]}"; do
    [[ -d "$DOTFILES/$pkg" ]] || { warn "$pkg: not in the repo, skipped"; continue; }
    # Everything this package would create in $HOME, e.g. .config/hypr or .zshrc. If that exists
    # and isn't already our link, move it to the backup so stow can link the whole folder.
    while IFS= read -r -d '' entry; do
        rel="${entry#"$DOTFILES/$pkg/"}"
        target="$HOME/$rel"
        if [[ -L "$target" ]]; then
            [[ "$(readlink -f "$target")" == "$(readlink -f "$entry")" ]] && continue
            backup "$target"
        elif [[ -e "$target" ]]; then
            backup "$target"
        fi
    # (top-level items like .zshrc or scripts, plus each .config/<app>)
    done < <(find "$DOTFILES/$pkg" -mindepth 1 -maxdepth 1 ! -name .config -print0
             find "$DOTFILES/$pkg/.config" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)
    run stow --dir="$DOTFILES" --target="$HOME" --restow "$pkg"
    info "$pkg ✓"
done

# ── 5. zsh: oh-my-zsh and its plugins ──────────────────────────────────────────────────────

step "zsh (oh-my-zsh + plugins)"
# Set explicitly: if this runs from a zsh that already uses oh-my-zsh, the inherited $ZSH would
# point somewhere else and the installer refuses to run
export ZSH="$HOME/.oh-my-zsh" ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
if [[ -d "$ZSH" ]]; then
    info "oh-my-zsh is installed"
else
    # KEEP_ZSHRC: don't overwrite our .zshrc link; RUNZSH/CHSH: don't start zsh or change shell
    run env KEEP_ZSHRC=yes RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
plugins="$ZSH_CUSTOM/plugins"
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    [[ -d "$plugins/$plugin" ]] || run git clone --depth 1 "https://github.com/zsh-users/$plugin" "$plugins/$plugin"
done
if [[ "$(getent passwd "$USER" | cut -d: -f7)" != */zsh ]]; then
    run sudo chsh -s /usr/bin/zsh "$USER"
fi

# ── 6. tmux plugins ────────────────────────────────────────────────────────────────────────

step "tmux plugins (tpm)"
# tpm installs into TMUX_PLUGIN_MANAGER_PATH; set it so a value inherited from a running tmux
# session can't point it somewhere else
export TMUX_PLUGIN_MANAGER_PATH="$HOME/.config/tmux/plugins/"
tpm="$HOME/.config/tmux/plugins/tpm"
[[ -d "$tpm" ]] || run git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm"
run "$tpm/bin/install_plugins" || warn "tmux plugins: open tmux and press prefix + I"

# ── 7. the shell (my-first-shell) ──────────────────────────────────────────────────────────

shell_dir="$HOME/.config/quickshell/my-first-shell"

step "Building the shell's C++ plugin"
run cmake -S "$shell_dir/engine" -B "$shell_dir/engine/build" -DCMAKE_BUILD_TYPE=Release
run cmake --build "$shell_dir/engine/build" -j"$(nproc)"

step "Wallpaper and colours"
# The wallpaper folder from shell.json ("~/raunak/Wallpapers")
wall_dir=$(python3 -c "import json,os;print(os.path.expanduser(json.load(open(os.path.expanduser('~/.config/myshell/shell.json')))['paths']['wallpaperDir']))" 2>/dev/null || echo "$HOME/Pictures/Wallpapers")
run mkdir -p "$wall_dir" "$HOME/Pictures/Screenshots"
if [[ -n "$WALLPAPER_SOURCE" ]]; then
    info "copying wallpapers from $WALLPAPER_SOURCE"
    run rsync -a "$WALLPAPER_SOURCE"/ "$wall_dir"/
fi
if [[ -z "$(ls -A "$wall_dir" 2>/dev/null)" ]]; then
    info "no wallpapers yet: using the default one from the repo"
    run cp "$DOTFILES"/wallpapers/* "$wall_dir"/
fi
if [[ -f "${XDG_STATE_HOME:-$HOME/.local/state}/myshell/wallpaper.json" ]]; then
    info "a wallpaper is already set"
else
    first=$(find "$wall_dir" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | sort | head -1)
    if [[ -n "$first" ]]; then
        # Writes the colour scheme for the shell, Hyprland, kitty, btop and GTK
        run "$shell_dir/scripts/set-wallpaper.py" "$first"
    else
        warn "no wallpaper found in $wall_dir"
    fi
fi

# ── 8. system settings and services ────────────────────────────────────────────────────────

step "Desktop settings"
run xdg-user-dirs-update || true
# Dark mode for GTK apps (needs a session bus; harmless if there isn't one yet)
run gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || info "gsettings: will apply at first login"

if ((!SKIP_SERVICES)); then
    step "System services"
    for service in "${SYSTEM_SERVICES[@]}"; do
        if systemctl list-unit-files "$service" &>/dev/null && systemctl list-unit-files "$service" | grep -q "$service"; then
            run sudo systemctl enable "$service"
        else
            info "$service: not installed, skipped"
        fi
    done
    getent group libvirt >/dev/null && ! id -nG "$USER" | grep -qw libvirt && run sudo usermod -aG libvirt "$USER"
fi

# ── done ───────────────────────────────────────────────────────────────────────────────────

step "Done"
if [[ -d "$BACKUP" ]]; then info "your previous configs are in ${BACKUP/#$HOME/\~}"; fi
info "Reboot, and log in to Hyprland (uwsm) from SDDM. The shell starts by itself."
info "To push changes to GitHub, add an SSH key to your GitHub account first."
