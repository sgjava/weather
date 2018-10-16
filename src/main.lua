require "config"
require "display"
require "wifi_connect"

-- Display on/off toggle
local display_on = true
-- What screen sequence to display
local display_seq = 0
-- Button in debounce if true
local button_wait = false
-- Weather data persisted
local weather_data = {}


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

--- Get local temperature and humidity using DHT module.
function get_local_temp()
  local temp, humi, status = get_temp_humi(main_config.dht_pin)
  weather_data.local_temp = temp
  weather_data.local_humi = humi
end

--- Get outside weather from api.openweathermap.org.
function get_outside_temp()
  http.get(string.format(main_config.url, main_config.zip_code, main_config.api_key), nil, function(code, data)
    if (code < 0) then
      print(string.format("HTTP request failed: %d", code))
      weather_data["outside_main"] = string.format("Err %d",code)
    else
      local payload = sjson.decode(data)
      weather_data.outside_temp = payload.main.temp
      weather_data.outside_temp_min = payload.main.temp_min
      weather_data.outside_temp_max = payload.main.temp_max
      weather_data.outside_temp_pressure = payload.main.pressure
      weather_data.outside_humi = payload.main.humidity
      weather_data.outside_main = payload.weather[1].main
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
    get_outside_temp()
    get_local_temp()
    -- Add hours timezone offset from UTC
    local tm = rtctime.epoch2cal(rtctime.get() + (main_config.timezone_offset * 3600))
    print(string.format("%02d/%02d/%02d %02d:%02d:%02d, heap: %d", tm["mon"], tm["day"], tm["year"], tm["hour"], tm["min"], tm["sec"], node.heap()))
    -- Only do display updates if display on
    if display_on then
      -- Display sequence to call
      local seq = {
        [0] = function () temp_display(weather_data.outside_main, weather_data.outside_temp, weather_data.outside_humi) end,
        [1] = function () weather_display(weather_data.outside_temp_pressure , weather_data.outside_temp_min, weather_data.outside_temp_max) end,
        [2] = function () time_display("Date", tm) end,
        [3] = function () temp_display("Local", weather_data.local_temp, weather_data.local_humi) end,
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
  get_outside_temp()
end

print("Start")
-- Configure button
gpio.mode(main_config.button_pin, gpio.INT, gpio.PULLUP)
gpio.trig(main_config.button_pin, "both", button_cb)
-- Connect to wifi
wifi_connect(wifi_config.ip, wifi_config.netmask, wifi_config.gateway, wifi_config.ssid, wifi_config.pwd, wifi_started)
-- Update local data right away
get_local_temp()
temp_display("Inside", weather_data.local_temp, weather_data.local_humi)
print("End")
