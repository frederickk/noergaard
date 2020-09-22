-- Per Nørgård
-- Uendelighedsrækken
--
-- A small library to generate Nørgård infinity sequences for Norns.
-- https://github.com/frederickk/noergaard
--

local music_util = require "musicutil"


local VERSION = "0.1.0"

local OCTAVE_OPTIONS = {"Natural", "-2", "-1", "0", "1", "2", "3", "4", "5", "6", "7", "8"}

--- Maximum number of values to store in a table (#allThePerformance)
local TABLE_MAX = 16 * 20


local Noergaard = {
  intervals = {0, 1}, -- Classic starting intervals table
  len = 0, -- Limit intervals table size; 0 = TABLE_MAX
  limit_len = false,
  octave = nil, -- Natural octave 
}


-- @private
local function number_to_binary(val)
  local bin = {}

	while val ~= 1 and val ~= 0 do
    if val % 2 == 0 then
      bin[#bin + 1] = 0
    else
      bin[#bin + 1] = 1
    end
    
    val = math.floor(val / 2)
	end

	return bin
end

-- @private
local function reset_table()
  Noergaard.intervals = {
    params:get("noergaard_start"), params:get("noergaard_step")
  }
  Noergaard.step()
end

-- @private
local function clear_table()
  Noergaard.intervals = {
    Noergaard.intervals[#Noergaard.intervals]
  }
  Noergaard.step()
end

-- @private
local function init()
  print("Noergaard " .. VERSION)

  params:add_separator("Noergaard")
  params:add_number("noergaard_start", "Start", 0, 12, 0)
  params:set_action("noergaard_start", function(val)
      reset_table()
    end)
  params:add_number("noergaard_midi_root", "MIDI root", 0, 127, 60) -- C4
  params:add_number("noergaard_step", "Step", 1, 12, 1)
  params:set_action("noergaard_step", function(val)
      reset_table()
    end)
  params:add_option("noergaard_octave", "Octave", OCTAVE_OPTIONS, 1)
  params:set_action("noergaard_octave", function(val)
      if val == 1 then
        Noergaard.octave = nil
      else
        Noergaard.octave = val - 4
      end
    end)
  params:add_number("noergaard_len", "Length", 0, TABLE_MAX, Noergaard.len)
  params:set_action("noergaard_len", function(val) 
      Noergaard.len = (val ~= 1 and val) or 2
    end)
  params:add_option("noergaard_limit_len", "Length Limit", {"No", "Yes"}, 1)
  params:set_action("noergaard_limit_len", function(val)
      Noergaard.limit_len = val
    end)
end  

--- Nørgård algorithm to compute intervals. Thank you @zebra!
-- https://llllllll.co/t/35657/9
-- @param {integer} t A table containing at least 2 values
-- @param[opt] integer step Nw interval step (default=1) 
-- @returns nothing; new value is appended to the table in-place
function Noergaard.compute(t, step)
  step = step or 1
  local n = #t -- new index (zero-based)
  local y

  if n % 2 == 0 then
    y = -1 * t[n / 2 + 1]
  else
    y = t[((n - 1) / 2) + 1] + step
  end 

  table.insert(t, y)
end 

--- Returns integer in inifinity series by index. Thank you @_greathorned!
-- https://www.lawtonhall.com/blog/2019/9/9/per-nrgrds-infinity-series
-- @param integer index Index of infinity series to calculate 
-- @returns integer Nørgård number
function Noergaard.integer(index)
	local bin = number_to_binary(index)
	local num = 0;

  for item = 1, #bin do
    if bin[item] == 0 then
      num = num * -1
    elseif bin[item] == 1 then
      num = num + 1
    end
  end

  return num
end

--- Populates intervals table with Nørgård integers within a given range. Thank you @_greathorned!
-- https://www.lawtonhall.com/blog/2019/9/9/per-nrgrds-infinity-series
-- @param integer start_index Starting index of infinity series
-- @param integer end_index Ending index of infinity series
function Noergaard.compute_subset(start_index, end_index)
  local len = end_index - start_index + 1  
  Noergaard.intervals = {}
  
  for i = start_index, end_index do  
    table.insert(Noergaard.intervals, Noergaard.integer(i))
  end
end

--- Adds interval to table, based on "start" and "step" params.
function Noergaard.step()
  if Noergaard.len > 0 then 
    -- TODO(frederickk): This is causing some problems with sequence iteration, 
    -- because the table is seeded with 2 numbers on init.
    if Noergaard.limit_len == true and #Noergaard.intervals > Noergaard.len then
      reset_table()
    else
      while #Noergaard.intervals > Noergaard.len - 1 do
        table.remove(Noergaard.intervals, 1)
      end
    end
  end

  if #Noergaard.intervals > TABLE_MAX and Noergaard.len < TABLE_MAX then
    clear_table()
  end

  Noergaard.compute(Noergaard.intervals, params:get("noergaard_step"))
end

--- Gets step increment.
-- @returns integer Step interval
function Noergaard.get_step()
  return params:get("noergaard_step")
end

--- Gets interval.
-- @param[opt] integer index interval index; no index returns last added interval
-- @returns integer Interval
function Noergaard.get_interval(index)
  local i = (index ~= nil and index) or #Noergaard.intervals

  return Noergaard.intervals[i]   
end

--- Gets Midi note number.
-- @param[opt] integer index note index; no index returns last added note
-- @returns integer Midi note number
function Noergaard.get_midi_note(index)
  local i = (index ~= nil and index) or #Noergaard.intervals
  local note = params:get("noergaard_midi_root") + Noergaard.get_interval(i)

  if Noergaard.octave ~= nil then
    note = note % 12
    note = note + 24 + (Noergaard.octave * 12)
  end

  return util.clamp((note) % 127, 0, 127)
end

--- Gets Midi note number, snapped to given scale.
-- @param string scale_type String defining scale type (eg, "major", "aeolian" or "neapolitan major"), see "musicutil" class for full list.
-- @param[opt] integer index Note index; no index returns last added note
-- @returns integer Midi note number
function Noergaard.get_midi_note_scale(scale_type, index)
  local scale_notes = music_util.generate_scale(params:get("noergaard_midi_root"), scale_type, 1)

  return music_util.snap_note_to_array(Noergaard.get_midi_note(index or nil), scale_notes)
end

--- Gets Midi root note as name + octave e.g. "C4".
-- @returns string Midi root note
function Noergaard.get_midi_root()
  return music_util.note_num_to_name(params:get("noergaard_midi_root"), true)
end

--- Gets Midi note name e.g. "C".
-- @param[opt] integer index Note index; no index returns last added note
-- @returns string Midi note name
function Noergaard.get_note_name(index)
  local i = (index ~= nil and index) or #Noergaard.intervals

  return music_util.note_num_to_name(Noergaard.get_midi_note(i), true)
end

--- Gets note as frequency name e.g. C4 => "261.63".
-- @param[opt] integer index Note index; no index returns last added note
-- @returns float Frequency value
function Noergaard.get_note_freq(index)
  local i = (index ~= nil and index) or #Noergaard.intervals

  return music_util.note_num_to_freq(Noergaard.get_midi_note(i), true)
end

--- Gets note as frequency name e.g. C4 => "261.63".
-- @param string scale_type String defining scale type (eg, "major", "aeolian" or "neapolitan major"), see "musicutil" class for full list.
-- @param[opt] integer index Note index; no index returns last added note
-- @returns float Frequency value
function Noergaard.get_note_freq_scale(scale_type, index)
  local i = (index ~= nil and index) or #Noergaard.intervals

  return music_util.note_num_to_freq(Noergaard.get_midi_note_scale(scale_type, i), true)
end

--- Sets octave to lock Midi notes to.
-- @param[opt] integer index Midi octave value -2 to 8; no index sets octave to "Natural".
function Noergaard.set_octave(index)
  params:set("noergaard_octave", (index + 4) or 1)
end

--- Gets octave as string.
-- @returns string Octave value
function Noergaard.get_octave()
  return OCTAVE_OPTIONS[params:get("noergaard_octave")]
end

init()

return Noergaard