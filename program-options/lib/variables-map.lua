local map = require("containers/map")
local variablesMap = setmetatable({}, map)
variablesMap.__index = variablesMap

function variablesMap.new()
    local self = map.new() -- map<string, variableValue>
    setmetatable(self, variablesMap)

    return self
end

function variablesMap:get(name)
    checkArg(1, name, "string")

    local val = map.get(self, name)
    return val:value()
end

function variablesMap:notify()
    for _, val in self:entries() do
        local notifier = val:semantic():notifier()
        notifier(val:value())
    end
    return self
end

function variablesMap:store(parsedOpts) -- luacheck: ignore self
    error("FIXME: not implemented", parsedOpts)
end

return variablesMap
