local lazy = {}

-- Same as the builtin require() except it loads modules lazily.
function lazy.require(modName)
    -- Mutate 'dst' so that it becomes identical to 'src'.
    local function overwrite(dst, src)
        for k, v in pairs(src) do
            rawset(dst, k, v)
        end
        setmetatable(dst, getmetatable(src))
    end
    local mt = {
        __index = function (module, symbol)
            overwrite(module, require(modName))
            return module[symbol]
        end,
        __newindex = function (module, symbol, value)
            overwrite(module, require(modName))
            module[symbol] = value
        end
    }
    return setmetatable({}, mt)
end

-- Create a lazily evaluated value out of a thunk which computes the
-- value. The computed value will be automatically memoized.
local mt = {
    __call = function (val)
        if val.thunk then
            val.value = val.thunk()
            val.thunk = nil
        end
        return val.value
    end
}
function lazy.delay(thunk)
    checkArg(1, thunk, "function")
    local obj = {
        thunk = thunk,
        value = nil
    }
    return setmetatable(obj, mt)
end

-- Force a delayed computation of a value and return it. If the value
-- has already been computed, it will be simply returned without
-- getting computed twice.
function lazy.force(val)
    checkArg(1, val, "table")
    if getmetatable(val) == mt then
        return val()
    else
        error("Expected a lazy value but got "..tostring(val), 2)
    end
end

return lazy
