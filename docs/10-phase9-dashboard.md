# Phase 9: Dashboard + your first C++ plugin

> **Status: 🔍 built 2026-10-04. Waiting for your check** (see [Check it](#check-it)).
> Implemented by Claude. This doc explains what was built so you can understand,
> change and debug it.

## What you got

A **dashboard** that drops down from the top edge, centred, with four tabs:

| Tab | Shows | Data from |
| --- | --- | --- |
| **Overview** | big clock and date, small weather, this month's calendar, now playing | `Time`, `Weather`, `Players` |
| **Media** | album art, title/artist/album, seek bar, controls, a chip per player | `Players` (MPRIS) |
| **Performance** | CPU, memory and disk gauges, CPU and GPU temperature | **your C++ plugin** |
| **Weather** | now (feels like, humidity, wind, sunrise/sunset), next 12 hours, 7 days | `Weather` (Open-Meteo) |

**How to open it:**
- **`Super + A`** opens it and it stays open. `←`/`→` switch tabs, and Escape (or a click
  outside) closes it.
- **Touching the top edge with the mouse** (middle part) opens it, and it closes when the mouse
  leaves.

The tab you were on is remembered.

```
                    top edge (hover here)
   ─────────╮ ┌──────────────────────────────────────┐ ╭─────────
            ╰─┤ ▦ Overview   ♪ Media   ◔ Perf   ☀ Weather│─╯
              │ ───────                                │
              │ ┌────────┐ ┌──────────┐ ┌───────────┐   │
              │ │ 13:15  │ │ October  │ │  ♪ cover  │   │
              │ │ Sunday │ │ calendar │ │  title    │   │
              │ ├────────┤ │          │ │  ⏮ ⏯ ⏭   │   │
              │ │ ☀ 35°  │ │          │ │           │   │
              │ └────────┘ └──────────┘ └───────────┘   │
              ╰────────────────────────────────────────╯
```

## How it fits together

```
 engine/ (C++)                             QML
 ─────────────                             ───
 systemstats.cpp ─ reads /proc/stat,       PerformanceTab.qml
   /proc/meminfo, /sys/class/hwmon, /         import MyShell.Engine
        │                                     SystemStats { running: root.visible }
        ▼ cmake --build engine/build              ▲
 engine/build/qml/MyShell/Engine/                 │ Qt looks in QML2_IMPORT_PATH
   qmldir + libmyshell-engineplugin.so ───────────┘ (set in Hyprland's shellCmd)

 Open-Meteo ──HTTP──▶ services/Weather.qml ──▶ Overview (small) + WeatherTab
 MPRIS (D-Bus) ─────▶ services/Players.qml ──▶ Overview (small) + MediaTab
 Super + A ─▶ myshell:dashboard ─▶ ShellState.toggleDashboard() ─┐
 top-edge strip hovered ─▶ ShellState.hoverDashboard() ──────────┴▶ Dashboard.qml (in ContentWindow)
```

## Files

| File | What it is | Caelestia equivalent |
| --- | --- | --- |
| `engine/CMakeLists.txt` | Builds the QML module `MyShell.Engine` | `plugin/CMakeLists.txt`, `plugin/cmake/qml-module.cmake` |
| `engine/src/systemstats.hpp/.cpp` | `SystemStats`: CPU, memory, disk, temperatures | `plugin/src/Caelestia/Services/cpu.cpp`, `memory.cpp`, `diskinfo.cpp`, `gpu.cpp` |
| `services/Weather.qml` + `utils/weather.js` | Weather data and code → icon/description | `services/Weather.qml`, `utils/Icons.qml` |
| `services/Players.qml` | + `chosen` / `choose()` (pick the player) | `services/Players.qml` |
| `services/ShellState.qml` | + `dashboardScreen`, `dashboardPinned`, `dashboardTab` | `services/Visibilities.qml` |
| `components/IconButton.qml`, `Gauge.qml` | Round icon button; 270° ring gauge | `components/controls/IconButton.qml`, performance `HeroCard.qml` |
| `modules/dashboard/Dashboard.qml` | The panel, tab bar, tab switching | `modules/dashboard/Content.qml`, `Tabs.qml` |
| `modules/dashboard/Overview.qml` | First tab | `modules/dashboard/Dash.qml` + `dash/*` |
| `modules/dashboard/Calendar.qml` | Month grid | `dash/Calendar.qml` |
| `modules/dashboard/MediaTab.qml`, `Cover.qml`, `MediaControls.qml` | Media | `Media.qml`, `media/Details.qml` |
| `modules/dashboard/PerformanceTab.qml` | Uses the C++ type | `Performance.qml` |
| `modules/dashboard/WeatherTab.qml` | Weather details | `WeatherTab.qml` |
| `modules/dashboard/Card.qml` | The rounded boxes | — |
| `modules/drawers/ContentWindow.qml` | Hosts the dashboard and the hover strip | `modules/drawers/Interactions.qml` (hover) |

Hyprland: `shellCmd` gained the `QML2_IMPORT_PATH=…` prefix, and `kbDashboard = "SUPER + A"`
(`Super + D` was already your communication workspace).

`shell.json` has a new section (added automatically with defaults):

```json
"services": { "weatherLocation": "", "useFahrenheit": false }
```

## Part 1: the C++ plugin

### Why C++ here at all?

QML *could* read `/proc/stat` with a `FileView` and do the maths in JavaScript. It's done in
C++ because this is the plan's chosen place to learn how Quickshell/Caelestia extend QML. In
Caelestia most services are C++ (`plugin/src/Caelestia/Services/`), and later phases (audio
visualiser, calculator) really need it. CPU stats are a small, safe first example.

### The class: `engine/src/systemstats.hpp`

```cpp
class SystemStats : public QObject {
    Q_OBJECT      // turns on Qt's meta-object system: signals, properties, introspection
    QML_ELEMENT   // "make this usable in QML as SystemStats { }"

    Q_PROPERTY(bool running READ running WRITE setRunning NOTIFY runningChanged)
    Q_PROPERTY(double cpuUsage READ cpuUsage NOTIFY updated)
    ...
```

- **`Q_OBJECT`:** Qt runs a code generator (**moc**) over the header. It writes the code
  that lets QML find properties by name, connect to signals, and so on. Every class QML
  touches needs it.
- **`QML_ELEMENT`:** registers the class in the module (`MyShell.Engine`) under its own name.
  (Caelestia's `Cpu` uses `QML_SINGLETON` too: one shared instance. Ours is an ordinary type
  you create, `SystemStats { }`, so each user controls its own polling.)
- **`Q_PROPERTY(type name READ getter WRITE setter NOTIFY signal)`:** what QML sees as a
  property.
  - `READ` is required.
  - `WRITE` makes it settable from QML (`running: root.visible`).
  - `NOTIFY` is the signal that makes **bindings update**: when C++ emits `updated()`, every
    QML binding that uses `cpuUsage` re-evaluates. Forget `NOTIFY` and the UI shows the
    first value forever.
  - `CONSTANT` (on `cpuName`) means it never changes, so no signal is needed.
- **`Q_INVOKABLE void refresh()`:** callable from QML as `stats.refresh()`.

### The work: `systemstats.cpp`

- **CPU usage:** `/proc/stat`'s first line is how many "ticks" all CPUs spent in each state
  since boot: `cpu user nice system idle iowait irq …`. One reading alone means nothing, so
  we keep the previous totals:
  `usage = 1 - (idle now - idle before) / (total now - total before)`.
  That's why the very first reading is 0.
- **Memory:** `/proc/meminfo`, used = `MemTotal - MemAvailable`. "Available" includes the
  caches the kernel would drop if needed, so this matches what `free` calls *used*.
- **Disk:** `QStorageInfo("/")`, used = total - free, like `df`.
- **Temperatures:** every `/sys/class/hwmon/hwmonN` has a `name` file (the driver). We look
  for `k10temp` (AMD CPU; Intel's is `coretemp`) and `amdgpu`, and read `temp1_input`
  (millidegrees: `52250` = 52.25 °C). On your laptop that's `hwmon5` (k10temp, label
  "Tctl") and `hwmon4` (amdgpu, label "edge"). This replaces Caelestia's libsensors
  dependency.
- **Timer:** a `QTimer` calls `refresh()` every `interval` ms, only while `running`. The tab
  sets `running: root.visible`, and the tab's `Loader` is only active while the dashboard is
  open on that tab, so nothing reads `/proc` while you aren't looking.

### Building: `engine/CMakeLists.txt`

```cmake
find_package(Qt6 6.9 REQUIRED COMPONENTS Core Qml)
qt_standard_project_setup(REQUIRES 6.9)          # turns on moc and sensible defaults
set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml")

qt_add_qml_module(myshell-engine
    URI MyShell.Engine                           # what QML imports
    VERSION 1.0
    SOURCES src/systemstats.hpp src/systemstats.cpp
)
target_include_directories(myshell-engine PRIVATE src)
```

`qt_add_qml_module` does a lot for you:
- it runs moc
- it generates code that registers every `QML_ELEMENT` class
- it builds two libraries: the backing library `libmyshell-engine.so` and the **plugin**
  `libmyshell-engineplugin.so`
- it writes a **`qmldir`** file (the module's table of contents) and a `.qmltypes` file
  (type info for tooling)

Thanks to `QT_QML_OUTPUT_DIRECTORY`, the result lands in `engine/build/qml/MyShell/Engine/`.
The folders spell out the URI, which is where an `import MyShell.Engine` looks.

```sh
cmake -S engine -B engine/build      # configure (once): finds Qt, writes Makefiles
cmake --build engine/build           # compile (after every C++ change)
```

`engine/build/` is in `.gitignore`: build outputs aren't committed. **After a fresh clone,
you must build before the Performance tab works.**

### Finding it: `QML2_IMPORT_PATH`

Qt looks for QML modules in its own folder (`/usr/lib/qt6/qml`, where Quickshell's modules
are) plus every folder in `QML2_IMPORT_PATH`. Caelestia installs its plugin into the system
folder (`cmake --install`). We keep ours in the repo instead and point Qt at it. That's the
prefix in `variables.lua`:

```lua
shellCmd = "QML2_IMPORT_PATH=$HOME/.config/quickshell/my-first-shell/engine/build/qml qs -c my-first-shell -n",
```

`hl.exec_cmd` runs this through `sh`, so `VAR=value command` sets the variable just for `qs`.
The restart key uses the same `shellCmd`.

### Containing failure: the `Loader`

If the plugin isn't built, or the variable is missing, `import MyShell.Engine` fails. Had
`Dashboard.qml` imported it directly, the failure would climb up and **the whole shell
wouldn't load**. Instead `PerformanceTab.qml` is loaded by a `Loader`. A Loader's failure
stays inside it (`status === Loader.Error`), so the dashboard shows a red "build the plugin"
message on that tab and everything else works.

## Part 2: the dashboard (QML)

### Opening: key vs hover (`ShellState`, `ContentWindow`)

- **`Super + A`:**
  - `toggleDashboard()` sets `dashboardPinned = true`.
  - The window takes the keyboard (`OnDemand`), so Escape and the arrows work.
  - The focus grab is on, so a click outside closes it.
- **Hover:**
  - A 2 px `dashboardTrigger` Item along the top edge is part of the window's `mask`.
  - Its `HoverHandler` calls `hoverDashboard()` (`pinned = false`).
  - A `Timer` closes the dashboard 400 ms after the mouse is on neither the strip nor the
    dashboard. `running` is a binding, so moving back in cancels it.
  - Over a fullscreen app the strip is under the app (Top layer), so hovering does nothing
    there. That's on purpose: games and videos use the top edge too.
- While open, notification popups are hidden (they'd overlap).

### Tabs (`Dashboard.qml`)

All four tab Items exist at once; only `visible` changes. The content's `implicitHeight` is
the current tab's, and the panel's `height` is animated, so switching to a taller tab grows
the panel smoothly. The underline's `x` is animated too.

### Calendar

Qt's `MonthGrid` and `DayOfWeekRow` (from `QtQuick.Controls`) work out which days go where,
including the previous and next month's days and the locale's first weekday. We only draw
each day (`delegate`): `model.today` gets the primary circle, and other-month days are
dimmed. Use the arrows or scroll to change month; click the title to go back to now.

### Media

- `Players.active` is now: the player you **chose** (chips under the controls, when there's
  more than one), otherwise a playing one, otherwise the first.
- **Seek bar:** MPRIS doesn't push the position (it would every millisecond). A `Timer` calls
  `player.positionChanged()` once a second while the Media tab is visible and playing, which
  makes Quickshell re-read it. Dragging sets `player.position` (if `canSeek`).

### Weather (`services/Weather.qml`)

1. **Where?**
   - `weatherLocation` set to `"lat,lon"` is used directly.
   - A city name goes through Open-Meteo's geocoding API.
   - Empty means **ip-api.com** guesses from your IP address. It said *New Delhi*: if that's
     wrong, set your city.
2. **Forecast:** `api.open-meteo.com/v1/forecast` (free, no key) with current, hourly and
   daily data.
3. Fetched when the dashboard opens, at most every 15 minutes (or ⟳ in the Weather tab),
   with `XMLHttpRequest`, which is built into QML's JavaScript.
4. `utils/weather.js` maps the WMO weather code (0 = clear, 61 = light rain, 95 =
   thunderstorm…) to a Material Symbol and a description.

## How to change it

| I want to… | Edit |
| --- | --- |
| My real city | `~/.config/myshell/shell.json`: `"weatherLocation": "Pune"` (applies immediately) |
| °F | `"useFahrenheit": true` |
| A different key | `kbDashboard` in `~/.config/hypr/variables.lua` |
| No hover opening | delete the `dashboardTrigger` Item (and its `Region`) in `ContentWindow.qml` |
| Start on another tab | `dashboardTab: 0` in `services/ShellState.qml` |
| Wider dashboard | `dashboardWidth` in `config/Appearance.qml` |
| Faster gauges | `interval: 1000` in `PerformanceTab.qml` |
| A new number from C++ (e.g. uptime) | add a `Q_PROPERTY` + getter + member, read it in `refresh()`, rebuild, restart; see *Try it* |

## Try it (15 minutes)

1. **A new C++ property:** add uptime.
   - In `systemstats.hpp`: `Q_PROPERTY(double uptime READ uptime NOTIFY updated)`, a getter
     `double uptime() const { return m_uptime; }`, and `double m_uptime = 0;`.
   - In `refresh()`: `m_uptime = readFile("/proc/uptime").section(' ', 0, 0).toDouble();`.
   - `cmake --build engine/build`, then **restart** the shell (`Ctrl + Super + Alt + R`):
     a running process never reloads a `.so`.
   - Show `Math.floor(stats.uptime / 3600) + " h"` somewhere in `PerformanceTab.qml`.
2. **Break the NOTIFY:** remove `NOTIFY updated` from `cpuUsage`, rebuild, restart. The CPU
   gauge freezes at its first value. Put it back.
3. **Break the path:** run the shell without the prefix
   (`qs kill -c my-first-shell; sleep 0.5; qs -c my-first-shell -n`). Everything works except
   the Performance tab, which shows the red message (the Loader at work). Restart normally.
4. `notify-send` while the dashboard is open: no popup (but it's in `Super + N`).
5. Set `"weatherLocation": "Reykjavik"` in `shell.json` and watch the Weather tab change.
6. Play a video in two browser tabs, or the browser and mpv. The Media tab shows two chips:
   pick one and the media keys follow it.

## Debugging

- **Is the plugin there?** `ls engine/build/qml/MyShell/Engine/` should list `qmldir` and
  `libmyshell-engineplugin.so`.
- **Did the shell get the path?**
  `tr '\0' '\n' < /proc/$(pgrep -xn qs)/environ | grep QML2`
- **Try the type alone:** a 10-line `shell.qml` in a temp folder with
  `SystemStats { running: true; onUpdated: console.log(cpuUsage) }`, run with
  `QML2_IMPORT_PATH=… qs -p <folder>`. That's how it was first tested.
- **Build errors:** read the *first* error. Generated files (`*_qmltyperegistrations.cpp`,
  `moc_*.cpp`) in an error usually mean a missing `Q_OBJECT`, a missing include path, or a
  stale build (`rm -rf engine/build` and configure again).
- **Weather empty:** the Weather tab shows the error. `curl 'http://ip-api.com/json'` checks
  the location step.

## Common errors

| Symptom | Cause |
| --- | --- |
| `'SystemStats' was not declared in this scope` in `…qmltyperegistrations.cpp` | the generated file includes `systemstats.hpp` by bare name: `target_include_directories(… src)` |
| `module "MyShell.Engine" is not installed` | not built, or `QML2_IMPORT_PATH` not set for this `qs` |
| A C++ change has no effect | not rebuilt, or not restarted (hot reload doesn't reload plugins) |
| Value never updates in QML | the `Q_PROPERTY` has no `NOTIFY`, or the signal isn't emitted |
| `Cannot override FINAL property` | a property called `top`/`bottom`/`left`/`right` (anchor lines), again |
| A column of a `RowLayout` eats all the space | nested layouts default to `Layout.fillWidth: true`; set it to `false` on fixed-width ones |

## Completion notes

- **Include path:** the first build failed because the generated registration code
  includes `systemstats.hpp` by bare name. Fixed with
  `target_include_directories(myshell-engine PRIVATE src)`.
- **Disk "used"** first counted root-reserved blocks (`bytesAvailable`), so it disagreed
  with `df`. Switched to `bytesFree`.
- **`Super + D` is taken** (communication special workspace), so the dashboard uses
  `Super + A`.
- **Weather tab didn't load:** the `Forecast` component used `top`/`bottom` properties
  (anchor lines), renamed to `upper`/`lower`. A failed hot reload keeps the old shell
  running, so nothing broke on screen.
- **Overview's media card had zero width:** the clock column (a nested `ColumnLayout`)
  stretched. Fixed with `Layout.fillWidth: false` on the fixed-width columns.
- **Cover icon size warnings** (`Point size <= 0`) while the cover had no width yet:
  clamped to ≥ 1.
- The real numbers on first run: Ryzen 5 5600H, 3% CPU, 57 °C CPU / 48 °C GPU, 5.5 of
  7.1 GiB memory, matching `free` and `df`.
- Tested: every tab screenshotted (scratch copy, starting tab picked by a test-only env
  variable), Weather fetched live, the key opening, the hover opening and closing on the real
  shell, a clean log, 12 global shortcuts. **Not tested:** the Media tab with something
  playing (nothing was playing).
- Not built (compared with Caelestia): lyrics, audio visualiser, user/avatar card,
  network and battery cards, GPU usage (needs vendor-specific files).

## Check it

- [ ] `Super + A` opens the dashboard; `←`/`→` switch tabs; Escape closes
- [ ] Touching the top edge (middle) opens it; moving away closes it
- [ ] Overview: clock, weather (right city? set `weatherLocation` if not), calendar (arrows,
      scroll)
- [ ] Media: play a YouTube video, see title, cover and seek bar move; pause from the dashboard
- [ ] Performance: CPU % moves when you do something heavy; temperatures look right
- [ ] Weather tab: hourly and 7 days
- [ ] After your next reboot: the Performance tab still works (the plugin path is in the
      autostart)

## Questions

<details><summary>1. What does NOTIFY do, and what breaks without it?</summary>

It names the signal that tells QML a property changed. Bindings re-evaluate when it's emitted.
Without it, QML reads the value once and never again.
</details>

<details><summary>2. Why is the first CPU reading 0?</summary>

Usage is the change in idle/total ticks between two readings. The first reading has nothing
to compare with, so it only stores the totals.
</details>

<details><summary>3. Why is PerformanceTab.qml loaded by a Loader instead of used directly?</summary>

Its `import MyShell.Engine` fails if the plugin isn't built or found. Directly used, that
error would make Dashboard, then ContentWindow, then the whole shell fail to load. A Loader
keeps the failure inside itself.
</details>

<details><summary>4. You changed systemstats.cpp. What two things must happen before you see it?</summary>

`cmake --build engine/build` (compile a new `.so`) and a full shell restart (the running
process keeps the old library loaded).
</details>

<details><summary>5. Why doesn't hovering the top edge open the dashboard over a fullscreen video?</summary>

The drawer window is on the Top layer, below fullscreen windows, so the 2 px strip is covered
and never gets the mouse. (Once something opens, the window moves up to Overlay.)
</details>
