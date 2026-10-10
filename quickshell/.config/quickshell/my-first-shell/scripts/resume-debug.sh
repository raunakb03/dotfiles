#!/usr/bin/env bash
# Run this from a TTY (Ctrl + Alt + F3, log in) when the keyboard stops working after a resume,
# BEFORE rebooting: Hyprland's log lives in /run/user (RAM) and is lost on reboot.
#   ~/.config/quickshell/my-first-shell/scripts/resume-debug.sh
# It writes ~/resume-debug-<date>.txt. Then get back with Ctrl + Alt + F1 (or reboot).

out="$HOME/resume-debug-$(date +%Y%m%d-%H%M%S).txt"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
hypr="hyprctl --instance 0"

{
    echo "### keyboard works in this TTY: yes (you're typing here)"
    echo; echo "### Hyprland devices (does it still see the keyboards?)"
    $hypr devices
    echo; echo "### locked? (our lock screen)"
    qs ipc -c my-first-shell call lock isLocked 2>&1
    echo; echo "### layers / focused window"
    $hypr layers | head -40
    $hypr activewindow
    echo; echo "### Hyprland log (last 200 lines)"
    tail -n 200 "$XDG_RUNTIME_DIR"/hypr/*/hyprland.log 2>&1
    echo; echo "### shell log (last 100 lines)"
    qs log -c my-first-shell 2>&1 | tail -n 100
    echo; echo "### system journal since the last resume"
    since=$(journalctl -k -b -q -o short-iso -g 'PM: suspend exit' | tail -1 | cut -c1-19)
    journalctl -b -q --no-pager -o short-iso --since "${since:-today}" | tail -n 300
} > "$out" 2>&1

echo "Saved $out"
