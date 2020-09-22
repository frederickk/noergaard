-- Noergaard
-- Simple
--
-- Generates Noergaard infinity
-- sequences, played using
-- the PolyPerc engine. 
-- There are no controls, it
-- just starts and goes on... 
-- infinitely
-- 

engine.name = 'PolyPerc'

local noergaard = include("lib/noergaard")

local note_index = 1

--- Handler for clock update sync.
local function update()
  while true do
    clock.sync(1)

    -- play the notes
    engine.hz(noergaard.get_note_freq(note_index))

    -- compute the steps
    if note_index > 2 then
      noergaard.step()
    end
    
    note_index = note_index + 1
    
    redraw()
  end
end

--- Initialize.
function init()
  screen.aa(0)
  screen.font_size(30)
  screen.ping()
  
  -- setup engine params
  engine.amp(1)
  engine.release(2)
  engine.cutoff(700)

  -- seed initial intervals
  noergaard.step()

  clock.run(update)
end

--- Handler for screen redraw.
function redraw() 
  screen.clear()

  screen.move(5, 40)
  screen.text(noergaard.get_interval(note_index))

  screen.move(123, 40)
  screen.text_right(noergaard.get_note_name(note_index))

  screen.update()
end