-- Blatantly lifted from Neauoire's Monitor script
--

local Keys = {
  pressed = {},
}

--- Draw keys.
-- @param x number: x position
-- @param y number: y position
-- @param w number: w width
-- @param h number: h height
function Keys.draw(x, y, w, h)
  template = { sw = 4, sh = 15 }

  -- White Keys Down
  screen.level(15)
  if Keys.pressed[0] then screen.rect(x, y, w, h) ; screen.fill() end
  if Keys.pressed[2] then screen.rect(x + (w*1), y, w, h) ; screen.fill() end
  if Keys.pressed[4] then screen.rect(x + (w*2), y, w, h) ; screen.fill() end
  if Keys.pressed[5] then screen.rect(x + (w*3), y, w, h) ; screen.fill() end
  if Keys.pressed[7] then screen.rect(x + (w*4), y, w, h) ; screen.fill() end
  if Keys.pressed[9] then screen.rect(x + (w*5), y, w, h) ; screen.fill() end
  if Keys.pressed[11] then screen.rect(x + (w*6), y, w, h) ; screen.fill() end

  -- White Keys Outline
  screen.level(2)
  screen.rect(x, y, w, h)
  screen.rect(x + (w*1), y, w, h)
  screen.rect(x + (w*2), y, w, h)
  screen.rect(x + (w*3), y, w, h)
  screen.rect(x + (w*4), y, w, h)
  screen.rect(x + (w*5), y, w, h)
  screen.rect(x + (w*6), y, w, h)
  screen.stroke()

  -- Black Keys Mask
  screen.rect(x + 7, y, w - template.sw, h - template.sh)
  screen.rect(x + 17, y, w - template.sw, h - template.sh)
  screen.rect(x + 37, y, w - template.sw, h - template.sh)
  screen.rect(x + 47, y, w - template.sw, h - template.sh)
  screen.rect(x + 57, y, w - template.sw, h - template.sh)
  screen.level(0)
  screen.fill()

  -- Black Keys Down
  screen.level(15)
  if Keys.pressed[1] then screen.rect(x + 7, y, w - template.sw, h - template.sh) ; screen.fill() end
  if Keys.pressed[3] then screen.rect(x + 17, y, w - template.sw, h - template.sh) ; screen.fill() end
  if Keys.pressed[6] then screen.rect(x + 37, y, w - template.sw, h - template.sh) ; screen.fill() end
  if Keys.pressed[8] then screen.rect(x + 47, y, w - template.sw, h - template.sh) ;  screen.fill() end
  if Keys.pressed[10] then screen.rect(x + 57, y, w - template.sw, h - template.sh) ; screen.fill() end

  -- Black Keys Outline
  screen.level(2)
  screen.rect(x + 7, y, w - template.sw, h - template.sh)
  screen.rect(x + 17, y, w - template.sw, h - template.sh)
  screen.rect(x + 37, y, w - template.sw, h - template.sh)
  screen.rect(x + 47, y, w - template.sw, h - template.sh)
  screen.rect(x + 57, y, w - template.sw, h - template.sh)
  screen.stroke()
end

return Keys