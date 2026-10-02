local vars = require("variables")

-- Give the "tag" to every window matching one of `matches`.
-- With `field`, matches is a list of strings for that field (e.g. "class").
-- Without it, matches is a list of full match tables.
local function tagged_rule(tag, matches, field)
    for _, match in ipairs(matches) do
        if field then
            match = { [field] = match }
        end
        hl.window_rule({ match = match, tag = "+" .. tag })
    end
end

-- Say what a tag actually does
local function create_tag(tag, rules)
    local rule = { match = { tag = tag } }
    for k, v in pairs(rules) do
        rule[k] = v
    end
    hl.window_rule(rule)
end


----------------------
---- Window rules ----
----------------------

-- Every non-fullscreen window is slightly see-through (blur shows behind it)
hl.window_rule({ match = { fullscreen = false }, opacity = vars.windowOpacity .. " override" })

-- Centre floating windows (not xwayland: its popups are windows too)
hl.window_rule({ match = { float = true, xwayland = false }, center = true })

-- Picture in picture (resizing is done in execs.lua)
hl.window_rule({
    match             = { title = "Picture(-| )in(-| )[Pp]icture" },
    move              = "(monitor_w*0.98-window_w) (monitor_h*0.97-window_h)",
    pin               = true,
    float             = true,
    keep_aspect_ratio = true,
})


----------------------
---- Tagged rules ----
----------------------

-- Apps that handle their own transparency, or must never be see-through
tagged_rule("opaque", {
    "kitty",                         -- Terminal (set background_opacity in kitty.conf instead)
    "org.quickshell",                -- Quickshell
    "feh|imv|swappy",                -- Image viewers
    "krita|gimp|inkscape|darktable", -- Image editors
    "blender|godot",                 -- 3D editors
}, "class")

-- Floating apps
tagged_rule("float", {
    "yad|zenity",                       -- Dialogs
    "wev",                              -- Input detector
    "org.gnome.FileRoller|file-roller", -- Archive manager
    "blueman-manager",                  -- Bluetooth GUI
    "feh|imv|swappy",                   -- Image viewers
    "org.quickshell",                   -- Quickshell
}, "class")
tagged_rule("float", {
    "File (Operation|Upload)( Progress)?", -- File copy/move progress
    ".* Properties",                       -- File properties
    'Rename ".*"',                         -- File renaming
}, "title")

-- Sized floaters: 60% x 70% of the monitor
tagged_rule("float_60_70", {
    "(Select|Open)( a)? (File|Folder)(s)?", -- File dialogs
    "Save As",                              -- Save dialogs
}, "title")
tagged_rule("float_60_70", {
    "org.pulseaudio.pavucontrol|com.saivert.pwvucontrol", -- Audio control
}, "class")

-- 70% x 80%
tagged_rule("float_70_80", { "org.gnome.Settings" }, "class")

-- Games
tagged_rule("game", {
    "steam_app_[0-9]+",  -- Steam games
    "steam_app_default", -- Lutris games
    "gamescope",         -- Gamescope
}, "class")

-- Xwayland popups (menus of X11 apps)
tagged_rule("xwl_popup", {
    { xwayland = true, title = "win[0-9]+" },
    { xwayland = true, title = "",         class = "", initial_title = "", initial_class = "" },
})

-- Apps that belong on special workspaces
tagged_rule("system_monitor", { "btop" }, "class")
tagged_rule("music_player", { "Spotify" }, "class")
tagged_rule("music_player", { "Spotify|Spotify Free" }, "initial_title")
tagged_rule("communication_app", { "discord|vesktop|equibop" }, "class")


-------------------------
---- Tag definitions ----
-------------------------
-- These must come after every rule that adds a tag

create_tag("opaque", { opaque = true })
create_tag("float", { float = true })
create_tag("float_60_70", { float = true, size = "(monitor_w*0.6) (monitor_h*0.7)", center = true })
create_tag("float_70_80", { float = true, size = "(monitor_w*0.7) (monitor_h*0.8)", center = true })
create_tag("game", { opaque = true, immediate = true, idle_inhibit = "always" })
create_tag("xwl_popup", {
    no_dim    = true,
    no_shadow = true,
    no_blur   = true,
    opaque    = true,
    rounding  = math.min(10, vars.windowRounding),
})
create_tag("system_monitor", { workspace = "special:sysmon" })
create_tag("music_player", { workspace = "special:music" })
create_tag("communication_app", { workspace = "special:communication" })


-------------------------
---- Workspace rules ----
-------------------------

-- A lone tiled window (or a lone fullscreen one) gets bigger outer gaps
hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = vars.singleWindowGapsOut })
hl.workspace_rule({ workspace = "f[1]s[false]", gaps_out = vars.singleWindowGapsOut })


---------------------
---- Layer rules ----
---------------------

hl.layer_rule({ match = { namespace = "hyprpicker" }, animation = "fade" })              -- Colour picker
hl.layer_rule({ match = { namespace = "selection" }, animation = "fade" })               -- slurp
hl.layer_rule({ match = { namespace = "rofi" }, animation = "popin 80%", blur = true })  -- TEMPORARY until Phase 7

