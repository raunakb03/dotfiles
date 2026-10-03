# Phase 2: Quickshell & QML fundamentals

> **Status: ✅ completed 2026-10-03.** See [Completion notes](#completion-notes)
> at the end.

**Goal:** understand what a Quickshell config actually *is*, and be able to
explain every line of a small multi-file shell. By the end you'll have a bar
on every monitor with a live clock, split into files the way Caelestia does
it:

```
my-first-shell/
├── shell.qml              entry point: one Bar per monitor
├── modules/bar/Bar.qml    the bar itself
└── services/Time.qml      a shared clock (a "singleton")
```

**Prerequisite:** Phase 1 done. Your hello bar from step 0.7 runs.

**Reference folder:** `~/raunak/configurations/shell/`

---

## 2.0 How this phase works

- You edit `~/.config/quickshell/my-first-shell/shell.qml` (and later new
  files) step by step. **Every code block is a complete file:** replace the
  whole file with it.
- Keep the shell running while you work, with the log open in a second
  terminal:
  ```bash
  quickshell -c my-first-shell              # terminal 1
  qs log -c my-first-shell -f               # terminal 2
  ```
  Thanks to `settings.watchFiles: true`, saving a file reloads the shell
  instantly. Errors appear in terminal 2.
- **waybar keeps running.** Your bar appears just below it, because both
  reserve space at the top of the screen. That's expected. Your bar replaces
  waybar in Phase 5.
- Commit after each step that works:
  `git add -A && git commit -m "phase2: <step>"`.

---

## 2.1 Anatomy of a QML file

**Why:** Before changing anything, read the file you already have and know
what every part is.

**Read:** your current `shell.qml` (from step 0.7):
```qml
import QtQuick
import Quickshell

ShellRoot {
    settings.watchFiles: true

    PanelWindow {
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: 30
        color: "#1e1e2e"

        Text {
            anchors.centerIn: parent
            color: "#cdd6f4"
            text: "Hello from my shell"
        }
    }
}
```

**The four building blocks of QML:**

| Thing | Example | Meaning |
| --- | --- | --- |
| **import** | `import QtQuick` | makes a library of *types* available. `QtQuick` gives `Text`, `Rectangle`, `Row`, `MouseArea`, `Timer`… `Quickshell` gives `ShellRoot`, `PanelWindow`, `SystemClock`, `Variants`… |
| **object** | `Text { ... }` | `TypeName { }` creates one object of that type |
| **property** | `color: "#cdd6f4"` | `name: value` sets a property of the object |
| **child object** | `Text` inside `PanelWindow` | objects nested inside another become its children. A `Text` inside a window is drawn in that window |

**Line by line:**
- `ShellRoot { }`: the root object of every Quickshell config. Everything
  else lives inside it.
- `settings.watchFiles: true`: `settings` is a *grouped property* (an
  object with its own properties). The dot sets one of them. It turns on hot
  reload.
- `PanelWindow { }`: a window that sticks to screen edges (a Wayland
  "layer-shell" surface, like waybar). Not a normal app window.
- `anchors { top: true; left: true; right: true }`: glue the window to the
  top, left and right edges, so it stretches across the screen = a bar. The
  `{ }` form is shorthand for `anchors.top: true` etc.
- `implicitHeight: 30`: 30 pixels tall. (`implicit…` = "the size I'd like".
  Quickshell windows use it instead of `height`.)
- `color: "#1e1e2e"`: background colour, as hex `#RRGGBB`.
- `anchors.centerIn: parent`: for *items* (things inside a window),
  `anchors` positions them relative to another item. `parent` = the object
  this one is inside.

**Check:** you can say what each line does without looking at the table.

---

## 2.2 Properties and bindings

**Why:** This is *the* most important idea in QML. A property's value can
be an **expression**, and QML re-evaluates it automatically whenever
anything it uses changes. That's called a **binding**. Your whole shell
will be built from them: "the volume icon *is* `Audio.muted ? muted : on`",
and it just stays correct.

**Read:** `shell/services/Time.qml` in Caelestia. Notice it's almost all
`property … : <expression>`, i.e. bindings.

**Write:** `shell.qml`
```qml
import QtQuick
import Quickshell

ShellRoot {
    id: root

    settings.watchFiles: true

    property int clicks: 0

    PanelWindow {
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: 30
        color: "#1e1e2e"

        Text {
            anchors.centerIn: parent
            color: root.clicks >= 5 ? "#f38ba8" : "#cdd6f4"
            text: "Clicked " + root.clicks + " times"
        }
    }
}
```

**What's new:**
- `id: root`: a name for this object, so others can refer to it
  (`root.clicks`). Ids are only visible inside the same file.
- `property int clicks: 0`: declares **your own** property. Syntax:
  `property <type> <name>: <initial value>`. Common types: `int`, `real`
  (decimal), `bool`, `string`, `color`, `var` (anything).
- `text: "Clicked " + root.clicks + " times"`: a **binding**. QML notices
  this expression reads `root.clicks`, so whenever `clicks` changes, `text`
  is recomputed.
- `color: root.clicks >= 5 ? "#f38ba8" : "#cdd6f4"`: another binding,
  using JavaScript's `condition ? a : b`. Red from 5 clicks on.
- The part after `:` is **JavaScript**. QML embeds JS for expressions and
  functions.

**Run:** save, and the bar reloads. It says "Clicked 0 times".

**Try it:** change `property int clicks: 0` to `7` and save. The text
*and* the colour update. You never told them to; the bindings did. Set it
back to `0`.

**Check:** you can explain why changing one number changed two things.

**Commit:** `git add -A && git commit -m "phase2: properties and bindings"`

---

## 2.3 Signals and handlers

**Why:** Bindings react to *values*. Signals react to *events*: a click, a
timer firing, a property changing. You'll use both everywhere.

**Read:** in Caelestia, search for handlers:
`grep -rn "onClicked" ~/raunak/configurations/shell/modules/bar | head`

**Write:** `shell.qml`
```qml
import QtQuick
import Quickshell

ShellRoot {
    id: root

    settings.watchFiles: true

    property int clicks: 0

    onClicksChanged: console.log("clicks is now", clicks)

    PanelWindow {
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: 30
        color: "#1e1e2e"

        Text {
            id: label

            anchors.centerIn: parent
            color: root.clicks >= 5 ? "#f38ba8" : "#cdd6f4"
            text: "Clicked " + root.clicks + " times"
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    root.clicks = 0;
                else
                    root.clicks++;
            }
        }

        Timer {
            interval: 5000
            running: root.clicks > 0
            onTriggered: root.clicks = 0
        }
    }
}
```

**What's new:**
- **Signal handlers** are written `on<Signal>: <code>`, with the signal
  name's first letter capitalised:
  - `MouseArea` has a `clicked` signal → handler `onClicked`.
  - `Timer` has `triggered` → `onTriggered`.
- **Every property gets a free "changed" signal.** `clicks` →
  `clicksChanged` → handler `onClicksChanged`. Here it logs the new value
  (watch terminal 2).
- `MouseArea { anchors.fill: parent }`: an invisible item that catches
  mouse input over its whole parent (the bar).
  `acceptedButtons: Qt.LeftButton | Qt.RightButton` = listen to both buttons.
- `onClicked: mouse => { ... }`: the `clicked` signal carries a `mouse`
  argument. `mouse => { }` is a JavaScript arrow function receiving it.
  `mouse.button` tells which button.
- `root.clicks++` / `root.clicks = 0`: **assignments**. Code in handlers
  *changes* values, and bindings elsewhere react.
- `Timer { interval: 5000; running: root.clicks > 0; onTriggered: ... }`:
  `running` is itself a binding. The timer runs only while `clicks > 0`, so
  5 seconds after you start clicking, it resets to 0.
- `id: label` on the `Text`: not used yet. It's for the experiment below.

**Run:** left-click the bar a few times, right-click to reset, or wait 5 s.
Watch `clicks is now …` in the log.

**Experiment: how to *break* a binding.** Add this line inside `onClicked`,
after the `if/else`:
```js
                if (root.clicks === 3)
                    label.text = "Three!";
```
Click 3 times: "Three!". Now right-click to reset. The label **stays**
"Three!" and never updates again. Assigning a value (`=`) in code
**replaces** the binding, permanently. This is the #1 QML beginner bug.
The rule: *a property is either bound or assigned, not both.* Remove the
experiment lines again.

**Check:** you can explain the difference between `text: a + b` (binding)
and `label.text = a + b` (assignment).

**Commit:** `git add -A && git commit -m "phase2: signals and handlers"`

---

## 2.4 Positioning things: anchors and Row

**Why:** A bar has things on the left, in the centre and on the right.
That's anchors (relative positions) and positioners like `Row`.

**Read:** `shell/modules/bar/Bar.qml` in Caelestia. Its bar is vertical,
so look for `anchors.top` / `ColumnLayout` instead.

**Write:** `shell.qml`
```qml
import QtQuick
import Quickshell

ShellRoot {
    settings.watchFiles: true

    PanelWindow {
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: 30
        color: "#1e1e2e"

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            color: "#cdd6f4"
            text: "left"
        }

        Text {
            anchors.centerIn: parent
            color: "#cdd6f4"
            text: "centre"
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                color: "#a6e3a1"
                text: "one"
            }
            Text {
                color: "#f9e2af"
                text: "two"
            }
            Text {
                color: "#f38ba8"
                text: "three"
            }
        }
    }
}
```

**What's new:**
- `anchors.left: parent.left`: "my left edge sits on my parent's left
  edge". You can anchor `left`, `right`, `top`, `bottom`,
  `horizontalCenter`, `verticalCenter`.
- `anchors.leftMargin: 12`: keep 12 px of space from that edge.
- `anchors.verticalCenter: parent.verticalCenter`: centred vertically in the
  bar.
- `Row { spacing: 8 }`: lays its children out left-to-right with 8 px
  between them. You don't position the children yourself. (`Column` does
  the same vertically. `RowLayout` from `QtQuick.Layouts` can also stretch
  children, which we'll use later.)
- The `Row` is anchored to the right. Its children just follow along.

**Run:** save. "left", "centre" and three coloured words on the right.

**Try it:** add a fourth `Text` to the `Row`, then change `spacing` to `20`.

**Commit:** `git add -A && git commit -m "phase2: layout"`

---

## 2.5 A live clock

**Why:** Your first real piece of *system* data. Quickshell's
`SystemClock` gives the current time, updating on its own, so no `Timer` is
needed.

**Read:** `shell/services/Time.qml` again. It uses exactly this `SystemClock`.

**Write:** `shell.qml`
```qml
import QtQuick
import Quickshell

ShellRoot {
    settings.watchFiles: true

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }

    PanelWindow {
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: 30
        color: "#1e1e2e"

        Text {
            anchors.centerIn: parent
            color: "#cdd6f4"
            text: Qt.formatDateTime(clock.date, "dddd d MMMM  ·  hh:mm:ss")
        }
    }
}
```

**What's new:**
- `SystemClock { id: clock; precision: SystemClock.Seconds }`: a
  *non-visual* object. It draws nothing; it just exposes `clock.date`,
  which changes every second (`Minutes` would be cheaper, updating once a
  minute).
- It lives directly in `ShellRoot`. Non-visual objects can go anywhere.
- `Qt.formatDateTime(clock.date, "…")` turns a date into text. Because the
  binding reads `clock.date`, the text updates every second.
- Format codes: `hh` hours (00–23), `mm` minutes, `ss` seconds, `dddd`
  weekday name, `d` day, `MMMM` month name, `yyyy` year. Add `AP` for AM/PM
  with `h:mm AP`.

**Run:** a ticking clock in the middle of the bar.

**Try it:** switch to 12-hour format, or show only `hh:mm` with
`precision: SystemClock.Minutes`.

**Commit:** `git add -A && git commit -m "phase2: live clock"`

---

## 2.6 One bar on every monitor: `Variants`

**Why:** A `PanelWindow` appears on *one* screen. With an external monitor
plugged in, you want a bar on each, and you want them to appear and
disappear as monitors are connected. `Variants` creates one copy of its
content for every item in a list.

**Read:** `shell/modules/drawers/Drawers.qml`. It's only 26 lines and is
exactly this pattern (`Variants { model: Screens.screens … }`).

**Write:** `shell.qml`
```qml
import QtQuick
import Quickshell

ShellRoot {
    settings.watchFiles: true

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property ShellScreen modelData

            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: 30
            color: "#1e1e2e"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                color: "#cdd6f4"
                text: modelData.name
            }

            Text {
                anchors.centerIn: parent
                color: "#cdd6f4"
                text: Qt.formatDateTime(clock.date, "hh:mm:ss")
            }
        }
    }
}
```

**What's new:**
- `Variants { model: Quickshell.screens; PanelWindow { … } }`:
  `Quickshell.screens` is the list of connected monitors. For **each** one,
  `Variants` creates a fresh `PanelWindow`. When a monitor is plugged in or
  out, the list changes and a window is created or destroyed. That's a
  binding again.
- The `PanelWindow` inside isn't created directly. It's a **template**
  (QML calls it a *component* or *delegate*) that `Variants` stamps out once
  per screen.
- `required property ShellScreen modelData`: `Variants` hands each copy
  "its" item from the model as a property named `modelData`. `required`
  means "this must be given to me, or it's an error", which also lets
  `qmlls` check it.
- `screen: modelData`: put this window on that monitor.
- `text: modelData.name`: the monitor's name (`eDP-1` for your laptop
  panel, the same name `hyprctl monitors` shows).

