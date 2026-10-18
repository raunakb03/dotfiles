-- Is an external monitor (HDMI / DisplayPort) plugged in?
local function external_connected()
    local p = io.popen("cat /sys/class/drm/card*-HDMI-*/status /sys/class/drm/card*-DP-*/status 2>/dev/null")
    if not p then return false end
    local out = p:read("*a")
    p:close()
    return out:find("^connected") ~= nil or out:find("\nconnected") ~= nil
end

if external_connected() then
    -- Docked: use only the external monitor, laptop screen off
    hl.monitor({ output = "eDP-1", disabled = true })
    hl.monitor({
        output   = "HDMI-A-1",
        mode     = "2560x1440@144",
        position = "0x0",
        scale    = 1.25,
    })
else
    -- Laptop screen: 1920x1080 @ 144 Hz, scaled to 1.33 (from my old hyprland.conf)
    hl.monitor({
        output   = "eDP-1",
        mode     = "1920x1080@144",
        position = "0x0",
        scale    = 1.333333,
    })
end

-- Re-apply the layout above when a monitor is plugged in or unplugged
local function relayout()
    local laptop_on = hl.get_monitor("eDP-1") ~= nil
    if external_connected() == laptop_on then
        hl.exec_cmd("hyprctl reload")
    end
end
hl.on("monitor.added", relayout)
hl.on("monitor.removed", relayout)

-- Caps Lock acts as Ctrl
hl.config({
    input = {
        kb_options = "ctrl:nocaps",
    },
})
