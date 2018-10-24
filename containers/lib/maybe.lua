local adt = require('algebraic-data-types')

local maybe = adt.define(
    adt.constructor('Nothing'),
    adt.constructor('Just', adt.field()))

local function checkMaybe(pos, arg)
    if type(arg) ~= "table" or not arg:is(maybe) then
        error("bad argument #"..pos.." (Maybe expected, got "..type(arg)..")", 3)
    end
end

function maybe.isNothing(m)
    checkMaybe(1, m)
    return m:is(maybe.Nothing)
end

function maybe.isJust(m)
    checkMaybe(1, m)
    return m:is(maybe.Just)
end

function maybe.fromJust(m)
    checkMaybe(1, m)
    if m:is(maybe.Just) then
        return m.fields[1]
    else
        error("Maybe.Just expected, got Nothing", 2)
    end
end

function maybe.fmap(f, m)
    checkArg(1, f, "function")
    checkMaybe(2, m)
    if m:is(maybe.Just) then
        return f(m.fields[1])
    else
        return m
    end
end

-- FIXME: more functions

return maybe
