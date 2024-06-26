local Midididi = {}

local reflection = require("reflection")

local patterns = {}
local norns_midi_event

-- try adjusting these if you find yourself accidentally clearing loops by bumping knobs
local TOLERANCE_TIME_MS = 200 -- time after recording cc loop stops before it can be cleared
local TOLERANCE_DISTANCE = 0 -- difference between cc values after cc loop stops before it can be cleared

local MIDI_EVENT_CODES = {
    [0x80] = "note_off",
    [0x90] = "note_on",
    [0xB0] = "cc",
}

local on_rec_change
local enabled_device_id

local function create_pattern(device_id, channel, event_id)
    local pattern = {}
    pattern.device_id = device_id
    pattern.channel = channel
    pattern.event_id = event_id
    pattern.last_value = 0
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

local function on_midi_event(device_id, midi_msg)
    if device_id ~= enabled_device_id then
        norns_midi_event(device_id, midi_msg)
        return
    end
    local event_code = midi_msg[1] & 0xF0
    local channel = (midi_msg[1] & 0x0F) + 1
    local event_id = midi_msg[2]
    local event = MIDI_EVENT_CODES[event_code]
    local value = midi_msg[3]
    local pattern = get_pattern(device_id, channel, event_id)
    if pattern == nil then
        pattern = create_pattern(device_id, channel, event_id)
    end

    if event == "note_on" then
        pattern.loop:clear()
        pattern.loop:set_rec(1)
        if on_rec_change ~= nil then
            on_rec_change(device_id, channel, event_id, 1)
        end
    elseif pattern and event == "note_off" then
        pattern.loop:set_rec(0)
        pattern.tolerance_time_passed = false
        clock.run(function()
            clock.sleep(TOLERANCE_TIME_MS / 1000)
            pattern.tolerance_time_passed = true
        end)
        if on_rec_change ~= nil then
            on_rec_change(device_id, channel, event_id, 0)
        end
    elseif pattern and event == "cc" then
        local tolerance_distance = math.abs(pattern.last_value - value) > TOLERANCE_DISTANCE
        if pattern.loop.rec == 0 and tolerance_distance and pattern.tolerance_time_passed then
            pattern.loop:clear()
        end
        pattern.last_value = value
        pattern.loop:watch({ device_id = device_id, midi_msg = midi_msg })
    end

    norns_midi_event(device_id, midi_msg)
end

function Midididi.init()
    norns_midi_event = _norns.midi.event
    _norns.midi.event = on_midi_event
end

function Midididi.cleanup()
    if norns_midi_event ~= nil then
        _norns.midi.event = norns_midi_event
    end
end

function Midididi.on_rec_change(callback)
    on_rec_change = callback
end

function Midididi.set_device(device_id)
    enabled_device_id = device_id
end

return Midididi
