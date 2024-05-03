local mod = require("core/mods")
local menu = include("midididi/lib/menu")
local midididi = include("midididi/lib/midididi")
local data_file = _path.data .. mod.this_name .. "/mod.state"

mod.hook.register("script_pre_init", "midididi remove norns midi event hook", function()
    local selected_device
    if util.file_exists(data_file) then
        selected_device = tab.load(data_file).selected_device
    else
        selected_device = 1
    end
    midididi.init()
    midididi.set_device(selected_device)
end)

mod.hook.register("script_post_cleanup", "midididi remove norns midi event hook", function()
    midididi.cleanup()
end)

menu.on_device_change = midididi.set_device

mod.menu.register(mod.this_name, menu)
