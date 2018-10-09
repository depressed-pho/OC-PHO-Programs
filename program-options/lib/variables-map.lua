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
        val:semantic():notify(val:value())
    end
    return self
end

function variablesMap:store(parsedOpts)
    checkArg(1, parsedOpts, "table") -- map<string, variableValue>

    for name, newVal in parsedOpts:entries() do
        if self:has(name) then
            local oldVal = map.get(self, name)
            if oldVal:defaulted() then
                self:set(name, newVal)
            else
                oldVal:value(
                    oldVal:semantic():compose(oldVal:value(), newVal:value()))
            end
        else
            self:set(name, newVal)
        end
    end
    return self
end

return variablesMap
