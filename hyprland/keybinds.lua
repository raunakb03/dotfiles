local vars = require("variables")
local fn   = require("utils.functions")

---------------------------
---- Bind helpers ----
---------------------------

-- Flags
local locked           = { locked = true }    -- also works on the lock screen
local mouse            = { mouse = true }     -- hold-and-drag mouse bind
local release          = { release = true }   -- fires when the key is released
local repeating        = { repeating = true } -- repeats while held
local locked_repeating = { locked = true, repeating = true }

-- "SUPER + Mouse_Down" -> "super+mouse_down" so binds can be compared
local function normalise_keybind(key)
    return key:gsub("%s+", ""):lower()
end

-- A usable bind is a string with at least one non-space character
local function valid_keybind(key)
    return type(key) == "string" and key:match("%S") ~= nil
end

-- Scroll-wheel binds must not repeat; key binds should
local function repeating_unless_mouse(key)
    return not normalise_keybind(key):find("mouse", 1, true) and repeating or nil
end

-- Turn "a" or {"a", {"b", "c"}} into the flat list {"a", "b", "c"}
local function flatten_keybinds(keybinds, keys)
    keys = keys or {}

    if type(keybinds) == "table" then
        for _, keybind in pairs(keybinds) do
            flatten_keybinds(keybind, keys)
        end
    elseif valid_keybind(keybinds) then
        keys[#keys + 1] = keybinds
    end

    return keys
end

-- Bind every key in `keybinds` to `action`.
-- `flags` is a table, or a function that picks flags per key.
-- `desc` is a human-readable description, shown by the keybind cheat sheet.
local function create_bind(keybinds, action, flags, desc)
    local get_flags = type(flags) == "function" and flags or function()
        return flags
    end

    for _, key in ipairs(flatten_keybinds(keybinds)) do
        -- Copy the flags so the shared tables (locked, repeating, ...) are never modified
        local opts = {}
        for k, v in pairs(get_flags(key) or {}) do
            opts[k] = v
        end
        opts.description = desc

        hl.bind(key, action, opts)
    end
end

-- ("SUPER", 1) -> "SUPER + 1"
local function extend_keybind(base, suffix)
    return valid_keybind(base) and base .. " + " .. suffix or nil
end

-------------------
---- Launcher ----
-------------------

-- Tapping Super alone opens the launcher, so it must fire on *release*
-- (otherwise Super + T would open the launcher too)
local launcher_default = normalise_keybind("SUPER + SUPER_L")
create_bind(
    vars.kbLauncher,
    hl.dsp.exec_cmd(vars.launcherCmd),
    function(key)
        return normalise_keybind(key) == launcher_default and release or nil
    end,
    "Launcher: open app launcher"
)

---------------
---- Misc ----
---------------

create_bind(vars.kbLock, hl.dsp.exec_cmd(vars.lockCmd), nil, "Session: lock screen")
create_bind(vars.kbExit, hl.dsp.exit(), nil, "Session: exit Hyprland (log out)")
create_bind(vars.kbSleep, hl.dsp.exec_cmd(vars.sleepCmd), locked, "Session: suspend")
create_bind(vars.kbClipboard, hl.dsp.exec_cmd(vars.clipboardCmd), nil, "Utilities: clipboard history")

--------------------
---- Workspaces ----
--------------------

for i = 1, 10 do
    local key = i % 10 -- workspace 10 is on key 0
    create_bind(extend_keybind(vars.kbGoToWs, key), fn.wsaction("focus", "", i), nil,
        "Workspaces: go to workspace " .. i)
    create_bind(extend_keybind(vars.kbMoveWinToWs, key), fn.wsaction("move", "", i), nil,
        "Workspaces: move window to workspace " .. i)
    create_bind(extend_keybind(vars.kbGoToWsGroup, key), fn.wsaction("focus", "group", i), nil,
        "Workspaces: go to workspace group " .. i)
    create_bind(extend_keybind(vars.kbMoveWinToWsGroup, key), fn.wsaction("move", "group", i), nil,
        "Workspaces: move window to workspace group " .. i)
end

create_bind(vars.kbPrevWs, hl.dsp.focus({ workspace = "-1" }), repeating_unless_mouse, "Workspaces: previous workspace")
create_bind(vars.kbNextWs, hl.dsp.focus({ workspace = "+1" }), repeating_unless_mouse, "Workspaces: next workspace")
create_bind(vars.kbPrevWsGroup, hl.dsp.focus({ workspace = "-10" }), repeating_unless_mouse, "Workspaces: previous workspace group")
create_bind(vars.kbNextWsGroup, hl.dsp.focus({ workspace = "+10" }), repeating_unless_mouse, "Workspaces: next workspace group")

create_bind(vars.kbMoveWinToWsNext, hl.dsp.window.move({ workspace = "+1" }), repeating_unless_mouse,
    "Workspaces: move window to next workspace")
create_bind(vars.kbMoveWinToWsPrev, hl.dsp.window.move({ workspace = "-1" }), repeating_unless_mouse,
    "Workspaces: move window to previous workspace")

create_bind(vars.kbMoveWinToWsSpecial, hl.dsp.window.move({ workspace = "special:special" }), nil,
    "Workspaces: move window to special workspace")
create_bind(vars.kbMoveWinFromWsSpecial, hl.dsp.window.move({ workspace = "e+0" }), nil,
    "Workspaces: move window out of special workspace")

-----------------------
---- Window groups ----
-----------------------

create_bind(vars.kbWindowCycleNext, hl.dsp.window.cycle_next(), repeating, "Groups: next window")
create_bind(vars.kbWindowCyclePrev, hl.dsp.window.cycle_next({ next = false }), repeating, "Groups: previous window")
create_bind(vars.kbWindowGroupCycleNext, hl.dsp.group.next(), repeating, "Groups: next tab in group")
create_bind(vars.kbWindowGroupCyclePrev, hl.dsp.group.prev(), repeating, "Groups: previous tab in group")
create_bind(vars.kbToggleGroup, hl.dsp.group.toggle(), nil, "Groups: make / dissolve group")
create_bind(vars.kbUngroup, hl.dsp.window.move({ out_of_group = true }), nil, "Groups: move window out of group")
create_bind(vars.kbGroupLockActive, hl.dsp.group.lock_active(), nil, "Groups: lock / unlock group")

------------------------
---- Window actions ----
------------------------

create_bind(vars.kbFocusLeft, hl.dsp.focus({ direction = "left" }), nil, "Windows: focus left")
create_bind(vars.kbFocusDown, hl.dsp.focus({ direction = "down" }), nil, "Windows: focus down")
create_bind(vars.kbFocusUp, hl.dsp.focus({ direction = "up" }), nil, "Windows: focus up")
create_bind(vars.kbFocusRight, hl.dsp.focus({ direction = "right" }), nil, "Windows: focus right")

for _, dir in ipairs({ "left", "right", "up", "down" }) do
    create_bind("SUPER + SHIFT + " .. dir, hl.dsp.window.move({ direction = dir }), nil, "Windows: move window " .. dir)
end

create_bind(vars.kbWindowDecreaseWidth, fn.resize_active_window(-10, 0), repeating, "Windows: narrower")
create_bind(vars.kbWindowIncreaseWidth, fn.resize_active_window(10, 0), repeating, "Windows: wider")
create_bind(vars.kbWindowDecreaseHeight, fn.resize_active_window(0, -10), repeating, "Windows: shorter")
create_bind(vars.kbWindowIncreaseHeight, fn.resize_active_window(0, 10), repeating, "Windows: taller")

create_bind({ vars.kbMoveWindow, "SUPER + mouse:272" }, hl.dsp.window.drag(), mouse, "Windows: drag to move")
create_bind({ vars.kbResizeWindow, "SUPER + mouse:273" }, hl.dsp.window.resize(), mouse, "Windows: drag to resize")
create_bind(vars.kbCenterWindow, hl.dsp.window.center(), nil, "Windows: centre (floating)")
create_bind(vars.kbNormalizeWindow, function()
    hl.dispatch(hl.dsp.window.resize(fn.resize_by_screen(55, 70)))
    hl.dispatch(hl.dsp.window.center())
end, nil, "Windows: resize to 55% x 70% and centre")
create_bind(vars.kbWindowPip, function()
    local a = hl.get_active_window()
    if a then
        local pip = fn.move_actions(a) or {}
        if not a.floating then table.insert(pip, 1, hl.dsp.window.float()) end
        table.insert(pip, hl.dsp.window.pin({ action = "on", window = "address:" .. a.address }))

        for _, x in ipairs(pip) do
            hl.dispatch(x)
        end
    end
end, nil, "Windows: picture-in-picture (float, shrink, pin to corner)")
create_bind(vars.kbPinWindow, hl.dsp.window.pin(), nil, "Windows: pin (show on every workspace)")
create_bind(vars.kbWindowFullscreen, hl.dsp.window.fullscreen({ mode = "fullscreen" }), nil, "Windows: fullscreen")
create_bind(vars.kbWindowBorderedFullscreen, hl.dsp.window.fullscreen({ mode = "maximized" }), nil, "Windows: maximize (keep gaps and bar)")
create_bind(vars.kbToggleWindowFloating, hl.dsp.window.float(), nil, "Windows: toggle floating")
create_bind(vars.kbCloseWindow, hl.dsp.window.close(), nil, "Windows: close")

-----------------------------------
---- Special workspace toggles ----
-----------------------------------

create_bind(vars.kbSpecialWs, fn.toggle("specialws"), nil, "Special: show / hide special workspace")
create_bind(vars.kbSystemMonitorWs, fn.toggle("sysmon"), nil, "Special: system monitor (btop)")
create_bind(vars.kbMusicWs, fn.toggle("music"), nil, "Special: music")
create_bind(vars.kbCommunicationWs, fn.toggle("communication"), nil, "Special: communication")
create_bind(vars.kbTodoWs, fn.toggle("todo"), nil, "Special: todo")

--------------
---- Apps ----
--------------

create_bind(vars.kbTerminal, hl.dsp.exec_cmd(vars.terminal), nil, "Apps: terminal")
create_bind(vars.kbBrowser, hl.dsp.exec_cmd(vars.browser), nil, "Apps: browser")
create_bind(vars.kbEditor, hl.dsp.exec_cmd(vars.editor), nil, "Apps: editor")
create_bind(vars.kbFileExplorer, hl.dsp.exec_cmd(vars.fileExplorer), nil, "Apps: file manager")
create_bind(vars.kbAudioSettings, hl.dsp.exec_cmd(vars.audioSettings), nil, "Apps: audio settings")

-------------------
---- Utilities ----
-------------------

-- TEMPORARY screenshots (Phase 11 replaces these with the shell's area picker)
create_bind(vars.kbScreenshot, hl.dsp.exec_cmd("grim - | wl-copy"), locked, "Utilities: screenshot (to clipboard)")
create_bind(vars.kbScreenshotRegion, hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'), nil,
    "Utilities: screenshot a region (to clipboard)")
create_bind(vars.kbColorPicker, hl.dsp.exec_cmd("hyprpicker -a"), nil, "Utilities: colour picker")

-- Keybind cheat sheet: every bind with a description, searchable in rofi
create_bind(vars.kbShowKeybinds, hl.dsp.exec_cmd(vars.keybindsCmd), nil, "Utilities: show this keybind list")

-------------------------------
---- Brightness and media ----
-------------------------------

-- TEMPORARY: Phase 8 routes these through the shell so it can show an OSD
create_bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), locked_repeating, "Media: brightness up")
create_bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), locked_repeating, "Media: brightness down")

create_bind({ vars.kbMediaToggle, "XF86AudioPlay", "XF86AudioPause" }, hl.dsp.exec_cmd("playerctl play-pause"), locked,
    "Media: play / pause")
create_bind({ vars.kbMediaNext, "XF86AudioNext" }, hl.dsp.exec_cmd("playerctl next"), locked, "Media: next track")
create_bind({ vars.kbMediaPrev, "XF86AudioPrev" }, hl.dsp.exec_cmd("playerctl previous"), locked, "Media: previous track")
create_bind({ vars.kbMediaStop, "XF86AudioStop" }, hl.dsp.exec_cmd("playerctl stop"), locked, "Media: stop")

----------------
---- Volume ----
----------------

create_bind({ vars.kbVolumeMute, "XF86AudioMute" }, hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), locked,
    "Media: mute / unmute")
create_bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), locked,
    "Media: mute / unmute microphone")
create_bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd(
        "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l " ..
        (vars.volumeMax / 100) .. " @DEFAULT_AUDIO_SINK@ " .. vars.volumeStep .. "%+"
    ),
    locked_repeating,
    "Media: volume up"
)
create_bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd(
        "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. vars.volumeStep .. "%-"
    ),
    locked_repeating,
    "Media: volume down"
)

