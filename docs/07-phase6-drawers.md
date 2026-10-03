# Phase 6: Drawers & popouts

> **Status: 🔍 built 2026-10-03. Waiting for your check** (see [Check it](#check-it)).
> Implemented by Claude. This doc explains what was built so you can understand,
> change and debug it.

## What you got

Caelestia's signature look: a **frame** around the screen with rounded inner corners,
merged with the bar. And **popouts** that slide out of the bar when you hover the
status icons:

```
┌──────────────────────────────────────────────────────┬────┐
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│ ▲  │
│▓ ╭────────────────────────────────────────────────╮ ▓│(1) │  ▓ = frame (surface colour)
│▓ │                                                │ ▓│ 2  │
│▓ │            your windows / wallpaper            │ ▓│ …  │
│▓ │                                    ╭──────────╮│ ▓│    │
│▓ │                                    │ Wi-Fi  ◉ ├┘ ▓│ 📶 │◀── hover
│▓ │                                    │ ▸ Home   │   ▓│    │
│▓ │                                    │   Next…  ├┐ ▓│    │
│▓ │                                    ╰──────────╯│ ▓│    │
│▓ ╰────────────────────────────────────────────────╯ ▓│ 🔋 │
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│    │
└──────────────────────────────────────────────────────┴────┘
                                    popout slides out of the bar,
                                    joined to it with curved "fillets" (├┘ ┐)
```

| Hover | Popout | Clicks inside |
| --- | --- | --- |
| 🔊 volume | output devices, input devices, volume slider | pick a device, drag the slider, click the speaker to mute |
| 📶 network | Wi-Fi switch, nearby networks (connected first, then strongest) | connect/disconnect. A new secured network asks for its password |
| ᛒ Bluetooth | Bluetooth switch, paired devices with icons (battery % when known) | connect/disconnect |
| 🔋 battery | percentage, charging state, time remaining | n/a |

Moving the mouse off both the icon and the popout closes it after 0.3 s, so you have
time to move from the icon into the popout.

## The big idea: one invisible window that draws everything

Until Phase 5, the bar was its own window. Now **each monitor has one transparent,
full-screen window** (`ContentWindow`) that draws the frame, the bar and the popouts
together. Why not separate windows?
- **They look like one shape.** The frame, bar and popout share one colour and one
  shadow, and the popout grows *out of* the bar. That's only possible if they're
  drawn in the same window.
- **Panels can animate anywhere** without opening and closing windows.

Two problems this creates, and how they're solved:

| Problem | Solution |
| --- | --- |
| A full-screen window would swallow every click | **Input mask:** `mask: Region { … }` lists the only areas that take mouse input (the bar and the open popout). Everywhere else, clicks go straight to the windows below |
| A full-screen window can't reserve space at one edge | **`Exclusions.qml`:** four invisible 1×1 windows, one per edge, each reserving space with `exclusiveZone` (bar width on the bar side, 10 px elsewhere). The drawer window itself sets `exclusionMode: Ignore` |

That's exactly Caelestia's design. Its `Regions.qml` and `Exclusions.qml` do the same
two jobs.

```
 ShellRoot (shell.qml)
 ├─ Background {}                        wallpaper, Background layer
 └─ Drawers {}  ── Variants: per monitor ─┐
                                           ├─ Exclusions   4 × invisible 1-px windows → reserve space
                                           └─ ContentWindow (Top layer, full screen, mask)
                                               ├─ [one layer + MultiEffect shadow]
                                               │    ├─ Border           the frame (Shape, even-odd hole)
                                               │    └─ Background       popout background + fillets
                                               ├─ Bar                   (moved in from its own window)
                                               │    └─ StatusIcons ── hover ──▶ PopoutState
                                               └─ Wrapper               popout container ◀── PopoutState
                                                    └─ Loader: AudioPopout / NetworkPopout / …
```

## Files

| File | What it does | Caelestia equivalent |
| --- | --- | --- |
| `modules/drawers/Drawers.qml` | per monitor: `Exclusions` + `ContentWindow` | `drawers/Drawers.qml` |
| `modules/drawers/ContentWindow.qml` | the full-screen window: mask, shadow layer, bar, popouts | `drawers/ContentWindow.qml` |
| `modules/drawers/Exclusions.qml` | reserves the frame's space | `drawers/Exclusions.qml` |
| `modules/drawers/Border.qml` | draws the frame | `BlobInvertedRect` (C++ GPU shader) |
| `modules/bar/popouts/PopoutState.qml` | which popout is open, where, close timer | `popouts/PopoutState.qml` + parts of `Interactions.qml` |
| `modules/bar/popouts/Wrapper.qml` | popout container: position, size, slide animation, content | `popouts/Wrapper.qml` + `Content.qml` |
| `modules/bar/popouts/Background.qml` | popout background with curved joins to the bar | `PopoutBg` (C++ `BlobRect`) |
| `modules/bar/popouts/AudioPopout.qml` … `BatteryPopout.qml` | the four popouts | `popouts/AudioPopout.qml`, `Network.qml`, `Bluetooth.qml`, `Battery.qml` |
| `components/InvertedCorner.qml` | concave corner piece | part of the blob shaders |
| `components/ListItem.qml` | clickable row with icon/text/trailing text | various list delegates |
| `components/StyledSwitch.qml`, `StyledSlider.qml` | Material switch and slider | `components/controls/StyledSwitch.qml`, `StyledSlider.qml` |
| `modules/bar/Bar.qml` | now an `Item` inside the drawer window, not a window | `bar/BarWrapper.qml` |
| `modules/bar/components/StatusIcons.qml` | icons open popouts on hover | `bar/components/StatusIcons.qml` |
| `services/Audio.qml` | + device lists, set device | `services/Audio.qml` |
| `services/NetworkService.qml` | renamed from `Network.qml`, + network list, scanning | `services/Nmcli.qml` |
| `config/Config.qml` | + `border.thickness` (10), `border.rounding` (25) | `Config.border` |
| `~/.config/hypr/hyprland/rules.lua` | drawers fade in, exclusion windows not animated | `caelestia/hypr/hyprland/rules.lua` |

---

## The frame: `Border.qml`

```qml
ShapePath {
    fillRule: ShapePath.OddEvenFill
    PathRectangle { x: 0; y: 0; width: root.width; height: root.height }                // the whole screen
    PathRectangle { x: root.innerX; …; radius: root.rounding }                          // the hole
}
```
- **`Shape`** (from `QtQuick.Shapes`) draws vector paths, like SVG in QML.
- **Even-odd fill rule:** a point is filled if it's inside an *odd* number of shapes.
  Inside the screen only (1) = filled. Inside the screen *and* the hole (2) = empty.
  Two rectangles, one rounded, make a frame.
- `innerX` etc.: the hole starts after the bar on the bar side and after `thickness`
  on the other sides.
- **Caelestia** uses C++ GPU shaders ("blobs") here. They let panels *melt* into the
  frame, with a gooey deformation while they move. Our `Shape` gives the same static
  look in ~50 lines of QML, without compiling anything.

## One shadow for everything: `ContentWindow.qml`

```qml
Item {
    layer.enabled: true
    layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.7); blurMax: 15 }
    Border { … }
    Background { … }
}
```
- `layer.enabled` renders the item and its children into one image, then
  `layer.effect` processes that image. The frame and the popout background get **one
  combined shadow**, so they look like a single shape.
- The bar and the popout *content* are outside this layer: no shadow on text.

## Mouse input: the mask

```qml
mask: Region {
    Region { item: bar }
    Region { item: wrapper }
}
```
- A `Region` with `item:` follows that item's position and size live. When the popout
  is closed, `wrapper.width` is 0, so it takes no input.
- Child regions are **combined** (the default). Caelestia's `Regions.qml` uses
  `intersection: Xor` / `Subtract` to *cut* areas out instead. That's the same idea
  with more panels.
- The frame itself is not in the mask, so clicks on the thin border go to whatever is
  below. Nothing is below, since the exclusion zones keep windows away.

## Popouts: state → position → content

**`PopoutState.qml`**: a tiny state machine, one per screen:
```qml
property string currentName: ""   // "audio", "network", … or "" = closed
function open(name, y)            // called by a hovered icon
function scheduleClose()          // called on mouse leave: close in 300 ms…
function keepOpen()               // …unless the popout is hovered in time
property bool locked              // while typing a password: never close on leave
```
- The **300 ms delay** is what makes moving from the icon to the popout possible.
  Without it, leaving the icon would close the popout before you reach it.
- It's a `QtObject`, which has no children. The `Timer` lives in a property instead.

**Status icons** (`StatusIcons.qml`): each is a `StatusIcon`, an inline component:
```qml
onEntered: root.popouts.open(icon.name, icon.mapToItem(null, 0, icon.height / 2).y)
```
- `mapToItem(null, …)` converts the icon's centre into **window coordinates**, the
  same coordinates the popout is positioned in.
- `anchors.margins: -spacing / 2` makes each mouse area slightly bigger than its icon,
  so there's no gap between icons. Moving from one icon to the next switches popouts
  without a close/reopen flicker.

**`Wrapper.qml`**: geometry and animation:
```qml
width: popouts.isOpen ? openWidth : 0                 // animated: the slide
x: barOnRight ? parent.width - barWidth - width : barWidth
y: clamp(anchorY - height / 2, margin, parent.height - margin - height)
```
- **The slide** is just `width` animating from 0 with `clip: true`. The content is
  positioned from the **bar side** (`x: width - openWidth + padding`), so as the
  container widens, the content moves *out of the bar*.
- `shownName` remembers the last popout while it closes, so the content doesn't vanish
  before the slide finishes.
- `Behavior on y { enabled: root.width > 0 }`: when switching between icons, the popout
  glides. When opening from closed, it appears in place.

**`Background.qml` + `InvertedCorner.qml`**: the merged look:
- The background rectangle has **per-corner radii** (`topLeftRadius`, …): rounded on
  the screen side, square against the bar.
- Two **inverted corners** (fillets) sit above and below it, against the bar. Each is a
  small square with a quarter circle cut out, drawn as a `Shape` path: start at the
  solid corner, line along one edge, then a `PathArc` back. The arc direction is
  chosen so it bulges towards the solid corner.

## The four popouts

All four have the same shape: an `Item` with a fixed `implicitWidth`, and a
`ColumnLayout` inside that fills it.

> **Why the wrapper `Item`?** (found while building) A `ColumnLayout` calculates its
> **own** `implicitWidth` from its children, so setting `implicitWidth: 300` on it is
> overwritten. The first version came out ~140 px wide, with device names cut to
> "Ryze…". Fixed width on a plain `Item`, layout inside: problem gone.

- **Audio:** `Audio.sinks` / `Audio.sources` = PipeWire nodes that are audio, not
  streams (a "stream" is an app playing sound, not a device). Clicking sets
  `Pipewire.preferredDefaultAudioSink`, the same as choosing a device in `pavucontrol`.
  `PwObjectTracker` now tracks both the output *and* the input.
- **Network:** `NetworkService.wifiNetworks` collects the networks of every Wi-Fi
  device, sorted connected-first, then by signal. `setScanning(true)` turns on Wi-Fi
  scanning **only while the popout is open** (`Component.onCompleted` /
  `onDestruction`). Click: connected → `disconnect()`. Saved or open network →
  `connect()`. New secured network → a password field appears:
  - `popouts.locked = true`, so the popout doesn't close while you type
  - the window asks for keyboard focus (`WlrKeyboardFocus.OnDemand`). It's `None` the
    rest of the time, so the shell never steals your keyboard
  - Enter → `connectWithPsk(password)`, Esc → cancel
- **Bluetooth:** paired or connected devices, connected first. The icon comes from
  BlueZ's freedesktop icon name (`audio-headset` → `headphones`). Click toggles
  `device.connected`.
- **Battery:** `UPower.displayDevice`: `percentage`, `state`, `timeToEmpty` /
  `timeToFull` (seconds → "1 h 31 min"). No power-profile buttons:
  `power-profiles-daemon` isn't installed (`sudo pacman -S power-profiles-daemon`
  would make them possible).

## Controls: `StyledSwitch`, `StyledSlider`, `ListItem`

- Built on **`QtQuick.Controls.Basic`**: the plain style that lets you replace the
  parts (`indicator`, `background`, `handle`). With the system's native style, Qt
  ignores custom parts and prints a warning.
- `Switch`: `checked` + `onToggled`. `Slider`: `value` (0–1) + `onMoved`. Both are
  user-only signals, so code changing `value` doesn't trigger them, which avoids
  feedback loops.
- `ListItem` declares `signal clicked` and emits it from its `StateLayer`. That's how a
  component offers its own `onClicked:`.

---

## How to change it

| I want to… | Edit |
| --- | --- |
| a thicker or thinner frame, rounder or sharper corners | `"border": { "thickness": 10, "rounding": 25 }` in `~/.config/myshell/shell.json` (live) |
| no frame at all | `"thickness": 0` |
| wider popouts | `sizes.popoutWidth` in `config/Appearance.qml` |
| a longer or shorter close delay | `interval: 300` in `PopoutState.qml` |
| show more Wi-Fi networks | `.slice(0, 8)` in `NetworkPopout.qml` |
| a stronger or softer shadow | `Qt.alpha(…, 0.7)` and `blurMax` in `ContentWindow.qml` |
| add a popout for another icon | 1) a `StatusIcon { name: "x" … }` in `StatusIcons.qml`, 2) an `XPopout.qml` in `popouts/`, 3) a `case "x"` plus a `Component` in `Wrapper.qml` |

