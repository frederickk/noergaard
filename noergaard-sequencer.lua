-- Noergaard
-- Sequencer
-- 
-- A fairly simple sequencer that
-- plays infinity sequences.
--
-- See README for details
-- 

engine.name = 'PolyPerc'

local music_util = require "musicutil"
local ui = include("lib/core/ui")
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

local SCALE_NAMES = {
  "Noergaard",
}
for i = 1, #music_util.SCALES do
  SCALE_NAMES[i + 1] = music_util.SCALES[i].name
end


local midi_output
local staff = {}
local note_index = 1

--- Handler for clock update sync.
local function update()
  local midi_note = nil
  
  while true do
    clock.sync(BEAT_VALS[params:get("beat_div")].value * 4)

    if midi_note ~= nil then
      midi_output:note_off(midi_note)
    end
    
    -- play the notes
    midi_note = noergaard.get_midi_note(note_index)

    if params:get("scale_name") ~= 1 then
      local scale_name = SCALE_NAMES[params:get("scale_name")]
      midi_note = noergaard.get_midi_note_scale(scale_name, note_index)
      engine.hz(noergaard.get_note_freq_scale(scale_name, note_index))
      midi_output:note_on(midi_note)
    else
      engine.hz(noergaard.get_note_freq(note_index))
      midi_output:note_on(midi_note)
    end

    note_index = note_index + params:get("increment")

    -- compute the steps
    if note_index >= #noergaard.intervals then
      for i = 1, params:get("increment") do
        noergaard.step()
      end
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

  params:add_number("beat_div", "Beat", 1, #BEAT_VALS, 8) -- 1/8
  params:add_option("scale_name", "Chord name", SCALE_NAMES, 1)
  params:set_action("scale_name", function(val)
      note_index = 1
    end)
  params:add_number("increment", "Increment", 1, 8, 1)
  
  params:bang()
  params:read()

  -- Create staff
  local num_lines = 7
  local staff_height = ui.VIEWPORT.height - 15
  local staff_offset = 1
  for i = 1, num_lines do  
    staff[i] = ((staff_height / num_lines) * i) + staff_offset
  end
end

--- Initialize.
function init()
  init_params()

  engine.amp(1)
  engine.release(math.min(3, 12 * BEAT_VALS[params:get("beat_div")].value))
  engine.cutoff(700)

  -- init Midi
  midi_output = midi.connect(1)
  midi_output.event = midi_output_event

  -- seed initial intervals
  for i = 1, params:get("increment")^2 - 1 do
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
      params:delta("scale_name", delta)
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
      params:delta("increment", delta)
    end
  end

  redraw()
end

--- Draws notes onto the staff.
function draw_notes()
  local note_ids = {"d", "c", "b", "a", "g", "f", "e"}

  for i = 1, #noergaard.intervals do    
    local noergaard_note = noergaard.get_note_name(i)
    if params:get("scale_name") ~= 1 then
      local midi_note = noergaard.get_midi_note_scale(SCALE_NAMES[params:get("scale_name")], i)
      noergaard_note = music_util.note_num_to_name(midi_note, true)
    end
    local note_id = string.lower(string.sub(noergaard_note, 1, 1))

    for j = 1, #note_ids do
      if note_id == note_ids[j] then
        if i == note_index - 1 then
          screen.level(ui.ON)
        else
          screen.level(ui.OFF)
        end
        screen.move(5 + (i % 16) * 6, staff[j] - 1)
        screen.text(noergaard.get_interval(i) .. " " .. noergaard_note)
        
        break
      end
    end
  end

end

--- Handler for screen redraw.
function redraw() 
  screen.clear()

  screen.level(ui.OFF)
  for i = 1, #staff do  
    screen.move(0, staff[i])
    screen.line(ui.VIEWPORT.width, staff[i])
  end
  screen.stroke()

  draw_notes()

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
  screen.text(SCALE_NAMES[params:get("scale_name")]:sub(1, 7) .. "...")

  ui.highlight({3})
  screen.move((ui.VIEWPORT.width / 3) * 2, y)
  screen.text(note_index .. "/" .. noergaard.len)

  ui.highlight({4})
  screen.move(ui.VIEWPORT.width - 5, y)
  screen.text_right(params:get("increment"))

  screen.update()
end

--- Writes params on script end.
function cleanup()
  params:write()
end