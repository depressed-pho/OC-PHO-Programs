local adt = require('algebraic-data-types')
local maybe -- Forward declaration

local function bind(self, f)
    checkArg(1, f, "function")
    return self:match {
        Nothing = function ()
            return self
        end,
        Just = function (a)
            return f(a)
        end
    }
end

local function map(self, f)
    checkArg(1, f, "function")
    return self:match {
        Nothing = function ()
            return self
        end,
        Just = function (a)
            return maybe.Just(f(a))
        end
    }
end

local function __concat(ma, mb)
    return ma:match {
        Nothing = function ()
            return mb
        end,
        Just = function (a)
            return mb:match {
                Nothing = function ()
                    return ma
                end,
                Just = function (b)
                    return maybe.Just(a..b)
                end
            }
        end
    }
end

local function __eq(ma, mb)
    return ma:match {
        Nothing = function ()
            return mb:is(maybe.Nothing)
        end,
        Just = function (a)
            return mb:match {
                Nothing = function ()
                    return false
                end,
                Just = function (b)
                    return a == b
                end
            }
        end
    }
end

local function __lt(ma, mb)
    return ma:match {
        Nothing = function ()
            return mb:is(maybe.Just)
        end,
        Just = function (a)
            return mb:match {
                Nothing = function ()
                    return false
                end,
                Just = function (b)
                    return a < b
                end
            }
        end
    }
end

local function __le(ma, mb)
    return ma:match {
        Nothing = function ()
            return true
        end,
        Just = function (a)
            return mb:match {
                Nothing = function ()
                    return false
                end,
                Just = function (b)
                    return a <= b
                end
            }
        end
    }
end

local function __tostring(m)
    return m:match {
        Nothing = function ()
            return "Nothing"
        end,
        Just = function (a)
            return string.format("Just(%s)", a)
        end
    }
end

maybe = adt.define(
    adt.constructor('Nothing'),
    adt.constructor('Just', adt.field()),
    adt.method('bind', bind),
    adt.method('map', map),
    adt.metamethod('__concat', __concat),
    adt.metamethod('__eq', __eq),
    adt.metamethod('__lt', __lt),
    adt.metamethod('__le', __le),
    adt.metamethod('__tostring', __tostring))

local function checkMaybe(pos, arg)
    if type(arg) ~= "table" or not arg:is(maybe) then
        error("bad argument #"..pos.." (Maybe expected, got "..type(arg)..")", 3)
    end
end

function maybe.maybe(b, f, m)
    checkArg(2, f, "function")
    checkMaybe(3, m)
    return m:match {
        Nothing = function ()
            return b
        end,
        Just = function (a)
            return f(a)
        end
    }
end

function maybe.isJust(m)
    checkMaybe(1, m)
    return m:is(maybe.Just)
end

function maybe.isNothing(m)
    checkMaybe(1, m)
    return m:is(maybe.Nothing)
end

function maybe.fromJust(m)
    checkMaybe(1, m)
    return m:match {
        Nothing = function ()
            error("Maybe.Just expected, got Nothing", 2)
        end,
        Just = function (a)
            return a
        end
    }
end

function maybe.fromMaybe(a, m)
    checkMaybe(2, m)
    return m:match {
        Nothing = function ()
            return a
        end,
        Just = function (b)
            return b
        end
    }
end

function maybe.catMaybes(ms)
    checkArg(1, ms, "table")
    local ys = {}
    for _, x in ipairs(ms) do
        x:match {
            Nothing = function () end,
            Just = function (y)
                ys[#ys+1] = y
            end
        }
    end
    return ys
end

function maybe.mapMaybe(f, xs)
    checkArg(1, f, "function")
    checkArg(2, xs, "table")
    local ys = {}
    for _, x in ipairs(xs) do
        f(x):match {
            Nothing = function () end,
            Just = function (y)
                ys[#ys+1] = y
            end
        }
    end
    return ys
end

return maybe