**Run:** your bar now shows `eDP-1` on the left. If you have an external
monitor, plug it in and a second bar appears with its name.

**Check:** you can explain why there's one `PanelWindow` in the file but
possibly several on screen.

**Commit:** `git add -A && git commit -m "phase2: one bar per monitor"`

---

## 2.7 Splitting into files: your own `Bar` type

**Why:** `shell.qml` would become thousands of lines. QML's answer: **every
file is a new type.** A file `Bar.qml` defines a type `Bar` you can use
like `Text` or `Row`. Caelestia has about 280 of these files.

**Read:** the top of Caelestia's `shell.qml`: `import "modules"`,
`import qs.services`, … and how `Drawers {}` and `Lock {}` are used.

**Run first:**
```bash
mkdir -p ~/.config/quickshell/my-first-shell/modules/bar
```

**Write:** `modules/bar/Bar.qml` (new file)
```qml
import QtQuick
import Quickshell

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
    color: "#1e1e2e"

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        color: "#cdd6f4"
        text: root.modelData.name
    }

    Text {
        anchors.centerIn: parent
        color: "#cdd6f4"
        text: Qt.formatDateTime(clock.date, "hh:mm:ss")
    }
}
```

**Write:** `shell.qml`
```qml
import QtQuick
import Quickshell
import qs.modules.bar

ShellRoot {
    settings.watchFiles: true

    Variants {
        model: Quickshell.screens

        Bar {}
    }
}
```

