import QtQuick
import qs.components
import qs.config
import qs.services

// New notifications, stacked in the top corner next to the bar.
// The panel grows down from the top edge as popups arrive and shrinks as they time out.
Item {
    id: root

    required property bool barOnRight

    readonly property real padding: Appearance.padding.normal

    width: Appearance.sizes.notificationWidth + padding * 2
    height: Notifs.popups.length > 0 ? column.implicitHeight + padding * 2 : 0
    x: barOnRight ? parent.width - Appearance.sizes.barWidth - width : Appearance.sizes.barWidth
    y: 0
    clip: true

    Behavior on height {
        Anim {
            easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
        }
    }

    Column {
        id: column

        // Anchored to the bottom: as the panel grows, the cards slide down out of the top edge
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.padding
        x: root.padding
        width: Appearance.sizes.notificationWidth
        spacing: Appearance.spacing.small

        Repeater {
            model: Notifs.popups

            NotificationCard {
                required property var modelData

                width: Appearance.sizes.notificationWidth
                entry: modelData
            }
        }
    }
}
