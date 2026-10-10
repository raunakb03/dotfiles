import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell.Networking
import qs.components
import qs.config
import qs.services

// Wi-Fi on/off, nearby networks, connect (with a password if needed) and disconnect
Item {
    id: root

    required property PopoutState popouts

    // The secured network we're asking a password for, if any
    property WifiNetwork passwordFor: null

    function signalIcon(strength: real): string {
        const bars = Math.round(strength * 4);
        return bars >= 4 ? "signal_wifi_4_bar" : `network_wifi_${Math.max(1, bars)}_bar`;
    }

    function choose(net: WifiNetwork): void {
        if (net.connected)
            net.disconnect();
        else if (net.known || net.security === WifiSecurityType.Open)
            net.connect(); // saved password, or no password needed
        else
            root.passwordFor = net;
    }

    implicitWidth: Appearance.sizes.popoutWidth
    implicitHeight: layout.implicitHeight

    // Look for networks only while this popout is open
    Component.onCompleted: NetworkService.setScanning(true)
    Component.onDestruction: NetworkService.setScanning(false)

    // Typing a password needs keyboard focus, and the popout must not close meanwhile
    onPasswordForChanged: popouts.locked = passwordFor !== null

    ColumnLayout {
        id: layout

        width: parent.width
        spacing: Appearance.spacing.small

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                Layout.fillWidth: true
                text: "Wi-Fi"
                font.bold: true
            }

            StyledSwitch {
                checked: Networking.wifiEnabled
                onToggled: Networking.wifiEnabled = checked
            }
        }

        Repeater {
            model: Networking.wifiEnabled ? NetworkService.wifiNetworks.slice(0, 8) : []

            ListItem {
                required property WifiNetwork modelData

                Layout.fillWidth: true
                icon: root.signalIcon(modelData.signalStrength)
                text: modelData.name
                selected: modelData.connected
                trailing: modelData.stateChanging ? "…" : modelData.connected ? "Connected"
                        : modelData.security !== WifiSecurityType.Open && !modelData.known ? "Secured" : ""
                onClicked: root.choose(modelData)
            }
        }

        // Password entry for a new secured network
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.passwordFor !== null
            spacing: Appearance.spacing.small

            StyledText {
                text: `Password for ${root.passwordFor?.name ?? ""}`
                color: Colours.palette.m3onSurfaceVariant
            }

            TextField {
                Layout.fillWidth: true
                echoMode: TextInput.Password
                color: Colours.palette.m3onSurface
                font.family: Appearance.font.family.sans
                placeholderText: "Enter to connect, Esc to cancel"
                placeholderTextColor: Colours.palette.m3outline
                background: StyledRect {
                    radius: Appearance.rounding.small
                    color: Colours.palette.m3surfaceContainerHigh
                }

                onVisibleChanged: if (visible) forceActiveFocus()
                onAccepted: {
                    root.passwordFor.connectWithPsk(text);
                    text = "";
                    root.passwordFor = null;
                }
                Keys.onEscapePressed: {
                    text = "";
                    root.passwordFor = null;
                }
            }
        }
    }
}
