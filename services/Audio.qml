pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// The default output device (speakers/headphones) via PipeWire
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real volume: sink?.audio?.volume ?? 0 // 0.0 - 1.0

    function setVolume(value: real): void {
        if (sink?.ready && sink.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1, value));
        }
    }

    function toggleMute(): void {
        if (sink?.ready && sink.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    // PipeWire objects only report their properties while something "tracks" them
    PwObjectTracker {
        objects: [root.sink]
    }
}
