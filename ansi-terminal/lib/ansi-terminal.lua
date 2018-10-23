local types = require('ansi-terminal/types')
local ansi  = {}

-- csi(parameters, controlFunction), where parameters is a sequence of
-- integers, returns the control sequence comprising the control
-- function CONTROL SEQUENCE INTRODUCER (CSI) followed by the
-- parameter(s) (separated by ';') and ending with the controlFunction
-- character(s) that identifies the control function.
local function csi(args, code)
    local xs = {"\x1B["}
    for i, arg in ipairs(args) do
        if i > 1 then
            table.insert(xs, ";")
        end
        table.insert(xs, tostring(arg))
    end
    table.insert(xs, code)
    return table.concat(xs)
end

-- Generate a function which performs an IO operation outputting
-- CSI. The argument 'arity' is the arity of transformer.
local function mkIOFunc(name, arity)
    return function (...)
        local args = table.pack(...)
        if args.n == arity then
            -- ansi.cursorUp(n)
            local code = ansi[name.."Code"](...)
            io.output():write(code)

        elseif args.n == arity + 1 then
            -- ansi.cursorUp(handle, n)
            local handle = table.remove(args, 1)
            local code   = ansi[name.."Code"](table.unpack(args))
            handle:write(code)
        else
            error("bad number of arguments: expected "..arity.." or "..(arity+1)..
                      " but got "..args.n, 2)
        end
    end
end

-- Generate a function which creates a CSI by applying some
-- transormations to function arguments.
local function mkCodeGen(f, arity) -- f: (...)->({int}, string)
    return function (...)
        local args = table.pack(...)
        if args.n == arity then
            if type(f) == "function" then
                return f(...)

            elseif type(f) == "string" then
                assert(arity == 0)
                return f

            else
                error("Internal error: wrong type of transformer: "..type(f))
            end
        else
            error("bad number of arguments: expected "..arity.." but got "..args.n, 2)
        end
    end
end

-- Define public functions with pairs of function names and argument
-- transformers.
local function define(tab)
    for name, spec in pairs(tab) do
        local arity, tr = spec[1], spec[2]
        ansi[name]         = mkIOFunc(name, arity)
        ansi[name.."Code"] = mkCodeGen(tr, arity)
    end
end

