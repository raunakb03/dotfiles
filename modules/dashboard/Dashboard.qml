import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

// The dashboard: drops down from the top edge, centred. Opens with Super + A (stays open) or
// by touching the top edge with the mouse (closes when the mouse leaves).
Item {
    id: root

    required property bool open
    required property bool barOnRight
    readonly property bool hovered: hover.hovered

    readonly property real padding: Appearance.padding.large
    readonly property var tabs: [
        {
            icon: "dashboard",
            name: "Overview"
        },
        {
            icon: "music_note",
            name: "Media"
        },
        {
            icon: "speed",
            name: "Performance"
        },
        {
            icon: "partly_cloudy_day",
            name: "Weather"
        }
    ]
    readonly property int tab: ShellState.dashboardTab
    readonly property var tabItems: [overview, media, performance, weather]

    // Centred in the part of the screen the bar doesn't cover
    readonly property real freeLeft: barOnRight ? 0 : Appearance.sizes.barWidth
    readonly property real freeWidth: parent.width - Appearance.sizes.barWidth

    function switchTab(index: int): void {
        ShellState.dashboardTab = (index + tabs.length) % tabs.length;
    }

    width: Appearance.sizes.dashboardWidth + padding * 2
    height: open ? column.implicitHeight + padding * 2 : 0
    x: freeLeft + (freeWidth - width) / 2
    y: 0
    clip: true

    onOpenChanged: {
        if (!open)
            return;
        Weather.refreshIfStale();
        if (ShellState.dashboardPinned)
            column.forceActiveFocus(); // for Escape and the arrow keys
    }

    Behavior on height {
        Anim {
            easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
        }
    }

    HoverHandler {
        id: hover
    }

    ColumnLayout {
        id: column

        // Anchored to the bottom: as the panel grows, the content slides down out of the top edge
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.padding
        x: root.padding
        width: Appearance.sizes.dashboardWidth
        spacing: Appearance.spacing.normal

        Keys.onEscapePressed: ShellState.closeAll()
        Keys.onLeftPressed: root.switchTab(root.tab - 1)
        Keys.onRightPressed: root.switchTab(root.tab + 1)

        // Tab bar
        Item {
            Layout.fillWidth: true
            implicitHeight: tabRow.implicitHeight + 4

            Row {
                id: tabRow

                anchors.horizontalCenter: parent.horizontalCenter

                Repeater {
                    model: root.tabs

                    Item {
                        id: tabButton

                        required property var modelData
                        required property int index
                        readonly property bool current: root.tab === index

                        implicitWidth: Appearance.sizes.dashboardWidth / root.tabs.length
                        implicitHeight: tabContent.implicitHeight + Appearance.padding.small * 2

                        Row {
                            id: tabContent

                            anchors.centerIn: parent
                            spacing: Appearance.spacing.small

                            MaterialIcon {
                                text: tabButton.modelData.icon
                                fill: tabButton.current ? 1 : 0
                                color: tabButton.current ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                            }

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: tabButton.modelData.name
                                color: tabButton.current ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                            }
                        }

                        StateLayer {
                            radius: Appearance.rounding.normal
                            onClicked: root.switchTab(tabButton.index)
                        }
                    }
                }
            }

            // The line under the current tab, sliding between tabs
            StyledRect {
                readonly property real tabWidth: Appearance.sizes.dashboardWidth / root.tabs.length

                x: tabRow.x + tabWidth * root.tab + tabWidth * 0.2
                y: parent.height - height
                width: tabWidth * 0.6
                height: 3
                radius: Appearance.rounding.full
                color: Colours.palette.m3primary

                Behavior on x {
                    Anim {}
                }
            }
        }

        // The tabs. Only the current one is visible; the panel's height follows it.
        Item {
            Layout.fillWidth: true
            implicitHeight: root.tabItems[root.tab].implicitHeight

            Overview {
                id: overview

                width: parent.width
                visible: root.tab === 0
            }

            MediaTab {
                id: media

                width: parent.width
                visible: root.tab === 1
            }

            // A Loader, because this tab needs the C++ plugin: if it isn't built, only this tab
            // fails (and says how to fix it) instead of the whole shell.
            Loader {
                id: performance

                width: parent.width
                visible: root.tab === 2
                active: visible && root.open // also stops SystemStats polling when hidden
                source: "PerformanceTab.qml"

                StyledText {
                    width: parent.width
                    visible: performance.status === Loader.Error
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    padding: Appearance.padding.large
                    text: "The C++ plugin isn't available. Build it with\ncmake -S engine -B engine/build && cmake --build engine/build\nand start the shell with QML2_IMPORT_PATH set (see docs/10)."
                    color: Colours.palette.m3error
                }
            }

            WeatherTab {
                id: weather

                width: parent.width
                visible: root.tab === 3
            }
        }
    }
}
