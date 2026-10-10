import QtQuick

// Which popout is open, and where. One per screen; the bar opens popouts, the popout
// itself keeps them open while hovered, and leaving both closes it after a short delay.
QtObject {
    id: root

    property string currentName: ""  // "audio", "network", ... or "" when closed
    property real anchorY: 0         // vertical centre of the icon that opened it (window coordinates)
    property bool locked: false      // true while typing a password: don't close on mouse leave

    readonly property bool isOpen: currentName !== ""

    function open(name: string, y: real): void {
        closeTimer.stop();
        currentName = name;
        anchorY = y;
    }

    function keepOpen(): void {
        closeTimer.stop();
    }

    // The delay lets the mouse travel from the icon to the popout without it closing
    function scheduleClose(): void {
        if (!locked)
            closeTimer.restart();
    }

    function close(): void {
        closeTimer.stop();
        locked = false;
        currentName = "";
    }

    // QtObject has no children, so the timer is stored in a property
    property Timer closeTimer: Timer {
        interval: 300
        onTriggered: root.currentName = ""
    }
}
