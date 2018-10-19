require "config"
require "display_1306"
require "wifi_connect"

-- Display on/off toggle
local display_on = true
-- What screen sequence to display
local display_seq = 0
-- Button in debounce if true
local button_wait = false
-- Weather data persisted
local payload = nil


--- Use DHT module to get temperature and humidity
-- @param pin number: DHT data pin.
function get_temp_humi(pin)
  local status, temp, humi, temp_dec, humi_dec = dht.read(pin)
  if status == dht.OK then
    -- Convert to Fahrenheit
    temp = temp * 1.8 + 32
  else
    temp = 0.0
    humi = 0.0
  end
  return temp, humi, status
end

--- Get outside weather from api.openweathermap.org.
function get_weather()
  http.get(string.format(main_config.url, main_config.zip_code, main_config.api_key), nil, function(code, data)
    if (code < 0) then
      print(string.format("HTTP request failed: %d", code))
    else
      payload = sjson.decode(data)
    end
  end)
end

--- Button callback toggles display on/off.
function button_cb()
  value = gpio.read(main_config.button_pin)
  -- Ignore value unless it changed and button_wait is false
  if value ~= last_value and not button_wait then
    button_wait = true
    if value == 0 then
      if display_on then
        display_on = false
        sleep_display()
      else
        display_on = true
        wake_display()
      end
    end
    -- Debounce time
    tmr.alarm(2, main_config.button_debounce, tmr.ALARM_SINGLE, function()
      button_wait = false
    end)
  end
end

--- Wifi_connect callback after wifi connection established.
function wifi_started()
  print("Wifi started")
  -- Display weather using sequence
  tmr.alarm(0, main_config.update_interval, tmr.ALARM_AUTO, function()
    -- Get weather data even if display off
    get_weather()
    -- Add hours timezone offset from UTC
    local tm = rtctime.epoch2cal(rtctime.get() + (main_config.timezone_offset * 3600))
    -- Get local temp/humi
    local temp, humi, status = get_temp_humi(main_config.dht_pin)
    print(string.format("%02d/%02d/%02d %02d:%02d:%02d, heap: %d", tm["mon"], tm["day"], tm["year"], tm["hour"], tm["min"], tm["sec"], node.heap()))
    -- Only do display updates if display on
    if display_on then
      -- Display sequence to call
      local seq = {
        [0] = function () temp_display(payload.weather[1].main, payload.main.temp, payload.main.humidity) end,
        [1] = function () weather_display(payload.main.pressure, payload.main.temp_min, payload.main.temp_max) end,
        [2] = function () time_display("Date", tm) end,
        [3] = function () temp_display("Local", temp, humi) end,
      }
      seq[display_seq]()
      display_seq = display_seq + 1
      if display_seq > 3 then
        display_seq = 0
      end
    end
  end)
  -- Auto time sync
  sntp.sync(main_config.ntp_host, nil, nil, 1)
  -- Get first payload
  get_weather()
end

print("Start")
-- Configure button
gpio.mode(main_config.button_pin, gpio.INT, gpio.PULLUP)
gpio.trig(main_config.button_pin, "both", button_cb)
-- Connect to wifi
wifi_connect(wifi_config.ip, wifi_config.netmask, wifi_config.gateway, wifi_config.ssid, wifi_config.pwd, wifi_started)
-- Update local data right away
local temp, humi, status = get_temp_humi(main_config.dht_pin)
temp_display("Inside", temp, humi)
print("End")
