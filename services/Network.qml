pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

// The current network connection, via Quickshell's NetworkManager integration
Singleton {
    readonly property var devices: Networking.devices.values

    // The first connected Wi-Fi network, if any
    readonly property WifiNetwork wifi: {
        for (const dev of devices) {
            if (dev.type !== DeviceType.Wifi)
                continue;
            const net = dev.networks.values.find(n => n.connected);
            if (net)
                return net;
        }
        return null;
    }

    readonly property bool wired: devices.some(d => d.type === DeviceType.Wired && d.connected)
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property string name: wifi?.name ?? (wired ? "Ethernet" : "")
    readonly property real strength: wifi?.signalStrength ?? 0 // 0.0 - 1.0
}
