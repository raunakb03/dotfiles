pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The notification server: apps send notifications here (over D-Bus) instead of to dunst.
// Each notification is copied into an Entry, so the history keeps it after the app is gone.
Singleton {
    id: root

    property list<Entry> list: []                    // newest first: the sidebar's history
    readonly property list<Entry> popups: list.filter(n => n.popup)
    property bool dnd: false                         // do not disturb: no popups (history still fills)
    // No popups while you're looking at the history
    readonly property bool sidebarOpen: ShellState.sidebarScreen !== ""

    readonly property int defaultTimeout: 5000 // ms a popup stays when the app doesn't say

    function dismiss(entry: Entry): void {
        entry.notification?.dismiss(); // tell the app (it may react, e.g. clear its badge)
        list = list.filter(n => n !== entry);
        entry.destroy();
    }

    // Hide all popups (they stay in the history)
    function hidePopups(): void {
        for (const entry of popups)
            entry.popup = false;
    }

    onSidebarOpenChanged: if (sidebarOpen) hidePopups()

    function clearAll(): void {
        for (const entry of list)
            entry.notification?.dismiss();
        const old = list;
        list = [];
        for (const entry of old)
            entry.destroy();
    }

    NotificationServer {
        // Tell apps what we can show, so they send the right things
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: false
        persistenceSupported: true
        keepOnReload: false

        onNotification: notification => {
            notification.tracked = true; // keep the object alive until it's dismissed or closed
            const entry = entryComponent.createObject(root, {
                notification,
                popup: !root.dnd && !root.sidebarOpen
            });
            root.list = [entry, ...root.list];
        }
    }

    Component {
        id: entryComponent

        Entry {}
    }

    // One notification. Its text is *copied* from the Notification object (and updated if the
    // app changes it), because that object goes away when the app closes the notification,
    // and the history must still show it afterwards.
    component Entry: QtObject {
        id: entry

        property Notification notification
        property bool popup
        property bool hovered // set by the card under the mouse: the popup doesn't time out meanwhile
        readonly property date time: new Date()

        property string appName
        property string appIcon
        property string summary
        property string body
        property string image
        property int urgency: NotificationUrgency.Normal
        // Buttons like "Reply" or "Open"; they only work while the app still has the notification
        readonly property var actions: notification?.actions ?? []

        function update(): void {
            if (!notification)
                return;
            appName = notification.appName;
            appIcon = notification.appIcon;
            summary = notification.summary;
            body = notification.body;
            image = notification.image;
            urgency = notification.urgency;
        }

        function invoke(action: var): void {
            action.invoke();
            root.dismiss(entry);
        }

        Component.onCompleted: update()

        // Hide the popup after the timeout. Critical notifications (e.g. low battery) stay until dismissed.
        readonly property Timer timer: Timer {
            running: entry.popup && !entry.hovered && entry.urgency !== NotificationUrgency.Critical
            interval: (entry.notification?.expireTimeout ?? 0) > 0 ? entry.notification.expireTimeout : root.defaultTimeout
            onTriggered: entry.popup = false
        }

        readonly property Connections watcher: Connections {
            target: entry.notification

            // The app replaced the notification's content (e.g. a download's progress)
            function onSummaryChanged(): void {
                entry.update();
            }
            function onBodyChanged(): void {
                entry.update();
            }
            function onImageChanged(): void {
                entry.update();
            }

            // The app closed it, or it expired on the app's side: keep it in the history
            function onClosed(): void {
                entry.popup = false;
                entry.notification = null;
            }
        }
    }
}
