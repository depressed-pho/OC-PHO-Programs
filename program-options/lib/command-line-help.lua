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

function commandLineHelp:format(width)
    checkArg(1, width, "number")
    if not self._opts then
        error("Misuse of commandLineHelp: options unset", 2)
    end

    local doc = self:_root()
    return pp.displayS(true, pp.renderPretty(1.0, width, doc))
end

function commandLineHelp:_root()
    local usage = self:_usage()
    return usage -- FIXME
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
        local optSet = self._opts:options()
        for _, name in self._posOpts:toMap():entries() do
            -- Ugh, this is terribly inefficient O(n^2) but what else
            -- can we do?
            optSet = optSet:filter(
                function (opt)
                    return not opt:match(name)
                end)
        end
        if #optSet > 0 then
            table.insert(words, pp.text("[options]"))
        end
    end

    -- FIXME

    return pp.nest(4, pp.fillSep(words))
end

return commandLineHelp