## Try it (10 minutes)

1. **Hover tour:** slowly move down the status icons. Each popout should slide, and
   switching between icons should *glide* instead of closing.
2. **The delay:** hover the volume icon, move into the popout, and drag the slider.
3. **Frame:** set `"thickness": 30` in `shell.json`, save, watch, and set it back.
4. **The mask:** open a popout, then click a window *right next to* the frame. The click
   reaches the window. That's the mask at work.
5. **Break the mask:** in `ContentWindow.qml`, change `mask: Region { … }` to
   `mask: Region { x: 0; y: 0; width: 10000; height: 10000 }`. Now you can't click
   any window! Undo with `git checkout modules/drawers/ContentWindow.qml`.
6. **Theme:** run `scripts/set-wallpaper.py ~/raunak/Wallpapers/berries-1.jpg` and watch
   the frame, bar and an open popout fade together.
7. **Bar side:** set `"position": "left"` in `shell.json`. Frame, popouts and fillets
   all follow. Set it back to `"right"`.

## Debugging

- `hyprctl layers`: should list `myshell-background`, `myshell-drawers` and 4×
  `myshell-exclusion`.
- Popout won't open: is the mouse area above the icon? Temporarily add
  `onEntered: console.log("enter", icon.name)` and watch `qs log -c my-first-shell -f`.
