local po = {}

-- Require a module lazily. THINKME: Worth moving to a separate
-- package?
local function requireL(modName)
    -- Mutate 'dst' so that it becomes identical to 'src'.
    local function overwrite(dst, src)
        for k, v in pairs(src) do
            rawset(dst, k, v)
        end
        setmetatable(dst, getmetatable(src))
    end
    local mt = {
        __index = function (module, symbol)
            overwrite(module, require(modName))
            return module[symbol]
        end,
        __newindex = function (module, symbol, value)
            overwrite(module, require(modName))
            module[symbol] = value
        end
    }
    return setmetatable({}, mt)
end

-- Modules
po.commandLineParser            = requireL('program-options/command-line-parser')
po.optionDescription            = requireL('program-options/option-description')
po.optionsDescription           = requireL('program-options/options-description')
po.positionalOptionsDescription = requireL('program-options/positional-options-description')
po.valueSemantic                = requireL('program-options/value-semantic')
po.variablesMap                 = requireL('program-options/variables-map')

-- Utility functions
function po.parseCommandLine(args, desc)
    return po.commandLineParser.new():options(desc):run(args)
end

-- Predefined value semantics
function po.string()
    return po.valueSemantic.new()
end

function po.integer()
    return po.valueSemantic.new():parser(
        function (strVal)
            if strVal:match("^%-?%d+$") then
                return tonumber(strVal)
            else
                error("Not an integer: "..strVal)
            end
        end)
end

function po.number()
    return po.valueSemantic.new():parser(
        function (strVal)
            local num = tonumber(strVal)
            if num then
                return num
            else
                error("Not a number: "..strVal)
            end
        end)
end

function po.boolean()
    return po.valueSemantic.new():parser(
        function (strVal)
            local lower = strVal:lower()
            if lower == "true" or lower == "yes" then
                return true
            elseif lower == "false" or lower == "no" then
                return false
            else
                error("Not a boolean: "..strVal)
            end
        end)
end

function po.boolSwitch()
    return po.valueSemantic.new():default(false):implicit(true):noArgs()
end

function po.enum(...)
    local args = table.pack(...)
    return po.valueSemantic.new():parser(
        function (strVal)
            for i = 1, #args do
                if strVal == args[i] then
                    return strVal
                end
            end
            error("Unrecognized argument: "..strVal)
        end)
end

function po.sequence(inner)
    if not po.valueSemantic.isInstance(inner) then
        error("Not an instance of valueSemantic: "..tostring(inner), 2)
    end
    local function parse(strVal)
        return inner:parse(strVal)
    end
    local function append(old, value)
        checkArg(1, old, "table")
        -- Insert 'value' at the end of a shallow copy of 'old'.
        local ret = {}
        for i = 1, #old do
            ret[i] = old[i]
        end
        ret[#ret+1] = value
        return ret
    end
    local function merge(old, new)
        checkArg(1, old, "table")
        checkArg(2, new, "table")
        -- Concatenate 'old' and 'new' together.
        local ret = {}
        for i = 1, #old do
            ret[i] = old[i]
        end
        for i = 1, #new do
            ret[#ret+1] = new[i]
        end
        return ret
    end
    return po.valueSemantic.new():parser(parse):appender(append):merger(merge):default({})
end

return po
