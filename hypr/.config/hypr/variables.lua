local scheme = require("scheme.current")

return {
    ------------------
    ---- HYPRLAND ----
    ------------------

    -- Apps
    terminal                   = "kitty",
    browser                    = "zen-browser",
    editor                     = "kitty -e nvim",
    fileExplorer               = "nautilus",
    audioSettings              = "pavucontrol",

    -- Our shell (bar, wallpaper, launcher, ...); no -d: Hyprland already runs it in the background
    -- QML2_IMPORT_PATH: where Qt finds our C++ plugin (MyShell.Engine, built into engine/build/qml)
    shellCmd                   = "QML2_IMPORT_PATH=$HOME/.config/quickshell/my-first-shell/engine/build/qml qs -c my-first-shell -n",

    -- Temporary tools: each one is replaced by our own shell in a later phase
    lockCmd                    = "loginctl lock-session",                       -- logind tells our shell to lock

    -- Touchpad
    touchpadDisableTyping      = true,
    touchpadScrollFactor       = 0.3,
    gestureFingers             = 3,
    workspaceSwipeFingers      = 4,
    gestureFingersMore         = 4,

    -- Blur
    blurEnabled                = true,
    blurSpecialWs              = false,
    blurPopups                 = true,
    blurInputMethods           = true,
    blurSize                   = 8,
    blurPasses                 = 2,
    blurXray                   = false,

    -- Shadow
    shadowEnabled              = true,
    shadowRange                = 15,
    shadowRenderPower          = 4,
    shadowColour               = "rgba(" .. scheme.inversePrimary .. "10)",

    -- Gaps
    workspaceGaps              = 20,
    windowGapsIn               = 5,
    windowGapsOut              = 10,
    singleWindowGapsOut        = 5,

    -- Window styling
    windowOpacity              = 0.95,
    windowRounding             = 10,
    windowBorderSize           = 1,
    activeWindowBorderColour   = "rgba(" .. scheme.primary .. "e6)",
    inactiveWindowBorderColour = "rgba(" .. scheme.onSurfaceVariant .. "11)",

    -- Animation speeds, in units of 100 ms (2.5 = 250 ms). Smaller = faster.
    -- Caelestia's originals are in the comments.
    layersInSpeed              = 2.5, -- 5   shell panels and other layers appearing
    layersOutSpeed             = 2,   -- 4   ... disappearing
    fadeLayersSpeed            = 2.5, -- 5   ... their fade
    windowsInSpeed             = 3,   -- 5   window opening
    windowsOutSpeed            = 2,   -- 3   window closing
    windowsMoveSpeed           = 3.5, -- 6   window moving / resizing / re-tiling
    workspacesSpeed            = 3,   -- 5   switching workspace
    specialWorkspaceSpeed      = 2.5, -- 4   special workspace sliding in/out
    fadeSpeed                  = 3.5, -- 6   window fades and dimming
    borderSpeed                = 3.5, -- 6   border colour change on focus

    -- Misc
    volumeStep                 = 10,
    volumeMax                  = 100,
    cursorTheme                = "Adwaita",
    cursorSize                 = 24,
    sleepCmd                   = "systemctl suspend",

    -- Apps that live on each special workspace (used by utils/functions.lua)
    --   match   = window fields that must contain these strings
    --   command = started if no matching window exists
    --   move    = pull matching windows onto the special workspace
    specialApps                = {
        sysmon        = {
            btop = { match = { class = "btop" }, command = "kitty --class btop -T btop btop" },
        },
        music         = {
            spotify = { match = { class = "Spotify" }, move = true },
        },
        communication = {
            discord = { match = { class = "discord" }, move = true },
        },
        todo          = {},
    },

    ------------------
    ---- KEYBINDS ----
    ------------------

    -- Modifier only: the actual binds are mod + 0-9
    kbGoToWs                   = "SUPER",
    kbGoToWsGroup              = "CTRL + SUPER",
    kbMoveWinToWs              = "SUPER + SHIFT",          -- + number: send the window there (was SUPER + ALT)
    kbMoveWinToWsGroup         = "CTRL + SUPER + ALT",

    -- Everything below can be one string or a list of strings

    -- Workspaces
    kbMoveWinToWsSpecial       = { "SUPER + ALT + S", "CTRL + SUPER + SHIFT + Up" },
    kbMoveWinFromWsSpecial     = "CTRL + SUPER + SHIFT + Down",
    kbMoveWinToWsNext          = { "SUPER + ALT + mouse_down", "SUPER + ALT + Page_Down", "CTRL + SUPER + SHIFT + Right" },
    kbMoveWinToWsPrev          = { "SUPER + ALT + mouse_up", "SUPER + ALT + Page_Up", "CTRL + SUPER + SHIFT + Left" },
    kbNextWs                   = { "SUPER + mouse_down", "CTRL + SUPER + Right", "SUPER + Page_Down" },
    kbPrevWs                   = { "SUPER + mouse_up", "CTRL + SUPER + Left", "SUPER + Page_Up" },
    kbNextWsGroup              = "CTRL + SUPER + mouse_down",
    kbPrevWsGroup              = "CTRL + SUPER + mouse_up",

    -- Window groups
    kbWindowCycleNext          = "ALT + TAB",
    kbWindowCyclePrev          = "SHIFT + ALT + TAB",
    kbWindowGroupCycleNext     = "CTRL + ALT + TAB",
    kbWindowGroupCyclePrev     = "CTRL + SHIFT + ALT + TAB",
    kbUngroup                  = "SUPER + U",
    kbToggleGroup              = "SUPER + Comma",
    kbGroupLockActive          = "SUPER + SHIFT + Comma",

    -- Window actions
    kbWindowDecreaseWidth      = { "SUPER + Minus", "SUPER + ALT + Left" },
    kbWindowIncreaseWidth      = { "SUPER + Equal", "SUPER + ALT + Right" },
    kbWindowDecreaseHeight     = { "SUPER + SHIFT + Minus", "SUPER + ALT + Up" },
    kbWindowIncreaseHeight     = { "SUPER + SHIFT + Equal", "SUPER + ALT + Down" },
    kbMoveWindow               = "SUPER + Z",
    kbResizeWindow             = "SUPER + X",
    kbCenterWindow             = "CTRL + SUPER + Backslash",
    kbNormalizeWindow          = "CTRL + SUPER + ALT + Backslash",
    kbWindowPip                = "SUPER + ALT + Backslash",
    kbPinWindow                = "SUPER + P",
    kbWindowFullscreen         = "SUPER + F",              -- fake fullscreen (the app keeps its UI)
    kbWindowBorderedFullscreen = "SUPER + ALT + F",
    kbToggleWindowFloating     = "SUPER + ALT + Space",
    kbCloseWindow              = "SUPER + Q",
    kbFocusLeft                = "SUPER + H",
    kbFocusDown                = "SUPER + J",
    kbFocusUp                  = "SUPER + K",
    kbFocusRight               = "SUPER + L",

    -- Special workspace toggles
    kbSpecialWs                = "SUPER + S",
    kbSystemMonitorWs          = "CTRL + SHIFT + Escape",
    kbMusicWs                  = "",                -- disabled (was SUPER + M)
    kbCommunicationWs          = "SUPER + D",
    kbTodoWs                   = "SUPER + R",

    -- Apps
    kbTerminal                 = "SUPER + Return",
    kbBrowser                  = "SUPER + B",
    kbEditor                   = "SUPER + C",
    kbFileExplorer             = "SUPER + E",
    kbAudioSettings            = "CTRL + ALT + V",

    -- Utilities
    kbScreenshot               = "Print",
    kbScreenshotRegion         = "SUPER + SHIFT + S",
    kbColorPicker              = "SUPER + SHIFT + C",
    kbShowKeybinds             = "SUPER + slash",
    kbRestartShell             = "CTRL + SUPER + ALT + R",

    -- Media
    kbMediaToggle              = "CTRL + SUPER + Space",
    kbMediaNext                = "CTRL + SUPER + Equal",
    kbMediaPrev                = "CTRL + SUPER + Minus",
    kbMediaStop                = "CTRL + SUPER + Backspace",
    kbVolumeMute               = "SUPER + SHIFT + M",

    -- Misc
    kbLauncher                 = "SUPER + Space",
    kbExit                     = "CTRL + SUPER + ALT + Delete",
    kbLock                     = "SUPER + Escape",
    kbSleep                    = "",                       -- disabled (was SUPER + SHIFT + L; suspend is in the power menu)
    kbClipboard                = "SUPER + V",
    kbSidebar                  = "SUPER + N",              -- notification history
    kbSession                  = "CTRL + ALT + Delete",    -- power menu
    kbDashboard                = "SUPER + A",              -- dashboard (also: touch the top edge)
}
