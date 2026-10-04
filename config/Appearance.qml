pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property real roundingScale: Config.appearance.roundingScale
    readonly property real spacingScale: Config.appearance.spacingScale
    readonly property real paddingScale: Config.appearance.paddingScale
    readonly property real fontScale: Config.appearance.fontScale
    readonly property real animDurationScale: Config.appearance.animDurationScale

    readonly property QtObject rounding: QtObject {
        readonly property int extraSmall: Math.round(4 * root.roundingScale)
        readonly property int small: Math.round(8 * root.roundingScale)
        readonly property int normal: Math.round(12 * root.roundingScale)
        readonly property int large: Math.round(16 * root.roundingScale)
        readonly property int extraLarge: Math.round(28 * root.roundingScale) // panels and popouts
        readonly property int full: 1000
    }

    readonly property QtObject spacing: QtObject {
        readonly property int extraSmall: Math.round(4 * root.spacingScale)
        readonly property int small: Math.round(8 * root.spacingScale)
        readonly property int normal: Math.round(12 * root.spacingScale)
        readonly property int large: Math.round(16 * root.spacingScale)
    }

    readonly property QtObject padding: QtObject {
        readonly property int extraSmall: Math.round(4 * root.paddingScale)
        readonly property int small: Math.round(8 * root.paddingScale)
        readonly property int normal: Math.round(12 * root.paddingScale)
        readonly property int large: Math.round(16 * root.paddingScale)
    }

    // Fixed sizes of specific parts of the shell, in pixels
    readonly property QtObject sizes: QtObject {
        readonly property int barInnerWidth: 32 // width of the pills inside the bar
        readonly property int barWidth: barInnerWidth + root.padding.small * 2 // the whole bar
        readonly property int popoutWidth: 300 // width of the popouts' content
        readonly property int launcherWidth: 600
        readonly property int launcherItemHeight: 56
        readonly property int wallpaperWidth: 200 // thumbnail size in the wallpaper picker
        readonly property int wallpaperHeight: 130
        readonly property int notificationWidth: 360 // popups and the sidebar's history
        readonly property int osdHeight: 180         // the volume / brightness bars
        readonly property int sessionButtonSize: 72  // the power menu's buttons
    }

    readonly property QtObject font: QtObject {
        readonly property QtObject family: QtObject {
            readonly property string sans: sansLoader.status === FontLoader.Ready ? sansLoader.name : "sans-serif"
            readonly property string mono: "JetBrainsMono Nerd Font"
            readonly property string material: "Material Symbols Rounded"
        }

        readonly property QtObject size: QtObject {
            readonly property real small: 11 * root.fontScale
            readonly property real smaller: 12 * root.fontScale
            readonly property real normal: 13 * root.fontScale
            readonly property real larger: 15 * root.fontScale
            readonly property real large: 18 * root.fontScale
            readonly property real extraLarge: 28 * root.fontScale
        }
    }

    readonly property QtObject anim: QtObject {
        readonly property QtObject durations: QtObject {
            readonly property int small: 200 * root.animDurationScale
            readonly property int normal: 400 * root.animDurationScale
            readonly property int large: 600 * root.animDurationScale
            readonly property int extraLarge: 1000 * root.animDurationScale
            readonly property int fastEffects: 150 * root.animDurationScale
            readonly property int effects: 200 * root.animDurationScale
            readonly property int slowEffects: 300 * root.animDurationScale
        }

        readonly property QtObject curves: QtObject {
            readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
            readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
            readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
            readonly property list<real> effects: [0.34, 0.8, 0.34, 1, 1, 1]
        }
    }

    FontLoader {
        id: sansLoader

        source: Quickshell.shellPath("assets/fonts/GoogleSansFlex.ttf")
    }
}

