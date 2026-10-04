import QtQuick
import QtQuick.Layouts
import MyShell.Engine // our C++ plugin (engine/), found through QML2_IMPORT_PATH
import qs.components
import qs.config
import qs.services

// CPU, memory and disk as gauges, plus temperatures, from the C++ SystemStats type.
// Loaded through a Loader in Dashboard.qml, so a missing plugin only breaks this tab.
ColumnLayout {
    id: root

    function gib(bytes: real): string {
        return (bytes / 1024 ** 3).toFixed(1);
    }

    function tempColour(celsius: real): color {
        return celsius >= 85 ? Colours.palette.m3error : celsius >= 70 ? Colours.palette.m3tertiary : Colours.palette.m3primary;
    }

    spacing: Appearance.spacing.normal

    // Only read /proc while you can see the numbers
    SystemStats {
        id: stats

        running: root.visible
        interval: 1000
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        Repeater {
            model: [
                {
                    label: "CPU",
                    value: stats.cpuUsage,
                    detail: stats.cpuName
                },
                {
                    label: "Memory",
                    value: stats.memTotal > 0 ? stats.memUsed / stats.memTotal : 0,
                    detail: `${root.gib(stats.memUsed)} / ${root.gib(stats.memTotal)} GiB`
                },
                {
                    label: "Disk /",
                    value: stats.diskTotal > 0 ? stats.diskUsed / stats.diskTotal : 0,
                    detail: `${root.gib(stats.diskUsed)} / ${root.gib(stats.diskTotal)} GiB`
                }
            ]

            Card {
                id: card

                required property var modelData

                Layout.fillWidth: true
                implicitHeight: gaugeColumn.implicitHeight + Appearance.padding.large * 2

                ColumnLayout {
                    id: gaugeColumn

                    anchors.centerIn: parent
                    width: parent.width - Appearance.padding.normal * 2
                    spacing: Appearance.spacing.small

                    Gauge {
                        Layout.alignment: Qt.AlignHCenter
                        value: card.modelData.value
                        text: `${Math.round(card.modelData.value * 100)}%`
                        label: card.modelData.label
                    }

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: card.modelData.detail
                        elide: Text.ElideRight
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }
        }
    }

    // Temperatures
    Card {
        Layout.fillWidth: true
        implicitHeight: temps.implicitHeight + Appearance.padding.normal * 2

        RowLayout {
            id: temps

            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            spacing: Appearance.spacing.large

            Repeater {
                model: [
                    {
                        icon: "memory",
                        label: "CPU",
                        value: stats.cpuTemp
                    },
                    {
                        icon: "videogame_asset",
                        label: "GPU",
                        value: stats.gpuTemp
                    }
                ]

                RowLayout {
                    id: temp

                    required property var modelData

                    Layout.fillWidth: true
                    visible: modelData.value > 0
                    spacing: Appearance.spacing.small

                    MaterialIcon {
                        text: "device_thermostat"
                        color: root.tempColour(temp.modelData.value)
                    }

                    StyledText {
                        text: temp.modelData.label
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    // A bar from 30 °C to 100 °C
                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: 8
                        radius: Appearance.rounding.full
                        color: Colours.palette.m3surfaceContainerHighest

                        StyledRect {
                            width: parent.width * Math.max(0, Math.min(1, (temp.modelData.value - 30) / 70))
                            height: parent.height
                            radius: Appearance.rounding.full
                            color: root.tempColour(temp.modelData.value)

                            Behavior on width {
                                Anim {}
                            }
                        }
                    }

                    StyledText {
                        text: `${Math.round(temp.modelData.value)}°C`
                        font.bold: true
                    }
                }
            }
        }
    }
}
