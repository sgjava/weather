require "config"
require "display"

--- Startup function just calls main.
function startup()
  print('Start')
  dofile('main.lua')
end

-- Wait 5 seconds before calling main
--tmr.alarm(0,5000,0,startup)
print('5 seconds until start')
-- Initialize SSD1306 display
init_display(main_config.sda_pin, main_config.scl_pin, main_config.sla_addr)
str_display(0, 0, "Starting")
