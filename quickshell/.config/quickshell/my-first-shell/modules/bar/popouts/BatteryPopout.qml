import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.components
import qs.config
import qs.services

// Charge level, charging state and time remaining
Item {
    id: root

    readonly property UPowerDevice battery: UPower.displayDevice

    // 5430 seconds -> "1 h 31 min"
    function formatTime(seconds: real): string {
        const h = Math.floor(seconds / 3600);
        const m = Math.round((seconds % 3600) / 60);
        return h > 0 ? `${h} h ${m} min` : `${m} min`;
    }

    implicitWidth: Appearance.sizes.popoutWidth * 0.75
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        width: parent.width
        spacing: Appearance.spacing.extraSmall

        StyledText {
            text: `${Math.round(root.battery.percentage * 100)}%`
            font.pointSize: Appearance.font.size.extraLarge
            font.bold: true
            color: Colours.palette.m3primary
        }

        StyledText {
            text: {
                switch (root.battery.state) {
                case UPowerDeviceState.Charging:
                    return "Charging";
                case UPowerDeviceState.Discharging:
                    return "On battery";
                case UPowerDeviceState.FullyCharged:
                    return "Fully charged";
                case UPowerDeviceState.PendingCharge:
                    return "Plugged in, not charging";
                }
                return "Battery";
            }
        }

        StyledText {
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.small
            text: {
                if (root.battery.state === UPowerDeviceState.Charging && root.battery.timeToFull > 0)
                    return `Full in ${root.formatTime(root.battery.timeToFull)}`;
                if (root.battery.state === UPowerDeviceState.Discharging && root.battery.timeToEmpty > 0)
                    return `${root.formatTime(root.battery.timeToEmpty)} remaining`;
                return "";
            }
            visible: text !== ""
        }
    }
}
