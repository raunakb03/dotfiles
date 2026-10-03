# Phase 3: Foundation layer

**Goal:** build the small building blocks that *every* later part of the
shell uses, the same ones Caelestia has in `components/`, `services/` and
its config. By the end, your bar is restyled from them and controlled by a
settings file you can edit live:

```
┌──────────────────────────────────────────────────────────────────────────┐
│ 🖥 eDP-1                  ( 🕑 12:41:15 )               📅 Saturday 3 October │
└──────────────────────────────────────────────────────────────────────────┘
          click the clock pill → seconds on/off, saved to shell.json
```

New files:
```
my-first-shell/
├── assets/fonts/GoogleSansFlex.ttf      the UI font (bundled, like Caelestia)
├── services/Colours.qml                 the colour palette (fixed for now)
├── config/Appearance.qml                sizes, spacing, rounding, fonts, animation timings
├── config/Config.qml                    reads/writes ~/.config/myshell/shell.json
└── components/
    ├── Anim.qml  CAnim.qml              standard animations
    ├── StyledRect.qml  StyledText.qml   rectangles and text with the shell's style
    ├── MaterialIcon.qml                 icons from the Material Symbols font
    └── StateLayer.qml                   hover and press highlight for anything clickable
```

**Why bother?** Without these, every widget hard-codes its own colours
(`"#cdd6f4"`), sizes (`12`) and fonts. Changing the look later would mean
editing hundreds of places. With them, a widget says *what* it is
(`Colours.palette.m3primary`, `Appearance.spacing.small`) and the look is
decided in one place. That's also what makes Phase 4 (colours from the
wallpaper) possible.

**Prerequisite:** Phase 2 done. Your bar shows monitor · clock · date.

**Reference folder:** `~/raunak/configurations/shell/`

---

## 3.0 How this phase works, and fonts

Same workflow as Phase 2:
- **Running:** `quickshell -c my-first-shell` in one terminal and
  `qs log -c my-first-shell -f` in another.
- **Editing:** every code block is a **complete file**, so replace the whole
  file. The only exception is step 3.6, which says so.
- **Committing:** after **every** step:
  `git add -A && git commit -m "phase3: <step>"`.

Each step adds one building block **and** uses it in `Bar.qml` right away,
so you always see a change.

### Install the fonts

**Why:** Caelestia's look relies on two fonts:
- **Google Sans Flex** for all UI text. Caelestia ships it inside the shell
  (`assets/google-sans-flex/`) and loads it with a `FontLoader`. We'll do
  the same.
- **Material Symbols Rounded** for icons. It's an *icon font*: typing the
  word `schedule` in it draws a clock icon.

**Run:**
```bash
# Icon font (from the Arch repos)
sudo pacman -S --needed ttf-material-symbols-variable

# UI font: copy the font file and its licence into your shell
cd ~/.config/quickshell/my-first-shell
mkdir -p assets/fonts
cp ~/raunak/configurations/shell/assets/google-sans-flex/GoogleSansFlex-VariableFont_GRAD,ROND,opsz,slnt,wdth,wght.ttf assets/fonts/GoogleSansFlex.ttf
cp ~/raunak/configurations/shell/assets/google-sans-flex/LICENSE assets/fonts/GoogleSansFlex-LICENSE.txt
```
This is the one file we copy from Caelestia. It's a font, not code, and its
licence (SIL Open Font License) allows sharing it as long as the licence
file goes with it, which is why we copy `LICENSE` too.

**Check:** `fc-list | grep -i "material symbols"` prints at least one line,
and `ls assets/fonts` shows both files.

> **Restart Quickshell after installing a font.** A running Quickshell
> loads the list of installed fonts once, when it starts. Hot reload
> re-reads your `.qml` files but **not** the font list. If Quickshell was
> already running when you installed Material Symbols, press `Ctrl + C`
> in its terminal and start it again (`quickshell -c my-first-shell`).
> Otherwise the icons in step 3.4 show up as words.

**Commit:** `git add -A && git commit -m "phase3: fonts"`

---

## 3.1 A colour palette: `services/Colours.qml`

**Why:** Material 3 (the design system Caelestia follows) names colours
by **role**, not by hue:

| Role | Used for |
| --- | --- |
| `m3surface` | the background of large areas (the bar) |
| `m3surfaceContainer…` (`Low` → `Highest`) | things sitting *on* the surface, each a step lighter (cards, pills) |
| `m3onSurface` | text/icons on a surface. "on-X" always means "readable on top of X" |
| `m3onSurfaceVariant` | secondary, dimmer text |
| `m3primary` | the accent colour, for important things |
| `m3outline` | borders |

