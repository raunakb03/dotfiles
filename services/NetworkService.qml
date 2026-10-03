pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

// The current network connection, via Quickshell's NetworkManager integration.
// Named NetworkService (not Network) because Quickshell.Networking already has a type called Network.
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

    // Every Wi-Fi network in range: connected first, then strongest first
    readonly property var wifiNetworks: {
        let nets = [];
        for (const dev of devices)
            if (dev.type === DeviceType.Wifi)
                nets = nets.concat(dev.networks.values);
        return nets.sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength));
    }

    // Ask the Wi-Fi devices to scan for networks (only while something needs the list)
    function setScanning(enabled: bool): void {
        for (const dev of devices)
            if (dev.type === DeviceType.Wifi)
                dev.scannerEnabled = enabled;
    }
}
