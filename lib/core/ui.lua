local UI = {
  --- Viewport size and position constants.
  VIEWPORT = {
    width = 128,
    height = 64,
    center = 64,
    middle = 32
  },
  --- Default brightness state for "off" elements.
  OFF = 2,
  --- Default brightness state for "on" elements.
  ON = 15,
  -- Default first page index.
  FIRST_PAGE = 0,
  -- Default last page index; e.g. total pages
  LAST_PAGE = 4,
  -- Current active page
  active_page = 0
}

--- Handler for metro thread, e.g. screen redrawing.
local function update(count)
  UI.update()
end

--- Init
function init()
  screen.aa(0)
  screen.ping()

  UI.add_page_params() 
  
  --- Init Metro to handle screen redraw
  counter = metro.init()
  counter.time = (1 / 128) * 4
  counter.count = -1
  counter.event = update
  counter:start()
end

--- Exposed update callback for metro
function UI.update() end

--- Add params for Page
-- @param default_val number:
function UI.add_page_params(default_val) 
  params:add_number("page", "Page", UI.FIRST_PAGE - 1, UI.LAST_PAGE + 1, (default_val or 1))
  params:hide("page")
  params:add_separator()
end

--- Sets Page parameter value as delta
-- @param val number:
function UI.page_delta(val)
  params:delta("page", val)

  if (params:get("page") > UI.LAST_PAGE) then
    params:set("page", UI.FIRST_PAGE)
  elseif (params:get("page") < UI.FIRST_PAGE) then
    params:set("page", UI.LAST_PAGE)
  end
end

--- Returns current page number.
function UI.page_get()
  return params:get("page")
end

--- Toggles the brightness of an element based on page.
-- @param page_nums table:  page numbers to toggle "on" state
-- @param on  number:  brightnless level for "on" state
-- @param off number:  brightnless level for "off" state
function UI.highlight(page_nums, on, off)
  for i = 1, #page_nums do
    if params:get("page") == page_nums[i] then
      screen.level((on or UI.ON))
      break
    else
      screen.level((off or UI.OFF))
    end
  end
end

--- Creates marker for displaying current UI page.
-- @param x number:  X-coordinate of element
-- @param y number:  Y-coordinate of element
-- @param page_num {number|string}  Page number to display
-- @param args table:
function UI.page_marker(x, y, param_str, args)
  screen.move(UI.VIEWPORT.width - x, y)
  screen.text_center("P" .. (param_str or UI.page_get()))
  screen.line_width(1)
  screen.rect(UI.VIEWPORT.width - x - 6, y - 6, 14, 8)
  screen.stroke()
end

--- Creates activity element to signify status of parameter.
-- @param x number:  X-coordinate of icon
-- @param y number:  Y-coordinate of icon
-- @param state {number|boolean} 1 is active, 0 is inactive
function UI.signal(x, y, state)
  local r = 3
  screen.move(math.floor(x) + r, math.floor(y))
  screen.circle(math.floor(x), math.floor(y), r)

  if (state) then screen.fill()
  else screen.stroke() end
end

--- Draws given param with signal and value.
-- @param name string:  Name of parameter
-- @param page number:
-- @param x number:
-- @param y number:
-- @param args table:
-- @tparam suffix string:  Optional suffix for display value
-- @tparam bool boolean:  Optional Boolean to trigger signal
function UI.draw_param(name, page, x, y, args)
  if args.label ~= false then
    UI.highlight({page}, UI.ON, 0)
    screen.move(x, y + 10)
    screen.text(string.sub(name, 1, 6))
  end

  UI.highlight({page})

  if (args.bool ~= nil) then
    UI.signal(x + 3, y, args.bool)
    screen.move(x + 8, y + 2)
  else
    screen.move(x, y + 2)
  end
  screen.text(params:string(string.lower(name)) .. (args.suffix or ""))
end

--- Creates icon to show beat relative to interval.
-- Thank you @itsyourbedtime for creating this for Takt!
-- @param x number:  X-coordinate of icon
-- @param y number:  Y-coordinate of icon
-- @param tick boolean:
function UI.metro_icon(x, y, tick)
  screen.move(x + 2, y + 5)
  screen.line(x + 7, y)
  screen.line(x + 12, y + 5)
  screen.line(x + 3, y + 5)
  screen.stroke()
  screen.move(x + 7, y + 3)
  screen.line(tick and (x + 4) or (x + 10), y)
  screen.stroke()
end

--- Creates recording indicator (e.g. circle).
-- @param x number:  X-coordinate of element
-- @param y number:  Y-coordinate of element
function UI.recording(x, y)
  screen.rect(math.floor(x), math.floor(y) - 5, 5, 5)
  screen.fill()
end

--- Creates tape icon.
-- @param x number:  X-coordinate of icon
-- @param y number:  Y-coordinate of icon
function UI.tape_icon(x, y)
  local r = 2

  screen.move(math.floor(x), math.floor(y) - 4)
  screen.line_rel(1, 0)
  screen.line_rel((r * 5), 0)

  for i = 0, 6, 2 do
    screen.move(math.floor(x) + (r * i), math.floor(y) - 4)
    screen.line_rel(0, 1)
    screen.line_rel(0, r)
  end

  screen.move(math.floor(x), math.floor(y) + (r * 2) - 4)
  screen.line_rel(1, 0)
  screen.line_rel(r, 0)
  screen.move(math.floor(x) + (r * 4), math.floor(y) + (r * 2) - 4)
  screen.line_rel(1, 0)
  screen.line_rel(r, 0)
  screen.stroke()
end

--- Creates speaker icon
-- @param x number:  X-coordinate of icon
-- @param y number:  Y-coordinate of icon
function UI.speaker_icon(x, y)
  screen.rect(x, y + 1, 2, 4)
  screen.fill()

  screen.move(x + 1, y + 2)
  screen.line_rel(4, -2)
  screen.line_rel(0, 6)
  screen.line_rel(-4, -2)
  screen.stroke()
end

-- Default, page 0 is reserved for handling any E4 Fates
-- for genuine 3 encoder Norns devices.
if (#norns.encoders.accel == 4) then
  UI.FIRST_PAGE = 1
end

init()

return UI
