pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Laptop screen brightness, via brightnessctl (it asks systemd-logind, so no root needed)
Singleton {
    id: root

    property real value: 0 // 0.0 - 1.0
    property int changes: 0 // counts changes, so the OSD can react even when the value is the same

    function set(v: real): void {
        v = Math.max(0.01, Math.min(1, v)); // never fully black
        root.value = v;
        root.changes++;
        Quickshell.execDetached(["brightnessctl", "set", `${Math.round(v * 100)}%`]);
    }

    function increase(): void {
        set(value + 0.05);
    }

    function decrease(): void {
        set(value - 0.05);
    }

    // Read the starting value: `brightnessctl -m` prints "device,class,current,percent,max"
    Process {
        running: true
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split(",");
                if (fields.length >= 5)
                    root.value = parseInt(fields[2]) / parseInt(fields[4]);
            }
        }
    }
}
