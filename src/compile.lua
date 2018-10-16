-- Compile source then delete source file.
node.stripdebug(3)
node.compile("config.lua")
file.remove("config.lua")
node.compile("wifi_connect.lua")
file.remove("wifi_connect.lua")
node.compile("display.lua")
file.remove("display.lua")
node.compile("main.lua")
file.remove("main.lua")
for k,v in pairs(file.list()) do print(k.." ("..v.." bytes)") end
