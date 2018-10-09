local variableValue = {}
variableValue.__index = variableValue

function variableValue.new(semantic, value, defaulted)
    checkArg(3, defaulted, "boolean")
    local self = setmetatable({}, variableValue)

    self._semantic  = semantic -- valueSemantic
    self._value     = value
    self._defaulted = defaulted

    return self
end

function variableValue:semantic()
    return self._semantic
end

function variableValue:value(...)
    local args = table.pack(...)
    if args.n > 0 then
        self._value = args[1]
    else
        return self._value
    end
end

function variableValue:defaulted()
    return self._defaulted
end

return variableValue
