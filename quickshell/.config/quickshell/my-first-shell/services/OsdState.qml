pragma Singleton

import QtQuick
import Quickshell

// Decides when the on-screen display shows: whenever the volume, mute or brightness changes,
// for 1.5 s after the last change, on the focused monitor.
Singleton {
    id: root

    property bool visible: false
    property string screen: ""

    function show(): void {
        if (!ready.done) // the startup values arriving are not "changes"
            return;
        screen = ShellState.focusedScreen;
        visible = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer

        interval: 1500
        onTriggered: root.visible = false
    }

    // Pipewire and brightnessctl report their first values shortly after startup
    Timer {
        id: ready

        property bool done: false

        running: true
        interval: 2000
        onTriggered: done = true
    }

    Connections {
        target: Audio

        function onVolumeChanged(): void {
            root.show();
        }
        function onMutedChanged(): void {
            root.show();
        }
    }

    Connections {
        target: Brightness

        function onChangesChanged(): void {
            root.show();
        }
    }
}
