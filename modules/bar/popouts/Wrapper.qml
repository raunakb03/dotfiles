import QtQuick
import qs.components
import qs.config

// The popout container: sits against the bar and slides out of it.
// Its geometry is also used by Background.qml (drawn behind it) and by the window's input mask.
Item {
    id: root

    required property PopoutState popouts
    required property bool barOnRight

    // Remember the last popout while it slides closed, so its content doesn't vanish mid-animation
    property string shownName: ""
    // True when going straight from one popout to another (e.g. audio -> network):
    // only then should the popout glide to its new position and size
    property bool switching: false
    property string previousName: ""
    readonly property Item content: loader.item
    readonly property real padding: Appearance.padding.large
    readonly property real openWidth: (content?.implicitWidth ?? 0) + padding * 2
    readonly property real openHeight: (content?.implicitHeight ?? 0) + padding * 2
    // Distance from the screen's top/bottom edge: room for the curved joins, and the frame if there is one
    readonly property real margin: Config.border.thickness + Appearance.rounding.extraLarge

    Connections {
        target: root.popouts
        function onCurrentNameChanged(): void {
            const name = root.popouts.currentName;
            root.switching = root.previousName !== "" && name !== "";
            root.previousName = name;
            if (name !== "")
                root.shownName = name;
        }
    }

    width: popouts.isOpen ? openWidth : 0
    height: openHeight
    // Against the bar's inner edge
    x: barOnRight ? parent.width - Appearance.sizes.barWidth - width : Appearance.sizes.barWidth
    // Centred on the icon, but kept away from the screen's top and bottom edges
    y: Math.max(margin, Math.min(popouts.anchorY - height / 2, parent.height - margin - height))
    clip: true

    Behavior on width {
        Anim {
            easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
        }
    }

    Behavior on height {
        enabled: root.switching
        Anim {}
    }

    Behavior on y {
        enabled: root.switching // jump into place when opening, glide when switching
        Anim {}
    }

    HoverHandler {
        onHoveredChanged: hovered ? root.popouts.keepOpen() : root.popouts.scheduleClose()
    }

    Loader {
        id: loader

        // Anchored to the bar side: as the container widens, the content slides out of the bar
        x: root.barOnRight ? root.padding : root.width - root.openWidth + root.padding
        y: root.padding
        opacity: root.popouts.isOpen ? 1 : 0

        sourceComponent: {
            switch (root.shownName) {
            case "audio":
                return audioComponent;
            case "network":
                return networkComponent;
            case "bluetooth":
                return bluetoothComponent;
            case "battery":
                return batteryComponent;
            }
            return null;
        }

        Behavior on opacity {
            Anim {
                duration: Appearance.anim.durations.small
            }
        }
    }

    Component {
        id: audioComponent

        AudioPopout {}
    }

    Component {
        id: networkComponent

        NetworkPopout {
            popouts: root.popouts
        }
    }

    Component {
        id: bluetoothComponent

        BluetoothPopout {}
    }

    Component {
        id: batteryComponent

        BatteryPopout {}
    }
}
