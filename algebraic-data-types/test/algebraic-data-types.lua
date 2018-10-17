local test = require('tap/test')
local t    = test.new()
t:plan(2)

local adt = t:requireOK('algebraic-data-types') or t:bailOut("Can't load algebraic-data-types")

t:subtest(
    "Maybe a = Nothing | Just a",
    function ()
        t:plan(8)

        local maybe = adt.define(
            adt.constructor('Nothing'),
            adt.constructor('Just', adt.field()))

        t:ok(maybe.Just(42):is(maybe), 'Just(42):is(Maybe)')

        t:ok(maybe.Just(42):is(maybe.Just), 'Just(42):is(Just)')
        t:ok(maybe.Nothing:is(maybe.Nothing), 'Nothing:is(Nothing)')
        t:ok(not maybe.Just(42):is(maybe.Nothing), 'not Just(42):is(Nothing)')

        t:isDeeply(maybe.Just(42).fields[1], 42, 'Just(42).fields')
        t:is(maybe.Just(42):fields(), 42, 'Just(42):fields()')
        t:isDeeply(#maybe.Nothing.fields, 0, 'Nothing.fields')

        local ret = maybe.Just(42):match {
            Nothing = function ()
                return -1
            end,
            Just = function (n)
                return n
            end
        }
        t:is(ret, 42, 'Just(42):match()')
    end)

t:subtest(
    "List a = Nil | Cons a (List a)",
    function ()
        t:plan(4)

        local list = adt.define(
            adt.constructor('Nil'),
            adt.constructor('Cons', adt.field('head'), adt.field('tail')))

        local ab = list.Cons('a', list.Cons('b', list.Nil))
        t:is(ab.head, 'a', 'ab.head')
        t:is(ab.tail.head, 'b', 'ab.tail.head')

        ab.tail.tail = list.Cons('c', list.Nil)
        t:is(ab.tail.tail.fields[1], 'c', 'ab.tail.tail.fields[1]')

        local a = list.Cons {head = 42, tail = list.Nil}
        t:is(a.fields[1], 42, 'a.fields[1]')
    end)