- Clicks don't reach windows: the mask is too big. Check `Region`s in `ContentWindow`.
- Windows under the frame: exclusion zones. `hyprctl layers` should show the 4
  exclusion windows. Check `Exclusions.qml` values.
- **After adding a new folder** (like `modules/drawers/`), hot reload may report
  `module "qs.modules.X" is not installed` once. Save any file again, or restart with
  `Ctrl + Super + Alt + R`.

## Common errors

| Symptom | Cause |
| --- | --- |
| Popout very narrow, text cut off | `implicitWidth` set on a Layout. Wrap it in an `Item` |
| `Property 'setScanning' … is not a function` | Name clash: `Network` meant Quickshell's type. That's why our service is `NetworkService` |
| `Cannot override FINAL property` | A property name already used by the base type (we hit it with `left`/`top` in `InvertedCorner`) |
| `"size" is a read-only property` | A `Behavior` on a `readonly property`. Make it a plain property |
| Popout closes while moving the mouse into it | Close delay too short, or the popout's `HoverHandler` is missing |
| Keyboard stuck in the shell | `keyboardFocus` stuck on `OnDemand`. `popouts.locked` didn't reset. Press Esc in the field, or restart the shell |

## Completion notes

Problems found while building (2026-10-03), and their fixes:
- **"The frame isn't drawn":** it was. The theme's surface colour is nearly black
  (`#0a0f10`), so it's only obvious when zoomed in. Confirmed with a red/green test
  shape, then a 4× zoom of the corner.
