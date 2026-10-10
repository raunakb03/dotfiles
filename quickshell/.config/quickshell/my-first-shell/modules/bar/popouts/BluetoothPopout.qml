import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.components
import qs.config
import qs.services

// Turn Bluetooth on/off and connect/disconnect paired devices
Item {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter

    // Paired (or connected) devices, connected ones first
    readonly property var devices: Bluetooth.devices.values
        .filter(d => d.paired || d.connected)
        .sort((a, b) => b.connected - a.connected)

    // BlueZ gives freedesktop icon names like "audio-headset"; pick a matching Material icon
    function iconFor(device: BluetoothDevice): string {
        const icon = device.icon ?? "";
        if (icon.includes("headset") || icon.includes("headphone"))
            return "headphones";
        if (icon.includes("audio"))
            return "speaker";
        if (icon.includes("phone"))
            return "smartphone";
        if (icon.includes("mouse"))
            return "mouse";
        if (icon.includes("keyboard"))
            return "keyboard";
        return "bluetooth";
    }

    implicitWidth: Appearance.sizes.popoutWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        width: parent.width
        spacing: Appearance.spacing.small

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                Layout.fillWidth: true
                text: "Bluetooth"
                font.bold: true
            }

            StyledSwitch {
                checked: root.adapter?.enabled ?? false
                enabled: root.adapter !== null
                onToggled: root.adapter.enabled = checked
            }
        }

        Repeater {
            model: root.adapter?.enabled ? root.devices : []

            ListItem {
                required property BluetoothDevice modelData

                Layout.fillWidth: true
                icon: root.iconFor(modelData)
                text: modelData.name
                selected: modelData.connected
                trailing: modelData.connected && modelData.batteryAvailable ? `${Math.round(modelData.battery * 100)}%`
                        : modelData.state === BluetoothDeviceState.Connecting ? "Connecting…" : ""
                onClicked: modelData.connected = !modelData.connected
            }
        }

        StyledText {
            visible: (root.adapter?.enabled ?? false) && root.devices.length === 0
            text: "No paired devices"
            color: Colours.palette.m3onSurfaceVariant
        }
    }
}
