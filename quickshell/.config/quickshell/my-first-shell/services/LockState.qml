pragma Singleton

import QtQuick
import Quickshell

// Whether the session is locked. Anything can lock (idle, logind, the IPC command);
// only a correct password (modules/lock/Lock.qml) or `loginctl unlock-session` unlocks.
Singleton {
    property bool locked: false

    function lock(): void {
        locked = true;
    }
}
