local vars = require("variables")

hl.config({
    animations = {
        enabled = true,
    },
})

-- Animation curves
hl.curve("specialWorkSwitch", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("emphasizedAccel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("emphasizedDecel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("standard", { type = "bezier", points = { { 0.2, 0 }, { 0, 1 } } })

-- Animation configs
hl.animation({ leaf = "layersIn", enabled = true, speed = vars.layersInSpeed, bezier = "emphasizedDecel", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = vars.layersOutSpeed, bezier = "emphasizedAccel", style = "slide" })
hl.animation({ leaf = "fadeLayers", enabled = true, speed = vars.fadeLayersSpeed, bezier = "standard" })

hl.animation({ leaf = "windowsIn", enabled = true, speed = vars.windowsInSpeed, bezier = "emphasizedDecel" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = vars.windowsOutSpeed, bezier = "emphasizedAccel" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = vars.windowsMoveSpeed, bezier = "standard" })
hl.animation({ leaf = "workspaces", enabled = true, speed = vars.workspacesSpeed, bezier = "standard" })

hl.animation({
    leaf    = "specialWorkspace",
    enabled = true,
    speed   = vars.specialWorkspaceSpeed,
    bezier  = "specialWorkSwitch",
    style   = "slidefadevert 15%"
})
hl.animation({ leaf = "fade", enabled = true, speed = vars.fadeSpeed, bezier = "standard" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = vars.fadeSpeed, bezier = "standard" })
hl.animation({ leaf = "border", enabled = true, speed = vars.borderSpeed, bezier = "standard" })

