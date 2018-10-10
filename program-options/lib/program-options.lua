local po = {}

-- Modules
po.commandLineParser  = require('program-options/command-line-parser')
po.optionsDescription = require('program-options/options-description')
po.valueSemantic      = require('program-options/value-semantic')
po.variablesMap       = require('program-options/variables-map')

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
        function (_, strVal)
            if strVal:match("^%-?%d+$") then
                return tonumber(strVal)
            else
                error("Not an integer: "..strVal)
            end
        end)
end

return po
