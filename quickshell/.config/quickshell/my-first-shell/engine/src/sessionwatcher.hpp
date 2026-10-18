#pragma once

#include <QDBusUnixFileDescriptor>
#include <QObject>
#include <QtQml/qqmlregistration.h>

// Listens to systemd-logind (the service that manages logins, sleep and the lid) on D-Bus:
//
// - `loginctl lock-session` (or anything else asking logind to lock) → lockRequested()
// - `loginctl unlock-session`                                         → unlockRequested()
// - the system is about to suspend (lid closed, `systemctl suspend`, idle) → aboutToSleep()
//   and after waking up → resumed()
//
// To make sure the lock screen is on screen *before* the laptop sleeps (otherwise your desktop
// flashes up for a moment on wake), it holds a logind "delay inhibitor": logind waits (up to
// a few seconds) until we call sleepReady(), which releases it.
class SessionWatcher : public QObject {
    Q_OBJECT
    QML_ELEMENT

public:
    explicit SessionWatcher(QObject* parent = nullptr);

    // Call when the lock screen is up: lets the pending suspend go ahead
    Q_INVOKABLE void sleepReady();
    // Tell logind whether we're locked (shown by `loginctl show-session`, used by other tools)
    Q_INVOKABLE void setLockedHint(bool locked);

signals:
    void lockRequested();
    void unlockRequested();
    void aboutToSleep();
    void resumed();

private slots:
    void handlePrepareForSleep(bool sleeping);
    void handleLock();
    void handleUnlock();

private:
    void takeSleepInhibitor();

    QString m_sessionPath;            // e.g. /org/freedesktop/login1/session/_32
    QDBusUnixFileDescriptor m_inhibitor; // valid while we hold the delay lock
    bool m_sleeping = false;             // between PrepareForSleep(true) and sleepReady()
};
