local test = require('tap/test')
local t    = test.new()
t:plan(7)

local pp = t:requireOK('wl-pprint') or t:bailOut("Can't load wl-pprint")

local function render(width, doc)
    return pp.displayS(true, pp.renderPretty(1.0, width, doc))
end

t:subtest(
    "Basic combinators",
    function ()
        t:plan(13)
        t:is(render(80, pp.empty),
             "",
             "pp.empty")
        t:is(render(80, pp.char('a')),
             "a",
             "pp.char")
        t:is(render(80, pp.text("Hello, world!")),
             "Hello, world!",
             "pp.text")
        t:is(render(80, pp.string("Hello,\nworld!")),
             "Hello,\nworld!",
             "pp.string")
        t:is(render(80, pp.number(42)),
             "42",
             "pp.number")
        t:is(render(80, pp.boolean(true)),
             "true",
             "pp.boolean")
        t:is(render(80, pp.text("Hello, ")..pp.text("world!")),
             "Hello, world!",
             "'..'")
        t:is(render(80, pp.nest(2,
                                pp.text("hello") &
                                pp.text("world")) & pp.text("!")),
            "hello\n" ..
            "  world\n" ..
            "!",
            "pp.nest")
        t:is(render(80, pp.text("Hello,")..pp.hardline..pp.text("world!")),
             "Hello,\n"..
             "world!",
             "pp.hardline")
        t:is(render(80, pp.text("Hello,")..pp.line..pp.text("world!")),
             "Hello,\n"..
             "world!",
             "pp.line")
        t:is(render(80,
                    pp.group(
                        pp.text("Hello,")..pp.line..pp.text("world!"))),
             "Hello, world!",
             "pp.group(pp.line)")
        t:is(render(80, pp.text("Hello,")..pp.linebreak..pp.text("world!")),
             "Hello,\n"..
             "world!",
             "pp.linebreak")
        t:is(render(80,
                    pp.group(
                        pp.text("Hello,")..pp.linebreak..pp.text("world!"))),
             "Hello,world!",
             "pp.group(pp.linebreak)")
    end)

t:subtest(
    "Alignment combinators",
    function ()
        t:plan(6)
        t:is(
            render(80, pp.text("hi") +
                       pp.align(pp.text("nice") & pp.text("world"))),
            "hi nice\n"..
            "   world",
            "pp.align")
        t:is(
            render(20, pp.hang(4, pp.fillSep(
                                   { pp.text("the"), pp.text("hang"), pp.text("combinator"),
                                     pp.text("indents"), pp.text("these"), pp.text("words"),
                                     pp.char('!') }))),
            "the hang combinator\n"..
            "    indents these\n"..
            "    words !",
            "pp.hang")
        t:is(
            render(20, pp.indent(4, pp.fillSep(
                                     { pp.text("the"), pp.text("indent"), pp.text("combinator"),
                                       pp.text("indents"), pp.text("these"), pp.text("words"),
                                       pp.char('!') }))),
            "    the indent\n"..
            "    combinator\n"..
            "    indents these\n"..
            "    words !",
            "pp.indent")
        t:is(
            render(20, pp.text("list") +
                       pp.encloseSep(
                           pp.lbracket, pp.rbracket, pp.comma,
                           {pp.number(10), pp.number(200), pp.number(3000)})),
            "list [10,200,3000]",
            "pp.encloseSep -- width 20")
        t:is(
            render(15, pp.text("list") +
                       pp.encloseSep(
                           pp.lbracket, pp.rbracket, pp.comma,
                           {pp.number(10), pp.number(200), pp.number(3000)})),
            "list [10\n"..
            "     ,200\n"..
            "     ,3000]",
            "pp.encloseSep -- width 15")
        t:is(
            render(10, pp.list({pp.number(10), pp.number(200), pp.number(3000)})),
            "{10\n"..
            ",200\n"..
            ",3000}",
            "pp.list")
    end)

