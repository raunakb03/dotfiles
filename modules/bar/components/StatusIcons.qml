import QtQuick
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import qs.components
import qs.config
import qs.modules.bar.popouts
import qs.services

// Volume, network, Bluetooth and battery, in one pill. Hovering an icon opens its popout.
StyledRect {
    id: root

    required property PopoutState popouts

    readonly property UPowerDevice battery: UPower.displayDevice

    implicitWidth: Appearance.sizes.barInnerWidth
    implicitHeight: column.implicitHeight + Appearance.padding.small * 2
    radius: Appearance.rounding.full
    color: Colours.palette.m3surfaceContainer

    Column {
        id: column

        anchors.centerIn: parent
        spacing: Appearance.spacing.small

        // Volume: click to mute, scroll to change
        StatusIcon {
            name: "audio"
            text: Audio.muted ? "volume_off" : Audio.volume >= 0.5 ? "volume_up" : Audio.volume > 0 ? "volume_down" : "volume_mute"
            onClicked: Audio.toggleMute()
            onWheel: event => Audio.setVolume(Audio.volume + (event.angleDelta.y > 0 ? 0.05 : -0.05))
        }

        // Network: Wi-Fi bars, Ethernet, or off
        StatusIcon {
            name: "network"
            text: {
                if (NetworkService.wired)
                    return "lan";
                if (!NetworkService.wifi)
                    return NetworkService.wifiEnabled ? "signal_wifi_0_bar" : "signal_wifi_off";
                const bars = Math.round(NetworkService.strength * 4); // 0-4
                return bars >= 4 ? "signal_wifi_4_bar" : `network_wifi_${Math.max(1, bars)}_bar`;
            }
        }

        // Bluetooth: off, on, or connected to something
        StatusIcon {
            name: "bluetooth"
            text: {
                if (!Bluetooth.defaultAdapter?.enabled)
                    return "bluetooth_disabled";
                return Bluetooth.devices.values.some(d => d.connected) ? "bluetooth_connected" : "bluetooth";
            }
        }

        // Battery: level in 7 steps, or charging
        StatusIcon {
            name: "battery"
            visible: root.battery.isLaptopBattery
            color: root.battery.percentage < 0.15 && root.battery.state !== UPowerDeviceState.Charging ? Colours.palette.m3error : Colours.palette.m3onSurface
            text: {
                if (root.battery.state === UPowerDeviceState.Charging)
                    return "battery_charging_full";
                const level = Math.round(root.battery.percentage * 7); // 0-7
                return level >= 7 ? "battery_full" : `battery_${level}_bar`;
            }
        }
    }

    // An icon that opens the popout called `name` while hovered
    component StatusIcon: MaterialIcon {
        id: icon

        required property string name

        signal clicked
        signal wheel(var event)

        anchors.horizontalCenter: parent.horizontalCenter

        MouseArea {
            anchors.fill: parent
            anchors.margins: -Appearance.spacing.small / 2 // no gaps between icons, so moving down doesn't flicker
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            // Open at this icon's vertical centre, in window coordinates
            onEntered: root.popouts.open(icon.name, icon.mapToItem(null, 0, icon.height / 2).y)
            // Only the icon that owns the open popout may close it. Neighbouring hover areas
            // overlap slightly, so the next icon's "entered" can arrive before this "exited".
            onExited: if (root.popouts.currentName === icon.name) root.popouts.scheduleClose()
            onClicked: icon.clicked()
            onWheel: event => icon.wheel(event)
        }
    }
}
