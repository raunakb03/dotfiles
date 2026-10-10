pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// A thin layer over Quickshell's Hyprland module.
// Our Hyprland uses the Lua config, so dispatchers are Lua expressions (like in keybinds.lua).
Singleton {
    readonly property HyprlandToplevel activeToplevel: Hyprland.activeToplevel

    // Title of the focused window, or "" on an empty workspace.
    // The title comes from the Wayland side (ToplevelManager): unlike Hyprland.activeToplevel,
    // it's known right after startup, without waiting for a focus change.
    readonly property string activeTitle: (Hyprland.focusedWorkspace?.toplevels.values.length ?? 0) > 0
        ? (ToplevelManager.activeToplevel?.title ?? "") : ""

    // Quickshell learns about windows from Hyprland's events. Ask for the
    // current state once at startup, so the active window is known right away.
    Component.onCompleted: {
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
    }

    function monitorFor(screen: ShellScreen): HyprlandMonitor {
        return Hyprland.monitorFor(screen);
    }

    function dispatch(lua: string): void {
        Hyprland.dispatch(lua);
    }

    // id can be a number (3) or a relative string ("r+1" = next workspace)
    function focusWorkspace(id: var): void {
        dispatch(`hl.dsp.focus({ workspace = "${id}" })`);
    }

    // Does this workspace have any windows?
    function isOccupied(id: int): bool {
        const ws = Hyprland.workspaces.values.find(w => w.id === id);
        return (ws?.toplevels.values.length ?? 0) > 0;
    }
}
