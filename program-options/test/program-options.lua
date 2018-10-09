local test = require('tap/test')
local t    = test.new()
t:plan(1)

local po = t:requireOK('program-options') or t:bailOut("Can't load program-options")

local desc = po.optionsDescription.new("Allowed options")
desc:addOptions()
("help,h", "produce help message")

t:subtest(
    "--help, -h",
    function ()
        t:plan(2)

        local vm = po.variablesMap.new()
        vm:store(po.parseCommandLine({"--help"}, desc))
        vm:notify()

        t:is(vm:has("help"), true, "--help")

        vm:clear()
        vm:store(po.parseCommandLine({"-h"}, desc))
        vm:notify()

        t:is(vm:has("help"), true, "-h")
    end)
