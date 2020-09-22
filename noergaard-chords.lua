-- Noergaard
-- Chords
--
-- Generate chords from infinity
-- series intervals.
--
-- See README for details
-- 

engine.name = 'PolyPerc'

local music_util = require "musicutil"
local ui = include("lib/core/ui")
local keys = include("lib/core/keys")
local noergaard = include("lib/noergaard")


local BEAT_VALS = {
  { str = "1/256", value = 1 / 256},
  { str = "1/128", value = 1 / 128},
  { str = "1/96", value = 1 / 96},
  { str = "1/64", value = 1 / 64 },
  { str = "1/48", value = 1 / 48 },
  { str = "1/32", value = 1 / 32 },
  { str = "1/16", value = 1 / 16 },
  { str = "1/8", value = 1 / 8 },
  { str = "1/4", value = 1 / 4 },
  { str = "1/2", value = 1 / 2 },
  { str = "1", value = 1 },
  { str = "2", value = 2 },
  { str = "3", value = 3 },
  { str = "4", value = 4 },
}

local CHORD_NAMES = {
  "Noergaard",
}
for i = 1, #music_util.CHORDS do
  CHORD_NAMES[i + 1] = music_util.CHORDS[i].name
end

local midi_output
local note_index = 1

--- Handler for clock update sync.
local function update()
  local midi_note = nil
  
  while true do
    clock.sync(BEAT_VALS[params:get("beat_div")].value * 4)

    for j = 1, 12 do
      keys.pressed[j] = false
    end

    -- build the chords
    local chord = {}
    if params:get("chord_name") == 1 then
      for i = 1, params:get("chord_len") do
        local index = (note_index - i) % #noergaard.intervals
        chord[i] = noergaard.get_midi_note(index + 1)
        if note_index > 2 then
          noergaard.step()
        end
      end
      note_index = note_index + params:get("chord_len")
    else
      chord = music_util.generate_chord(noergaard.get_midi_note(note_index), CHORD_NAMES[params:get("chord_name")])
      if note_index > 2 then
        noergaard.step()
      end
      note_index = note_index + 1
    end

    -- play the chords
    for i = 1, #chord do
      engine.hz(music_util.note_num_to_freq(chord[i]))

      if midi_note ~= nil then
        midi_output:note_off(midi_note)
      end
      midi_note = chord[i]
      midi_output:note_on(chord[i])

      keys.pressed[(chord[i] % 12) + 1] = true
    end
    
    if note_index > #noergaard.intervals or 
       note_index > params:get("noergaard_len") and
       params:get("noergaard_len") ~= 0 then
      note_index = 1
    end
  end
end

--- Exposed UI handler for screen redraws.
function ui.update()
  redraw()
end

--- Create params.
local function init_params()
  ui.add_page_params(default_val) 

  params:add_separator()

  -- wrapper for listening to and setting global BPM
  params:add_number("bpm", "bpm", 20, 300, 60)
  params:set_action("bpm", function(val)
      params:set("clock_tempo", val)
    end)
  params:hide("bpm")

  params:add_number("beat_div", "Beat", 1, #BEAT_VALS, 9) -- 1/4
  params:set_action("beat_div", function(val)
      engine.release(math.min(3, 12 * BEAT_VALS[val].value))
    end)
  params:add_option("chord_name", "Chord name", CHORD_NAMES, 1)
  params:set_action("chord_name", function(val)
      note_index = 1
    end)
  params:add_number("chord_len", "Chord notes", 2, 9, 5)
  
  params:bang()
  params:read()
end

--- Initialize.
function init()
  init_params()
  
  -- init Midi
  midi_output = midi.connect(1)
  midi_output.event = midi_output_event

  -- init Midi
  engine.amp(1)
  engine.release(math.min(3, 12 * BEAT_VALS[params:get("beat_div")].value))
  engine.cutoff(700)

  -- seed initial intervals
  for i = 1, params:get("chord_len")^2 - 1 do
    noergaard.step()
  end

  update_id = clock.run(update)
end

--- Encoder input.
function enc(index, delta)
  if index == 1 then
    ui.page_delta(delta)
  end

  if ui.page_get() == 1 then
    if index == 2 then
      params:delta("bpm", delta)
    elseif index == 3 then
      params:delta("beat_div", delta)
    end
  elseif ui.page_get() == 2 then
    if index == 2 then
      params:delta("noergaard_midi_root", delta)
    elseif index == 3 then
      params:delta("chord_name", delta)
    end
  elseif ui.page_get() == 3 then
    if index == 2 then
      note_index = 1
      params:delta("noergaard_step", delta)
    elseif index == 3 then
      params:delta("noergaard_len", delta)
    end
  elseif ui.page_get() == 4 then
    if index == 2 then
      params:delta("noergaard_limit_len", delta)
    elseif index == 3 then
      if params:get("chord_name") == 1 then
        params:delta("chord_len", delta)
      end
    end
  end

  redraw()
end

--- Handler for screen redraw.
function redraw() 
  screen.clear()

  screen.level(ui.OFF)
  
  keys.draw(5, 5, 10, ui.VIEWPORT.height - 20)

  local y = ui.VIEWPORT.height - 8
  ui.highlight({1})
  screen.move(5, y)
  screen.text(string.upper(string.sub(params:string("clock_source"), 1, 1)) .. params:get("clock_tempo"))

  ui.highlight({2})
  screen.move(ui.VIEWPORT.width / 3, y)
  screen.text("Root " .. noergaard.get_midi_root())

  ui.highlight({3})
  screen.move((ui.VIEWPORT.width / 3) * 2, y)
  screen.text("Step " .. noergaard.get_step())

  ui.highlight({4})
  screen.move(ui.VIEWPORT.width - 5, y)
  screen.text_right(noergaard.limit_len)


  y = ui.VIEWPORT.height

  ui.highlight({1})
  screen.move(5, y)
  screen.text(BEAT_VALS[params:get("beat_div")].str)

  ui.highlight({2})
  screen.move(ui.VIEWPORT.width / 3, y)
  screen.text(CHORD_NAMES[params:get("chord_name")]:sub(1, 7) .. "...")

  ui.highlight({3})
  screen.move((ui.VIEWPORT.width / 3) * 2, y)
  screen.text(note_index .. "/" .. noergaard.len)

  if params:get("chord_name") == 1 then
    ui.highlight({4})
    screen.move(ui.VIEWPORT.width - 5, y)
    screen.text_right(params:get("chord_len"))
  end
  
  screen.update()
end

--- Writes params on script end.
function cleanup()
  params:write()
end