A widget asks for a *role*. In Phase 4 the actual colours are generated
from your wallpaper, and every widget follows automatically.

**Read:** `shell/services/Colours.qml` in Caelestia. Look for
`palette.m3…`. (Its palette is built in C++; ours is plain QML.)

**Write:** `services/Colours.qml` (new file)
```qml
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // A fixed dark Material 3 palette for now.
    // Phase 4 replaces these values with colours generated from the wallpaper.
    readonly property QtObject palette: QtObject {
        readonly property color m3surface: "#131317"
        readonly property color m3surfaceContainerLow: "#1c1b1f"
        readonly property color m3surfaceContainer: "#201f23"
        readonly property color m3surfaceContainerHigh: "#2a292e"
        readonly property color m3surfaceContainerHighest: "#353438"
        readonly property color m3onSurface: "#e5e1e7"
        readonly property color m3onSurfaceVariant: "#c8c5d1"
        readonly property color m3outline: "#918f9a"
        readonly property color m3outlineVariant: "#47464f"
        readonly property color m3primary: "#c2c1ff"
        readonly property color m3onPrimary: "#2a2a60"
        readonly property color m3primaryContainer: "#7171ac"
        readonly property color m3onPrimaryContainer: "#ffffff"
        readonly property color m3secondary: "#c6c4e0"
        readonly property color m3secondaryContainer: "#45455c"
        readonly property color m3onSecondaryContainer: "#b4b2ce"
        readonly property color m3tertiary: "#f5b2e0"
        readonly property color m3error: "#ffb4ab"
    }
}
```

- `readonly property QtObject palette: QtObject { … }`: `QtObject` is the
  simplest QML object, with no visuals, just properties. It's used here as a
  **group**, so you write `Colours.palette.m3primary` (the same style as
  Caelestia).
- `property color`: a colour type. It accepts `"#rrggbb"` strings.
- These are the dark default colours from Caelestia's
  `hypr/scheme/default.lua` (you used 7 of them in Phase 1).

**Write:** `modules/bar/Bar.qml`
```qml
import QtQuick
import Quickshell
import qs.services

PanelWindow {
    id: root

    required property ShellScreen modelData

    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 30
    color: Colours.palette.m3surface

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        color: Colours.palette.m3onSurfaceVariant
        text: root.modelData.name
    }

    Text {
        anchors.centerIn: parent
        color: Colours.palette.m3primary
        text: Time.time
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        color: Colours.palette.m3onSurface
        text: Time.format("dddd d MMMM")
    }
}
```

**Run:** the bar turns darker. The time is in the accent colour and the
monitor name dimmer.

**Commit:** `git add -A && git commit -m "phase3: colour palette"`

---

## 3.2 Design tokens: `config/Appearance.qml`

**Why:** **Design tokens** are named values for everything that isn't a
colour: corner rounding, spacing, padding, font sizes, animation timings.
A widget says `Appearance.padding.normal` instead of `12`. The **scales**
at the top let you resize *everything* at once. In step 3.6 they move into
your settings file.

**Read:** the values come from Caelestia's
`shell/plugin/src/Caelestia/Config/tokens.hpp` (C++; just look at the
numbers, e.g. `RoundingTokens`, `FontSizeTokens`, `durations`) and the font
loader `shell/modules/GSFLoader.qml`.

**Run first:**
```bash
mkdir -p ~/.config/quickshell/my-first-shell/config
```

