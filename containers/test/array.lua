local test = require('tap/test')
local t    = test.new()
t:plan(21)

local array = t:requireOK('containers/array') or t:bailOut("Can't load array")

t:isDeeply(
    array.new('a', 'b', nil, 'c'):table(),
    table.pack('a', 'b', nil, 'c'),
    'array.new(...):table()')

t:subtest(
    'array.from()',
    function ()
        t:plan(2)

        local tab = table.pack('a', 'b', nil, 'c')
        local function itr(xs)
            return function (_, i)
                i = i + 1
                if i <= xs.n then
                    return i, xs[i]
                else
                    return nil
                end
            end, nil, 0
        end
        t:isDeeply(array.from(tab):table(), tab, 'array.from(table)')
        t:isDeeply(array.from(itr(tab)):table(), tab, 'array.from(iterator)')
    end)

t:subtest(
    'array:get()',
    function ()
        t:plan(3)

        local arr = array.new('a', 'b', nil, 'c')
        t:is(arr:get(2), 'b', 'get non-nil')
        t:is(arr:get(3), nil, 'get nil')
        t:diesOK(function () arr:get(5) end, 'out of range')
    end)

t:subtest(
    'array:set()',
    function ()
        t:plan(2)

        local arr = array.new('a', 'b', nil, 'c')
        local tab = table.pack('a', 'B', nil, 'c')
        t:isDeeply(arr:set(2, 'B'):table(), tab, 'set()')
        t:diesOK(function () arr:set(5, 'D') end, 'out of range')
    end)

t:is(array.new('a', 'b', nil, 'c'):length(), 4, 'array:length()')

t:subtest(
    'array:concat()',
    function ()
        t:plan(2)

        local arr = array.new('a', 'b', nil, 'c')
        local tab = table.pack('a', 'b', nil, 'c')
        t:isDeeply(
            arr:concat(array.new('d', 'e')):table(),
            table.pack('a', 'b', nil, 'c', 'd', 'e'),
            'array:concat() can concatenate two arrays')
        t:isDeeply(arr:table(), tab, 'array:concat() does not mutate the original array')
    end)

t:subtest(
    'array:entries()',
    function ()
        t:plan(1)

        local arr = array.new('a', 'b', nil, 'c')
        local tab = table.pack('a', 'b', nil, 'c')
        t:isDeeply(
            array.from(arr:entries()):table(), tab,
            'array:entries() returns a key/value iterator')
    end)

t:subtest(
    'array:clone()',
    function ()
        t:plan(2)

        local arr = array.new('a', 'b', nil, 'c')
        local tab = table.pack('a', 'b', nil, 'c')
        local cln = arr:clone()
        t:isDeeply(cln:table(), tab, 'array:clone() clones an array')
        cln:push('d')
        t:isDeeply(arr:table(), tab, 'mutating a cloned array does not affect the original')
    end)

t:subtest(
    'array:all()',
    function ()
        t:plan(3)

        local function p(n)
            return n >= 2
        end
        t:is(array.new(1, 2, 3):all(p), false, 'false case')
        t:is(array.new(2, 2, 3):all(p), true, 'true case')
        t:is(array.new():all(p), true, 'empty case')
    end)

t:subtest(
    'array:any()',
    function ()
        t:plan(3)

        local function p(n)
            return n >= 2
        end
        t:is(array.new(1, 2, 3):any(p), true, 'true case')
        t:is(array.new(1, 1, 1):any(p), false, 'false case')
        t:is(array.new():any(p), false, 'empty case')
    end)

t:subtest(
    'array:filter()',
    function ()
        t:plan(1)

        local function f(n)
            return n >= 2
        end
        t:isDeeply(
            array.new(1, 2, 3):filter(f):table(),
            array.new(2, 3):table())
    end)

t:subtest(
    'array:find()',
    function ()
        t:plan(2)

        local function f(n)
            return n >= 20
        end
        t:isDeeply(
            table.pack(array.new(10, 20, 30):find(f)),
            table.pack(20, 2),
            ':find() == 20, 2')
        t:isDeeply(
            table.pack(array.new(1, 2, 3):find(f)),
            table.pack(nil),
            ':find() == nil')
    end)

t:subtest(
    'array:concatMap()',
    function ()
        t:plan(1)

        local function f(n)
            return array.new(n * 2, n * 2)
        end
        t:isDeeply(
            array.new(1, 2, 3):concatMap(f):table(),
            table.pack(2, 2, 4, 4, 6, 6))
    end)

t:subtest(
    'array:includes()',
    function ()
        t:plan(4)

        local arr = array.new('a', 'b', nil, 'c')
        t:is(arr:includes('b'), true, 'includes non-nil')
        t:is(arr:includes(nil), true, 'includes nil')
        t:is(arr:includes('d'), false, 'non-existent')
        t:is(arr:includes('a', 2), false, 'skip')
    end)

