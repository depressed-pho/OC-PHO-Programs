local test = require('tap/test')
local t    = test.new()
t:plan(1)

local map = t:requireOK('containers/map') or t:bailOut("Can't load map")

t:subtest(
    'map.new()',
    function ()
        t:plan(2)

        local tab = {a=1, b=2}
        t:isDeeply(map.new(tab):table(), tab, 'map.new(table):table()')
        t:isDeeply(map.new(pairs(tab)):table(), tab, 'map.new(iterator):table()')
    end)

t:subtest(
    'map:size()',
    function ()
        t:plan(1)

        local m = map.new()
        m:set('foo', 1)
        m:set('bar', nil)
        t:is(m:size(), 2, 'nil counts as a valid value')
    end)

t:subtest(
    'map:has()',
    function ()
        t:plan(2)

        t:is(map.new({a=1}):has('a'), true, 'true case')
        t:is(map.new({a=1}):has('b'), false, 'false case')
    end)

t:subtest(
    'map:get()',
    function ()
        t:plan(3)

        t:is(map.new({a=1}):get('a'), 1, 'existing key')
        t:diesOK(function () map.new():get('a') end, 'absent key')
        t:is(map.new():get('a', nil), nil, 'absent key with a default value')
    end)

t:subtest(
    'map:set()',
    function ()
        t:plan(1)

        t:isDeeply(
            map.new({a=1}):set('a', 2):table(),
            {a=2},
            'set() without a combining function')

        local function f(old, new)
            return old + new
        end
        t:isDeeply(
            map.new({a=1}):set('a', 1, f):set('b', 1):table(),
            {a=2, b=1},
            'set() with a combining function')
    end)

t:isDeeply(
    map.new():set('a', 1):set('b', 2):table(), {a=1, b=2}, 'map:table()')

t:subtest(
    'map:clear()',
    function ()
        t:plan(4)

        local m = map.new({a=1})
        t:is(m:has('a'), true, "has('a') before clear()")
        t:is(m:size(), 1, "size() before clear()")

        m:clear()
        t:is(m:has('a'), false, "has('a') after clear()")
        t:is(m:size(), 0, "size() after clear()")
    end)

t:subtest(
    'map:delete()',
    function ()
        t:plan(2)

        t:isDeeply(map.new({a=1, b=2}):delete('a'):table(), {b=2}, 'existing key')
        t:livesOK(function () map.new():delete('a') end, 'absent key')
    end)

t:subtest(
    'map:entries()',
    function ()
        t:plan(4)

        local m = map.new({a=1, b=2}):set('c', nil)
        local n = map.new(m:entries())
        t:is(n:size(), 3, 'size')
        t:is(n:get('a'), 1, 'get(a)')
        t:is(n:get('b'), 2, 'get(b)')
        t:is(n:get('c'), nil, 'get(c)')
    end)

t:subtest(
    'map:clone()',
    function ()
        t:plan(2)

        local m   = map.new({a=1, b=2})
        local tab = {a=1, b=2}
        local cln = m:clone()
        t:isDeeply(cln:table(), tab, 'map:clone() clones a map')
        cln:set('c', 3)
        t:isDeeply(m:table(), tab, 'mutating a cloned map does not affect the original')
    end)

t:subtest(
    'map:union()',
    function ()
        t:plan(2)

        local mA = map.new({a=1, b=2})
        local mB = map.new({a=3, c=4})

        t:isDeeply(
            mA:union(mB):table(),
            {a=1, b=2, c=4},
            'map:union() without a combining function')

        local function f(_, right)
            return right
        end
        t:isDeeply(
            mA:union(mB, f):table(),
            {a=3, b=2, c=4},
            'map:union() with a combining function')
    end)

t:isDeeply(
    map.new({a=1, b=2}):difference(map.new({b=3})):table(),
    {a=1},
    'map:difference()')

t:subtest(
    'map:intersection()',
    function ()
        t:plan(2)

        local mA = map.new({a=1, b=2})
        local mB = map.new({a=3, c=4})

        t:isDeeply(
            mA:intersection(mB):table(),
            {a=1},
            'map:intersection() without a combining function')

        local function f(_, right)
            return right
        end
        t:isDeeply(
            mA:intersection(mB, f):table(),
            {a=3},
            'map:intersection() with a combining function')
    end)

t:subtest(
    'map:map()',
    function ()
        t:plan(1)

        local function f(x)
            return x * 2
        end
        t:isDeeply(
            map.new({a=1, b=2, c=3}):map(f):table(),
            {a=2, b=4, c=6})
    end)

t:subtest(
    'map:filter()',
    function ()
        t:plan(1)

        local function f(x)
            return x >= 2
        end
        t:isDeeply(
            map.new({a=1, b=2, c=3}):filter(f):table(),
            {b=2, c=3})
    end)

t:subtest(
    'map:partition()',
    function ()
        t:plan(2)

        local function f(x)
            return x >= 2
        end
        local m      = map.new({a=1, b=2, c=3})
        local mA, mB = m:partition(f)
        t:isDeeply(mA:table(), {b=2, c=3}, 'partition().fst')
        t:isDeeply(mB:table(), {a=1}, 'partition().snd')
    end)
