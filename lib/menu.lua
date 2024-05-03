local Menu = {}

local mod = require("core/mods")

local data_dir = _path.data .. mod.this_name
local data_file = data_dir .. "/mod.state"

-- default state
local state = {
    selected_device = 1,
}

local function short_name(name)
    return string.len(name) <= 6 and name or util.acronym(name)
end

function Menu.key(n, z)
    if n == 2 and z == 1 then
        mod.menu.exit()
    end
end

function Menu.enc(n, d)
    if n == 3 then
        local selected_device = util.clamp(state.selected_device + d, 1, 16)
        state.selected_device = selected_device
        Menu.on_device_change(selected_device)
    end
    mod.menu.redraw()
end

function Menu.redraw()
    screen.clear()
    local device_name = short_name(midi.vports[state.selected_device].name)
    screen.font_face(1)
    screen.font_size(8)
    screen.level(15)
    screen.move(0, 10)
    screen.text("midi in")
    screen.move(120, 10)
    screen.text_right(string.format("%d (%s)", state.selected_device, device_name))
    screen.update()
end

function Menu.init()
    if util.file_exists(data_file) then
        state = tab.load(data_file)
    else
        util.make_dir(data_dir)
    end
end

function Menu.deinit()
    tab.save(state, data_file)
end

function Menu.on_device_change(_) end

return Menu
