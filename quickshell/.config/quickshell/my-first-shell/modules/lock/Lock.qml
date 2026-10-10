import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import MyShell.Engine
import qs.services

// The lock screen's logic: the Wayland session lock, the password check (PAM), and the
// connection to logind. The picture itself is LockContent.qml.
Scope {
    id: root

    // What you've typed so far (never shown, only counted as dots)
    property string buffer: ""
    // "" or a message under the password field ("Wrong password", "Account locked …")
    property string message: ""
    property bool failed: false // true for a moment after a wrong password (the field shakes)
    readonly property bool checking: pam.active

    signal shake
    signal refocus // after waking up: the surfaces take the keyboard again

    function submit(): void {
        if (pam.active || buffer === "")
            return;
        message = "";
        pam.start();
    }

    // Keys from the lock surface
    function handleKey(event: var): void {
        if (pam.active)
            return;
        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            submit();
        } else if (event.key === Qt.Key_Escape) {
            buffer = "";
        } else if (event.key === Qt.Key_Backspace) {
            buffer = event.modifiers & Qt.ControlModifier ? "" : buffer.slice(0, -1);
        } else if (event.text !== "" && !/[\x00-\x1F\x7F]/.test(event.text)) {
            buffer += event.text; // any printable character, including non-Latin ones
        }
    }

    // The Wayland session lock: while `locked`, Hyprland shows only our surfaces (one per
    // monitor) and sends them all input. If the shell crashes, the session *stays* locked;
    // with misc.allow_session_lock_restore a restarted shell can take over again.
    WlSessionLock {
        id: sessionLock

        locked: LockState.locked

        // Once Hyprland confirms the lock (all surfaces drawn): safe to let a pending suspend go
        onSecureChanged: if (secure) watcher.sleepReady()

        LockSurface {
            lock: root
        }
    }

    // The password check. PAM asks a question ("Password: ") → we answer with the buffer.
    PamContext {
        id: pam

        config: "lock"                                       // assets/pam.d/lock
        configDirectory: Quickshell.shellPath("assets/pam.d")

        onResponseRequiredChanged: {
            if (!responseRequired)
                return;
            respond(root.buffer);
            root.buffer = "";
        }

        // Informational/error messages from PAM, e.g. faillock's "The account is locked due to 3 failed logins."
        onPamMessage: {
            if (messageIsError || message.includes("locked"))
                root.message = message;
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.message = "";
                LockState.locked = false;
                return;
            }
            root.buffer = ""; // also when PAM failed before asking (e.g. account locked)
            if (root.message === "")
                root.message = result === PamResult.MaxTries ? "Too many attempts" : result === PamResult.Error ? "Couldn't check the password" : "Wrong password";
            root.failed = true;
            root.shake();
            failedReset.restart();
        }
    }

    Timer {
        id: failedReset

        interval: 3000
        onTriggered: {
            root.failed = false;
            root.message = "";
        }
    }

    // logind: `loginctl lock-session` (Super + Escape), suspend, `loginctl unlock-session`
    SessionWatcher {
        id: watcher

        onLockRequested: LockState.lock()
        onResumed: root.refocus()
        onUnlockRequested: LockState.locked = false
        onAboutToSleep: {
            if (sessionLock.secure) // already locked: nothing to wait for
                sleepReady();
            else
                LockState.lock(); // sleepReady() is called from onSecureChanged
        }
    }

    Connections {
        target: LockState

        function onLockedChanged(): void {
            watcher.setLockedHint(LockState.locked);
            root.buffer = "";
            root.message = "";
        }
    }

    // `qs ipc -c my-first-shell call lock unlock` — e.g. from a TTY (Ctrl + Alt + F3) if the
    // lock screen ever misbehaves. Anyone who can run commands as you could do anything else
    // as you anyway, so this doesn't make the lock weaker.
    IpcHandler {
        target: "lock"

        function lock(): void {
            LockState.lock();
        }

        function unlock(): void {
            LockState.locked = false;
        }

        function isLocked(): bool {
            return LockState.locked;
        }
    }
}
