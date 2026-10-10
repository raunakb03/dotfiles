import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// One notification: icon, app name and age, title, text and action buttons.
// Used by the popups and by the sidebar's history.
StyledRect {
    id: root

    required property var entry // a Notifs.Entry
    property bool inHistory     // in the sidebar: clicking dismisses instead of just hiding the popup

    // An icon can be a file path/URL (e.g. a contact photo) or an icon-theme name (e.g. "discord").
    // Quickshell passes theme icons on as "image://icon/<name>"; those go through iconPath(…, true),
    // which returns "" if the theme doesn't have the icon (so we show a bell, not a checkerboard).
    function iconSource(icon: string): string {
        if (icon.startsWith("image://icon/"))
            icon = icon.slice("image://icon/".length);
        if (icon === "")
            return "";
        if (icon.startsWith("/"))
            return "file://" + icon; // a bare path would be read as a path inside the app (qrc:)
        if (icon.includes("://"))
            return icon;
        return Quickshell.iconPath(icon, true);
    }

    // "now", "5m", "2h", "3d", updated every second via the Time service
    readonly property string age: {
        const minutes = Math.floor((Time.date - entry.time) / 60000);
        if (minutes < 1)
            return "now";
        if (minutes < 60)
            return `${minutes}m`;
        if (minutes < 60 * 24)
            return `${Math.floor(minutes / 60)}h`;
        return `${Math.floor(minutes / 60 / 24)}d`;
    }
    readonly property string picture: iconSource(entry.image) || iconSource(entry.appIcon)

    implicitHeight: layout.implicitHeight + Appearance.padding.normal * 2
    radius: Appearance.rounding.large
    color: Colours.palette.m3surfaceContainer
    border.width: entry.urgency === 2 ? 2 : 0 // 2 = Critical
    border.color: Colours.palette.m3error

    // Clicking the card: run its default action if it has one, otherwise dismiss/hide it
    StateLayer {
        radius: root.radius
        onClicked: {
            const def = root.entry.actions.find(a => a.identifier === "default");
            if (def)
                root.entry.invoke(def);
            else if (root.inHistory)
                Notifs.dismiss(root.entry);
            else
                root.entry.popup = false;
        }
    }

    HoverHandler {
        onHoveredChanged: root.entry.hovered = hovered
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Appearance.padding.normal
        spacing: Appearance.spacing.normal

        // Picture or icon, else a generic bell
        Item {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 40
            implicitHeight: 40

            ClippingRectangle {
                anchors.fill: parent
                radius: Appearance.rounding.full
                color: Colours.palette.m3surfaceContainerHigh
                visible: root.picture !== ""

                IconImage {
                    anchors.fill: parent
                    source: root.picture
                }
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: root.picture === ""
                text: "notifications"
                fill: 1
                color: Colours.palette.m3primary
                font.pointSize: Appearance.font.size.large
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: `${root.entry.appName || "Notification"} · ${root.age}`
                    elide: Text.ElideRight
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                // Dismiss for good (removes it from the history too)
                MaterialIcon {
                    text: "close"
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3onSurfaceVariant

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.dismiss(root.entry)
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.entry.summary
                visible: text !== ""
                font.bold: true
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: root.entry.body
                visible: text !== ""
                wrapMode: Text.Wrap
                maximumLineCount: root.inHistory ? 6 : 3
                elide: Text.ElideRight
                color: Colours.palette.m3onSurfaceVariant
            }

            // Action buttons (not the hidden "default" action, which is the click on the card)
            Flow {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.small
                spacing: Appearance.spacing.small
                visible: children.length > 1

                Repeater {
                    model: root.entry.actions.filter(a => a.identifier !== "default")

                    StyledRect {
                        required property var modelData

                        implicitWidth: label.implicitWidth + Appearance.padding.normal * 2
                        implicitHeight: label.implicitHeight + Appearance.padding.small
                        radius: Appearance.rounding.full
                        color: Colours.palette.m3secondaryContainer

                        StyledText {
                            id: label

                            anchors.centerIn: parent
                            text: parent.modelData.text
                            font.pointSize: Appearance.font.size.small
                            color: Colours.palette.m3onSecondaryContainer
                        }

                        StateLayer {
                            onClicked: root.entry.invoke(parent.modelData)
                        }
                    }
                }
            }
        }
    }
}
