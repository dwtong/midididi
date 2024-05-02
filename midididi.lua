--- midididi

local midididi = include("lib/midididi")
local screen_dirty = false

rec_states = {}

function init()
    for i = 1, 16 do
        params:add_number("num" .. i, "num" .. i, 0, 100)
        params:set_action("num" .. i, function()
            screen_dirty = true
        end)
    end

    clock.run(function()
        while true do
            if screen_dirty then
                redraw()
            end
            clock.sleep(1 / 30)
        end
    end)

    midididi.init()
    midididi.on_rec_change(function(device_id, channel, event_id, rec_state)
        for param, pmap in pairs(norns.pmap.data) do
            if pmap.dev == device_id and pmap.ch == channel and pmap.cc == event_id then
                rec_states[param] = rec_state
                screen_dirty = true
            end
        end
    end)
end

function key(n, z)
    if n == 3 and z == 1 then
        r()
    end
end

function redraw()
    screen.clear()
    for i = 1, 16 do
        local x = math.floor((i - 1) / 4) * 32 + 0
        local y = (i - 1) % 4 * 12 + 18
        screen.move(x, y)
        screen.font_size(9)
        screen.text(params:get("num" .. i))
        if rec_states["num" .. i] == 1 then
            screen.move(x + 11, y - 1)
            screen.font_size(7)
            screen.text("rec")
        end
    end
    screen.update()
end

function r()
    norns.script.clear()
    norns.script.load("code/midididi/midididi.lua")
end
