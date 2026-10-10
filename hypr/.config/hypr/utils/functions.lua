local vars = require("variables")

--------------------
---- Workspaces ----
--------------------

-- Workspaces are grouped in tens: group 1 = 1-10, group 2 = 11-20, ...
-- action: "focus" or "move". range: "group" to jump between groups.
local function wsaction(action, range, i)
    return function()
        local activews = hl.get_active_workspace()
        if activews then
            local id = activews.id
            local s  = (i - 1) * 10 + (id % 10)            -- same slot, group i
            local t  = math.floor((id - 1) / 10) * 10 + i  -- slot i, same group
            local z  = (range == "group") and s or t

            if action == "move" then
                return hl.dispatch(hl.dsp.window.move({ workspace = z }))
            else
                return hl.dispatch(hl.dsp.focus({ workspace = z }))
            end
        end
    end
end

-----------------
---- Resizing ----
-----------------

-- Size as a percentage of the active monitor, e.g. (55, 70) = 55% x 70%
local function resize_by_screen(x, y)
    local screen = hl.get_active_monitor()
    if screen and type(screen.width) == "number" and type(screen.height) == "number" then
        if not (x == 0 and y == 0) then
            local w = (x and x > 0) and math.floor(screen.width * x / 100) or screen.width
            local h = (y and y > 0) and math.floor(screen.height * y / 100) or screen.height
            return { x = w, y = h, relative = false }
        end
    end
end

-- Grow/shrink the active window by a percentage of its own size
local function resize_active_window(x, y)
    return function()
        local win = hl.get_active_window()
        if win and win.size then
            local w = win.size.x * (x / 100)
            local h = win.size.y * (y / 100)
            hl.dispatch(hl.dsp.window.resize({ x = w, y = h, relative = true }))
        end
    end
end

-- Actions that shrink `win` to a quarter of the screen height and park it
-- in the bottom-right corner (used for picture-in-picture)
local function move_actions(win)
    local screen = hl.get_active_monitor()

    if screen and screen.width and screen.height and win and win.size then
        local monitor_height = screen.height / screen.scale
        local monitor_width  = screen.width / screen.scale

        local scale_factor   = (monitor_height / 4) / win.size.y

        local x_resize       = math.floor(math.max(200, win.size.x * scale_factor))
        local y_resize       = math.floor(math.max(150, win.size.y * scale_factor))

        local offset         = math.min(monitor_width, monitor_height) * 0.03

        local move_x         = math.floor(screen.x + monitor_width - x_resize - offset)
        local move_y         = math.floor(screen.y + monitor_height - y_resize - offset)

        return {
            hl.dsp.window.resize({ x = x_resize, y = y_resize, window = win }),
            hl.dsp.window.move({ x = move_x, y = move_y, relative = false, window = win }),
        }
    end
end

-- If window[field] matches `pattern`, run `actions` on it, then resize it
local function resizer(window, pattern, x_percent, y_percent, actions, exact, field)
    local value = window and window[field or "title"]
    if value and string.find(value, pattern, 1, exact) then
        for _, action in ipairs(actions) do
            hl.dispatch(action)
        end

        -- window = ... targets THIS window, not whichever one has focus
        local size = resize_by_screen(x_percent, y_percent)
        if size then
            size.window = window
            hl.dispatch(hl.dsp.window.resize(size))
        end
        hl.dispatch(hl.dsp.window.set_prop({ prop = "keep_aspect_ratio", value = "true", window = window }))
    end
end

---------------------------------
---- Special workspace toggle ----
---------------------------------

-- True if every field in `rule` is contained in the same field of `window`
local function window_matches(window, rule)
    for key, expected in pairs(rule) do
        local actual = window[key]
        if actual == nil or not string.find(tostring(actual), expected, 1, true) then
            return false
        end
    end
    return true
end

-- Make sure the apps of a special workspace are there:
-- start them if missing, or pull stray windows in
local function place_apps(apps, name)
    local target = "special:" .. name

    for _, app in pairs(apps) do
        local found = {}
        for _, window in ipairs(hl.get_windows() or {}) do
            if window_matches(window, app.match) then
                table.insert(found, window)
            end
        end

        if #found == 0 then
            if app.command then
                hl.dispatch(hl.dsp.exec_cmd(app.command, { workspace = target }))
            end
        elseif app.move then
            for _, window in ipairs(found) do
                local ws = window.workspace and window.workspace.name
                if ws ~= target then
                    hl.dispatch(hl.dsp.window.move({ window = window, workspace = target, follow = false }))
                end
            end
        end
    end
end

-- Returns a function that opens/closes special workspace `name`.
-- "specialws" means: close whichever special is open, or open "special".
local function toggle(name)
    return function()
        local active = hl.get_active_special_workspace()

        if name == "specialws" then
            local target = active and active.name:gsub("^special:", "") or "special"
            return hl.dispatch(hl.dsp.workspace.toggle_special(target))
        end

        local already_open = active and active.name == "special:" .. name

        if not already_open then
            hl.dispatch(hl.dsp.focus({ workspace = "special:" .. name }))
        end

        place_apps(vars.specialApps[name] or {}, name)

        if already_open then
            hl.dispatch(hl.dsp.workspace.toggle_special(name))
        end
    end
end

return {
    wsaction             = wsaction,
    resize_by_screen     = resize_by_screen,
    resize_active_window = resize_active_window,
    move_actions         = move_actions,
    resizer              = resizer,
    toggle               = toggle,
}