**What's new:**
- **File name = type name.** `Bar.qml` → type `Bar`. It must start with a
  capital letter.
- **The file's root object is the type's base.** `Bar` *is a*
  `PanelWindow` with these extra properties and children.
- `import qs.modules.bar`: Quickshell maps `qs` to **your config's root
  folder**, so `qs.modules.bar` = the folder `modules/bar/`, and all its
  `.qml` files become available. Caelestia imports everything this way.
- `Bar {}` in `shell.qml` is now the whole template for `Variants`.
  `modelData` still arrives, because `Bar` declares
  `required property ShellScreen modelData`.
- `id: root` inside `Bar.qml` is private to that file. `shell.qml` can't
  see it, and other files can use `root` for their own objects. That's why
  most Caelestia files (244 of 284) name their root object `id: root`.
- The `SystemClock` moved into `Bar` for now, so each bar has its own clock.
  The next step fixes that.

**Run:** same bar as before. But `shell.qml` is now 13 lines.

**Commit:** `git add -A && git commit -m "phase2: Bar in its own file"`

---

## 2.8 Shared data: a singleton service

**Why:** If 5 widgets on 3 monitors each made their own clock, that's 15
clocks. Worse, for things like "volume" or "notifications" you need **one**
source of truth that everyone reads. A **singleton** is a type with exactly
one instance, usable from anywhere by its type name. Caelestia's
`services/` folder is all singletons: `Audio`, `Time`, `Notifs`, `Hypr`…

