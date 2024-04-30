--- midididi

reflection = require("reflection")

local num = 0
local pattern = reflection.new()
local screen_dirty = false

pattern.process = function(event)
    num = event.value
    screen_dirty = true
end

function pattern.start_callback() -- user-script callback
    print("playback started", clock.get_beats())
end

function pattern.end_of_rec_callback() -- user-script callback
    print("recording finished", clock.get_beats())
end

function pattern.end_of_loop_callback() -- user-script callback
    print("loop ended", clock.get_beats())
end

function pattern.end_callback() -- user-script callback
    print("playback ended")
end

function init()
    pattern:set_loop(1)
    clock.run(function()
        while true do
            if screen_dirty then
                redraw()
            end
            clock.sleep(1 / 30)
        end
    end)
end

function enc(n, d)
    if n == 3 then
        if pattern.rec == 0 then
            pattern:clear()
        end
        num = num + d
        pattern:watch({ value = num })
    end
    screen_dirty = true
end

function key(n, z)
    if n == 2 then
        if z == 1 then
            pattern:clear()
            pattern:set_rec(1)
        else
            pattern:set_rec(0)
        end
    end
    if n == 3 and z == 1 then
        r()
    end
    screen_dirty = true
end

function redraw()
    screen.clear()
    screen.move(10, 10)
    screen.font_size(10)
    screen.text(pattern.rec == 1 and "rec" or "")
    screen.text(pattern.rec == 0 and pattern.play == 1 and "play" or "")
    screen.move(55, 30)
    screen.font_size(24)
    screen.text(num)
    screen.update()
end

function r()
    norns.script.load("code/midididi/midididi.lua")
end