t:subtest(
    "Operators",
    function ()
        t:plan(5)
        t:is(
            render(80, pp.text("foo") + pp.text("bar")),
            "foo bar",
            "'+'")
        t:is(
            render(80, pp.text("foo") & pp.text("bar")),
            "foo\n"..
            "bar",
            "'&'")
        t:is(
            render(80, pp.text("foo") / pp.text("bar")),
            "foo bar",
            "'/'")
        t:is(
            render(80, pp.text("foo") % pp.text("bar")),
            "foo\n"..
            "bar",
            "'%'")
        t:is(
            render(80, pp.text("foo") // pp.text("bar")),
            "foobar",
            "'//'")
    end)

t:subtest(
    "List combinators",
    function ()
        t:plan(8)
        t:is(
            render(80, pp.hsep({pp.text("foo"), pp.text("bar"), pp.text("baz")})),
            "foo bar baz",
            "pp.hsep")
        t:is(
            render(80, pp.vsep({pp.text("foo"), pp.text("bar"), pp.text("baz")})),
            "foo\n"..
            "bar\n"..
            "baz",
            "pp.vsep")
        t:is(
            render(7, pp.fillSep({pp.text("foo"), pp.text("bar"), pp.text("baz")})),
            "foo bar\n"..
            "baz",
            "pp.fillSep")
        t:is(
            render(80, pp.hcat({pp.text("foo"), pp.text("bar"), pp.text("baz")})),
            "foobarbaz",
            "pp.hcat")
        t:is(
            render(80, pp.vcat({pp.text("foo"), pp.text("bar"), pp.text("baz")})),
            "foo\n"..
            "bar\n"..
            "baz",
            "pp.vcat")
        t:is(
            render(6, pp.fillCat({pp.text("foo"), pp.text("bar"), pp.text("baz")})),
            "foobar\n"..
            "baz",
            "pp.fillSep")
        t:is(
            render(80, pp.cat({pp.text("foo"), pp.text("bar"), pp.text("baz")})),
            "foobarbaz",
            "pp.cat")
        t:is(
            render(15,
                   pp.braces(
                       pp.align(
                           pp.cat(
                               pp.punctuate(
                                   pp.comma,
                                   { pp.text("words"), pp.text("in"),
                                     pp.text("a"), pp.text("sequence") }))))),
            "{words,\n"..
            " in,\n"..
            " a,\n"..
            " sequence}",
            "pp.punctuate")
    end)

t:subtest(
    "Filler combinators",
    function ()
        t:plan(2)
        t:is(
            render(80, pp.text("let") +
                       pp.align(
                           pp.vcat(
                               { pp.fill(6, pp.text("empty"    )) + pp.text("::") + pp.text("Doc"),
                                 pp.fill(6, pp.text("nest"     )) + pp.text("::") + pp.text("Int -> Doc -> Doc"),
                                 pp.fill(6, pp.text("linebreak")) + pp.text("::") + pp.text("Doc") }))),
            "let empty  :: Doc\n"..
            "    nest   :: Int -> Doc -> Doc\n"..
            "    linebreak :: Doc",
            "pp.fill")
        t:is(
            render(80, pp.text("let") +
                       pp.align(
                           pp.vcat(
                               { pp.fillBreak(6, pp.text("empty"    )) + pp.text("::") + pp.text("Doc"),
                                 pp.fillBreak(6, pp.text("nest"     )) + pp.text("::") + pp.text("Int -> Doc -> Doc"),
                                 pp.fillBreak(6, pp.text("linebreak")) + pp.text("::") + pp.text("Doc") }))),
            "let empty  :: Doc\n"..
            "    nest   :: Int -> Doc -> Doc\n"..
            "    linebreak\n"..
            "           :: Doc",
            "pp.fillBreak")
    end)

t:subtest(
    "Bracketing combinators",
    function ()
        t:plan(7)
        t:is(render(80, pp.enclose(pp.text('[['), pp.text(']]'), pp.char('a'))),
             "[[a]]",
             "pp.enclose")
        t:is(render(80, pp.squotes(pp.char('a'))),
             "'a'",
             "pp.squotes")
        t:is(render(80, pp.dquotes(pp.char('a'))),
             '"a"',
             "pp.dquotes")
        t:is(render(80, pp.parens(pp.char('a'))),
             "(a)",
             "pp.parens")
        t:is(render(80, pp.angles(pp.char('a'))),
             "<a>",
             "pp.angles")
        t:is(render(80, pp.braces(pp.char('a'))),
             "{a}",
             "pp.braces")
        t:is(render(80, pp.brackets(pp.char('a'))),
             "[a]",
             "pp.brackets")
    end)

t:subtest(
    "ANSI formatting combinators",
    function ()
        t:plan(9)
        t:is(render(80, pp.green(pp.text("XXX"))),
             "\x1B[92mXXX\x1B[0m",
             "pp.green")
        t:is(render(80, pp.dullGreen(pp.text("XXX"))),
             "\x1B[32mXXX\x1B[0m",
             "pp.dullGreen")
        t:is(render(80, pp.onGreen(pp.text("XXX"))),
             "\x1B[102mXXX\x1B[0m",
             "pp.onGreen")
        t:is(render(80, pp.onDullGreen(pp.text("XXX"))),
             "\x1B[42mXXX\x1B[0m",
             "pp.onDullGreen")

        t:is(render(80, pp.bold(pp.text("XXX"))),
             "\x1B[1mXXX\x1B[0m",
             "pp.bold")
        t:is(render(80, pp.bold(pp.parens(pp.debold(pp.text("XXX"))))),
             "\x1B[1m(\x1B[22mXXX\x1B[0;1m)\x1B[0m",
             "pp.debold (nested)")

        t:is(render(80, pp.underline(pp.text("XXX"))),
             "\x1B[4mXXX\x1B[0m",
             "pp.underline")
        t:is(render(80, pp.underline(pp.parens(pp.noUnderline(pp.text("XXX"))))),
             "\x1B[4m(\x1B[24mXXX\x1B[0;4m)\x1B[0m",
             "pp.noUnderline (nested)")

        t:is(render(80, pp.plain(pp.red(pp.text("XXX")))),
             "XXX",
             "pp.plain")
    end)

t:subtest(
    "Rendering and displaying documents",
    function ()
        t:plan(4)

        local doc = pp.text("foo(")..pp.nest(2, pp.empty & pp.text("bar") & pp.char(')'))

        t:is(pp.displayS(true, pp.renderPretty(1.0, 20, doc)),
             "foo(\n"..
             "  bar\n"..
             "  )",
             "pp.renderPretty")

        t:is(pp.displayS(true, pp.renderCompact(doc)),
             "foo(\n"..
             "bar\n"..
             ")",
             "pp.renderCompact")

        t:is(pp.displayS(true, pp.renderSmart(1.0, 20, doc)),
             "foo(\n"..
             "  bar\n"..
             "  )",
             "pp.renderSmart")

        t:subtest(
            "displayIO",
            function ()
                t:plan(1)

                -- We can't actually use io.output() as the destination stream to
                -- test displayIO. A dummy stream is thus needed.
                local dummyTTY = {}
                dummyTTY.__index = dummyTTY

                function dummyTTY.new()
                    local self = setmetatable({}, dummyTTY)
                    self.buf = ""
                    return self
                end

                function dummyTTY:write(...)
                    local args = table.pack(...)
                    for i = 1, args.n do
                        self.buf = self.buf .. tostring(args[i])
                    end
                    return self
                end

                function dummyTTY:reset()
                    local ret = self.buf
                    self.buf = ""
                    return ret
                end

                local out = dummyTTY.new()

                pp.displayIO(out, pp.renderPretty(1.0, 20, doc))
                t:is(out:reset(),
                     "foo(\n"..
                     "  bar\n"..
                     "  )",
                     "pp.displayIO")
            end)
    end)
