local test = require('tap/test')
local t    = test.new()
t:plan(1)

local set = t:requireOK('containers/set') or t:bailOut("Can't load set")

local function sort(seq)
    local ret = {table.unpack(seq)}
    table.sort(ret)
    return ret
end

t:subtest(
    'set.new()',
    function ()
        t:plan(2)

        local tab = {'a', 'b'}
        local function iter(xs)
            local i = 0
            return function ()
                i = i + 1
                if i <= #xs then
                    return xs[i]
                else
                    return nil
                end
            end
        end
        t:isDeeply(sort(set.new(tab):table()), tab, 'set.new(table):table()')
        t:isDeeply(sort(set.new(iter(tab)):table()), tab, 'set.new(iterator):table()')
    end)

t:subtest(
    'size',
    function ()
        t:plan(1)

        local s = set.new()
        s:insert('a')
        s:insert(nil)
        t:is(#s, 2, 'nil counts as a valid element')
    end)

t:subtest(
    'set:has()',
    function ()
        t:plan(3)

        local s = set.new()
        s:insert('a')
        s:insert(nil)
        t:is(s:has('a'), true, 'true case')
        t:is(s:has(nil), true, 'true case (nil)')
        t:is(s:has('b'), false, 'false case')
    end)

t:isDeeply(
    sort(set.new():insert('a'):insert('b'):table()),
    {'a', 'b'},
    'set:insert() & set:table()')

t:subtest(
    'set:clear()',
    function ()
        t:plan(4)

        local s = set.new({'a'})
        t:is(s:has('a'), true, "has('a') before clear()")
        t:is(#s, 1, "size before clear()")

        s:clear()
        t:is(s:has('a'), false, "has('a') after clear()")
        t:is(#s, 0, "size after clear()")
    end)

t:subtest(
    'set:delete()',
    function ()
        t:plan(2)

        t:isDeeply(sort(set.new({'a', 'b'}):delete('a'):table()), {'b'}, 'existing key')
        t:livesOK(function () set.new():delete('a') end, 'absent key')
    end)

t:subtest(
    'set:values()',
    function ()
        t:plan(2)

        local s = set.new({'a', 'b'})
        local n = set.new(s:values())
        t:isDeeply(sort(n:table()), {'a', 'b'})

        t:diesOK(
            function ()
                set.new(
                    set.new():insert(nil):values())
            end,
            's:values() raises an error when s has a nil element')
    end)

t:subtest(
    'set:clone()',
    function ()
        t:plan(2)

        local s   = set.new({'a', 'b'})
        local tab = {'a', 'b'}
        local cln = s:clone()
        t:isDeeply(sort(cln:table()), tab, 'set:clone() clones a set')
        cln:insert('c')
        t:isDeeply(sort(s:table()), tab, 'mutating a cloned set does not affect the original')
    end)

t:subtest(
    'set:isSubsetOf()',
    function ()
        t:plan(3)

        t:is(
            set.new({'a', 'b'}):isSubsetOf(set.new({'a', 'b', 'c'})), true,
            '{a, b} is a subset of {a, b, c}')
        t:is(
            set.new({'a', 'b', 'c'}):isSubsetOf(set.new({'a', 'b', 'c'})), true,
            '{a, b, c} is a subset of {a, b, c}')
        t:is(
            set.new({'a', 'b'}):isSubsetOf(set.new({'a', 'c'})), false,
            '{a, b} is not a subset of {a, c}')
    end)

t:subtest(
    'set:isProperSubsetOf()',
    function ()
        t:plan(2)

        t:is(
            set.new({'a', 'b'}):isProperSubsetOf(set.new({'a', 'b', 'c'})), true,
            '{a, b} is a proper subset of {a, b, c}')
        t:is(
            set.new({'a', 'b', 'c'}):isProperSubsetOf(set.new({'a', 'b', 'c'})), false,
            '{a, b, c} is not a proper subset of {a, b, c}')
    end)

t:subtest(
    'set:isDisjointTo()',
    function ()
        t:plan(2)

        t:is(
            set.new({'a', 'b'}):isDisjointTo(set.new({'c', 'd'})), true,
            '{a, b} is disjoint to {c, d}')
        t:is(
            set.new({'a', 'b'}):isDisjointTo(set.new({'a', 'd'})), false,
            '{a, b} is not disjoint to {a, d}')
    end)

t:subtest(
    'set:union()',
    function ()
        t:plan(1)

        local sA = set.new({'a', 'b'})
        local sB = set.new({'b', 'c'})
        t:isDeeply(
            sort(sA:union(sB):table()),
            {'a', 'b', 'c'})
    end)

t:subtest(
    'set:difference()',
    function ()
        t:plan(1)

        local sA = set.new({'a', 'b'})
        local sB = set.new({'b', 'c'})
        t:isDeeply(sort(sA:difference(sB):table()), {'a'})
    end)

t:subtest(
    'set:intersection()',
    function ()
        t:plan(1)

        local sA = set.new({'a', 'b'})
        local sB = set.new({'b', 'c'})
        t:isDeeply(sort(sA:intersection(sB):table()), {'b'})
    end)

t:subtest(
    'set:map()',
    function ()
        t:plan(1)

        local function f(x)
            return x * 2
        end
        t:isDeeply(
            sort(set.new({1, 2, 3}):map(f):table()), {2, 4, 6})
    end)

t:subtest(
    'set:filter()',
    function ()
        t:plan(1)

        local function f(x)
            return x >= 2
        end
        t:isDeeply(
            sort(set.new({1, 2, 3}):filter(f):table()),
            {2, 3})
    end)

t:subtest(
    'set:partition()',
    function ()
        t:plan(2)

        local function f(x)
            return x >= 2
        end
        local s      = set.new({1, 2, 3})
        local sA, sB = s:partition(f)
        t:isDeeply(sort(sA:table()), {2, 3}, 'partition().fst')
        t:isDeeply(sort(sB:table()), {1}, 'partition().snd')
    end)