**Read:** `shell/services/Time.qml` (now you'll understand all of it except
the `Caelestia.I18n` import).

**Run first:**
```bash
mkdir -p ~/.config/quickshell/my-first-shell/services
```

**Write:** `services/Time.qml` (new file)
```qml
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property date date: clock.date
    readonly property string time: Qt.formatDateTime(clock.date, "hh:mm:ss")

    function format(fmt: string): string {
        return Qt.formatDateTime(clock.date, fmt);
    }

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }
}
```

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
    color: "#1e1e2e"

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        color: "#cdd6f4"
        text: root.modelData.name
    }

    Text {
        anchors.centerIn: parent
        color: "#cdd6f4"
        text: Time.time
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        color: "#cdd6f4"
        text: Time.format("dddd d MMMM")
    }
}
```

`shell.qml` stays the same as in 2.7.

**What's new:**
- `pragma Singleton` (first line) plus the `Singleton { }` root object makes
  this file a singleton. There's no `Time {}` anywhere: Quickshell creates
  the single instance the first time something uses it.
- `import qs.services` in `Bar.qml`, then just `Time.time` and
  `Time.format(...)`. The type name *is* the instance.
- `readonly property`: others can read it but not assign it. Services expose
  data read-only so only the service itself changes it.
- `function format(fmt: string): string { … }`: a JavaScript function on
  the object, with type annotations (`fmt` is a string, returns a string).
  Callers pass their own format.
- The `SystemClock` is gone from `Bar.qml`. Every bar on every monitor reads
  the one clock in `Time`.

**Run:** monitor name on the left, time in the middle, date on the right.

**Check:**
- you can explain why `Time` doesn't need an `id`, and why it isn't
  created with `Time {}`
- you can say what would break if `time` weren't `readonly` and some
  widget did `Time.time = "x"` (hint: step 2.3)

**Commit:** `git add -A && git commit -m "phase2: Time singleton"`

---

## 2.9 Reading Caelestia with new eyes

**Why:** From now on, Caelestia's code is your textbook. Check that you can
read it.

**Read** these two files and answer the questions. Answers are below; try
first.

`~/raunak/configurations/shell/shell.qml`
1. What does `import "modules"` do, compared to `import qs.services`?
2. `Background {}`, `Drawers {}`, `Lock {}` have no properties set. Where do
   their contents come from?
3. `Lock { id: lock }` and later `IdleMonitors { lock: lock }`. What is
   happening there?

`~/raunak/configurations/shell/modules/drawers/Drawers.qml`
4. What is `Scope`, and why is it needed inside `Variants` here?
5. What does `required property ShellScreen modelData` receive?
6. Line 1 says `pragma ComponentBehavior: Bound`. Look it up in the Qt docs
   ("QML pragma ComponentBehavior"). What does it make stricter?

<details>
<summary>Answers</summary>

1. `import "modules"` imports a folder by **relative path** (from this
   file). `import qs.services` imports by **module name** from the config
   root. Same effect. The `qs.` form works from any file at any depth.
2. From their own files, `modules/background/Background.qml`,
   `modules/drawers/Drawers.qml` and `modules/lock/Lock.qml`, like your
   `Bar.qml`.
3. `lock` (the id) refers to the `Lock` object. It's passed into the
   `IdleMonitors` property `lock`, so the idle monitor can lock the screen
   by calling methods on it. Objects can be handed around like values.
4. `Scope` is a non-visual container from Quickshell. `Variants` creates one
   object per screen, but Caelestia needs **two** things per screen
   (`Exclusions` and `ContentWindow`), so it wraps them in one `Scope`.
5. One `ShellScreen` from `Screens.screens` (Caelestia's own filtered list of
   monitors), the same as your `Quickshell.screens`.
6. It ties every component (like a `Variants` template) to the file it's
   written in. Two effects: ids from the surrounding file can be used inside
   it safely (and `qmlls` can type-check them), and model data is **no
   longer injected magically**. A delegate must declare it as a
   `required property`, exactly as you did with `modelData`. About half of
   Caelestia's files (149 of 284) use it.

</details>

---

## Phase 2 done when
- [x] Your repo has `shell.qml`, `modules/bar/Bar.qml`, `services/Time.qml`
      and the bar shows monitor name · time · date
- [x] You can explain binding vs assignment, and broke one on purpose (2.3)
- [x] You can explain what `Variants`, `modelData` and `required` do
- [x] You can explain file = type, `import qs.…`, and what makes a singleton
- [x] You answered the 2.9 questions

---

## Completion notes

What was actually done, and where it differs from the steps above:

- **Final files** match steps 2.7–2.8 exactly (`shell.qml`,
  `modules/bar/Bar.qml`, `services/Time.qml`). The only difference is fewer
  blank lines between properties and children.
- Verified 2026-10-03: loads with no errors or warnings, and shows
  `eDP-1 · hh:mm:ss · Saturday 3 October` across the top.
- **Commits:** the whole phase went into one commit ("Add bar in it's own
  file") instead of one per step. That's fine, but per-step commits make it
  easier to go back to a working state, so try it in Phase 3.
- **waybar wasn't running** at check time. It only starts at login (from
  `execs.lua`), so it will be back after the next login. Start it by hand
  with `waybar & disown` if you want it now. It gets replaced in Phase 5
  anyway.

## Common errors

| Error in the log | Likely cause |
| --- | --- |
| `Bar is not a type` | File name doesn't match (`bar.qml` vs `Bar.qml`), wrong folder, or missing `import qs.modules.bar` |
| `Required property modelData was not initialized` | `Bar` used outside `Variants`, or the property isn't named exactly `modelData` |
| `ReferenceError: root is not defined` | Using an id from another file. Ids are file-private; pass values through properties instead |
| `Cannot assign to read-only property` | Assigning to a `readonly property` (e.g. `Time.time = …`) |
| `Expected token "}"` / `Syntax error` | A missing or extra brace. The log names the file and line |
| Text stopped updating | You assigned to a bound property in code (2.3 experiment) |
| Nothing changes on save | The shell isn't running, or `settings.watchFiles` is missing |

Next: [`04-phase3-foundation.md`](04-phase3-foundation.md)
