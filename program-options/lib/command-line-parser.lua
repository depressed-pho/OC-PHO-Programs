local array   = require('containers/array')
local map     = require('containers/map')
local unicode = require('unicode')
local optionsDescription = require('program-options/options-description')
local positionalOptionsDescription = require('program-options/positional-options-description')
local variableValue = require('program-options/variable-value')
local commandLineParser = {}
commandLineParser.__index = commandLineParser

function commandLineParser.new()
    local self = setmetatable({}, commandLineParser)

    self._opts       = nil -- optionsDescription
    self._posOpts    = positionalOptionsDescription.new()
    self._extParsers = array.new() -- array<((string)->string, string)>
    self._allowUnregistered = false

    return self
end

function commandLineParser:options(opts)
    if not optionsDescription.isInstance(opts) then
        error("Not an instance of optionsDescription: "..tostring(opts), 2)
    end
    self._opts = opts
    return self
end

function commandLineParser:positional(posOpts)
    if not positionalOptionsDescription.isInstance(posOpts) then
        error("Not an instance of positionalOptionsDescription: "..tostring(posOpts), 2)
    end
    self._posOpts = posOpts
    return self
end

function commandLineParser:extraParser(parser)
    checkArg(1, parser, "function")
    self._extParsers:push(parser)
    return self
end

-- Treat any unrecognized options as positional ones but not option
-- arguments.
function commandLineParser:allowUnregistered()
    self._allowUnregistered = true
    return self
end

local classifier = {}
classifier.__index = classifier

function classifier.new(tokens, extParsers)
    local self = setmetatable({}, classifier)

    self._tokens     = tokens -- array<string>
    self._extParsers = extParsers -- array<function>
    self._endOfOpts  = false

    return self
end

function classifier:next() -- type, value, original-token
    if self._tokens:length() == 0 then
        return nil
    else
        local token = self._tokens:shift()
        assert(type(token) == "string")

        if self._endOfOpts then
            -- We have already encountered the "--" marker.
            return "non-opt", token, token

        elseif token == "--" then
            -- It's the end of options. Remaining tokens should all be
            -- treated as positional options.
            self._endOfOpts = true
            return self:next()
        end

        for _, extP in self._extParsers:entries() do
            local name, value = extP(token)
            if name and value then
                -- It's an option with an argument.
                return "ext-pair", {name, value}, token
            elseif name then
                -- It's an option with no arguments.
                return "ext-opt", name, token
            end
        end

        local pairedLong, value = token:match("^%-%-([^=]+)=(.*)$")
        if pairedLong then
            return "long-pair", {pairedLong, value}, token
        end

        local longOpt = token:match("^%-%-(.+)$")
        if longOpt then
            return "long-opt", longOpt, token
        end

        local shortOpts = token:match("^%-(.+)$")
        if shortOpts then
            return "short-opts", shortOpts, token
        end

        -- Note that "-" is a perfectly valid non-option. Consider the
        -- stdin/out convention "-o" "-".
        return "non-opt", token, token
    end
end

function classifier:expect(expType)
    local tokType, tokValue, origToken = self:next()

    if tokType == nil then
        return nil

    elseif tokType == expType then
        return tokValue, origToken
    else
        self._tokens:unshift(origToken)
        return nil
    end
end

