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

function commandLineHelp:format(width, optsColumnWidth)
    checkArg(1, width, "number")
    checkArg(2, optsColumnWidth, "number", "nil")
    optsColumnWidth = optsColumnWidth or math.floor(width / 3)

    if not self._opts then
        error("Misuse of commandLineHelp: options unset", 2)
    end

    local doc = self:_root(optsColumnWidth)
    return pp.displayS(true, pp.renderPretty(1.0, width, doc))
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
    local sem   = opt:semantic()
    local parts = {}

    if opt:shortName() then
        table.insert(parts, pp.char('-')..pp.text(opt:shortName()))
        if opt:longName() then
            table.insert(parts, pp.comma + (pp.text("--")..pp.text(opt:longName())))
            if not sem:isNoArgs() then
                table.insert(parts, self:_argHelp(sem, true))
            end
        else
            if not sem:isNoArgs() then
                table.insert(parts, self:_argHelp(sem, false))
            end
        end
    else
        table.insert(parts, pp.indent(4, pp.text("--")..pp.text(opt:longName())))
        if not sem:isNoArgs() then
            table.insert(parts, self:_argHelp(sem, true))
        end
    end

    return pp.indent(2, pp.hcat(parts))
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

return commandLineHelp
