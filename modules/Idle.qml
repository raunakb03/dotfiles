import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// What happens when you leave the computer alone (times in shell.json → idle, in seconds;
// 0 turns a step off). Replaces hypridle. Any key or mouse movement resets all timers.
Scope {
    id: root

    // Don't count you as idle while something is playing (a video), or with "keep awake" on
    readonly property bool active: Config.loaded && !ShellState.keepAwake && !(Config.idle.inhibitWhenPlaying && Players.list.some(p => p.isPlaying))

    // 1. Lock
    Step {
        seconds: Config.idle.lockAfter
        onIdle: LockState.lock()
    }

    // 2. Screen off (and back on when you're back)
    Step {
        seconds: Config.idle.screenOffAfter
        onIdle: Hypr.dispatch(`hl.dsp.dpms({ action = "disable" })`)
        onBack: Hypr.dispatch(`hl.dsp.dpms({ action = "enable" })`)
    }

    // 3. Suspend. logind then tells SessionWatcher, which locks first (if not already locked).
    Step {
        seconds: Config.idle.suspendAfter
        onIdle: Quickshell.execDetached(["systemctl", "suspend"])
    }

    // One IdleMonitor. Quickshell's IdleMonitor only reads `timeout` when it starts, so a
    // changed time (or shell.json loading after startup) needs a *new* monitor: the Variants
    // model is the time itself, and a new value replaces the monitor. An empty model = off.
    component Step: Scope {
        id: step

        property int seconds
        signal idle
        signal back

        Variants {
            model: root.active && step.seconds > 0 ? [step.seconds] : []

            IdleMonitor {
                required property int modelData

                timeout: modelData
                onIsIdleChanged: isIdle ? step.idle() : step.back()
            }
        }
    }
}