- **Popouts too narrow:** Layout `implicitWidth` overridden. Wrapped in an `Item`.
- **Name clash** `Network`: renamed our service to `NetworkService`.
- **`left`/`top` FINAL properties** in `InvertedCorner`: renamed to `isLeft`/`isTop`.
- **`Behavior` on a readonly property** (switch knob): made it writable.
- **Testing without a mouse:** hover was tested by moving the pointer with
  `hyprctl dispatch 'hl.dsp.cursor.move({ x = …, y = … })'`, leaving the bar between
  icons so real enter events fire. Clicks couldn't be simulated (no `ydotool`).
- **Fullscreen:** verified that a fullscreen window covers the frame and bar.
- **Hot reload and new folders:** the first reload after adding `modules/drawers/`
  failed with "not installed". A second save fixed it.
- **Not done (later):** our own tray menu popout (tray menus are still the apps' own
  menus). Popouts for the window title/workspaces. Caelestia's gooey "blob" deformation
  while panels move. Power-profile buttons (daemon not installed).
- **Now redundant:** `nm-applet` in the tray (the network popout replaces it). It's
  autostarted by the system (`/etc/xdg/autostart/nm-applet.desktop`). To stop it, a
  user override: `printf '[Desktop Entry]\nHidden=true\n' > ~/.config/autostart/nm-applet.desktop`.
  Not done yet; your choice.

