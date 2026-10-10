import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// The wallpaper: one full-screen window per monitor, on the layer below all windows
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: root

        required property ShellScreen modelData

        screen: modelData

        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "myshell-background"
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Shown until the image has loaded, or if there's no wallpaper yet
        color: Colours.palette.m3surfaceContainer

        Image {
            anchors.fill: parent
            source: Wallpaper.path ? "file://" + Wallpaper.path : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            retainWhileLoading: true

            // Decode at screen size, not at the image's full size (saves a lot of memory)
            sourceSize.width: root.width * root.modelData.devicePixelRatio
            sourceSize.height: root.height * root.modelData.devicePixelRatio
        }
    }
}
