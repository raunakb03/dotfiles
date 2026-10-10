# Phase 8: Notifications, sidebar, OSD, session menu

> **Status: ✅ completed 2026-10-04** (checked by you).
> Implemented by Claude. This doc explains what was built so you can understand,
> change and debug it.

## What you got

Four new panels, all in the same drawer window as the bar, the popouts and the launcher,
all sliding out of an edge with the same curved joins:

| Panel | Opens | What it does |
| --- | --- | --- |
| **Notification popups** | when an app sends one | Cards grow down from the top edge, next to the bar. They hide after 5 s (or the app's own timeout), but stay while the mouse is on them. *Critical* ones (red outline) stay until dismissed. |
| **Sidebar** | `Super + N` | The history: every notification, newest first. Do-not-disturb switch, ✕ per card, "Clear all". |
| **OSD** | volume / brightness keys | Two vertical bars (volume, brightness) slide out of the bar's middle, then hide 1.5 s after the last change. |
| **Session menu** | `Ctrl + Alt + Delete` | Lock, log out, suspend, restart, shut down. Arrow keys + Enter, or click. Escape or a click outside closes it. |

The shell also took over the **brightness keys** and the **media keys**
(play/pause/next/previous/stop). **dunst** (the old notification program) and
**playerctld** are no longer used.

```
                                 top edge
            ┌─────────────────────────╮─────┐
            │ ╭─────────────────────╮ │     │
            │ │ 🔔 Discord · now  ✕ │ │  A  │ ← popups: grow down from the top
            │ │ Aman                │ │  1  │
            │ │ Coming at 5?        │ │  2  │
            │ ╰─────────────────────╯ │     │
            ╰─────────────────────────┤     │
                                 ╭────┤     │
                                 │ ▐▌ │     │ ← OSD (or the session menu):
                                 │ ▐▌ │ bar │   out of the bar, vertically centred
                                 ╰────┤     │
                                      │     │
```

## How it fits together

```
 app ──D-Bus──▶ NotificationServer (services/Notifs.qml)
                    │  each notification → an Entry (text copied, popup flag, timer)
                    ▼
               Notifs.list ───────────────▶ Sidebar.qml (history, Super + N)
               Notifs.popups (popup=true) ─▶ Popups.qml (top corner)
                             both draw ──▶ NotificationCard.qml

 volume key ─▶ wpctl (Hyprland) ─▶ PipeWire ─▶ Audio.volume changes ─┐
 brightness key ─▶ global myshell:brightnessUp ─▶ Brightness.qml ─────┼▶ OsdState.qml ─▶ Osd.qml
                                                  (brightnessctl)      │  (visible for 1.5 s)
 media key ─▶ global myshell:mediaToggle ─▶ Players.qml ─▶ MPRIS ─▶ Spotify / browser / mpv

 Ctrl+Alt+Delete ─▶ global myshell:session ─▶ ShellState.sessionScreen ─▶ Session.qml
 Super + N       ─▶ global myshell:sidebar ─▶ ShellState.sidebarScreen ─▶ Sidebar.qml
```

## Files

| File | What it is | Caelestia equivalent |
| --- | --- | --- |
| `services/Notifs.qml` | The notification server and the list of entries | `services/Notifs.qml`, `services/NotifData.qml` |
| `services/Brightness.qml` | Laptop brightness via `brightnessctl` | `services/Brightness.qml` (also does external monitors with `ddcutil`) |
| `services/Players.qml` | Media players via MPRIS | `services/Players.qml` |
| `services/OsdState.qml` | When the OSD shows | inside `modules/osd/Wrapper.qml` |
| `services/ShellState.qml` | Now also `sidebarScreen`, `sessionScreen`, `closeAll()` | `services/Visibilities.qml` |
| `components/AttachedBackground.qml` | Background for any panel touching an edge | the `Background.qml` in each module |
| `modules/notifications/NotificationCard.qml` | One notification card | `modules/notifications/Notification.qml` |
| `modules/notifications/Popups.qml` | The popup stack | `modules/notifications/Content.qml` |
| `modules/sidebar/Sidebar.qml` | The history | `modules/sidebar/` |
| `modules/osd/Osd.qml` | Volume + brightness bars | `modules/osd/Content.qml` |
| `modules/session/Session.qml` | The power menu | `modules/session/Content.qml` |
| `modules/drawers/ContentWindow.qml` | Hosts all of the above | `modules/drawers/Panels.qml` |
| `modules/Shortcuts.qml` | 8 new global shortcuts | `modules/Shortcuts.qml` |

Hyprland side (`~/.config/hypr`):
- `variables.lua`: `kbSidebar = "SUPER + N"`, `kbSession = "CTRL + ALT + Delete"`.
- `hyprland/keybinds.lua`: those two binds, and the brightness and media keys now call
  `hl.dsp.global("myshell:…")` instead of `brightnessctl` / `playerctl`. The volume keys
  still run `wpctl` (see [the OSD](#the-osd-servicesosdstateqml-modulesosdosdqml) for why).
- `hyprland/execs.lua`: `playerctld daemon` removed.

Outside both repos: `systemctl --user mask dunst` (see below).

## Being the notification server: `services/Notifs.qml`

Apps don't draw their own notifications. They send them over D-Bus to whoever owns the name
**`org.freedesktop.Notifications`**. Only one program can own it. Until now that was
**dunst**: it was never in your autostart, but D-Bus *started it on demand* the first time an
app sent a notification (`/usr/share/dbus-1/services/org.knopwob.dunst.service`).

`NotificationServer` (from `Quickshell.Services.Notifications`) claims that name. If someone
else has it, Quickshell logs `Could not register notification server … one is already
registered` and tries again when it's released. That's why dunst is now **masked**:

```sh
systemctl --user mask dunst      # done: D-Bus can't start dunst any more
systemctl --user unmask dunst    # undo (e.g. if you ever stop using this shell)
```

Without the mask, an app sending a notification *before* the shell has started at login
would bring dunst back, and the shell would never get the name.

```qml
NotificationServer {
    actionsSupported: true     // tell apps they may send buttons
    imageSupported: true       // and pictures
    bodyMarkupSupported: false // we show the body as plain text
    persistenceSupported: true // we keep a history
    keepOnReload: false

    onNotification: notification => {
        notification.tracked = true; // otherwise Quickshell drops it straight away
        const entry = entryComponent.createObject(root, { notification, popup: !root.dnd && !root.sidebarOpen });
        root.list = [entry, ...root.list];
    }
}
```

The "supported" flags are *advertised* to apps (`notify-send` doesn't care, but Firefox,
Discord, etc. send different things depending on them).

### Why an `Entry` copies the text

A `Notification` object lives only as long as the app keeps the notification open. When the
app closes it (or it expires on the app's side), the object is destroyed and its `summary`,
`body` and so on are gone. The history must still show it, so each `Entry` **copies** the
fields in `update()`, re-copies if the app changes them (e.g. download progress), and on
`closed` just sets `notification = null`. After that the text stays, but the action buttons
stop working (`actions` comes from the live object), which is the correct behaviour.

Caelestia does the same thing, plus it saves the list to `notifs.json` so the history
survives a restart. Ours doesn't (yet): after a restart the history is empty.

### The popup timer

```qml
readonly property Timer timer: Timer {
    running: entry.popup && !entry.hovered && entry.urgency !== NotificationUrgency.Critical
    interval: (entry.notification?.expireTimeout ?? 0) > 0 ? entry.notification.expireTimeout : root.defaultTimeout
    onTriggered: entry.popup = false
}
```

- `popup = false` only **hides the popup**. The entry stays in `list`, so it's in the history.
- `running` is a binding: hovering the card (`hovered`, set by the card's `HoverHandler`)
  stops the timer, and leaving restarts it from zero.
- `expireTimeout` is what the app asked for (`notify-send -t 10000`); `-1`/`0` means "your
  choice", so we use 5 s.

`Notifs.popups` is just `list.filter(n => n.popup)`, and `Popups.qml` shows a card per item.
Do not disturb (`dnd`) only affects *new* entries: they're created with `popup: false`.

### Dismiss vs hide

| Action | What happens |
| --- | --- |
| Popup times out, or click a card without a default action | `popup = false`: hidden, still in history |
| ✕ on a card, or click a card in the sidebar | `Notifs.dismiss()`: `notification.dismiss()` tells the app, then the entry is removed and destroyed |
| Click a card that has a "default" action | runs it (usually "focus the app"), then dismisses |
| An action button ("Open", "Reply") | `action.invoke()`, then dismisses |

## The card: `NotificationCard.qml`

- **Picture:** `entry.image` (a contact photo, an album cover…) or else `entry.appIcon`.
  Quickshell hands icon *names* over as `image://icon/discord`. If the theme has no such icon,
  that draws a checkerboard, so `iconSource()` unwraps the name and calls
  `Quickshell.iconPath(name, true)`, which returns "" when missing, and the card shows a bell.
- **Age** ("now", "5m", "2h") is computed from `Time.date`, which already ticks every second
  for the clock, so it updates without its own timer.
- **Critical** urgency (`urgency === 2`) draws an `m3error` border.
- **Action buttons:** a `Repeater` over `entry.actions`, skipping the one with identifier
  `"default"`. By convention that one isn't a button: it's what clicking the card does.

## One background for every edge: `AttachedBackground.qml`

The popouts and the launcher each had their own background file, because each touches a
different edge. Four more panels would mean four more, so this component works it out:

```qml
readonly property bool touchRight: barOnRight && Math.abs(panelRight - barEdge) < 1
readonly property bool touchTop: panelTop < 1
...
topRightRadius: root.touchTop || root.touchRight ? 0 : root.r   // square where it meets an edge
InvertedCorner { visible: root.touchRight && !root.touchTop; ... } // curved join to the bar
```

- **Popups:** touch the top edge and the bar, so they get square top/right corners, a join on
  the top edge (left of the panel) and a join under the panel against the bar.
- **Sidebar:** touches the top, the bottom and the bar.
- **OSD and session menu:** touch only the bar, so they get rounded outer corners and joins
  above and below.

(The properties are called `panelLeft`/`panelTop`… because `left`, `top` etc. already exist
on every Item: they're the anchor lines.)

## The OSD: `services/OsdState.qml`, `modules/osd/Osd.qml`

`OsdState` listens for changes rather than key presses:

```qml
Connections {
    target: Audio
    function onVolumeChanged(): void { root.show(); }
    function onMutedChanged(): void { root.show(); }
}
```

That's why the **volume keys didn't need to change**: they still run `wpctl`, PipeWire
reports the new volume, `Audio.volume` changes, and the OSD shows. It also shows when you
change the volume any other way (pavucontrol, the bar's audio popout…).

Brightness is different. Nothing tells us when the backlight changes (the sysfs file can't
be watched), so **the shell itself changes it**. The keys call `myshell:brightnessUp`,
`Brightness.set()` runs `brightnessctl set N%`, and it bumps a `changes` counter that
`OsdState` watches. (A counter, not `value`, so pressing "up" at 100% still shows the OSD.)

Two details:
- **`ready` timer:** at startup PipeWire and brightnessctl report their first values, which
  look like changes. `show()` ignores everything in the first 2 s.
- **Display only:** the OSD isn't in the window's `mask`, so clicks go through it.

## Media keys: `services/Players.qml`

MPRIS is the D-Bus interface media players offer (Spotify, Firefox/Zen tabs, mpv, VLC…).
`Quickshell.Services.Mpris` lists them; `Players.active` picks one that is playing, otherwise
the first. That's what `playerctld` used to do, so it's gone from autostart. (If it ever runs,
it shows up as a fake player; `Players.list` filters it out.) Phase 9's dashboard media
panel will build on this service.

## The session menu: `Session.qml`

- Each action is `{icon, name, command}` and is run with `Quickshell.execDetached(command)`:
  `hyprlock`, `hyprctl dispatch hl.dsp.exit()`, `systemctl suspend|reboot|poweroff`.
  No confirmation step: opening the menu on purpose *is* the confirmation.
- **Keyboard:** while it's open the window uses `WlrKeyboardFocus.OnDemand` (as for the
  launcher), and `onOpenChanged` calls `column.forceActiveFocus()` so the arrow keys reach
  `Keys.onUpPressed` and the others. Hovering also moves the highlight, so the mouse and
  keyboard never disagree.
- The highlighted button turns from a circle into a rounded square (`radius` animates).

## Changes to the drawer window

```qml
readonly property bool panelShowing: launcherOpen || sidebarOpen || sessionOpen || popups.height > 0 || osd.width > 0
WlrLayershell.layer: panelShowing ? WlrLayer.Overlay : WlrLayer.Top
```

The Phase 7 fix generalised: **anything showing lifts the window above fullscreen apps**.
A notification or the OSD over a fullscreen video is visible. The bar comes along for that
moment, since it's in the same window, and goes away again when the panel closes.

- **Mask:** `popups`, `sidebar` and `session` were added. The OSD wasn't.
- **Focus grab:** active for the launcher, sidebar or session menu. A click outside calls
  `ShellState.closeAll()`.
- **Popups** only show on the focused monitor, and not while that monitor's sidebar is open.
  Opening the sidebar also hides all popups (they're all in the list you're now looking at).

## How to change it

| I want to… | Edit |
| --- | --- |
| Popups stay longer | `defaultTimeout` in `services/Notifs.qml` |
| Wider cards | `notificationWidth` in `config/Appearance.qml` |
| Popups at the bottom instead | `Popups.qml`: `y: parent.height - height`, and anchor the `Column` to the top |
| OSD stays longer | `interval: 1500` in `services/OsdState.qml` |
| Bigger brightness steps | `increase()`/`decrease()` in `services/Brightness.qml` (0.05 = 5%) |
| Another session action (e.g. hibernate) | add `{ icon: "downloading", name: "Hibernate", command: ["systemctl", "hibernate"] }` to `actions` in `Session.qml` |
| Different keys | `kbSidebar` / `kbSession` in `~/.config/hypr/variables.lua` |

## Try it (10 minutes)

1. `notify-send "Hello" "World"` → a popup, gone after 5 s; it's still in `Super + N`.
2. `notify-send -t 15000 "Slow"` → stays 15 s. Hover a popup: it doesn't go away until you
   leave it.
3. `notify-send -u critical "Important"` → red outline, never times out.
4. `notify-send -A yes=Yes -A no=No "Choose"` → the terminal waits; click **Yes** and it prints
   `yes`. That's the action going back to the app.
5. Turn on do-not-disturb in the sidebar, send one: no popup, but the count goes up.
6. In `Osd.qml` change `Appearance.sizes.osdHeight` to `300` → save → press a volume key.
7. In `Session.qml` swap two entries in `actions` → save → `Ctrl + Alt + Delete`.
8. Play something in the browser, press play/pause. Then
   `qs log -c my-first-shell` is quiet: no `playerctl` needed.

## Debugging

- **Who owns notifications?**
  `busctl --user status org.freedesktop.Notifications | grep Comm=` should print `Comm=qs`.
  If it says `dunst`, check `systemctl --user is-enabled dunst` (should be `masked`) and
  restart the shell.
- **The shortcut does nothing:** `hyprctl globalshortcuts | grep myshell` should list 11. If
  some are missing, restart the shell (`Ctrl + Super + Alt + R`); hot reload doesn't
  re-register shortcuts.
- **Media keys do nothing:** is there a player?
  `busctl --user list | grep MediaPlayer2` (the browser only appears while a tab plays media).
- **Brightness keys do nothing:** run `brightnessctl set 50%` yourself. If that fails, the
  problem is brightnessctl (permissions), not the shell.

## Common errors

| Symptom | Cause |
| --- | --- |
| `Could not register notification server … already registered` | dunst (or mako, swaync…) owns the name: stop and mask it |
| Checkerboard instead of an app icon | an `image://icon/<name>` the theme doesn't have: unwrap it and use `iconPath(name, true)` |
| `Cannot override FINAL property` on `left`/`top` | those are an Item's anchor lines; pick other names |
| `X is not a type` for a file in another module folder | add `import qs.modules.<folder>` (the sidebar needs `qs.modules.notifications`) |
| A service and a module both called `Osd` | the later import wins and the other "disappears"; the service is `OsdState` |
| Popups/OSD invisible in a fullscreen app | the window must be on the Overlay layer while they show |

## Completion notes

- **dunst** was D-Bus activated (not in any autostart), so it had to be masked, not just
  stopped. Undo with `systemctl --user unmask dunst`.
- **`notify-send -A …` blocks** until an action is clicked, which froze a test script. Run it
  in the background (`… &`).
- **Name clash:** `services/Osd.qml` and `modules/osd/Osd.qml`, renamed to `OsdState`
  (the same lesson as `Network` → `NetworkService` in Phase 6).
- **FINAL properties:** `AttachedBackground` first used `left/right/top/bottom`, renamed to
  `panelLeft`/… (the same as `InvertedCorner` in Phase 6).
- **Checkerboard Discord icon:** Quickshell turns icon names into `image://icon/…`.
- **Popups hidden behind a fullscreen terminal:** extended the Phase 7 Overlay fix to
  everything that shows (`panelShowing`).
- `grim -g` takes **logical** coordinates (your screen is 1440×810 logical at scale 1.33),
  which matters for test screenshots.
- Tested: popups (plain, with actions, critical, missing icon), sidebar, OSD (volume and
  brightness, restored afterwards), session menu (opened and closed only, nothing clicked),
  over a fullscreen window; 11 global shortcuts registered; `hyprctl configerrors` empty.
- Not built (compared with Caelestia): history saved across restarts, grouping by app,
  inline replies, ddcutil for external monitors, a bar button for the sidebar.

## Check it

- [x] `notify-send "Hi" "there"` shows a popup at the top right, which goes after ~5 s
- [x] A real app's notification (Discord, browser download…) shows with its icon
- [x] `Super + N` opens the history; ✕ and "Clear all" work; do-not-disturb stops popups
- [x] Volume keys show the OSD; holding a key keeps it open, then it hides
- [x] Brightness keys change the brightness **and** show the OSD (holding one repeats)
- [x] Play/pause/next on your keyboard control a playing browser video or music
- [x] `Ctrl + Alt + Delete` opens the power menu; ↑/↓ move, Escape closes;
      **Lock** works (try only Lock and maybe Suspend)
- [x] After your next reboot: notifications still come from the shell (no dunst)

## Questions

<details><summary>1. You click ✕ on a popup. Is it still in the sidebar? And if the popup just times out?</summary>

✕ calls `Notifs.dismiss()`: removed from the list, gone everywhere. A timeout only sets
`popup = false`, so it stays in the history.
</details>

<details><summary>2. Why do the volume keys still run wpctl, while the brightness keys go through the shell?</summary>

PipeWire tells the shell when the volume changes (`Audio.volume` is a live property), so the
OSD can react to any change. Nothing reports backlight changes, so the shell has to make the
change itself to know it happened.
</details>

<details><summary>3. An app closes its notification. Why does the sidebar still show the text?</summary>

The `Entry` copied the text when it arrived. Only `entry.notification` becomes null, so the
action buttons stop working but the text stays.
</details>

<details><summary>4. What would happen without <code>systemctl --user mask dunst</code>?</summary>

If any app sends a notification before the shell has started (or while it's restarting),
D-Bus starts dunst, dunst owns the name, and the shell only gets it back when dunst exits.
</details>

<details><summary>5. Why doesn't the OSD block clicks on the window behind it?</summary>

It's not in the drawer window's `mask`, so that area of the window takes no input.
</details>
