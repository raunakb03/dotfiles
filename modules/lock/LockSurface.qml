import QtQuick
import Quickshell.Wayland

// One per monitor while locked (WlSessionLock creates them). It only hosts LockContent,
// which is also what you'd use to preview the design in a normal window.
WlSessionLockSurface {
    id: root

    required property var lock // Lock.qml

    color: "black" // under the content, while the wallpaper loads

    LockContent {
        anchors.fill: parent
        lock: root.lock
        screen: root.screen
    }
}
