#!/usr/bin/env bash
# Screenshot: save to ~/Pictures/Screenshots, copy to the clipboard, and show a notification.
#   screenshot.sh          whole screen
#   screenshot.sh region   drag a box with slurp (Escape cancels)
set -euo pipefail

dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$dir"
file="$dir/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"

if [[ "${1:-}" == "region" ]]; then
    geometry=$(slurp) || exit 0 # cancelled: do nothing
    grim -g "$geometry" "$file"
else
    grim "$file"
fi

wl-copy --type image/png < "$file"
# -i with the file shows the screenshot itself as the notification's picture
notify-send -a Screenshot -i "$file" "Screenshot saved" "Copied, and saved in ${dir/#$HOME/\~}"
