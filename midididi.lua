--- midididi

reflection = require("reflection")

local patterns = {}
local screen_dirty = false
local rec = false
local norns_midi_event

local MIDI_EVENT_CODES = {
    [0x80] = "note_off",
    [0x90] = "note_on",
    [0xB0] = "cc",
}

local function get_pattern(midi_channel, midi_param)
    if patterns[midi_channel] == nil then
        patterns[midi_channel] = {}
    end

    local pattern = patterns[midi_channel][midi_param]
    if pattern == nil then
        pattern = reflection.new()
        patterns[midi_channel][midi_param] = pattern
        pattern:set_loop(1)
        pattern.process = function(event)
            norns_midi_event(event.device_id, event.midi_msg)
        end
    end

    return pattern
end

local function on_midi_event(device_id, midi_msg)
    local event_code = midi_msg[1] & 0xF0
    local channel = midi_msg[1] & 0x0F
    local param = midi_msg[2]
    local event = MIDI_EVENT_CODES[event_code]
    local pattern = get_pattern(channel, param)

    if event == "note_on" then
        pattern:clear()
        pattern:set_rec(1)
        rec = true
    elseif event == "note_off" then
        pattern:set_rec(0)
        rec = false
    elseif event == "cc" then
        if pattern.rec == 0 then
            pattern:clear()
        end
        pattern:watch({ device_id = device_id, midi_msg = midi_msg })
    end

    norns_midi_event(device_id, midi_msg)
end

function init()
    params:add_number("num", "num", 0, 100)
    params:set_action("num", function()
        screen_dirty = true
    end)
    clock.run(function()
        while true do
            if screen_dirty then
                redraw()
            end
            clock.sleep(1 / 30)
        end
    end)

    norns_midi_event = _norns.midi.event
    _norns.midi.event = on_midi_event
end

function key(n, z)
    if n == 3 and z == 1 then
        r()
    end
end

function redraw()
    screen.clear()
    screen.move(10, 10)
    screen.font_size(10)
    screen.text(rec and "rec" or "")
    screen.move(55, 30)
    screen.font_size(24)
    screen.text(params:get("num"))
    screen.update()
end

function r()
    norns.script.load("code/midididi/midididi.lua")
end
