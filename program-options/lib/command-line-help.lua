local pp = require('wl-pprint')
local optionsDescription = require('program-options/options-description')
local positionalOptionsDescription = require('program-options/positional-options-description')
local commandLineHelp = {}
commandLineHelp.__index = commandLineHelp

function commandLineHelp.new(progName)
    checkArg(1, progName, "string")

    local self = setmetatable({}, commandLineHelp)
    self._progName = progName
    self._opts     = nil -- optionsDescription
    self._posOpts  = positionalOptionsDescription.new()

    return self
end

function commandLineHelp:options(opts)
    if not optionsDescription.isInstance(opts) then
        error("Not an instance of optionsDescription: "..tostring(opts), 2)
    end
    self._opts = opts
    return self
end

function commandLineHelp:positional(posOpts)
    if not positionalOptionsDescription.isInstance(posOpts) then
        error("Not an instance of positionalOptionsDescription: "..tostring(posOpts), 2)
    end
    self._posOpts = posOpts
    return self
end

function commandLineHelp:print(...)
    local args = table.pack(...)
    local stream, width
    local optsColumnWidth = nil
    if args.n == 0 then
        stream = io.output()
        width  = self:_termWidth()
    elseif args.n == 1 then
        if type(args[1]) == "number" then
            stream = io.output()
            width  = args[1]
        else
            stream = args[1]
            width  = 80
        end
    elseif args.n == 2 then
        if type(args[1]) == "number" then
            checkArg(2, args[2], "number", "nil")
            stream = io.output()
            width  = args[1]
            optsColumnWidth = args[2]
        else
            checkArg(2, args[2], "number")
            stream = args[1]
            width  = args[2]
        end
    else
        checkArg(2, args[2], "number")
        checkArg(3, args[3], "number", "nil")
        stream = args[1]
        width  = args[2]
        optsColumnWidth = args[3]
    end
    stream:write(self:format(width, optsColumnWidth))
end

function commandLineHelp:_termWidth() -- luacheck: ignore self
    -- Do we have the term API from OpenOS? If so we use it.
    local ok, result = pcall(require, "term")
    if ok then
        local w, _, _, _, _, _ = result.getViewport()
        return w
    else
        error("Unsupported OS: cannot detect the width of the terminal")
    end
end

function commandLineHelp:format(width, optsColumnWidth)
    checkArg(1, width, "number")
    checkArg(2, optsColumnWidth, "number", "nil")
    optsColumnWidth = optsColumnWidth or math.floor(width / 3)

    if not self._opts then
        error("Misuse of commandLineHelp: options unset", 2)
    end

    local doc = self:_root(optsColumnWidth)
    return pp.displayS(true, pp.renderPretty(1.0, width, doc)).."\n"
end

function commandLineHelp:_root(optsColumnWidth)
    local usage    = self:_usage()
    local optsHelp = self:_optsHelp(optsColumnWidth, self._opts)
    return usage % optsHelp
end

-- Build the "Usage:" line.
function commandLineHelp:_usage()
    local words = {
        pp.text("Usage:"),
        pp.text(self._progName)
    }
    -- The [options] is shown iff there are any options that aren't
    -- positional.
    do
        local allOpts = self._opts:allOpts()
        for _, name in self._posOpts:entries() do
            -- Ugh, this is terribly inefficient O(n^2) but what else
            -- can we do?
            allOpts = allOpts:filter(
                function (opt)
                    return not opt:match(name)
                end)
        end
        if #allOpts > 0 then
            table.insert(words, pp.text("[options]"))
        end
    end
    -- Now we enumerate positional arguments like "ARG1 ARG2
    -- [ARG3...]".
    for pos, name in self._posOpts:entries() do
        local opt = self._opts:find(name)
        if not opt then
            error("Application error: positional argument #"..pos..
                      " is defined as `"..name.."' but no such"..
                      " option is declared", 2)
        end

        local sem = opt:semantic()
        if sem:isNoArgs() then
            error("Application error: positional argument #"..pos..
                      " is defined as `"..name.."' which is"..
                      " supposed to take no arguments", 2)
        end

        local doc = pp.text(sem:name())
        if pos == math.huge then
            doc = doc .. pp.text("...")
        end
        if not sem:isRequired() then
            doc = pp.brackets(doc)
        end
        table.insert(words, doc)
    end
    return pp.nest(4, pp.fillSep(words))
