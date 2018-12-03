local valueSemantic = {}
valueSemantic.__index = valueSemantic

function valueSemantic.new()
    local self = setmetatable({}, valueSemantic)

    self._default   = nil -- any
    self._implicit  = nil -- any
    self._name      = "ARG"
    self._notifier  = function (_) end
    self._appender  = function (_, val) return val end
    self._merger    = nil -- nil | (any, any)->any
    self._merging   = false
    self._noArgs    = false
    self._parser    = function (str) return str end
    self._formatter = tostring

    return self
end

function valueSemantic.isInstance(obj)
    checkArg(1, obj, "table")
    local meta = getmetatable(obj)
    if meta == valueSemantic then
        return true
    elseif meta and type(meta.__index) == "table" then
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
        assert(not self._noArgs)
        assert(self._name)
        return self._name
    end
end

function valueSemantic:notifier(f)
    checkArg(1, f, "function")
    self._notifier = f
    return self
end

function valueSemantic:appender(f)
    checkArg(1, f, "function")
    self._appender = f
    return self
end

function valueSemantic:merger(f)
    checkArg(1, f, "function")
    self._merger = f
    return self
end

-- State that multiple occurences of the option in different sources
-- should result in those options combined together, as opposed to the
-- last source being preferred. This only makes sence if a merger
-- function is also defined.
function valueSemantic:merging()
    self._merging = true
    return self
end

-- State that the option cannot take any arguments.
function valueSemantic:noArgs()
    self._noArgs = true
    return self
end

function valueSemantic:isNoArgs()
    return self._noArgs
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

function valueSemantic:append(oldValue, newValue)
    return self._appender(oldValue, newValue)
end

function valueSemantic:merge(oldValue, newValue)
    if self._merging then
        if self._merger then
            return self._merger(oldValue, newValue)
        else
            error("Misuse of valueSemantic:merging(): a merging function is required", 2)
        end
    else
        return newValue
    end
end

function valueSemantic:parse(strVal)
    checkArg(1, strVal, "string")
    assert(not self._noArgs)
    return self._parser(strVal)
end

function valueSemantic:format(value)
    return self._formatter(value)
end

return valueSemantic
