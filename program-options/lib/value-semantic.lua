local valueSemantic = {}
valueSemantic.__index = valueSemantic

function valueSemantic.new()
    local self = setmetatable({}, valueSemantic)

    self._default    = nil
    self._implicit   = nil
    self._name       = nil
    self._notifier   = function (_) end
    self._composing  = false
    self._zeroTokens = false
    self._required   = false

    return self
end

function valueSemantic:default(...)
    local args = table.pack(...)
    if args.n > 0 then
        self._default = args[1]
        return self
    else
        return self._default
    end
end

function valueSemantic:implicit(val)
    self._implicit = val
    return self
end

function valueSemantic:name(...)
    local args = table.pack(...)
    if args.n > 0 then
        checkArg(1, args[1], "string")
        self._name = args[1]
        return self
    else
        assert(self._name)
        return self._name
    end
end

function valueSemantic:notifier(...)
    local args = table.pack(...)
    if args.n > 0 then
        checkArg(1, args[1], "function")
        self._notifier = args[1]
        return self
    else
        return self._notifier
    end
end

function valueSemantic:composing()
    self._composing = true
    return self
end

function valueSemantic:isComposing()
    return self._composing
end

function valueSemantic:zeroTokens()
    self._zeroTokens = true
    return self
end

function valueSemantic:required()
    self._required = true
    return self
end

function valueSemantic:isRequired()
    return self._required
end

function valueSemantic:parse(oldValue, token) -- luacheck: ignore self oldValue token
    error("Subclasses are expected to override this method.")
end

return valueSemantic
