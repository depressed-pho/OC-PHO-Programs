local test = require('tap/test')
local t    = test.new()
t:plan(6)

local pp = t:requireOK('wl-pprint') or t:bailOut("Can't load wl-pprint")

t:subtest(
    "Basic combinators",
    function ()
        t:plan(13)
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
        t:is(
            pp.renderPretty(1, 80, true, pp.text("Hello,")..pp.hardline..pp.text("world!")),
            "Hello,\n"..
            "world!",
            "pp.hardline")
        t:is(
            pp.renderPretty(1, 80, true, pp.text("Hello,")..pp.line..pp.text("world!")),
            "Hello,\n"..
            "world!",
            "pp.line")
        t:is(
            pp.renderPretty(1, 80, true, pp.group(
                                pp.text("Hello,")..pp.line..pp.text("world!"))),
            "Hello, world!",
            "pp.group(pp.line)")
        t:is(
            pp.renderPretty(1, 80, true, pp.text("Hello,")..pp.linebreak..pp.text("world!")),
            "Hello,\n"..
            "world!",
            "pp.linebreak")
        t:is(
            pp.renderPretty(1, 80, true, pp.group(
                                pp.text("Hello,")..pp.linebreak..pp.text("world!"))),
            "Hello,world!",
            "pp.group(pp.linebreak)")
    end)

t:subtest(
    "Alignment combinators",
    function ()
        t:plan(6)
        t:is(
            pp.renderPretty(1, 80, true, pp.text("hi") +
                                pp.align(pp.text("nice") & pp.text("world"))),
            "hi nice\n"..
            "   world",
            "pp.align")
        t:is(
            pp.renderPretty(1, 20, true,
                            pp.hang(4, pp.fillSep(
                                        { pp.text("the"), pp.text("hang"), pp.text("combinator"),
                                          pp.text("indents"), pp.text("these"), pp.text("words"),
                                          pp.char('!') }))),
            "the hang combinator\n"..
            "    indents these\n"..
            "    words !",
            "pp.hang")
        t:is(
            pp.renderPretty(1, 20, true,
                            pp.indent(4, pp.fillSep(
                                          { pp.text("the"), pp.text("indent"), pp.text("combinator"),
                                            pp.text("indents"), pp.text("these"), pp.text("words"),
                                            pp.char('!') }))),
            "    the indent\n"..
            "    combinator\n"..
            "    indents these\n"..
            "    words !",
            "pp.indent")
        t:is(
            pp.renderPretty(1, 20, true,
                            pp.text("list") +
                                pp.encloseSep(
                                    pp.lbracket, pp.rbracket, pp.comma,
                                    {pp.number(10), pp.number(200), pp.number(3000)})),
            "list [10,200,3000]",
            "pp.encloseSep -- width 20")
        t:is(
            pp.renderPretty(1, 15, true,
                            pp.text("list") +
                                pp.encloseSep(
                                    pp.lbracket, pp.rbracket, pp.comma,
                                    {pp.number(10), pp.number(200), pp.number(3000)})),
            "list [10\n"..
            "     ,200\n"..
            "     ,3000]",
            "pp.encloseSep -- width 15")
        t:is(
            pp.renderPretty(1, 10, true,
                            pp.list({pp.number(10), pp.number(200), pp.number(3000)})),
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
            pp.renderPretty(1, 80, true, pp.text("foo") + pp.text("bar")),
            "foo bar",
            "'+'")
        t:is(
            pp.renderPretty(1, 80, true, pp.text("foo") & pp.text("bar")),
            "foo\n"..
            "bar",
            "'&'")
        t:is(
            pp.renderPretty(1, 80, true, pp.text("foo") / pp.text("bar")),
            "foo bar",
            "'/'")
        t:is(
            pp.renderPretty(1, 80, true, pp.text("foo") % pp.text("bar")),
            "foo\n"..
            "bar",
            "'%'")
        t:is(
            pp.renderPretty(1, 80, true, pp.text("foo") // pp.text("bar")),
            "foobar",
            "'//'")
    end)

t:subtest(
    "List combinators",
    function ()
        t:plan(8)
        t:is(
            pp.renderPretty(1, 80, true,
                            pp.hsep({pp.text("foo"), pp.text("bar"), pp.text("baz")})),
            "foo bar baz",
            "pp.hsep")
        t:is(
            pp.renderPretty(1, 80, true,
                            pp.vsep({pp.text("foo"), pp.text("bar"), pp.text("baz")})),
            "foo\n"..
            "bar\n"..
            "baz",
            "pp.vsep")
        t:is(
            pp.renderPretty(1, 7, true,
                            pp.fillSep({pp.text("foo"), pp.text("bar"), pp.text("baz")})),
            "foo bar\n"..
            "baz",
            "pp.fillSep")
        t:is(
            pp.renderPretty(1, 80, true,
                            pp.hcat({pp.text("foo"), pp.text("bar"), pp.text("baz")})),
            "foobarbaz",
            "pp.hcat")
        t:is(
            pp.renderPretty(1, 80, true,
                            pp.vcat({pp.text("foo"), pp.text("bar"), pp.text("baz")})),
            "foo\n"..
            "bar\n"..
            "baz",
            "pp.vcat")
         t:is(
            pp.renderPretty(1, 6, true,
                            pp.fillCat({pp.text("foo"), pp.text("bar"), pp.text("baz")})),
            "foobar\n"..
            "baz",
            "pp.fillSep")
         t:is(
            pp.renderPretty(1, 80, true,
                            pp.cat({pp.text("foo"), pp.text("bar"), pp.text("baz")})),
            "foobarbaz",
            "pp.cat")
         t:is(
             pp.renderPretty(1, 15, true,
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
            pp.renderPretty(
                1, 80, true,
                pp.text("let") +
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
            pp.renderPretty(
                1, 80, true,
                pp.text("let") +
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
        t:is(pp.renderPretty(1, 80, true, pp.enclose(pp.text('[['), pp.text(']]'), pp.char('a'))),
             "[[a]]",
             "pp.enclose")
        t:is(pp.renderPretty(1, 80, true, pp.squotes(pp.char('a'))),
             "'a'",
             "pp.squotes")
        t:is(pp.renderPretty(1, 80, true, pp.dquotes(pp.char('a'))),
             '"a"',
             "pp.dquotes")
        t:is(pp.renderPretty(1, 80, true, pp.parens(pp.char('a'))),
             "(a)",
             "pp.parens")
        t:is(pp.renderPretty(1, 80, true, pp.angles(pp.char('a'))),
             "<a>",
             "pp.angles")
        t:is(pp.renderPretty(1, 80, true, pp.braces(pp.char('a'))),
             "{a}",
             "pp.braces")
        t:is(pp.renderPretty(1, 80, true, pp.brackets(pp.char('a'))),
             "[a]",
             "pp.brackets")
    end)
