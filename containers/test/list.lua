local test = require('tap/test')
local t    = test.new()
t:plan(1)

local list = t:requireOK('containers/list') or t:bailOut("Can't load list")

t:isDeeply(
    list.of('a', 'b', nil, 'c'):table(),
    table.pack('a', 'b', nil, 'c'),
    "list.of(...):table()")

t:subtest(
    "list.from()",
    function ()
        t:plan(2)

        local tab = table.pack('a', 'b', 'c')
        local function iter(xs)
            return function (_, i)
                i = i + 1
                if i <= xs.n then
                    return i, xs[i]
                else
                    return nil
                end
            end, nil, 0
        end
        t:isDeeply(list.from(tab):table(), tab, 'list.from(table)')
        t:isDeeply(list.from(iter(tab)):table(), tab, 'list.from(iterator)')
    end)

t:isDeeply(
    list.of('b'):cons('a'):table(),
    table.pack('a', 'b'),
    "cons")

t:subtest(
    "uncons",
    function ()
        t:plan(3)

        local xs = list.of('a')
        local y, ys = xs:uncons()
        t:is(y, 'a', "head")
        t:ok(ys:null(), "tail")
        t:diesOK(function () ys:uncons() end, "empty")
    end)

t:subtest(
    "head and tail",
    function ()
        t:plan(4)

        local xs = list.of('a')
        t:is(xs:head(), 'a', "head")
        t:ok(xs:tail():null(), "tail")
        t:diesOK(function () xs:tail():head() end, "empty head")
        t:diesOK(function () xs:tail():tail() end, "empty tail")
    end)

t:isDeeply(
    (list.of(1, 2, 3) .. list.of(4, 5, 6)):table(),
    table.pack(1, 2, 3, 4, 5, 6),
    "..")

t:is(#list.of('a', nil, 'b'), 3, "length")

t:subtest(
    "map",
    function ()
        t:plan(1)

        local function f(n)
            return n * 2
        end
        t:isDeeply(
            list.of(1, 2, 3):map(f):table(),
            table.pack(2, 4, 6))
    end)

t:isDeeply(
    list.of('a', nil, 'b'):reverse():table(),
    table.pack('b', nil, 'a'),
    "reverse")

t:isDeeply(
    list.of('a', nil, 'b'):intersperse('-'):table(),
    table.pack('a', '-', nil, '-', 'b'),
    "intersperse")

t:isDeeply(
    list.of(list.of('a', 'b'), list.of('c', 'd')):intercalate(list.of('-', '-')):table(),
    table.pack('a', 'b', '-', '-', 'c', 'd'),
    "intercalate")

t:subtest(
    "foldl",
    function ()
        t:plan(3)

        local function f(x, y)
            return x - y -- intentionally not commutative
        end
        t:is(
            list.of(1, 2, 3):foldl(f),
            (1 - 2) - 3,
            "foldl without an initial value")
        t:diesOK(
            function () list.empty:foldl(f) end,
            "foldl without an initial value on an empty list")
        t:is(
            list.of(1, 2, 3):foldl(f, 0),
            ((0 - 1) - 2) - 3,
            "foldl with an initial value")
    end)

t:subtest(
    "foldr",
    function ()
        t:plan(3)

        local function f(x, y)
            return x - y -- intentionally not commutative
        end
        t:is(
            list.of(1, 2, 3):foldr(f),
            1 - (2 - 3),
            "foldr without an initial value")
        t:diesOK(
            function () list.empty:foldr(f) end,
            "foldr without an initial value on an empty list")
        t:is(
            list.of(1, 2, 3):foldr(f, 4),
            1 - (2 - (3 - 4)),
            "foldr with an initial value")
    end)

t:isDeeply(
    list.of(list.of(1, 2), list.of(3, 4)):concat():table(),
    table.pack(1, 2, 3, 4),
    "concat")

t:subtest(
    'concatMap',
    function ()
        t:plan(1)

        local function f(n)
            return list.of(n * 2, n * 2)
        end
        t:isDeeply(
            list.of(1, 2, 3):concatMap(f):table(),
            table.pack(2, 2, 4, 4, 6, 6))
    end)

t:subtest(
    'any',
    function ()
        t:plan(3)

        local function p(n)
            return n >= 2
        end
        t:is(list.of(1, 2, 3):any(p), true, 'true case')
        t:is(list.of(1, 1, 1):any(p), false, 'false case')
        t:is(list.of():any(p), false, 'empty case')
    end)

t:subtest(
    'all',
    function ()
        t:plan(3)

        local function p(n)
            return n >= 2
        end
        t:is(list.of(1, 2, 3):all(p), false, 'false case')
        t:is(list.of(2, 2, 3):all(p), true, 'true case')
        t:is(list.of():all(p), true, 'empty case')
    end)

t:is(list.of(1, 2, 3):maximum(), 3, 'maximum')
t:is(list.of(1, 2, 3):minimum(), 1, 'minimum')

t:subtest(
    "scanll",
    function ()
        t:plan(3)

        local function f(x, y)
            return x - y -- intentionally not commutative
        end
        t:isDeeply(
            list.of(1, 2, 3):scanl(f):table(),
            table.pack(
                1,
                1 - 2,
                (1 - 2) - 3),
            "scanl without an initial value")
        t:isDeeply(
            list.empty:scanl(f):table(),
            table.pack(),
            "scanl without an initial value on an empty list")
        t:isDeeply(
            list.of(1, 2, 3):scanl(f, 0):table(),
            table.pack(
                0,
                0 - 1,
                (0 - 1) - 2,
                ((0 - 1) - 2) - 3),
            "scanl with an initial value")
    end)

t:subtest(
    "scanr",
    function ()
        t:plan(3)

        local function f(x, y)
            return x - y -- intentionally not commutative
        end
        t:isDeeply(
            list.of(1, 2, 3):scanr(f):table(),
            table.pack(
                1 - (2 - 3),
                2 - 3,
                3),
            "scanr without an initial value")
        t:isDeeply(
            list.empty:scanr(f):table(),
            table.pack(),
            "scanr without an initial value on an empty list")
        t:isDeeply(
            list.of(1, 2, 3):scanr(f, 4):table(),
            table.pack(
                1 - (2 - (3 - 4)),
                2 - (3 - 4),
                3 - 4,
                4),
            "scanr with an initial value")
    end)

t:isDeeply(
    list.of(1, 2, 3):take(2):table(),
    table.pack(1, 2),
    "take")

t:isDeeply(
    list.of(1, 2, 3):drop(2):table(),
    table.pack(3),
    "drop")

t:subtest(
    "splitAt",
    function ()
        t:plan(2)

        local xs, ys = list.of(1, 2, 3):splitAt(2)
        t:isDeeply(xs:table(), table.pack(1, 2), "fst")
        t:isDeeply(ys:table(), table.pack(3), "snd")
    end)

t:isDeeply(
    list.of(1, 2, 3):takeWhile(function (n) return n < 3 end):table(),
    table.pack(1, 2),
    "takeWhile")

t:isDeeply(
    list.of(1, 2, 3):dropWhile(function (n) return n < 3 end):table(),
    table.pack(3),
    "dropWhile")

t:subtest(
    "span",
    function ()
        t:plan(2)

        local function p(n)
            return n < 3
        end
        local xs, ys = list.of(1, 2, 3):span(p)
        t:isDeeply(xs:table(), table.pack(1, 2), "fst")
        t:isDeeply(ys:table(), table.pack(3), "snd")
    end)

t:is(list.of('a', 'b', 'c'):nth(2), 'b', 'nth')
