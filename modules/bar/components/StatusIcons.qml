import QtQuick
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import qs.components
import qs.config
import qs.services

// Volume, network, Bluetooth and battery, in one pill
StyledRect {
    id: root

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
        MaterialIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Audio.muted ? "volume_off" : Audio.volume >= 0.5 ? "volume_up" : Audio.volume > 0 ? "volume_down" : "volume_mute"

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Audio.toggleMute()
                onWheel: event => Audio.setVolume(Audio.volume + (event.angleDelta.y > 0 ? 0.05 : -0.05))
            }
        }

        // Network: Wi-Fi bars, Ethernet, or off
        MaterialIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                if (Network.wired)
                    return "lan";
                if (!Network.wifi)
                    return Network.wifiEnabled ? "signal_wifi_0_bar" : "signal_wifi_off";
                const bars = Math.round(Network.strength * 4); // 0-4
                return bars >= 4 ? "signal_wifi_4_bar" : `network_wifi_${Math.max(1, bars)}_bar`;
            }
        }

        // Bluetooth: off, on, or connected to something
        MaterialIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                if (!Bluetooth.defaultAdapter?.enabled)
                    return "bluetooth_disabled";
                return Bluetooth.devices.values.some(d => d.connected) ? "bluetooth_connected" : "bluetooth";
            }
        }

        // Battery: level in 7 steps, or charging
        MaterialIcon {
            anchors.horizontalCenter: parent.horizontalCenter
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
}
