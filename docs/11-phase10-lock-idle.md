# Phase 10: Lock screen & idle

> **Status: 🔍 built 2026-10-04. Waiting for your check** (see [Check it](#check-it)).
> Implemented by Claude. This doc explains what was built so you can understand,
> change and debug it.

## What you got

- **Your own lock screen**, replacing hyprlock:
  - the wallpaper, blurred and darkened
  - a big clock and the date, your avatar (`~/.face` if you add one) and user name
  - a password field that shows one dot per character
  - battery and what's playing at the bottom

  A wrong password turns the field red, shakes it and shows the reason. It covers every
  monitor.
- **Ways to lock** (they all go through the same path, see below):
  - `Super + Escape`
  - **Lock** in the power menu (`Ctrl + Alt + Delete`)
  - being idle
  - closing the lid or suspending: it locks *before* the laptop sleeps
- **Idle handling** (before this phase there was none at all):

  | After | What |
  | --- | --- |
  | 5 min | lock |
  | 5.5 min | screen off (any key or mouse movement turns it on) |
  | 15 min | suspend |

  - Nothing happens while media is playing.
  - The ☕ button in the notification sidebar (`Super + N`) pauses all of it ("keep awake").
- **A recovery command** in case the lock screen ever misbehaves:
  `qs ipc -c my-first-shell call lock unlock`
- **A second C++ class** in your engine: `SessionWatcher`, which talks to systemd-logind.

## How it fits together

```
 Super + Escape ──▶ loginctl lock-session ─┐
 Power menu "Lock" ───────────────────────┤        system D-Bus
 lid / systemctl suspend ─▶ logind ────────┤ ──▶ SessionWatcher (C++, engine/)
                                           │      lockRequested / aboutToSleep
 Idle.qml (5 min) ─────────────────────────┼──────────────┐
 qs ipc … call lock lock ──────────────────┘              ▼
                                                 LockState.locked = true
                                                          │
                                       Lock.qml: WlSessionLock { locked: LockState.locked }
                                                          │ one per monitor
                                               LockSurface ─▶ LockContent (what you see)
                                                          │ you type, Enter
                                       PamContext (assets/pam.d/lock) ── pam_faillock + pam_unix
                                                          │ Success
                                                 LockState.locked = false ─▶ unlocked
```

## Files

| File | What it is | Caelestia equivalent |
| --- | --- | --- |
| `engine/src/sessionwatcher.hpp/.cpp` | logind on D-Bus: lock/unlock/sleep signals, sleep delay inhibitor, locked hint | `plugin/src/Caelestia/Services/sessionmanager.cpp` |
| `services/LockState.qml` | `locked`: the one switch everything flips | `lock.locked` inside `Lock.qml` |
| `modules/lock/Lock.qml` | `WlSessionLock`, `PamContext`, `SessionWatcher`, `IpcHandler` | `modules/lock/Lock.qml`, `Pam.qml` |
| `modules/lock/LockSurface.qml` | The per-monitor lock surface | `modules/lock/LockSurface.qml` |
| `modules/lock/LockContent.qml` | The picture: wallpaper, clock, avatar, password field | `modules/lock/Content.qml`, `Center.qml` |
| `assets/pam.d/lock` | How the password is checked | `assets/pam.d/passwd` |
| `modules/Idle.qml` | The idle steps | `modules/IdleMonitors.qml` |
| `config/Config.qml` | New `idle` section | `general.idle` in Caelestia's config |
| `services/ShellState.qml` | `keepAwake` | `services/IdleInhibitor.qml` |

Elsewhere:
- `~/.config/hypr/variables.lua`: `lockCmd = "loginctl lock-session"`.
- `misc.allow_session_lock_restore = true` was already set in `hyprland/misc.lua` (see
  [safety](#safety-what-if-it-breaks-while-locked)).
- `shell.json` gained:

  ```json
  "idle": { "lockAfter": 300, "screenOffAfter": 330, "suspendAfter": 900, "inhibitWhenPlaying": true }
  ```

## The session lock: `WlSessionLock`

An ordinary window can't lock a desktop: other windows could still draw over it, and
`Alt + Tab` would get past it. Wayland has a dedicated protocol, **ext-session-lock**:

1. A client asks to lock. The compositor (Hyprland) stops showing *every* other surface and
   sends *all* input only to the locker's surfaces.
2. Only that client can end the lock, by asking to unlock.
3. **If the locker crashes, the session stays locked** (Hyprland shows a plain error screen).
   It never "fails open" into your desktop.

In QML that's:

```qml
WlSessionLock {
    locked: LockState.locked     // true → lock; false → unlock
    onSecureChanged: if (secure) watcher.sleepReady()   // Hyprland confirmed: everything is covered
    LockSurface { lock: root }   // a *component*: one is created for every monitor
}
```

## Checking the password: PAM

PAM ("Pluggable Authentication Modules") is how Linux programs check passwords without
reading `/etc/shadow` themselves. A program names a **config**, a list of modules to run.
`PamContext` runs it as a conversation:

```qml
PamContext {
    config: "lock"
    configDirectory: Quickshell.shellPath("assets/pam.d")   // our own file, not /etc/pam.d
    onResponseRequiredChanged: if (responseRequired) { respond(root.buffer); root.buffer = ""; }
    onCompleted: result => result === PamResult.Success ? LockState.locked = false : /* show error */
}
```

1. You press Enter, and `pam.start()` begins the conversation.
2. `pam_unix` asks a question ("Password: "), so `responseRequired` becomes true.
3. We answer with what you typed and wipe the buffer straight away.
4. `completed(result)`: `Success` unlocks; anything else shows a message, turns the field
   red, shakes it, and clears it.

`assets/pam.d/lock` is your system's own rule set (`/etc/pam.d/system-auth`), written out:

```
auth  required                 pam_faillock.so  preauth    # refuse if locked out
auth  [success=1 default=bad]  pam_unix.so      nullok     # the actual password check
auth  [default=die]            pam_faillock.so  authfail   # count a failure
auth  required                 pam_faillock.so  authsucc   # success resets the count
```

> ⚠️ **faillock:** like hyprlock and your login, **3 wrong passwords within 15 minutes lock
> the account for 10 minutes**. During that time even the right password fails, and the lock
> screen shows faillock's message ("The account is locked…"). That's deliberate brute-force
> protection. Use the recovery command if you get stuck. Settings:
> `/etc/security/faillock.conf`; reset with `faillock --user $USER --reset`.

Why a private file instead of `auth include system-auth`? `include` is resolved by PAM in
`/etc/pam.d`, and doesn't reliably work from a custom config directory. Writing the four lines
out also makes it obvious exactly what the lock screen does.

### Typing

The lock surface has keyboard focus. `LockContent`'s `Keys.onPressed` hands every key to
`Lock.handleKey()`:
- **Enter:** submit.
- **Backspace:** delete one character; **Ctrl + Backspace:** delete all.
- **Escape:** clear the field.
- **Any printable character** is added, including non-Latin ones.

The password is never drawn. Only `buffer.length` is used, for the dots.

## logind and the C++ `SessionWatcher`

**systemd-logind** manages sessions, the lid, suspend and so on. It lives on the **system**
D-Bus (notifications were on the session bus). `SessionWatcher` connects to three of its
signals:

| logind signal | Sent when | We do |
| --- | --- | --- |
| `Session.Lock` | `loginctl lock-session` | lock |
| `Session.Unlock` | `loginctl unlock-session` | unlock |
| `Manager.PrepareForSleep(true/false)` | just before suspending / after waking | lock / re-arm the inhibitor |

`Super + Escape` doesn't call the shell directly: it runs `loginctl lock-session`, and logind
tells every interested program. That's the standard way, and anything else that locks
through logind works with our lock screen too.

**Finding our session:**
- Hyprland was started in your login session (`loginctl list-sessions` shows it as session 2
  on `tty1`), and the shell inherits `XDG_SESSION_ID=2`.
- `Manager.GetSession("2")` returns its D-Bus path, and we subscribe to that path's
  `Lock`/`Unlock`.

**Locking before sleep (the delay inhibitor):**
- **Without it:** you close the lid, logind suspends straight away, and the lock screen
  appears only after waking. Your desktop flashes up for a moment first.
- **So, at startup:** `Manager.Inhibit("sleep", …, "delay")` hands us a file descriptor.
  While we hold it, logind *waits* (up to 5 s, `InhibitDelayMaxSec`) before suspending.
- **On `PrepareForSleep(true)`:** we lock. When Hyprland confirms the lock is drawn
  (`secure`), `sleepReady()` closes the fd and the suspend continues.
- **After waking:** we take a new one.
- You can see it with `systemd-inhibit --list` (`my-first-shell … sleep … delay`).

`setLockedHint(bool)` tells logind whether we're locked (`loginctl show-session 2 -p LockedHint`).
Other tools can read this.

CMake: the class needed `Qt6::DBus` (`find_package(… DBus)` + `target_link_libraries`).

## Idle: `modules/Idle.qml`

Hyprland supports the **ext-idle-notify** protocol: a client says "tell me when the user has
been idle for N seconds", and the compositor answers `isIdle = true`, then `false` on the next
key or mouse movement. Each `IdleMonitor` is one such request.

```qml
Step { seconds: Config.idle.lockAfter;      onIdle: LockState.lock() }
Step { seconds: Config.idle.screenOffAfter; onIdle: dpms off;  onBack: dpms on }
Step { seconds: Config.idle.suspendAfter;   onIdle: systemctl suspend }
```

- **"Paused"** (`active` false): with keep-awake on, or while any player `isPlaying`.
- **Screen off** is `hl.dsp.dpms({ action = "disable" })`. Your `misc.key_press_enables_dpms`
  and `mouse_move_enables_dpms` already turn it back on.
- **Suspend** goes through logind, so `SessionWatcher` makes sure the lock screen is up first.

### Why `Step` wraps the monitor in a `Variants`

Testing showed that **`IdleMonitor` reads its `timeout` only when it starts**. The shell
starts before `shell.json` is read, so the monitors started with the default and never picked
up your values. The fix is to *recreate* the monitor whenever its time changes:

```qml
Variants {
    model: root.active && step.seconds > 0 ? [step.seconds] : []
    IdleMonitor { required property int modelData; timeout: modelData; ... }
}
```

A new value means a new model, which means a new monitor; `[]` means none. Pausing (`active`
false) removes the monitors, which also restarts the count when you unpause.

## Safety: what if it breaks while locked?

| Problem | What happens | Fix |
| --- | --- | --- |
| The shell crashes while locked | the session stays locked (Hyprland shows an error message) | restart the shell from a TTY (below). With `allow_session_lock_restore` the new shell can lock again, and then you unlock normally |
| Your password is refused for no reason | stays locked | the recovery command from a TTY |
| faillock locked the account | right password refused for 10 min | wait, or the recovery command |

**From a TTY:**
1. `Ctrl + Alt + F3`, then log in.
2. `export XDG_RUNTIME_DIR=/run/user/$(id -u)` (usually already set).
3. `qs ipc -c my-first-shell call lock unlock`.
   - If the shell is dead, ask Hyprland to start it (so it gets Hyprland's environment;
     `--instance 0` means "the first running Hyprland", since a TTY doesn't know which one):

     ```sh
     hyprctl --instance 0 dispatch 'hl.dsp.exec_cmd("QML2_IMPORT_PATH=$HOME/.config/quickshell/my-first-shell/engine/build/qml qs -c my-first-shell -n")'
     ```

     It locks again straight away (allowed by `allow_session_lock_restore`); then run the
     unlock command, or just unlock normally on the lock screen.
4. `Ctrl + Alt + F1` to go back.

The `IpcHandler` doesn't weaken anything: running it needs a shell as *you*, and someone
with that could already read your files or kill the locker.

## How to change it

| I want to… | Edit |
| --- | --- |
| Different idle times | `idle` in `~/.config/myshell/shell.json` (applies immediately; `0` = never) |
| Suspend never | `"suspendAfter": 0` |
| Lock even while music plays | `"inhibitWhenPlaying": false` |
| A profile picture | put a square image at `~/.face` |
| A different clock format | `Time.format("hh:mm")` in `LockContent.qml` |
| Fewer/more allowed wrong passwords | `deny =` in `/etc/security/faillock.conf` (system-wide, needs sudo) |

## Try it (10 minutes)

1. `Super + Escape`, type something wrong, Enter: red field, shake, "Wrong password". Then
   your real password.
2. Set `"lockAfter": 15` in `shell.json`, keep your hands off for 15 s, and it locks. Set it
   back to `300`.
3. In the sidebar turn on ☕, set `lockAfter` to 15 again: nothing happens. Turn ☕ off.
4. `systemd-inhibit --list | grep my-first-shell`: our sleep delay lock.
5. `loginctl lock-session` from a terminal, the same thing `Super + Escape` does. Then try
   `qs ipc -c my-first-shell call lock isLocked` from another TTY while it's locked.
6. Close the lid, open it: the lock screen is already there, with no flash of your desktop.

## Debugging

- **Does the shell see logind?** `qs log -c my-first-shell | grep SessionWatcher`: any warning
  there (no system bus, no session, no inhibitor) explains why `Super + Escape` or lid locking
  doesn't work.
- **Did logind send it?** `dbus-monitor --system "interface='org.freedesktop.login1.Session'"`
  and press `Super + Escape`.
- **Idle not triggering?** Is something playing (`busctl --user list | grep MediaPlayer2`), is
  ☕ on, or does a window block idle (`hyprctl clients -j | grep inhibitingIdle`)?
- **Lock screen locks but the password never works:** faillock? Run
  `faillock --user $USER` to see recent failures.

## Common errors

| Symptom | Cause |
| --- | --- |
| `IdleMonitor` never fires after changing the timeout | it only reads `timeout` at start: recreate it (the `Variants` trick) |
| `Cannot open: file:///home/…/.face` warnings | the Image is pointed at a missing file; `LockContent` checks with a `FileView` first |
| Dots stay after a failed attempt | the buffer was only cleared when PAM asked for the password; now also on failure |
| `Super + Escape` does nothing | the shell isn't running, or `SessionWatcher` couldn't find the session (see Debugging) |

## Completion notes

- **There was no idle daemon at all before this phase**: hypridle wasn't installed or
  configured, so nothing ever locked or turned off the screen by itself.
- **Safe testing:** the lock was first tested in a scratch copy with a 25-second automatic
  unlock and throwaway PAM files (`pam_permit`, always yes; `pam_deny`, always no). That way
  no real or wrong password was ever tried against your account, so faillock wasn't touched.
  The real shell was then tested with `loginctl lock-session`, then unlocked with the IPC
  command.
- **Screenshots work while locked** (grim could capture the lock screen), which made checking
  the design easy.
- **Bug found:** with `pam_deny`, PAM fails without ever asking for the password, so the
  dots stayed. The buffer is now also cleared on failure.
- **`IdleMonitor` timeout quirk:** found by testing (changing `timeout` did nothing; toggling
  `enabled` did). Hence `Step`.
- `playerctld` came back on its own (it's D-Bus activated when something calls `playerctl`).
  It's harmless: `Players.list` ignores it.
- **Not tested by me:** your real password (only you can), lid close / suspend (would put your
  laptop to sleep), and screen off by idle.
- **Not built** (compared with Caelestia): fingerprint/face unlock, notifications and weather
  on the lock screen, a blurred screenshot of the desktop as background, Caps Lock warning.
- `hyprlock` is no longer used. Once you're happy: `sudo pacman -Rs hyprlock`.
- **Your feedback (2026-10-04):**
  - **Dots right-aligned:** I had anchored them to the right on purpose. They now start on the
    left (`x: Math.min(0, parent.width - width)`) and only scroll left once the field is full.
  - **Keyboard dead after opening the lid** (mouse fine, both keyboards dead). This is **older
    than this shell**: the journal shows boots ending within a minute of a resume on 22, 28,
    30 and 31 Aug, 2 and 14 Sep, and twice on 4 Oct, while most resumes work fine.
    - **Ruled out from the logs:** no kernel errors on the failed resumes; the 13:50 one even
      ended in a clean shutdown (the power button), so the system was alive.
    - **NVIDIA** uses `NVreg_UseKernelSuspendNotifiers=1`, which is fine. Hyprland runs on the
      AMD GPU.
    - **Likely cause:** the internal keyboard (not USB) dies too, which points at keyboard
      *focus* in Hyprland, not the devices. While locked, keys go only to the lock surface; if
      it has no keyboard focus, they go nowhere.
    - **Not reproduced:** a screen off/on cycle kept focus; a real lid close wasn't tested by
      Claude.
    - **Hardening:** clicking anywhere on the lock screen, the window becoming active, and
      logind's "resumed" signal all call `forceActiveFocus()`.
    - **If it happens again:**
      1. Click the password field and type.
      2. If that doesn't help, `Ctrl + Alt + F3`, log in, and run
         `~/.config/quickshell/my-first-shell/scripts/resume-debug.sh`. It saves Hyprland's
         log (lost on reboot) to `~/resume-debug-*.txt`.
      3. Then `qs ipc -c my-first-shell call lock unlock`, and `Ctrl + Alt + F1`.
      4. If even the TTY has no keyboard, it's below Hyprland (kernel/firmware).
    - **Your old workaround:** `/etc/systemd/system/reset-input-devices-after-sleep.service`
      (from 28 Aug) re-plugs every USB keyboard/mouse after each resume. Its `atkbd` part does
      nothing (the driver is built in), and failures continued after it was installed.


## Check it

- [ ] `Super + Escape` locks; your password unlocks
- [ ] A wrong password: red field, shake, "Wrong password"; then the right one works
- [ ] Power menu → Lock works
- [ ] Close the lid, open it: locked, without a flash of the desktop; password works
- [ ] Leave it alone 5 min: it locks (or set `lockAfter` to something short to try)
- [ ] With a video playing, it doesn't lock
- [ ] ☕ in the sidebar pauses idle
- [ ] Know the recovery: `Ctrl + Alt + F3`, `qs ipc -c my-first-shell call lock unlock`

## Questions

<details><summary>1. Why is a crashed lock screen still locked, and why is that good?</summary>

With ext-session-lock the compositor, not the locker, decides what's shown. If the locker
dies, Hyprland keeps everything hidden instead of revealing the desktop. A crash can't be
used to get in.
</details>

<details><summary>2. Super + Escape runs <code>loginctl lock-session</code>. Why not call the shell directly?</summary>

It's the standard path: logind sends the `Lock` signal to whoever listens. The lid, `systemctl
suspend` and other tools use logind too, so everything ends up in the same place, and
`LockedHint` stays correct.
</details>

<details><summary>3. What would happen without the sleep delay inhibitor?</summary>

logind would suspend straight away. The lock screen would only be drawn after waking, so your
unlocked desktop would show for a moment when you open the lid.
</details>

<details><summary>4. You set <code>lockAfter</code> to 60 in shell.json. How does the running shell apply it?</summary>

`Config.idle.lockAfter` changes, so `Step`'s Variants model changes from `[300]` to `[60]`.
The old IdleMonitor is destroyed and a new one with `timeout: 60` is created.
</details>

<details><summary>5. Why is the password buffer cleared right after <code>respond()</code>?</summary>

So the password sits in memory as briefly as possible. PAM has it now, and nothing else needs
it.
</details>
