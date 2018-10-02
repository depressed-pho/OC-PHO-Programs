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

function variableValue:value()
    return self._value
end

function variableValue:defaulted()
    return self._defaulted
end

return variableValue