**Write:** `config/Appearance.qml` (new file)
```qml
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // Global multipliers, so everything can be resized in one place
    // (step 3.6 moves these into shell.json)
    readonly property real roundingScale: 1
    readonly property real spacingScale: 1
    readonly property real paddingScale: 1
    readonly property real fontScale: 1
    readonly property real animDurationScale: 1

    // Corner radius, in pixels
    readonly property QtObject rounding: QtObject {
        readonly property int small: Math.round(8 * root.roundingScale)
        readonly property int normal: Math.round(12 * root.roundingScale)
        readonly property int large: Math.round(16 * root.roundingScale)
        readonly property int full: 1000 // more than half of any height = a pill shape
    }

    // Space BETWEEN items, in pixels
    readonly property QtObject spacing: QtObject {
        readonly property int small: Math.round(8 * root.spacingScale)
        readonly property int normal: Math.round(12 * root.spacingScale)
        readonly property int large: Math.round(16 * root.spacingScale)
    }

    // Space INSIDE an item, between its edge and its content, in pixels
    readonly property QtObject padding: QtObject {
        readonly property int small: Math.round(8 * root.paddingScale)
        readonly property int normal: Math.round(12 * root.paddingScale)
        readonly property int large: Math.round(16 * root.paddingScale)
    }

    readonly property QtObject font: QtObject {
        readonly property QtObject family: QtObject {
            // Use the bundled font once it has loaded, otherwise the system default
            readonly property string sans: sansLoader.status === FontLoader.Ready ? sansLoader.name : "sans-serif"
            readonly property string mono: "JetBrainsMono Nerd Font"
            readonly property string material: "Material Symbols Rounded"
        }

        // Point sizes
        readonly property QtObject size: QtObject {
            readonly property real small: 11 * root.fontScale
            readonly property real smaller: 12 * root.fontScale
            readonly property real normal: 13 * root.fontScale
            readonly property real larger: 15 * root.fontScale
            readonly property real large: 18 * root.fontScale
            readonly property real extraLarge: 28 * root.fontScale
        }
    }

    readonly property QtObject anim: QtObject {
        // Milliseconds
        readonly property QtObject durations: QtObject {
            readonly property int small: 200 * root.animDurationScale
            readonly property int normal: 400 * root.animDurationScale
            readonly property int large: 600 * root.animDurationScale
            readonly property int extraLarge: 1000 * root.animDurationScale
            readonly property int fastEffects: 150 * root.animDurationScale
            readonly property int effects: 200 * root.animDurationScale
            readonly property int slowEffects: 300 * root.animDurationScale
        }

        // Bezier curves as [x1, y1, x2, y2, 1, 1] (the same idea as Hyprland's curves)
        readonly property QtObject curves: QtObject {
            readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
            readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
            readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
            readonly property list<real> effects: [0.34, 0.8, 0.34, 1, 1, 1]
        }
    }

    FontLoader {
        id: sansLoader

        source: Quickshell.shellPath("assets/fonts/GoogleSansFlex.ttf")
    }
}
```

- **Groups again:** `Appearance.rounding.normal`,
  `Appearance.font.size.large`, `Appearance.anim.durations.small`… Nested
  `QtObject`s make the names read like a path.
- `id: root` lets the inner objects reach the scales (`root.fontScale`).
- `Math.round(8 * root.roundingScale)`: pixel values must be whole numbers.
- **Spacing vs padding:** spacing = gap *between* items. Padding = room
  *inside* an item, between its edge and its content.
- `rounding.full: 1000`: a radius larger than half the height turns any
  rectangle into a **pill**. Qt clamps it.
- **Font sizes are point sizes** (`font.pointSize`), which scale with your
  screen's DPI, unlike `pixelSize`.
- `FontLoader { source: Quickshell.shellPath("assets/…") }`: loads a font
  file that isn't installed system-wide. `Quickshell.shellPath()` turns a
  path relative to your config folder into a full path. Its `name` becomes
  `"Google Sans Flex"`.