Commits (`my-first-shell`):
1. "border settings, popout width, shadow colour; ListItem, StyledSwitch,
   StyledSlider, InvertedCorner"
2. "Audio sinks/sources; rename Network service to NetworkService"
3. "drawers: one window per screen with frame, bar and popouts"

`~/.config/hypr`: "layer rules for the shell's drawers and exclusion windows".

## Check it

These need a real mouse and keyboard. Please check:
- [ ] The frame and bar look like one shape, and windows stay inside the frame
- [ ] Hovering each status icon opens its popout; moving into the popout keeps it open; leaving closes it
- [ ] **Audio:** switching output device works (if you have more than one, e.g. headphones), the slider changes volume
- [ ] **Network:** clicking your connected network disconnects, clicking again reconnects
- [ ] **Network password:** clicking a *new* secured network shows the password field, you can type, Esc cancels (tested only as far as the field appearing)
- [ ] **Bluetooth:** the switch turns Bluetooth off/on, clicking a paired device connects it
- [ ] Clicks right next to the frame reach your windows
- [ ] Tray right-click menu still opens

## Questions

1. Why can't the bar simply stay its own window, with popouts as separate windows next to it?
2. The drawer window covers the whole screen. Why can you still click your windows?
3. Why does `Exclusions.qml` exist when the old bar window reserved its space by itself?
4. What would you see if the 300 ms close delay were 0?
5. Why does the network popout turn scanning on in `Component.onCompleted` and off in `onDestruction`?

<details>
<summary>Answers</summary>

1. Separate windows can't share one shape and one shadow, and a popout couldn't *grow
   out of* the bar. Each window is drawn separately by Hyprland, with its own
   animation. Caelestia moved everything into one window for exactly this.
2. The **input mask**: only the regions listed in `mask` (bar and open popout) receive
   input. Everywhere else, the window is "click-through".
3. The drawer window has `exclusionMode: Ignore`. A full-screen window reserving space
   would push *everything* away. Small invisible windows anchored to each edge
   reserve exactly the bar width / border thickness instead.
4. Popouts would close the moment the pointer left the icon, so you could never reach
   the popout to use its controls.
5. Scanning costs power and radio time. The popout's content only exists while it's
   open (it's loaded by a `Loader`), so creation and destruction are the natural
   "opened" and "closed" moments.

</details>
