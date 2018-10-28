local test = require('tap/test')
local t    = test.new()
t:plan(3)

local maybe = t:requireOK('containers/maybe') or t:bailOut("Can't load maybe")

-- Monadic computation
local m1 = maybe.Just(42)
local m2 = m1:bind(
    function (x)
        return maybe.Just(x + 1)
    end)
t:is(maybe.fromJust(m2), 43, "bind")

-- Mapping a function
local m3 = m1:map(
    function (x)
        return x + 1
    end)
t:is(maybe.fromJust(m3), 43, "map")