- `sansLoader.status === FontLoader.Ready ? sansLoader.name : "sans-serif"`:
  until the font has loaded (or if it's missing), fall back to the system
  font.
- **Animation curves** are lists `[x1, y1, x2, y2, 1, 1]`. They're the same
  bezier curves as in your Hyprland `animations.lua` (step 1.9). The final
  `1, 1` is the curve's end point, which Qt requires.

**Write:** `modules/bar/Bar.qml`
```qml
import QtQuick
import Quickshell
import qs.config
import qs.services

PanelWindow {
    id: root

    required property ShellScreen modelData

    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 36
    color: Colours.palette.m3surface

    Text {
        anchors.left: parent.left
        anchors.leftMargin: Appearance.padding.normal
        anchors.verticalCenter: parent.verticalCenter
        color: Colours.palette.m3onSurfaceVariant
        font.family: Appearance.font.family.sans
        font.pointSize: Appearance.font.size.smaller
        text: root.modelData.name
    }

    Text {
        anchors.centerIn: parent
        color: Colours.palette.m3primary
        font.family: Appearance.font.family.mono
        font.pointSize: Appearance.font.size.normal
        text: Time.time
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: Appearance.padding.normal
        anchors.verticalCenter: parent.verticalCenter
        color: Colours.palette.m3onSurface
        font.family: Appearance.font.family.sans
        font.pointSize: Appearance.font.size.normal
        text: Time.format("dddd d MMMM")
    }
}
```

- `import qs.config`: the folder `config/` becomes the module `qs.config`.
- The clock uses the **mono** font, so the digits don't jiggle as they change
  (every digit is the same width).

**Run:** the bar is a little taller and the text is now Google Sans Flex.

**Try it:** change `fontScale` from `1` to `1.3` in `Appearance.qml`. All
text grows. Put it back.

**Commit:** `git add -A && git commit -m "phase3: appearance tokens"`

---

## 3.3 Styled basics: `Anim`, `CAnim`, `StyledRect`, `StyledText`

**Why:** Look at your `Bar.qml`. Every `Text` repeats `font.family`,
`font.pointSize`, `color`. A **styled component** bakes those defaults in
once. You write `StyledText { text: "hi" }` and get the right font, size and
colour, and you can still override any of them. Caelestia uses
`StyledText` and `StyledRect` everywhere instead of plain `Text` and
`Rectangle`.

**Read:** `shell/components/StyledText.qml`, `StyledRect.qml`, `Anim.qml`
and `CAnim.qml`. Ours are simpler versions of exactly these.

**Run first:**
```bash
mkdir -p ~/.config/quickshell/my-first-shell/components
```

**Write:** `components/Anim.qml` (new file)
```qml
import QtQuick
import qs.config

// Animates a number (width, opacity, x, ...) with the shell's standard timing
NumberAnimation {
    duration: Appearance.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.anim.curves.standard
}
```

**Write:** `components/CAnim.qml` (new file)
```qml
import QtQuick
import qs.config

// Animates a colour change smoothly instead of jumping
ColorAnimation {
    duration: Appearance.anim.durations.slowEffects
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.anim.curves.effects
}
```

**Write:** `components/StyledRect.qml` (new file)
```qml
import QtQuick

// A Rectangle that is transparent by default and fades between colours
Rectangle {
    color: "transparent"

    Behavior on color {
        CAnim {}
    }
}
```

**Write:** `components/StyledText.qml` (new file)
```qml
import QtQuick
import qs.config
import qs.services

// Text with the shell's font, size and colour, fading between colours
Text {
    renderType: Text.NativeRendering
    textFormat: Text.PlainText
    color: Colours.palette.m3onSurface
    font.family: Appearance.font.family.sans
    font.pointSize: Appearance.font.size.normal

    Behavior on color {
        CAnim {}
    }
}
```

- `Anim` **is** a `NumberAnimation`, just with our duration and curve
  preset. `easing.type: Easing.BezierSpline` says "use my own curve",
  given in `easing.bezierCurve`.
- `Behavior on color { CAnim {} }`: a **Behavior** intercepts every change
  of that property and animates to the new value instead of jumping. Once
  colours come from the wallpaper (Phase 4), changing wallpaper fades the
  whole shell to the new colours. That's this line.
- `StyledRect` and `StyledText` are a `Rectangle` and a `Text` with new
  **defaults**. Anything you set when using them overrides the default
  (e.g. `StyledText { color: "red" }`).
- `renderType: Text.NativeRendering`: draw text with the system's font
  renderer, sharper at small sizes.
- `textFormat: Text.PlainText`: never interpret text as HTML. Safer and
  faster when showing things like window titles.
- Inside `components/`, files can use each other (`CAnim` in
  `StyledRect`) **without an import**: files in the same folder always see
  each other.

**Write:** `modules/bar/Bar.qml`
```qml
import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services

PanelWindow {
    id: root

    required property ShellScreen modelData

    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 36
    color: Colours.palette.m3surface

    StyledText {
        anchors.left: parent.left
        anchors.leftMargin: Appearance.padding.normal
        anchors.verticalCenter: parent.verticalCenter
        color: Colours.palette.m3onSurfaceVariant
        font.pointSize: Appearance.font.size.smaller
        text: root.modelData.name
    }

    // The clock sits on a rounded "pill"
    StyledRect {
        anchors.centerIn: parent
        implicitWidth: clock.implicitWidth + Appearance.padding.normal * 2
        implicitHeight: clock.implicitHeight + Appearance.padding.small
        radius: Appearance.rounding.full
        color: Colours.palette.m3surfaceContainerHigh

        StyledText {
            id: clock

            anchors.centerIn: parent
            color: Colours.palette.m3primary
            font.family: Appearance.font.family.mono
            text: Time.time
        }
    }

    StyledText {
        anchors.right: parent.right
        anchors.rightMargin: Appearance.padding.normal
        anchors.verticalCenter: parent.verticalCenter
        text: Time.format("dddd d MMMM")
    }
}
```

- Every `Text` became `StyledText`. Look how much shorter they are.
- The clock now sits on a **pill**, a `StyledRect` with
  `radius: Appearance.rounding.full` and a slightly lighter
  `m3surfaceContainerHigh`.
- `implicitWidth: clock.implicitWidth + Appearance.padding.normal * 2`: the
  pill sizes itself to the text plus padding on both sides. A binding, so
  it follows the text.

**Run:** the clock sits in a rounded pill.

**Commit:** `git add -A && git commit -m "phase3: styled components"`

---

## 3.4 Icons: `MaterialIcon`

**Why:** Caelestia's icons are almost all **text in an icon font**. In
Material Symbols, the *word* `schedule` is drawn as a clock (the font uses
"ligatures" to replace whole words with symbols). So an icon is just a
`StyledText` with a different font, and it inherits colour animation for
free.

**Read:** `shell/components/MaterialIcon.qml`.

**Write:** `components/MaterialIcon.qml` (new file)
```qml
import QtQuick
import qs.config

// An icon from the Material Symbols font: set `text` to the icon's name, e.g. "schedule"
StyledText {
    id: root

    property real fill: 0    // 0 = outlined, 1 = filled
    property int grade: -25  // stroke thickness tweak (-25 looks better on dark backgrounds)

    font.family: Appearance.font.family.material
    font.pointSize: Appearance.font.size.larger
    font.variableAxes: ({
            FILL: root.fill,
            GRAD: root.grade
        })
}
```

- `MaterialIcon` **is a** `StyledText` (a component built on your own
  component), with the icon font and a bigger size.
- `font.variableAxes`: Material Symbols is a **variable font**, with
  adjustable "axes" instead of separate files. `FILL` 0 → 1 goes from
  outlined to filled. `GRAD` adjusts stroke weight. The `({ … })`
  parentheses tell QML it's a JavaScript object, not a code block.
- Find icon names at <https://fonts.google.com/icons>. Use the name in
  lowercase with underscores, e.g. `calendar_month`.

**Write:** `modules/bar/Bar.qml`
```qml
import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services

PanelWindow {
    id: root

    required property ShellScreen modelData

    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 36
    color: Colours.palette.m3surface

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Appearance.padding.normal
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.small

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            color: Colours.palette.m3onSurfaceVariant
            text: "desktop_windows"
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.smaller
            text: root.modelData.name
        }
    }

    StyledRect {
        anchors.centerIn: parent
        implicitWidth: clockRow.implicitWidth + Appearance.padding.normal * 2
        implicitHeight: clockRow.implicitHeight + Appearance.padding.small
        radius: Appearance.rounding.full
        color: Colours.palette.m3surfaceContainerHigh

        Row {
            id: clockRow

            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                color: Colours.palette.m3primary
                fill: 1
                text: "schedule"
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                color: Colours.palette.m3primary
                font.family: Appearance.font.family.mono
                text: Time.time
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: Appearance.padding.normal
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.small

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: "calendar_month"
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Time.format("dddd d MMMM")
        }
    }
}
```

- Each icon and its text sit in a `Row`.
  `anchors.verticalCenter: parent.verticalCenter` on the children lines up
  icons and text of different heights.
- The clock icon has `fill: 1` (filled). The others are outlined.

**Run:** icons appear next to the monitor name, the time and the date.

**Check:** if you see the *words* `schedule` / `calendar_month` instead of
icons, either the icon font isn't installed (go back to 3.0), or, more
likely, **Quickshell was started before you installed it**. Restart it:
`Ctrl + C` in its terminal, then `quickshell -c my-first-shell`. (This
happened during the first run-through on 2026-10-03.)

**Try it:** change the clock's `fill: 1` to `0`, and `"schedule"` to
`"alarm"`.

**Commit:** `git add -A && git commit -m "phase3: material icons"`

---

## 3.5 Clickable things: `StateLayer`

**Why:** In Material 3, anything clickable shows a faint highlight on
hover and a stronger one while pressed. Caelestia's `StateLayer` does this
(plus a ripple effect). You drop it inside any item to make that item
clickable.

**Read:** `shell/components/StateLayer.qml`. It's long because of the
ripple animation. Ours keeps the core: hover, press and cursor.

**Write:** `components/StateLayer.qml` (new file)
```qml
import QtQuick
import qs.config
import qs.services

// Makes its parent clickable, with a hover highlight and a press highlight.
// Put it inside any item; handle clicks with onClicked.
MouseArea {
    id: root

    property bool disabled
    property color color: Colours.palette.m3onSurface
    property real radius: parent?.radius ?? 0 // match the parent's rounded corners

    anchors.fill: parent
    enabled: !disabled
    hoverEnabled: true
    cursorShape: disabled ? undefined : Qt.PointingHandCursor

    StyledRect {
        anchors.fill: parent
        radius: root.radius
        color: root.color
        opacity: root.pressed ? 0.12 : root.containsMouse ? 0.08 : 0

        Behavior on opacity {
            Anim {
                duration: Appearance.anim.durations.small
            }
        }
    }
}
```

- `StateLayer` **is a** `MouseArea` filling its parent, so the parent
  becomes clickable, and users of it write `onClicked: …` as usual.
- `hoverEnabled: true` makes `containsMouse` work (it's `true` while the
  mouse is over it). `pressed` is `true` while a button is held.
- `opacity: root.pressed ? 0.12 : root.containsMouse ? 0.08 : 0`: a layer
  of the text colour at 8% (hover) or 12% (pressed) opacity on top of the
  parent. These are Material 3's standard values.
- `Behavior on opacity { Anim { … } }`: the highlight fades in and out
  instead of blinking.
- `cursorShape: Qt.PointingHandCursor`: the hand cursor, so it *looks*
  clickable.
- `property real radius: parent?.radius ?? 0`: `?.` = "if `parent` exists,
  take its `radius`". `??` = "if that's missing, use 0". The highlight copies
  the parent's rounded corners, so on the pill it's pill-shaped too.

**Write:** `modules/bar/Bar.qml`
```qml
import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services

PanelWindow {
    id: root

    required property ShellScreen modelData

    // Click the clock to toggle seconds (moves into shell.json in step 3.6)
    property bool showSeconds: true

    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 36
    color: Colours.palette.m3surface

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Appearance.padding.normal
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.small

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            color: Colours.palette.m3onSurfaceVariant
            text: "desktop_windows"
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.smaller
            text: root.modelData.name
        }
    }

    StyledRect {
        anchors.centerIn: parent
        implicitWidth: clockRow.implicitWidth + Appearance.padding.normal * 2
        implicitHeight: clockRow.implicitHeight + Appearance.padding.small
        radius: Appearance.rounding.full
        color: Colours.palette.m3surfaceContainerHigh

        // Grow/shrink smoothly when the text gets longer/shorter
        Behavior on implicitWidth {
            Anim {}
        }

        StateLayer {
            onClicked: root.showSeconds = !root.showSeconds
        }

        Row {
            id: clockRow

            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                color: Colours.palette.m3primary
                fill: 1
                text: "schedule"
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                color: Colours.palette.m3primary
                font.family: Appearance.font.family.mono
                text: Time.format(root.showSeconds ? "hh:mm:ss" : "hh:mm")
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: Appearance.padding.normal
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.small

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: "calendar_month"
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Time.format("dddd d MMMM")
        }
    }
}
```

- `property bool showSeconds: true` on the bar, and the clock text reads it:
  `Time.format(root.showSeconds ? "hh:mm:ss" : "hh:mm")`.
- `StateLayer { onClicked: root.showSeconds = !root.showSeconds }`: click
  the pill to toggle. That's an assignment to `showSeconds`, which is a
  plain property (not bound), so it's fine. The clock *text* stays bound.
- `Behavior on implicitWidth { Anim {} }`: when the seconds disappear, the
  text gets shorter, the pill's `implicitWidth` binding changes, and the
  Behavior animates the pill shrinking.

**Run:** hover the clock (highlight + hand cursor), click it (the pill
shrinks smoothly, seconds gone), click again.

**Commit:** `git add -A && git commit -m "phase3: state layer"`

---

## 3.6 A settings file: `config/Config.qml`

**Why:** `showSeconds` resets every time the shell restarts. A real shell
keeps settings in a file, like Caelestia's `~/.config/caelestia/shell.json`.
Ours lives at `~/.config/myshell/shell.json`, next to your Hyprland
overrides. It works in **both directions**:
- **you edit the file** → the shell updates instantly
- **the shell changes a setting** (a click) → the file is saved

**Read:** the "Configuring" and "Example configuration" sections of
`~/raunak/configurations/shell/README.md` to see what a full `shell.json`
can hold. (Caelestia's file isn't created automatically. Ours will be.) Caelestia parses it in C++ (`plugin/src/Caelestia/Config/`).
Quickshell's `FileView` + `JsonAdapter` lets us do it in about 40 lines of
QML.

**Write:** `config/Config.qml` (new file)
```qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Shortcuts, so other files can write Config.bar.showSeconds
    property alias appearance: adapter.appearance
    property alias bar: adapter.bar

    FileView {
        path: Quickshell.env("HOME") + "/.config/myshell/shell.json"
        watchChanges: true

        // The file was edited (by you, in an editor): read it again
        onFileChanged: reload()

        // A setting was changed from inside the shell: save it to the file
        onAdapterUpdated: writeAdapter()

        // First run: the file doesn't exist yet, so write one with all the defaults
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        // The shape of shell.json, with default values
        JsonAdapter {
            id: adapter

            property JsonObject appearance: JsonObject {
                property real roundingScale: 1
                property real spacingScale: 1
                property real paddingScale: 1
                property real fontScale: 1
                property real animDurationScale: 1
            }

            property JsonObject bar: JsonObject {
                property bool showSeconds: true
                property bool showDate: true
            }
        }
    }
}
```

- `FileView`: watches one file. `watchChanges: true` → it emits
  `fileChanged` when the file is modified on disk.
- `JsonAdapter`: maps the file's JSON onto QML properties.
  - Each property is a key in the file.
  - A `JsonObject` property is a nested `{ … }` section.
  - The values written here are the **defaults**, used for any key the file
    doesn't have.
- **The three handlers make it two-way:**
  - `onFileChanged: reload()`: you saved the file → read it again → the
    properties change → every binding using them updates.
  - `onAdapterUpdated: writeAdapter()`: a property was changed from QML
    (your click) → write the whole adapter back to the file.
  - `onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter(); }`:
    the very first time, there's no file, so write one with all the
    defaults. You get a complete, documented-by-example `shell.json` for
    free.
- `property alias bar: adapter.bar`: an **alias** is a second name for
  another property. Others can write `Config.bar.showSeconds` instead of
  reaching inside the `FileView`.
- `Quickshell.env("HOME")`: reads an environment variable. Here it's your
  home folder.

**Edit:** `config/Appearance.qml`. **Replace only these lines** at the top:
```qml
    // Global multipliers, so everything can be resized in one place
    // (step 3.6 moves these into shell.json)
    readonly property real roundingScale: 1
    readonly property real spacingScale: 1
    readonly property real paddingScale: 1
    readonly property real fontScale: 1
    readonly property real animDurationScale: 1
```
with:
```qml
    // Global multipliers from shell.json, so everything can be resized in one place
    readonly property real roundingScale: Config.appearance.roundingScale
    readonly property real spacingScale: Config.appearance.spacingScale
    readonly property real paddingScale: Config.appearance.paddingScale
    readonly property real fontScale: Config.appearance.fontScale
    readonly property real animDurationScale: Config.appearance.animDurationScale
```

**Write:** `modules/bar/Bar.qml`
```qml
import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services

PanelWindow {
    id: root

    required property ShellScreen modelData

    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 36
    color: Colours.palette.m3surface

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Appearance.padding.normal
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.small

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            color: Colours.palette.m3onSurfaceVariant
            text: "desktop_windows"
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.smaller
            text: root.modelData.name
        }
    }

    StyledRect {
        anchors.centerIn: parent
        implicitWidth: clockRow.implicitWidth + Appearance.padding.normal * 2
        implicitHeight: clockRow.implicitHeight + Appearance.padding.small
        radius: Appearance.rounding.full
        color: Colours.palette.m3surfaceContainerHigh

        // Grow/shrink smoothly when the text gets longer/shorter
        Behavior on implicitWidth {
            Anim {}
        }

        StateLayer {
            onClicked: Config.bar.showSeconds = !Config.bar.showSeconds
        }

        Row {
            id: clockRow

            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                color: Colours.palette.m3primary
                fill: 1
                text: "schedule"
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                color: Colours.palette.m3primary
                font.family: Appearance.font.family.mono
                text: Time.format(Config.bar.showSeconds ? "hh:mm:ss" : "hh:mm")
            }
        }
    }

    Row {
        visible: Config.bar.showDate
        anchors.right: parent.right
        anchors.rightMargin: Appearance.padding.normal
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.small

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: "calendar_month"
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Time.format("dddd d MMMM")
        }
    }
}
```

- The bar's own `showSeconds` property is gone. The clock reads and toggles
  `Config.bar.showSeconds` instead.
- `visible: Config.bar.showDate` on the date `Row`: hide it from the file.

**Run:** the shell reloads, and the log shows one **expected** warning:
`Read of …/shell.json failed: File does not exist`. That was the first-run
case, so it wrote the file:
```bash
cat ~/.config/myshell/shell.json
```
```json
{
    "appearance": {
        "animDurationScale": 1,
        "fontScale": 1,
        "paddingScale": 1,
        "roundingScale": 1,
        "spacingScale": 1
    },
    "bar": {
        "showDate": true,
        "showSeconds": true
    }
}
```

**Try it, both directions:**
1. Click the clock pill, then `cat` the file again: `"showSeconds": false`.
2. Open `~/.config/myshell/shell.json` in your editor, set
   `"fontScale": 1.3` and `"showDate": false`, and save. The bar changes
   **while you watch**, with no restart.
3. Set them back.

**Commit:** `git add -A && git commit -m "phase3: settings file"`

(`shell.json` lives outside the repo, in `~/.config/myshell/`, so it's not
committed. It's *your* settings, not the shell's code, the same idea as
`hypr-vars.lua`.)

---

## 3.7 Compare with Caelestia

**Read** and answer. Answers are below.

1. Caelestia's `StyledText.qml` has a `Behavior on text` with a
   `SequentialAnimation`. What does it do when `animate: true`?
2. Caelestia's `MaterialIcon` gets its font from
   `Tokens.font.icon.size(...).weight(...).build()`. Where does `Tokens`
   come from, and what plays that role in your shell?
3. In Caelestia's `StateLayer.qml`, what happens in `press(x, y)`, and why
   does it need `pressX`/`pressY`?
4. Why do `Colours`, `Appearance` and `Config` have to be **singletons**
   rather than normal components?

<details>
<summary>Answers</summary>

1. When the text changes, it fades the old text out (`opacity → 0`),
   swaps the text (`PropertyAction`), then fades back in. It's a
   cross-fade for changing values, e.g. a clock digit.
2. From `import Caelestia.Config`, Caelestia's **C++ plugin**
   (`plugin/src/Caelestia/Config/tokens.hpp` and `appearanceconfig.hpp`).
   In your shell, `config/Appearance.qml` (QML) does the same job.
3. It records where you clicked, resets the ripple circle and starts
   `rippleAnim`, which grows a circle **from the click point**. That's the
   Material ripple. Ours skips the ripple and only fades a flat layer.
4. There must be exactly **one** palette, one set of tokens, and one
   settings file reader. If every widget made its own `Config {}`, you'd
   have dozens of `FileView`s on the same file, each writing it. A
   singleton is created once and shared by every file that imports it.

</details>

---

## Phase 3 done when
- [ ] Icons render as icons (not words), and text is Google Sans Flex
- [ ] The repo has `services/Colours.qml`, `config/Appearance.qml`,
      `config/Config.qml`, the six files in `components/`, and the font in
      `assets/fonts/`
- [ ] Clicking the clock toggles seconds, with a hover highlight and a
      smooth width animation
- [ ] Editing `~/.config/myshell/shell.json` changes the bar live, and
      clicking changes the file
- [ ] You can explain: design tokens, `Behavior`, `QtObject` groups,
      `property alias`, and the three `FileView` handlers
- [ ] One commit per step

---

## Common errors

| Symptom / log message | Likely cause |
| --- | --- |
| Words like `schedule` instead of icons | Quickshell was running when the font was installed. **Restart it** (hot reload doesn't reload fonts). Or the font isn't installed (step 3.0) |
| Text still in the old font | `assets/fonts/GoogleSansFlex.ttf` missing or misnamed. The `FontLoader` falls back to `sans-serif` |
| `module "qs.components" is not installed` | Folder not named exactly `components/`, or no `.qml` files in it yet |
| `StyledText is not a type` inside `MaterialIcon.qml` | `StyledText.qml` isn't in the same `components/` folder |
| `Read of …/shell.json failed: File does not exist` | **Expected on the first run only.** The file is then created |
| `shell.json` edits ignored | Invalid JSON (e.g. a trailing comma). Check the log. Fix the file and save again |
| Clicking does nothing | `StateLayer` not *inside* the pill, or something above it covers it. Later siblings are drawn on top and get clicks first |

Next: **Phase 4: Wallpaper & Material You theming.** Its guide is written
when we start it.
