local po = {}

-- Modules
po.commandLineParser  = require('program-options/command-line-parser')
po.optionsDescription = require('program-options/options-description')
po.variablesMap       = require('program-options/variables-map')

-- Utility functions
function po.parseCommandLine(args, desc)
    return po.commandLineParser.new():options(desc):run(args)
end

return po
