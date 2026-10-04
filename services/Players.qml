pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Media players (Spotify, browsers, mpv, …) via MPRIS. Replaces playerctl/playerctld.
Singleton {
    // Real players only: playerctld (if running) re-publishes another player under its own name
    readonly property var list: Mpris.players.values.filter(p => !p.dbusName.includes("playerctld"))
    // The player to control: one that's playing, otherwise the first one
    readonly property MprisPlayer active: list.find(p => p.isPlaying) ?? list[0] ?? null

    function togglePlaying(): void {
        if (active?.canTogglePlaying)
            active.togglePlaying();
    }

    function next(): void {
        if (active?.canGoNext)
            active.next();
    }

    function previous(): void {
        if (active?.canGoPrevious)
            active.previous();
    }

    function stop(): void {
        active?.stop();
    }
}