t:subtest(
    'array:indexOf()',
    function ()
        t:plan(4)

        local arr = array.new('a', 'b', nil, 'b')
        t:is(arr:indexOf('b'), 2, 'indexOf non-nil')
        t:is(arr:indexOf(nil), 3, 'indexOf nil')
        t:is(arr:indexOf('d'), nil, 'non-existent')
        t:is(arr:indexOf('a', 2), nil, 'skip')
    end)

t:subtest(
    'array:lastIndexOf()',
    function ()
        t:plan(4)

        local arr = array.new('a', 'b', nil, 'b')
        t:is(arr:lastIndexOf('b'), 4, 'lastIndexOf non-nil')
        t:is(arr:lastIndexOf(nil), 3, 'lastIndexOf nil')
        t:is(arr:lastIndexOf('d'), nil, 'non-existent')
        t:is(arr:lastIndexOf('b', 3), 2, 'skip')
    end)

t:subtest(
    'array:map()',
    function ()
        t:plan(1)

        local function f(n)
            return n * 2
        end
        t:isDeeply(
            array.new(1, 2, 3):map(f):table(),
            table.pack(2, 4, 6))
    end)

t:subtest(
    'array:pop()',
    function ()
        t:plan(2)

        local arr = array.new('a', nil)
        t:is(arr:pop(), nil, 'pop non-empty')
        t:is(arr:pop(), 'a', 'pop non-empty')
        t:diesOK(function () arr:pop() end, 'pop empty')
    end)

t:isDeeply(
    array.new('a'):push(nil, 'b'):table(),
    table.pack('a', nil, 'b'),
    'array:push()')

t:subtest(
    'array:foldl()',
    function ()
        t:plan(3)

        local function f(x, y)
            return x - y -- intentionally not commutative
        end
        t:is(
            array.new(1, 2, 3):foldl(f),
            (1 - 2) - 3,
            'foldl without an initial value')
        t:diesOK(
            function () array.new():foldl(f) end,
            'foldl without an initial value on an empty array')
        t:is(
            array.new(1, 2, 3):foldl(f, 0),
            (((0 - 1) - 2) - 3),
            'foldl with an initial value')
    end)

t:subtest(
    'array:foldr()',
    function ()
        t:plan(3)

        local function f(x, y)
            return x - y -- intentionally not commutative
        end
        t:is(
            array.new(1, 2, 3):foldr(f),
            (1 - (2 - 3)),
            'foldr without an initial value')
        t:diesOK(
            function () array.new():foldr(f) end,
            'foldr without an initial value on an empty array')
        t:is(
            array.new(1, 2, 3):foldr(f, 4),
            (1 - (2 - (3 - 4))),
            'foldr with an initial value')
    end)

t:subtest(
    'array:reverse()',
    function ()
        t:plan(2)

        local arr = array.new('a', 'b', nil, 'd')
        local rra = table.pack('d', nil, 'b', 'a')
        t:isDeeply(arr:reverse():table(), rra, 'reverse')
        t:isDeeply(
            arr:table(),
            table.pack('a', 'b', nil, 'd'),
            'array:reverse() does not mutate the original array')
    end)

t:subtest(
    'array:shift()',
    function ()
        t:plan(2)

        local arr = array.new('a', nil)
        t:is(arr:shift(), 'a', 'shift non-empty')
        t:is(arr:shift(), nil, 'shift non-empty')
        t:diesOK(function () arr:shift() end, 'shift empty')
    end)

t:subtest(
    'array:slice()',
    function ()
        t:plan(2)

        local arr = array.new('a', 'b', nil, 'd')
        t:isDeeply(
            arr:slice(2):table(),
            table.pack('b', nil, 'd'),
            'slice() without end')
        t:isDeeply(
            arr:slice(2, 3):table(),
            table.pack('b', nil),
            'slice() with end')
    end)

t:subtest(
    'array:sort()',
    function ()
        t:plan(4)

        local arr = array.new(5, 2, 1, 4, 9)
        t:isDeeply(
            arr:sort():table(),
            table.pack(1, 2, 4, 5, 9),
            'sort() without cmp')

        local function cmp(x, y)
            return y <= x -- in the reverse order
        end
        t:isDeeply(
            arr:sort(cmp):table(),
            table.pack(9, 5, 4, 2, 1),
            'sort() with cmp')

        local large = array.new()
        for _ = 1, 256 do
            large:push(math.random(256))
        end

        large = large:sort()
        t:is(large:length(), 256, 'length of sorted list')

        local isSorted = true
        for i = 1, large:length()-1 do
            if large:get(i) > large:get(i+1) then
                isSorted = false
            end
        end
        if not t:ok(isSorted, 'sorting a large array') then
            t:diag(large:table())
        end
    end)

t:subtest(
    'array:splice()',
    function ()
        t:plan(1)

        local arr = array.new('a', 'b', nil, 'd')
        t:isDeeply(
            arr:splice(2, 1, 'B', 'C'):table(),
            table.pack('a', 'B', 'C', nil, 'd'))
    end)

t:isDeeply(
    array.new('a'):unshift(nil, 'b'):table(),
    table.pack(nil, 'b', 'a'),
    'array:unshift()')
