local test = require('tap/test')
local t    = test.new()
t:plan(10)

local ansi = t:requireOK('ansi-terminal') or t:bailOut("Can't load ansi-terminal")

-- We can't actually use io.output() as the destination terminal to
-- test this module. A dummy stream is thus needed.
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

t:subtest(
    "movement by character",
    function ()
        t:plan(4)
        ansi.cursorUp(out, 42);       t:is(out:reset(), "\x1B[42A", "up")
        ansi.cursorDown(out, 42);     t:is(out:reset(), "\x1B[42B", "down")
        ansi.cursorForward(out, 42);  t:is(out:reset(), "\x1B[42C", "forward")
        ansi.cursorBackward(out, 42); t:is(out:reset(), "\x1B[42D", "backward")
    end)

t:subtest(
    "movement by line",
    function ()
        t:plan(2)
        ansi.cursorUpLine(out, 42);   t:is(out:reset(), "\x1B[42F", "up")
        ansi.cursorDownLine(out, 42); t:is(out:reset(), "\x1B[42E", "down")
    end)

t:subtest(
    "changing cursor position",
    function ()
        t:plan(2)
        ansi.cursorColumn(out, 42);     t:is(out:reset(), "\x1B[42G", "column")
        ansi.cursorPosition(out, 1, 2); t:is(out:reset(), "\x1B[1;2H", "position")
    end)

t:subtest(
    "save, restore, and report cursor position",
    function ()
        t:plan(3)
        ansi.saveCursor(out);           t:is(out:reset(), "\x1B7", "save")
        ansi.restoreCursor(out);        t:is(out:reset(), "\x1B8", "restore")
        ansi.reportCursorPosition(out); t:is(out:reset(), "\x1B[6n", "report")
    end)

t:subtest(
    "clear parts of the screen",
    function ()
        t:plan(6)
        ansi.clearFromCursorToScreenEnd(out);       t:is(out:reset(), "\x1B[0J")
        ansi.clearFromCursorToScreenBeginning(out); t:is(out:reset(), "\x1B[1J")
        ansi.clearScreen(out);                      t:is(out:reset(), "\x1B[2J")
        ansi.clearFromCursorToLineEnd(out);         t:is(out:reset(), "\x1B[0K")
        ansi.clearFromCursorToLineBeginning(out);   t:is(out:reset(), "\x1B[1K")
        ansi.clearLine(out);                        t:is(out:reset(), "\x1B[2K")
    end)

t:subtest(
    "scroll",
    function ()
        t:plan(2)
        ansi.scrollPageUp(out, 42);   t:is(out:reset(), "\x1B[42S", "up")
        ansi.scrollPageDown(out, 42); t:is(out:reset(), "\x1B[42T", "down")
    end)

t:subtest(
    "SGR",
    function ()
        t:plan(1)
        ansi.setSGR(
            out,
            { ansi.SGR.SetConsoleIntensity(ansi.ConsoleIntensity.Bold),
              ansi.SGR.SetUnderlining(ansi.Underlining.SingleUnderline)
            })
        t:is(out:reset(), "\x1B[1;4m", "bold + single underline")
    end)

t:subtest(
    "visibility",
    function ()
        t:plan(2)
        ansi.hideCursor(out); t:is(out:reset(), "\x1B[?25l", "hide")
        ansi.showCursor(out); t:is(out:reset(), "\x1B[?25h", "show")
    end)

t:subtest(
    "title",
    function ()
        t:plan(1)
        ansi.setTitle(out, "Hello, world!")
        t:is(out:reset(), "\x1B]0;Hello, world!\x07")
    end)