-- Ugh. Why do I have to implement this myself?
local function concatMap(f, xs)
    local ret = {}
    for _, x in ipairs(xs) do
        local ys = f(x)
        for _, y in ipairs(ys) do
            ret[#ret+1] = y
        end
    end
    return ret
end

-- colorToCode(color) returns the 0-based index of the color (one of
-- the eight colors in the standard).
local function colorToCode(color)
    return color:match {
        Black   = function () return 0 end,
        Red     = function () return 1 end,
        Green   = function () return 2 end,
        Yellow  = function () return 3 end,
        Blue    = function () return 4 end,
        Magenta = function () return 5 end,
        Cyan    = function () return 6 end,
        White   = function () return 7 end
    }
end

-- sgrToCode(sgr) returns the parameter of the SELECT GRAPHIC
-- RENDITION (SGR) aspect identified by 'sgr'.
local function sgrToCode(sgr) -- returns [number]
    return sgr:match {
        Reset = function ()
            return {0}
        end,
        SetConsoleIntensity = function (intensity)
            return intensity:match {
                Bold   = function () return {1} end,
                Faint  = function () return {2} end,
                Normal = function () return {22} end
            }
        end,
        SetItalicized = function (italicized)
            if italicized then
                return {3}
            else
                return {23}
            end
        end,
        SetUnderlining = function (underlining)
            return underlining:match {
                SingleUnderline = function () return {4} end,
                DoubleUnderline = function () return {21} end,
                NoUnderline     = function () return {24} end
            }
        end,
        SetBlinkSpeed = function (blinkSpeed)
            return blinkSpeed:match {
                SlowBlink  = function () return {5} end,
                RapidBlink = function () return {6} end,
                NoBlink    = function () return {25} end
            }
        end,
        SetVisible = function (visible)
            if visible then
                return {28}
            else
                return {8}
            end
        end,
        SetSwapForegroundBackground = function (swap)
            if swap then
                return {7}
            else
                return {27}
            end
        end,
        SetColor = function (layer, intensity, color)
            return layer:match {
                Foreground = function ()
                    return intensity:match {
                        Dull = function ()
                            return {30 + colorToCode(color)}
                        end,
                        Vivid = function ()
                            return {90 + colorToCode(color)}
                        end
                    }
                end,
                Background = function ()
                    return intensity:match {
                        Dull = function ()
                            return {40 + colorToCode(color)}
                        end,
                        Vivid = function ()
                            return {100 + colorToCode(color)}
                        end
                    }
                end
            }
        end,
        SetRGBColor = function (layer, red, green, blue)
            local function rgb24(c)
                return math.floor(c * 255)
            end
            local r, g, b = rgb24(red, green, blue)
            return layer:match {
                Foreground = function ()
                    return {38, 2, r, g, b}
                end,
                Background = function ()
                    return {48, 2, r, g, b}
                end
            }
        end
    }
end

-- Re-export types
ansi.SGR = types.SGR
ansi.ConsoleLayer = types.ConsoleLayer
ansi.Color = types.Color
ansi.ColorIntensity = types.ColorIntensity
ansi.ConsoleIntensity = types.ConsoleIntensity
ansi.Underlining = types.Underlining
ansi.BlinkSpeed = types.BlinkSpeed

-- Cursor movement by character
define {
    cursorUp       = {1, function (n) checkArg(1, n, "number"); return csi({n}, "A") end},
    cursorDown     = {1, function (n) checkArg(1, n, "number"); return csi({n}, "B") end},
    cursorForward  = {1, function (n) checkArg(1, n, "number"); return csi({n}, "C") end},
    cursorBackward = {1, function (n) checkArg(1, n, "number"); return csi({n}, "D") end}
}

-- Cursor movement by line
define {
    cursorDownLine = {1, function (n) checkArg(1, n, "number"); return csi({n}, "E") end},
    cursorUpLine   = {1, function (n) checkArg(1, n, "number"); return csi({n}, "F") end}
}

-- Directly changing cursor position
define {
    cursorColumn   = {1, function (n) checkArg(1, n, "number"); return csi({n}, "G") end},
    cursorPosition = {
        2,
        function (row, col)
            checkArg(1, row, "number")
            checkArg(2, col, "number")
            return csi({row, col}, "H")
        end
    }
}

-- Saving, restoring, and reporting cursor position
define {
    -- Save the cursor position in memory. The only way to access the
    -- saved value is with the restoreCursor command.
    saveCursor = {0, "\x1B7"},
    -- Restore the cursor position from memory. There will be no value
    -- saved in memory until the first use of the saveCursor command.
    restoreCursor = {0, "\x1B8"},
    -- Emit the cursor position into the console input stream,
    -- immediately after being recognised on the output stream, as:
    -- ESC [ <cursor row> ; <cursor column> R
    reportCursorPosition = {0, csi({}, "6n")}
}

-- Clearing parts of the screen
define {
    clearFromCursorToScreenEnd       = {0, csi({0}, "J")},
    clearFromCursorToScreenBeginning = {0, csi({1}, "J")},
    clearScreen                      = {0, csi({2}, "J")},
    clearFromCursorToLineEnd         = {0, csi({0}, "K")},
    clearFromCursorToLineBeginning   = {0, csi({1}, "K")},
    clearLine                        = {0, csi({2}, "K")}
}

-- Scrolling the screen
define {
    -- Scroll the displayed information up the terminal: not widely
    -- supported
    scrollPageUp = {1, function (n) checkArg(1, n, "number"); return csi({n}, "S") end},
    -- Scroll the displayed information down the terminal: not widely
    -- supported
    scrollPageDown = {1, function (n) checkArg(1, n, "number"); return csi({n}, "T") end},
}

-- Select Graphic Rendition mode: colors and other whizzy stuff
define {
    -- Set the Select Graphic Rendition mode. The parameter 'sgrs' is
    -- a sequence of commands: these will typically be applied on top
    -- of the current console SGR mode. An empty sequence of commands
    -- is equivalent to the sequence {Reset}. Commands are applied
    -- left to right.
    setSGR = {
        1,
        function (sgrs)
            checkArg(1, sgrs, "table")
            return csi(concatMap(sgrToCode, sgrs), "m")
        end
    }
}

-- Cursor visibilty changes
define {
    hideCursor = {0, csi({}, "?25l")},
    showCursor = {0, csi({}, "?25h")}
}

-- Changing the title
define {
    -- Set the terminal window title. This usually only makes sense
    -- for terminal emulators running on a window system.
    setTitle = {
        1,
        function (title)
            checkArg(1, title, "string")
            local filtered = title:gsub("\x07", "")
            return "\x1B]0;" .. filtered .. "\x07"
        end
    }
}

-- Checking if a handle supports ANSI

-- Use heuristics to determine whether the functions defined in this
-- package will work with a given handle.
function ansi.supportsANSI(handle)
    handle = handle or io.output()

    if type(handle) == "table" and handle.tty then
        -- OpenOS TTY
        return true
    else
        return false
    end
end

-- Getting the cursor position

-- Attempt to get the reported cursor position, combining the
-- functions reportCursorPosition, getReportedCursorPosition and
-- parseCursorPosition. Returns nil if any data emitted by
-- reportCursorPosition, obtained by getReportedCursorPosition, cannot
-- be parsed by parseCursorPosition.
function ansi.getCursorPosition() -- returns row: number, col: number
    -- NOTE: We really want to temporarily disable the buffering mode
    -- of io.input(), but the standard Lua I/O API doesn't specify how
    -- to do it. So we have to do some platform specific things here.
    --
    -- But fortunately io.stdin is non-buffered by default on OpenOS.
    ansi.reportCursorPosition()
    io.output():flush()
    return ansi.parseCursorPosition(ansi.getReportedCursorPosition())
end

-- Attempt to get the reported cursor position data from the console
-- input stream. The function is intended to be called immediately
-- after reportCursorPosition (or related functions) have caused
-- characters to be emitted into the stream.
function ansi.getReportedCursorPosition() -- returns string
    -- NOTE: We really want to turn off the echo mode of io.input()
    -- before reading anything from it, but the standard Lua I/O API
    -- doesn't specify how to do it. So we have to do some platform
    -- specific things here.
    --
    -- But fortunately the result of \ESC[6n isn't echoed on OpenOS.
    local c = io.read(1)
    if c then
        if c == '\x1B' then
            -- Continue reading chars until the expected 'R' character
            -- is obtained.
            local ret = c
            while true do
                local c1 = io.read(1)
                if c1 then
                    ret = ret .. c1
                    if c1 == 'R' then
                        return ret
                    end
                else
                    -- Hmm, got EOF in the middle of result.
                    return ret
                end
            end
        else
            -- If the first character is not the expected \ESC then
            -- give up. This provides a modicum of protection against
            -- unexpected data in the input stream.
            return c
        end
    else
        return ""
    end
end

-- Parse the characters emitted by reportCursorPosition into the
-- console input stream. Returns the cursor row and column, or nil if
-- they cannot be parsed.
function ansi.parseCursorPosition(report)
    checkArg(1, report, "string")
    -- NOTE: OpenOS 1.7.2 reports it as \ESC{row};{col}R but ANSI says
    -- it is supposed to be \ESC[{row};{col}R. This is a bug in OpenOS
    -- and we aren't willing to hide it.
    local row, col = report:match("^\x1B%[(%d+);(%d+)R")
    if row then
        return tonumber(row), tonumber(col)
    else
        return nil
    end
end

return ansi
