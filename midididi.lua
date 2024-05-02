--- midididi

reflection = require("reflection")

local patterns = {}
local screen_dirty = false
local norns_midi_event

-- adjust this value if you find bumping the knob is clearing the loop
local TOLERANCE = 1

local MIDI_EVENT_CODES = {
    [0x80] = "note_off",
    [0x90] = "note_on",
    [0xB0] = "cc",
}

local function create_pattern(device_id, channel, event_id)
    local pattern = {}
    pattern.device_id = device_id
    pattern.channel = channel
    pattern.event_id = event_id
    pattern.loop = reflection:new()
    pattern.loop:set_loop(1)
    pattern.loop.process = function(event)
        norns_midi_event(event.device_id, event.midi_msg)
    end
    table.insert(patterns, pattern)
    return pattern
end

local function get_pattern(device_id, channel, event_id)
    for _, p in pairs(patterns) do
        if p.device_id == device_id and p.channel == channel and p.event_id == event_id then
            return p
        end
    end
end

local function device_recording_enabled(device_id)
    return true
end

local function on_midi_event(device_id, midi_msg)
    if not device_recording_enabled(device_id) then
        norns_midi_event(device_id, midi_msg)
        return
    end
    local event_code = midi_msg[1] & 0xF0
    local channel = (midi_msg[1] & 0x0F) + 1
    local event_id = midi_msg[2]
    local event = MIDI_EVENT_CODES[event_code]
    local value = midi_msg[3]
    local pattern = get_pattern(device_id, channel, event_id)
    if pattern == nil and device_recording_enabled(device_id) then
        pattern = create_pattern(device_id, channel, event_id)
    end

    if event == "note_on" then
        pattern.loop:clear()
        pattern.loop:set_rec(1)
    elseif pattern and event == "note_off" then
        pattern.loop:set_rec(0)
    elseif pattern and event == "cc" then
        if pattern.loop.rec == 0 and math.abs(pattern.last_value - value) > TOLERANCE then
            pattern.loop:clear()
        end
        pattern.last_value = value
        pattern.loop:watch({ device_id = device_id, midi_msg = midi_msg })
    end

    norns_midi_event(device_id, midi_msg)
end

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
    for i = 1, 16 do
        local x = math.floor((i - 1) / 4) * 32 + 0
        local y = (i - 1) % 4 * 12 + 18
        local pmap = norns.pmap.data["num" .. i]
        local pattern = get_pattern(pmap.dev, pmap.ch, pmap.cc)
        screen.move(x, y)
        screen.font_size(9)
        screen.text(params:get("num" .. i))
        if pattern and pattern.loop.rec == 1 then
            screen.move(x + 11, y - 1)
            screen.font_size(7)
            screen.text("rec")
        end
    end
    screen.update()
end

function r()
    norns.script.load("code/midididi/midididi.lua")
end