end

-- Format a possibly nested optionsDescription.
function commandLineHelp:_optsHelp(optsColumnWidth, opts)
    assert(not opts:isHidden())
    local paragraphs = {}

    if #opts:caption() > 0 then
        table.insert(paragraphs, pp.empty)
        table.insert(paragraphs, pp.text(opts:caption()) .. pp.colon)
    end

    for _, opt in opts:options():entries() do
        table.insert(paragraphs, self:_optHelp(optsColumnWidth, opt))
    end

    for _, group in opts:groups():entries() do
        if not group:isHidden() then
            table.insert(paragraphs, self:_optsHelp(optsColumnWidth, group))
        end
    end

    return pp.vcat(paragraphs)
end

-- Format a single optionDescription.
function commandLineHelp:_optHelp(optsColumnWidth, opt) -- luacheck: ignore
    local sem      = opt:semantic()
    local optParts = {}

    if opt:shortName() then
        table.insert(optParts, pp.char('-')..pp.text(opt:shortName()))
        if opt:longName() then
            table.insert(optParts, pp.comma + (pp.text("--")..pp.text(opt:longName())))
            if not sem:isNoArgs() then
                table.insert(optParts, self:_argHelp(sem, true))
            end
        else
            if not sem:isNoArgs() then
                table.insert(optParts, self:_argHelp(sem, false))
            end
        end
    else
        table.insert(optParts, pp.indent(4, pp.text("--")..pp.text(opt:longName())))
        if not sem:isNoArgs() then
            table.insert(optParts, self:_argHelp(sem, true))
        end
    end

    local optDoc = pp.hcat(optParts)
    if opt:description() then
        local descDoc = self:_descHelp(opt:description())
        return pp.indent(2, pp.fillBreak(optsColumnWidth-2, optDoc)..
                             pp.text("  ")..descDoc)
    else
        return pp.indent(2, optDoc)
    end
end

-- Format an argument.
function commandLineHelp:_argHelp(sem, isLong) -- luacheck: ignore self
    local arg = pp.text(sem:name())

    if sem:implicit() == nil then
        if isLong then
            arg = pp.equals..arg
        else
            arg = pp.empty + arg
        end
    else
        if isLong then
            arg = pp.brackets(
                pp.equals..arg..pp.parens(
                    pp.equals..pp.string(sem:format(sem:implicit()))))
        else
            arg = pp.empty + pp.brackets(
                arg..pp.parens(
                    pp.equals..pp.string(sem:format(sem:implicit()))))
        end
    end

    if sem:default() ~= nil then
        arg = arg + pp.parens(
            pp.equals..pp.string(sem:format(sem:default())))
    end

    return arg
end

-- Format a description.
function commandLineHelp:_descHelp(desc) -- luacheck: ignore self
    local parts = {}
    local start = 1
    while true do
        local sepPos = desc:find("[ \n]", start)
        if sepPos == nil then
            parts[#parts+1] = pp.text(desc:sub(start))
            break
        else
            local sep
            if desc:sub(sepPos, sepPos) == " " then
                sep = pp.space
            else
                sep = pp.linebreak
            end

            if sepPos == start then
                parts[#parts+1] = sep
            else
                parts[#parts+1] = pp.text(desc:sub(start, sepPos-1))
                parts[#parts+1] = sep
            end
            start = sepPos + 1
        end
    end
    return pp.hcat(parts)
end

return commandLineHelp
