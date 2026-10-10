#include "sessionwatcher.hpp"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusObjectPath>
#include <QDBusReply>
#include <QDebug>

namespace {

const QString service = QStringLiteral("org.freedesktop.login1");
const QString managerPath = QStringLiteral("/org/freedesktop/login1");
const QString managerIface = QStringLiteral("org.freedesktop.login1.Manager");
const QString sessionIface = QStringLiteral("org.freedesktop.login1.Session");

} // namespace

SessionWatcher::SessionWatcher(QObject* parent)
    : QObject(parent) {
    // logind lives on the *system* bus (notifications were on the session bus)
    auto bus = QDBusConnection::systemBus();
    if (!bus.isConnected()) {
        qWarning() << "SessionWatcher: no system D-Bus";
        return;
    }

    // Manager.PrepareForSleep(bool): true just before suspending, false after waking
    bus.connect(service, managerPath, managerIface, QStringLiteral("PrepareForSleep"), this,
        SLOT(handlePrepareForSleep(bool)));

    // Which session are we? Hyprland was started in it, and passed XDG_SESSION_ID down to us.
    // ("auto" asks logind to work it out from our process, as a fallback.)
    const auto id = qEnvironmentVariable("XDG_SESSION_ID", QStringLiteral("auto"));
    auto call = QDBusMessage::createMethodCall(service, managerPath, managerIface, QStringLiteral("GetSession"));
    call << id;
    const QDBusReply<QDBusObjectPath> reply = bus.call(call);
    if (!reply.isValid()) {
        qWarning() << "SessionWatcher: can't find our login session:" << reply.error().message();
    } else {
        m_sessionPath = reply.value().path();
        // Session.Lock / Session.Unlock: sent by `loginctl lock-session` / `unlock-session`
        bus.connect(service, m_sessionPath, sessionIface, QStringLiteral("Lock"), this, SLOT(handleLock()));
        bus.connect(service, m_sessionPath, sessionIface, QStringLiteral("Unlock"), this, SLOT(handleUnlock()));
    }

    takeSleepInhibitor();
}

// Manager.Inhibit("sleep", who, why, "delay") returns a file descriptor. While we keep it open,
// logind delays suspending (by at most InhibitDelayMaxSec, 5 s by default). Closing it = "go ahead".
void SessionWatcher::takeSleepInhibitor() {
    if (m_inhibitor.isValid())
        return;
    auto call = QDBusMessage::createMethodCall(service, managerPath, managerIface, QStringLiteral("Inhibit"));
    call << QStringLiteral("sleep") << QStringLiteral("my-first-shell")
         << QStringLiteral("Show the lock screen before suspending") << QStringLiteral("delay");
    const QDBusReply<QDBusUnixFileDescriptor> reply = QDBusConnection::systemBus().call(call);
    if (reply.isValid())
        m_inhibitor = reply.value();
    else
        qWarning() << "SessionWatcher: can't take the sleep inhibitor:" << reply.error().message();
}

void SessionWatcher::sleepReady() {
    // QDBusUnixFileDescriptor owns a copy of the fd; replacing it closes that copy
    m_inhibitor = QDBusUnixFileDescriptor();
}

void SessionWatcher::setLockedHint(bool locked) {
    if (m_sessionPath.isEmpty())
        return;
    auto call = QDBusMessage::createMethodCall(service, m_sessionPath, sessionIface, QStringLiteral("SetLockedHint"));
    call << locked;
    QDBusConnection::systemBus().asyncCall(call); // fire and forget
}

void SessionWatcher::handlePrepareForSleep(bool sleeping) {
    if (sleeping) {
        emit aboutToSleep(); // QML locks, then calls sleepReady()
    } else {
        takeSleepInhibitor(); // ready for the next suspend
        emit resumed();
    }
}

void SessionWatcher::handleLock() {
    emit lockRequested();
}

void SessionWatcher::handleUnlock() {
    emit unlockRequested();
}
