#!/usr/bin/env bash
# Regenerate the package lists from what's installed on THIS machine.
# Run after installing/removing something you want on future installs, then commit.
#   ~/dotfiles/packages/update.sh
set -euo pipefail
cd "$(dirname "$0")"

skip() { grep -vE '^\s*(#|$)' exclude.txt; }

# -Qqe: explicitly installed (not pulled in as a dependency); -n: official repos; -m: AUR/foreign
pacman -Qqen | grep -vxF -f <(skip) > pacman.txt
pacman -Qqem | grep -vxF -f <(skip) > aur.txt

echo "pacman.txt: $(wc -l < pacman.txt) packages, aur.txt: $(wc -l < aur.txt) packages"
git -C .. --no-pager diff --stat -- packages/ || true
