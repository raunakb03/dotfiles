local vars = require("variables")
local fn   = require("utils.functions")

-- Runs once, when Hyprland starts (NOT on `hyprctl reload`)
hl.on("hyprland.start", function()
    -- Keyring and auth
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    -- Clipboard history
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Auto delete trash 30 days old
    hl.exec_cmd("trash-empty 30")

    -- Cursors
    hl.exec_cmd("hyprctl setcursor " .. vars.cursorTheme .. " " .. vars.cursorSize)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme " .. vars.cursorTheme)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size " .. vars.cursorSize)

    -- Forward bluetooth headphone buttons to MPRIS
    hl.exec_cmd("mpris-proxy")

    -- TEMPORARY: replaced by our own shell in later phases

    -- Our shell (bar, wallpaper, ...)
    hl.exec_cmd(vars.shellCmd)
    hl.exec_cmd("playerctld daemon")  -- Phase 8 (media keys use playerctl until then)
end)

-- Picture-in-picture windows: shrink and park them in the bottom-right corner
local function apply_resizer_rules(win)
    local pip_actions = fn.move_actions(win) or {}
    fn.resizer(win, "Picture[- ]in[- ][Pp]icture", 0, 0, pip_actions, false)
end

hl.on("window.title", apply_resizer_rules)
hl.on("window.open", apply_resizer_rules)

