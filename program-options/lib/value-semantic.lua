local valueSemantic = {}
valueSemantic.__index = valueSemantic

function valueSemantic.new()
    local self = setmetatable({}, valueSemantic)

    self._default   = nil
    self._implicit  = nil
    self._name      = nil
    self._notifier  = function (_) end
    self._composer  = function (_, b) return b end
    self._noArgs    = false
    self._required  = false
    self._parser    = function (_, str) return str end
    self._formatter = tostring

    return self
end

function valueSemantic.isInstance(obj)
    checkArg(1, obj, "table")
    local meta = getmetatable(obj)
    if meta == valueSemantic then
        return true
    elseif type(meta.__index) == "table" then
        return valueSemantic.isInstance(meta.__index)
    else
        return false
    end
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

function valueSemantic:implicit(...)
    local args = table.pack(...)
    if args.n > 0 then
        self._implicit = args[1]
        return self
    else
        return self._implicit
    end
end

-- Name of the value used in help messages, i.e. ARG in --opt=ARG.
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

function valueSemantic:notifier(f)
    checkArg(1, f, "function")
    self._notifier = f
    return self
end

function valueSemantic:composer(f)
    checkArg(1, f, "function")
    self._composer = f
    return self
end

function valueSemantic:noArgs()
    self._noArgs = true
    return self
end

function valueSemantic:isNoArgs()
    return self._noArgs
end

function valueSemantic:required()
    self._required = true
    return self
end

function valueSemantic:isRequired()
    return self._required
end

function valueSemantic:parser(f)
    checkArg(1, f, "function")
    self._parser = f
    return self
end

function valueSemantic:formatter(f)
    checkArg(1, f, "function")
    self._formatter = f
    return self
end

function valueSemantic:notify(value)
    self._notifier(value)
    return self
end

function valueSemantic:compose(oldValue, newValue)
    return self._composer(oldValue, newValue)
end

function valueSemantic:parse(oldValue, token)
    assert(not self._noArgs)
    return self._parser(oldValue, token)
end

function valueSemantic:format(value)
    return self._formatter(value)
end

return valueSemantic
