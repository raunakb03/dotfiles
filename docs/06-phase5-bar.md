# Phase 5: The bar

> **Status: 🔍 built 2026-10-03. Waiting for your check** (see [Check it](#check-it)).
> Implemented by Claude. This doc explains what was built so you can understand,
> change and debug it.

## What you got

Caelestia's vertical bar on the left edge of every monitor, replacing waybar:

```
┌────┐
│ ▲  │  OsIcon         Arch logo, tinted with m3primary
│(1) │  Workspaces     5 buttons per group, an animated pill on the active one
│ 2  │                 bold = has windows, dim = empty
│ 3  │                 click = go there, scroll = previous/next
│ 4  │
│ 5  │
│    │
│ z  │  ActiveWindow   the focused window's title, rotated 90°;
│ s  │                 takes all the free space, "…" when too long
│ h  │
│    │
│ ▣  │  Tray           background apps' icons: click = open, right-click = menu
│ 20 │  Clock          hours over minutes
│ 37 │
│ 🔊 │  StatusIcons    volume (click = mute, scroll = volume), Wi-Fi/Ethernet,
│ 📶 │                 Bluetooth, battery (red below 15% when not charging)
│ ᛒ  │
│ 🔋 │
└────┘
```

## How it fits together

```
 system                    services/ (singletons)        modules/bar/components/       modules/bar/Bar.qml
 ───────────               ─────────────────────         ───────────────────────       ───────────────────
 Hyprland IPC  ──────────▶ Hypr.qml ───────────────────▶ Workspaces, ActiveWindow ──┐
 Wayland toplevels ───────▶   (activeTitle)                                         │
 PipeWire  ──────────────▶ Audio.qml ──────────────────▶ StatusIcons ───────────────┤  ColumnLayout
 NetworkManager ─────────▶ Network.qml ────────────────▶ StatusIcons                ├─▶ in a PanelWindow
 UPower, BlueZ ──────────────(used directly)───────────▶ StatusIcons                │   anchored left
 StatusNotifier (tray) ──────(used directly)───────────▶ Tray                       │
 SystemClock ────────────▶ Time.qml (Phase 2) ─────────▶ Clock ─────────────────────┤
 /usr/share/pixmaps ─────────────────────────────────────▶ OsIcon ────────────────────┘
```

The same layering as Caelestia, and the reason it's split this way:
- **Services** talk to the system and expose clean properties (`Audio.muted`, `Network.strength`).
- **Components** only *display* those properties. They don't know what PipeWire or NetworkManager are.
- **`Bar.qml`** only *arranges* components.

To change *what's shown*, edit a component. To change *where data comes from*, edit a service. To change the *order*, edit `Bar.qml`.

## Files

| File | What it does | Caelestia equivalent |
| --- | --- | --- |
| `services/Hypr.qml` | Lua dispatch helper, workspace helpers, active window title | `services/Hypr.qml` |
| `services/Audio.qml` | default speaker: volume, mute | `services/Audio.qml` |
| `services/Network.qml` | current Wi-Fi network / Ethernet | `services/Nmcli.qml` (parses `nmcli`; we use `Quickshell.Networking`) |
| `modules/bar/Bar.qml` | the window plus the vertical layout | `modules/bar/Bar.qml` + `BarWrapper.qml` |
| `modules/bar/components/OsIcon.qml` | distro logo | `components/OsIcon.qml` |
| `modules/bar/components/Workspaces.qml` | workspace buttons + active pill | `components/workspaces/*` (6 files) |
| `modules/bar/components/ActiveWindow.qml` | vertical window title | `components/ActiveWindow.qml` |
| `modules/bar/components/Tray.qml` | system tray | `components/Tray.qml` + `TrayItem.qml` |
| `modules/bar/components/Clock.qml` | vertical clock | `components/Clock.qml` |
| `modules/bar/components/StatusIcons.qml` | volume, network, Bluetooth, battery | `components/StatusIcons.qml` |
| `config/Appearance.qml` | + `extraSmall` steps, `sizes.barInnerWidth` | `Tokens` (C++) |
| `config/Config.qml` | + `bar.workspaces.shown` | `Config.bar.workspaces` (C++) |
| `~/.config/hypr/…` | waybar removed from autostart | n/a |

Open each file next to this doc as you read: every file has comments, and the sections below explain the parts that aren't obvious.

---

## The window: `Bar.qml`

```qml
PanelWindow {
    anchors { top: true; bottom: true; left: true }
    implicitWidth: Appearance.sizes.barInnerWidth + Appearance.padding.small * 2
```
- **Three anchors make a vertical bar:** glued to top, bottom and left, so it's full height, and its width is our choice (32 + 2×8 = 48 px).
- **Exclusive zone:** a `PanelWindow` anchored to one edge automatically *reserves* its width, so Hyprland tiles windows next to it, never under it. (The wallpaper set `exclusionMode: Ignore` to opt out. The bar wants the default.)

```qml
    ColumnLayout {
        OsIcon { Layout.alignment: Qt.AlignHCenter }
        ...
        ActiveWindow { Layout.fillHeight: true }
```
- **`ColumnLayout`** (from `QtQuick.Layouts`) stacks children vertically like `Column`, but can also *stretch* them.
- **`Layout.fillHeight: true`** on `ActiveWindow`: "give this item all the height nobody else needs". That's what pushes the tray, clock and status icons to the bottom. Caelestia uses an explicit "spacer" entry for the same effect.
- **`Layout.alignment: Qt.AlignHCenter`:** centre each item horizontally.
- **`Layout.*` vs `anchors`:** inside a layout, use `Layout.*` properties. Anchors fight with the layout.

## Talking to Hyprland: `Hypr.qml`

```qml
function focusWorkspace(id: var): void {
    dispatch(`hl.dsp.focus({ workspace = "${id}" })`);
}
```
- `Hyprland.dispatch(…)` sends a command over Hyprland's IPC socket, the same as `hyprctl dispatch`. **With a Lua config, the command is a Lua expression**, exactly what you'd write in `keybinds.lua`. Caelestia checks `Hyprland.usingLua` and supports both formats. We only use Lua.
- `"r+1"` / `"r-1"` = relative: the next/previous workspace.

```qml
Component.onCompleted: {
    Hyprland.refreshMonitors(); Hyprland.refreshWorkspaces(); Hyprland.refreshToplevels();
}
```
- **Quickshell learns about Hyprland mostly from *events*** (a window opened, focus changed…). Some information isn't filled in until the first event. Asking for a full refresh at startup fills it in immediately.

```qml
readonly property string activeTitle: (Hyprland.focusedWorkspace?.toplevels.values.length ?? 0) > 0
    ? (ToplevelManager.activeToplevel?.title ?? "") : ""
```
- **Why not `Hyprland.activeToplevel.title`?** Tested on 2026-10-03: even after a refresh, it stayed empty until the focus changed once. `ToplevelManager` (from `Quickshell.Wayland`, the standard Wayland "foreign toplevel" protocol) knew the title about a second after start.
- **Why check the workspace first?** `ToplevelManager` remembers the last focused window even when you switch to an empty workspace. Caelestia uses the same check to show "Desktop" there.

```qml
function isOccupied(id: int): bool {
    const ws = Hyprland.workspaces.values.find(w => w.id === id);
    return (ws?.toplevels.values.length ?? 0) > 0;
}
```
- `Hyprland.workspaces` is a list model. `.values` gives a plain JavaScript array, so `.find()` works.
- `?.` / `??` again: no such workspace → `undefined` → 0.

## Workspaces: `Workspaces.qml`

```qml
readonly property int activeId: Hypr.monitorFor(screen)?.activeWorkspace?.id ?? 1
readonly property int groupOffset: Math.floor((activeId - 1) / shown) * shown
readonly property int activeIndex: (activeId - 1) % shown
```
- **Per monitor:** each bar shows its *own* monitor's active workspace (`monitorFor(screen)`).
- **Groups:** with `shown = 5`, workspace 7 is in group 2 (6–10), so the buttons read 6 7 8 9 10 and the pill sits on index 1. It's the same grouping as your `Ctrl + Super + number` binds, except those use groups of 10.

```qml
Repeater {
    model: root.shown            // a number: create this many delegates
    Item {
        required property int index
        readonly property int wsId: root.groupOffset + index + 1
```
- **`Repeater`** creates one delegate per model entry. With a *number* as the model, `index` runs 0…n-1.

```qml
StyledRect {   // the pill
    y: Appearance.padding.extraSmall + root.activeIndex * (root.buttonSize + column.spacing)
    Behavior on y { Anim { … emphasizedDecel } }
}
```
- **One pill that moves,** rather than one per button. `y` is computed from the active index, and the `Behavior` slides it there. It's declared *before* the `Column`, so it's drawn *behind* the numbers.
- **Colour rules:** active = `m3onPrimary` (readable on the primary pill), occupied = `m3onSurface` + bold, empty = `m3outline` (dim).
- **`WheelHandler`:** scroll over the pill → `r-1` / `r+1`. `angleDelta.y > 0` means scrolling up.

## Window title: `ActiveWindow.qml`

```qml
Item {
    implicitWidth: label.implicitHeight
    StyledText {
        anchors.centerIn: parent
        rotation: 90
        width: Math.min(implicitWidth, root.height)
        elide: Text.ElideRight
```
- **Rotation swaps the axes in your head, not in the layout.** The text is laid out horizontally, then drawn rotated around its centre. So the text's `width` is what ends up running *down* the bar, and its height becomes the bar-direction thickness. Hence `implicitWidth: label.implicitHeight`.
- `width: Math.min(implicitWidth, root.height)`: as long as the title fits, use its natural length. Otherwise limit it to the available height, and `elide` adds "…".

## Status icons: `StatusIcons.qml` + `Audio.qml` + `Network.qml`

**Audio** (`Quickshell.Services.Pipewire`):
```qml
readonly property PwNode sink: Pipewire.defaultAudioSink
PwObjectTracker { objects: [root.sink] }
```
- **`PwObjectTracker` is required:** PipeWire nodes only report live properties (volume, mute) while something *tracks* them. Without it, `sink.audio.volume` stays 0. Caelestia does the same.
- `setVolume()` clamps to 0–1 and unmutes. The volume icon's `MouseArea` uses `onClicked` (mute) and `onWheel` (±5%).

**Network** (`Quickshell.Networking`):
- `Networking.devices.values` = your network devices. For each Wi-Fi device (`DeviceType.Wifi`), find the network with `connected`.
- **`signalStrength` is 0–1** (it read 0.74 while `nmcli` said 100). The icon maps it to 1–4 bars: `signal_wifi_4_bar`, `network_wifi_3_bar`…
- Caelestia parses `nmcli` output in `Nmcli.qml`. Quickshell 0.3.1's built-in Networking module talks to NetworkManager directly, so there's no text parsing.

**Bluetooth** (`Quickshell.Bluetooth`): `Bluetooth.defaultAdapter.enabled` plus whether any device is `connected`.

**Battery** (`Quickshell.Services.UPower`):
- `UPower.displayDevice` is the combined battery. `percentage` is 0–1. `state === UPowerDeviceState.Charging` → charging icon.
- `visible: isLaptopBattery` hides the icon on a desktop PC.
- Red (`m3error`) below 15% when not charging.

**Icon names** are Material Symbols ligatures (Phase 3), e.g. `` `battery_${level}_bar` `` builds `battery_5_bar` with a JavaScript template string.

## Tray: `Tray.qml`

- `SystemTray.items`: apps that registered a tray icon (the StatusNotifierItem protocol).
- `IconImage` (from `Quickshell.Widgets`) understands the special `image://icon/…` URLs tray items use.
- Left click → `activate()`. Right click → `display(window, x, y)` shows the app's own menu at that position. Caelestia instead draws the menu itself in a popout (we'll do that in Phase 6).
- `visible: … length > 0`: the pill disappears when there are no tray apps.

## Logo: `OsIcon.qml`

```qml
Image { id: logo; source: "file:///usr/share/pixmaps/archlinux-logo.svg"; visible: false }
MultiEffect { source: logo; colorization: 1; colorizationColor: Colours.palette.m3primary }
```
- The Arch package ships its logo as an SVG. `/etc/os-release` names it (`LOGO=archlinux-logo`).
- **`MultiEffect`** (from `QtQuick.Effects`) draws `logo` recoloured. `colorization: 1` = fully tinted. The original `Image` is hidden, so only the effect is drawn.
- `sourceSize` at 2× renders the SVG sharply. SVGs have no fixed size.

---

## How to change it

| I want to… | Edit |
| --- | --- |
| show 10 workspace buttons instead of 5 | add `"workspaces": { "shown": 10 }` inside `"bar"` in `~/.config/myshell/shell.json` (live) |
| make the bar wider or narrower | `sizes.barInnerWidth` in `config/Appearance.qml` |
| reorder or remove items | the order of children in `modules/bar/Bar.qml` |
| change the volume scroll step | `0.05` in `StatusIcons.qml` |
| show the clock in 12-hour format | `"hh"` → `"h"` in `Clock.qml` (and add `AP` somewhere) |
| use a different logo | `source:` in `OsIcon.qml` (any image file; it gets tinted) |
| add a new status icon | add a `MaterialIcon` to the `Column` in `StatusIcons.qml`. If it needs system data, add a property to a service rather than reading the system in the component |

## Try it (10 minutes)

1. **Move the pill:** press `Super + 3`, then `Super + 1`, and watch the pill slide. Scroll over the workspace numbers.
2. **Groups:** press `Super + 7`. The buttons change to 6–10.
3. **Live settings:** add `"workspaces": { "shown": 3 }` to the `"bar"` object in `~/.config/myshell/shell.json`, save, watch it change, then remove it.
4. **Volume:** scroll over the speaker icon, then click it (mute). Check in `pavucontrol` that it really changed.
5. **Break it:** delete the `PwObjectTracker` block from `services/Audio.qml`, save, and look at the volume icon (always "mute"). Undo with `git checkout services/Audio.qml`. Now you know what the tracker is for.
6. **Theme:** run `scripts/set-wallpaper.py ~/raunak/Wallpapers/berries-1.jpg` and watch the logo, pill and clock turn peach.
7. **Layout:** in `Bar.qml`, move `Clock { … }` above `OsIcon`. Undo with `git checkout modules/bar/Bar.qml`.

## Debugging

- **Logs:** `qs log -c my-first-shell -f` (the shell runs in the background since Phase 4).
- **What does Quickshell see?** Temporarily add to any component:
  ```qml
  Component.onCompleted: console.log("volume", Audio.volume, "wifi", Network.name)
  ```
- **Hyprland side:** `hyprctl workspaces`, `hyprctl activewindow`, `hyprctl clients`.
- **Network side:** `nmcli dev wifi` (`ACTIVE`, `SIGNAL`).
- **Restart** after installing fonts or changing environment variables: `Ctrl + Super + Alt + R`.

## Common errors

| Symptom | Likely cause |
| --- | --- |
| Title shows "Desktop" while a window is focused | `ToplevelManager` not ready yet (the first second after start), or `activeTitle` changed back to `Hyprland.activeToplevel` |
| Volume icon always "mute" / volume 0 | `PwObjectTracker` missing in `Audio.qml` |
| Wi-Fi icon shows 0 bars while connected | `signalStrength` treated as 0–100. It's 0–1 |
| Clicking a workspace does nothing | Dispatch not in Lua syntax. Test with `hyprctl dispatch 'hl.dsp.focus({ workspace = "3" })'` |
| Windows go under the bar | The bar's anchors changed. It needs exactly top + bottom + left for its exclusive zone |
| Two bars | The old one is still running. Use `Ctrl + Super + Alt + R` |
| Tray right-click menu doesn't open | That app has no menu (`hasMenu` false), so it gets `secondaryActivate()` instead |

## Completion notes

Problems found while building (2026-10-03), and their fixes:
- **Window title empty at startup:** `Hyprland.activeToplevel` stayed `undefined` until a focus change, even after `refreshToplevels()`. Tested side by side: `ToplevelManager.activeToplevel` had the title after ~1 s. **Fix:** `Hypr.activeTitle` uses `ToplevelManager`.
- **Logo came out white:** `MultiEffect { brightness: 1 }` washed out the colourisation. **Fix:** removed `brightness`.
- **`signalStrength` scale:** confirmed 0–1 (0.74 while `nmcli` reported 100).
- **`list<NetworkDevice>` property:** made a plain `var`, since model values don't always convert to typed lists.
- **Hyprland:** waybar removed from `variables.lua` and `execs.lua`. The shell's autostart moved out of the "TEMPORARY" block.
- **Not done (later phases):** popouts on hover (audio, network, battery details, tray menus) → Phase 6. The power button → Phase 8 (session menu). App-specific window icons.

Commits (`my-first-shell`):
1. "bar sizes, extraSmall tokens, workspaces setting"
2. "Hypr, Audio and Network services"
3. "bar components"
4. "vertical bar on the left edge"

`~/.config/hypr`: "retire waybar", "tidy execs comments".

## Check it

Before this phase is marked complete, please check on your desktop:
- [ ] The bar is on the left, and windows tile next to it (not under it)
- [ ] Clicking and scrolling workspaces works, and the pill slides
- [ ] The title follows the focused window and shows "Desktop" on an empty workspace
- [ ] Volume click/scroll works. Wi-Fi, Bluetooth and battery icons look right
- [ ] Tray icon: left click and right click work
- [ ] After the next login, the bar starts by itself (and waybar doesn't)

## Questions

1. Why does `Workspaces.qml` draw **one** pill that moves, instead of giving each button its own background that turns on and off?
2. `ActiveWindow` has `implicitWidth: label.implicitHeight`. Why height for width?
3. What would break if `StatusIcons.qml` read `Pipewire.defaultAudioSink.audio.volume` directly instead of `Audio.volume`?
4. Why does the bar push windows aside, while the wallpaper (also a full-height `PanelWindow`) doesn't?

<details>
<summary>Answers</summary>

1. So it can **animate between positions**. A single item with an animated `y` slides smoothly from button to button. Separate backgrounds could only fade in and out in place.
2. The label is rotated 90°. Its *height* (the line thickness) becomes the space it takes **across** the bar, and its *width* (the text length) runs **along** the bar.
3. Two things. Nothing would be tracking the node (no `PwObjectTracker`), so the value would stay 0. And the component would be tied to PipeWire details. Going through the service keeps the tracking in one place, and if the audio source changes, only `Audio.qml` changes.
4. **Exclusive zones.** A panel anchored to one edge reserves its size by default. The wallpaper sets `exclusionMode: ExclusionMode.Ignore` and is on the Background layer.

</details>