function commandLineParser:run(args)
    checkArg(1, args, "table")
    if not self._opts then
        error("Misuse of commandLineParser: options unset", 2)
    end

    local ret = map.new() -- map<string, variableValue>
    local positionalIdx = 1
    local tokens = classifier.new(array.from(args), self._extParsers)

    local function positional(optToken)
        local name = self._posOpts:nameForPosition(positionalIdx)
        if name then
            if not self:_gotOption(ret, name, optToken) then
                error("Application error: positional argument #"..positionalIdx..
                          " is defined as "..self:_format(name, optToken)..
                          " but no such option has been declared", 2)
            end
            positionalIdx = positionalIdx + 1
        else
            error("Unrecognized positional option #"..positionalIdx..": "..optToken, 2)
        end
    end

    local function unknown(optToken)
        if self._allowUnregistered then
            positional(optToken)
        else
            error("Unrecognized option: "..optToken, 3)
        end
    end

    while true do
        local tokType, tokValue, origToken = tokens:next()

        if tokType == nil then
            break

        elseif tokType == "ext-pair" then
            if not self:_gotOption(ret, table.unpack(tokValue)) then
                error("Application error: an external command-line parser interpreted"..
                          " token `"..origToken.."' as "..self:_format(table.unpack(tokValue))..
                          " but no such option has been declared", 2)
            end
        elseif tokType == "ext-opt" then
            if not self:_gotOption(ret, tokValue) then
                error("Application error: an external command-line parser interpreted"..
                          " token `"..origToken.."' as "..self:_format(tokValue)..
                          " but no such option has been declared", 2)
            end
        elseif tokType == "long-pair" then
            if not self:_gotOption(ret, table.unpack(tokValue)) then
                unknown(origToken)
            end
        elseif tokType == "long-opt" then
            if not self:_gotOption(ret, tokValue) then
                unknown(origToken)
            end
        elseif tokType == "short-opts" then
            -- This is the hardest part. We interpret "-abc" as "-a"
            -- "-b" "-c" but also accept arguments. If "-b" and "-c"
            -- can take arguments "-a" doesn't, then "-abc" "foo" has
            -- to be interpreted as "-a" "-b" "foo" "-c".
            for i = 1, unicode.len(tokValue) do
                local shortName = unicode.sub(tokValue, i, i)
                local opt = self._opts:find(shortName)
                if opt then
                    local sem = opt:semantic()
                    if sem:isNoArgs() then
                        local found = self:_gotOption(ret, shortName)
                        assert(found)
                    else
                        local strArg = tokens:expect('non-opt')
                        local found  = self:_gotOption(ret, shortName, strArg)
                        assert(found)
                    end
                else
                    -- This is a special case. When "-abc" is given
                    -- but "b" is unknown, then the best we can do is
                    -- to treat it as a positional argument "-b" when
                    -- allowed.
                    unknown("-"..shortName)
                end
            end
        elseif tokType == "non-opt" then
            positional(tokValue)
        else
            error("Internal error: unknown token type: "..tokType)
        end
    end

    -- For options that have default values but didn't show up in
    -- args, apply those defaults here.
    for opt in self._opts:options():values() do
        local name = opt:canonicalName()
        if not ret:has(name) then
            local sem = opt:semantic()
            local def = sem:default()
            if def ~= nil then
                ret:set(name, variableValue.new(sem, def, true))
            end
        end
    end

    return ret
end

function commandLineParser:_format(name, value) -- luacheck: ignore self
    if #name == 1 then
        if value then
            return "-"..name.." "..value
        else
            return "-"..name
        end
    else
        if value then
            return "--"..name.."="..value
        else
            return "--"..name
        end
    end
end

function commandLineParser:_gotOption(ret, name, strVal)
    local opt = self._opts:find(name)
    if opt then
        local old   = ret:get(opt:canonicalName(), nil)
        local sem   = opt:semantic()
        local value -- variableValue
        if strVal then
            if sem:isNoArgs() then
                error("Option "..self:_format(name).." takes no arguments", 3)
            else
                local ok, result = pcall(
                    function ()
                        return sem:parse(strVal)
                    end)
                if ok then
                    if old then
                        value = variableValue.new(
                            sem, sem:append(old:value(), result), false)
                    else
                        value = variableValue.new(
                            sem, sem:append(sem:default(), result), false)
                    end
                else
                    error("Invalid argument for option "..self:_format(name)..": "..result, 3)
                end
            end
        else
            if sem:implicit() == nil then
                error("Option "..self:_format(name).." takes a mandatory argument", 3)

            elseif old then
                value = variableValue.new(
                    sem, sem:append(old:value(), sem:implicit()), false)
            else
                value = variableValue.new(
                    sem, sem:implicit(), false)
            end
        end
        ret:set(opt:canonicalName(), value)
        return true
    else
        return false
    end
end

return commandLineParser
