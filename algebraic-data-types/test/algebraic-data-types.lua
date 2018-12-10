local test = require('tap/test')
local t    = test.new()
t:plan(3)

local adt = t:requireOK('algebraic-data-types') or t:bailOut("Can't load algebraic-data-types")

t:subtest(
    "Maybe a = Nothing | Just a",
    function ()
        t:plan(11)

        local function bind(self, f)
            return self:match {
                Nothing = function ()
                    return self
                end,
                Just = function (x)
                    return f(x)
                end
            }
        end

        local function __tostring(m)
            return m:match {
                Nothing = function ()
                    return "Nothing"
                end,
                Just = function (x)
                    return "Just("..tostring(x)..")"
                end
            }
        end

        local Maybe = adt.define(
            adt.constructor('Nothing'),
            adt.constructor('Just', adt.field()),
            adt.method('bind', bind),
            adt.metamethod('__tostring', __tostring))

        t:ok(Maybe.Just(42):is(Maybe), 'Just(42):is(Maybe)')

        t:ok(Maybe.Just(42):is(Maybe.Just), 'Just(42):is(Just)')
        t:ok(Maybe.Nothing:is(Maybe.Nothing), 'Nothing:is(Nothing)')
        t:ok(not Maybe.Just(42):is(Maybe.Nothing), 'not Just(42):is(Nothing)')

        t:isDeeply(Maybe.Just(42).fields[1], 42, 'Just(42).fields')
        t:is(Maybe.Just(42):fields(), 42, 'Just(42):fields()')
        t:isDeeply(#Maybe.Nothing.fields, 0, 'Nothing.fields')

        t:is(Maybe.Just(42):bind(
                 function (x)
                     assert(type(x) == "number")
                     return Maybe.Just(x+1)
                 end).fields[1], 43, 'method (bind)')
        t:is(tostring(Maybe.Just(42)), "Just(42)", 'metamethod (__tostring)')

        local ret = Maybe.Just(42):match {
            Nothing = function ()
                return -1
            end,
            Just = function (n)
                return n
            end
        }
        t:is(ret, 42, 'Just(42):match()')

        Maybe.Just(42):match {
            Nothing = function ()
                t:fail('default match')
            end,
            _ = function (it)
                t:ok(it:is(Maybe.Just), 'default match')
            end
        }
    end)

t:subtest(
    "List a = Nil | Cons a (List a)",
    function ()
        t:plan(4)

        local List = adt.define(
            adt.constructor('Nil'),
            adt.constructor('Cons', adt.field('head'), adt.field('tail')))

        local ab = List.Cons('a', List.Cons('b', List.Nil))
        t:is(ab.head, 'a', 'ab.head')
        t:is(ab.tail.head, 'b', 'ab.tail.head')

        ab.tail.tail = List.Cons('c', List.Nil)
        t:is(ab.tail.tail.fields[1], 'c', 'ab.tail.tail.fields[1]')

        local a = List.Cons {head = 42, tail = List.Nil}
        t:is(a.fields[1], 42, 'a.fields[1]')
    end)
