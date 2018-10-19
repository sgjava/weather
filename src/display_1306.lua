--- Setup I2C and connect SSD1306 display.
-- @param sda number: SDA pin number.
-- @param scl number: SCL pin number.
-- @param sda number: SLA address.
function init_display(sda, scl, sla)
  i2c.setup(0, sda, scl, i2c.SLOW)
  disp = u8g.ssd1306_128x64_i2c(sla)
  -- Set your font here
  disp:setFont(u8g.font_courR18)
  disp:setFontRefHeightExtendedText()
  disp:setDefaultForegroundColor()
  disp:setFontPosTop()
end

--- Display string at X, Y.
-- @param x number: X coordinate.
-- @param y number: Y coordinate.
-- @param str string: String to display.
function str_display(x, y, str)
  if str then
    disp:firstPage()
    repeat
      disp:drawStr(x, y, str)
    until disp:nextPage() == false
  end
end

--- Display temperature and humidity.
-- @param msg string: Message to display at top.
-- @param temp number: Temperature.
-- @param humi number: Humidity.
function temp_display(msg, temp, humi)
  if msg and temp and humi then
    disp:firstPage()
    repeat
      disp:drawStr(0, 0, msg)
      disp:drawStr(0, 20, string.format("T %6.1f",temp))
      disp:drawStr(0, 40, string.format("H %6.1f",humi))
    until disp:nextPage() == false
  end
end

--- Display weather data.
-- @param pressure number: Pressure.
-- @param temp_lo number: Low temperature.
-- @param temp_hi number: High temperature.
function weather_display(pressure, temp_lo, temp_hi)
  if pressure and temp_lo and temp_hi then
    disp:firstPage()
    repeat
      disp:drawStr(0, 0, string.format("P %6d", pressure))
      disp:drawStr(0, 20, string.format("L %6.1f",temp_lo))
      disp:drawStr(0, 40, string.format("H %6.1f",temp_hi))
    until disp:nextPage() == false
  end
end

--- Display temperature and humidity.
-- @param msg string: Message to display at top.
-- @param tm table: rtctime.epoch2cal table.
function time_display(msg, tm)
  if msg and tm then
    disp:firstPage()
    repeat
      disp:drawStr(0, 0, msg)
      disp:drawStr(0, 20, string.format("%02d/%02d/%02d", tm["mon"], tm["day"], tm["year"]-2000))
      disp:drawStr(0, 40, string.format("%02d:%02d:%02d", tm["hour"], tm["min"], tm["sec"]))
    until disp:nextPage() == false
  end
end

--- Put display to sleep.
function sleep_display()
  disp:sleepOn()
end

--- Wake up display.
function wake_display()
  disp:sleepOff()
end
