local test = require('tap/test')
local t    = test.new()
t:plan(2)

local pp = t:requireOK('wl-pprint') or t:bailOut("Can't load wl-pprint")

t:subtest(
    "Basic combinators",
    function ()
        t:plan(8)
        t:is(
            pp.renderPretty(1, 80, true, pp.empty),
            "",
            "pp.empty")
        t:is(
            pp.renderPretty(1, 80, true, pp.char('a')),
            "a",
            "pp.char")
        t:is(
            pp.renderPretty(1, 80, true, pp.text("Hello, world!")),
            "Hello, world!",
            "pp.text")
        t:is(
            pp.renderPretty(1, 80, true, pp.string("Hello,\nworld!")),
            "Hello,\nworld!",
            "pp.string")
        t:is(
            pp.renderPretty(1, 80, true, pp.number(42)),
            "42",
            "pp.number")
        t:is(
            pp.renderPretty(1, 80, true, pp.boolean(true)),
            "true",
            "pp.boolean")
        t:is(
            pp.renderPretty(1, 80, true, pp.text("Hello, ")..pp.text("world!")),
            "Hello, world!",
            "'..'")
        t:is(
            pp.renderPretty(1, 80, true, pp.nest(2,
                                                 pp.text("hello") &
                                                 pp.text("world")) & pp.text("!")),
            "hello\n" ..
            "  world\n" ..
            "!",
            "pp.nest")
    end)
