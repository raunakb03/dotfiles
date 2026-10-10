import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

// The drawer window covers the whole screen and doesn't reserve any space.
// These four invisible 1-pixel windows reserve it instead, one per edge, so tiled
// windows stay inside the frame: the bar's width on its side, the border elsewhere.
Scope {
    id: root

    required property ShellScreen screen

    readonly property bool barOnRight: Config.bar.position === "right"
    readonly property int barWidth: Appearance.sizes.barWidth
    readonly property int thickness: Config.border.thickness

    ExclusionZone {
        anchors.left: true
        exclusiveZone: root.barOnRight ? root.thickness : root.barWidth
    }

    ExclusionZone {
        anchors.right: true
        exclusiveZone: root.barOnRight ? root.barWidth : root.thickness
    }

    ExclusionZone {
        anchors.top: true
    }

    ExclusionZone {
        anchors.bottom: true
    }

    // An inline component: a small reusable type defined inside this file
    component ExclusionZone: PanelWindow {
        screen: root.screen
        WlrLayershell.namespace: "myshell-exclusion"
        exclusiveZone: root.thickness
        mask: Region {} // takes no mouse input at all
        implicitWidth: 1
        implicitHeight: 1
        color: "transparent"
    }
}
