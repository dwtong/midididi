local mod = require("core/mods")
local midididi = include("midididi/lib/midididi")

mod.hook.register("script_pre_init", "midididi remove norns midi event hook", function()
    midididi.init()
    midididi.on_rec_change(function(device_id, channel, event_id, rec_state)
        print(device_id, channel, event_id, rec_state)
    end)
end)

mod.hook.register("script_post_cleanup", "midididi remove norns midi event hook", function()
    midididi.cleanup()
    print("norns midi event", _norns.midi.event)
end)
