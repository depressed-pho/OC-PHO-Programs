local harness = require("tap/harness")

--[[
local parser = require("tap/parser")

local file = io.open("test.tap", "r")
for result in parser(file) do
   print(result:as_string())
end
]]

local h = harness.new()
h.runTests({"test.lua"})
