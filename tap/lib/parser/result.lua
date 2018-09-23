-- base
local result = {}
result.__index = result

function result.new(resultType)
   local self = setmetatable({}, result)

   self.type = resultType

   return self
end

function result:type()
   return self.type
end

function result:as_string() -- luacheck: ignore self
   error("This method has to be overridden")
end

-- version
result.version = setmetatable({}, result)
result.version.__index = result.version

function result.version.new(version)
   local self = setmetatable(result.new("version"), result.version)

   self.version = version

   return self
end

function result.version:as_string()
   return "TAP version "..self.version
end

return result
