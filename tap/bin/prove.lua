local parser = require("tap/parser")

local file = io.open("test.tap", "r")
for result in parser(file) do
   print(result:as_string())
end
