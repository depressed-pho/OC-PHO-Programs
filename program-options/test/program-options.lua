local test = require('tap/test')
local t    = test.new()
t:plan(1)

local po = t:requireOK('program-options') or t:bailOut("Can't load program-options")

local desc = po.optionsDescription.new("Allowed options")
desc:addOptions()
    ("help,h"   , "produce help message")
    ("verbose,v", po.integer():default(0):implicit(1), "set the verbosity level")

t:subtest(
    "-h, --help",
    function ()
        t:plan(2)

        local vm = po.variablesMap.new()
        vm:store(po.parseCommandLine({"--help"}, desc))
        vm:notify()
        t:is(vm:has("help"), true, "--help")

        -- Can it also recognize short options?
        vm:clear()
        vm:store(po.parseCommandLine({"-h"}, desc))
        vm:notify()
        t:is(vm:has("help"), true, "-h")
    end)

t:subtest(
    "-v, --verbose",
    function ()
        t:plan(6)

        local vm = po.variablesMap.new()
        vm:store(po.parseCommandLine({}, desc))
        vm:notify()
        t:is(vm:get("verbose"), 0, "default integer")

        vm:clear()
        vm:store(po.parseCommandLine({"--verbose"}, desc))
        vm:notify()
        t:is(vm:get("verbose"), 1, "implicit integer (long)")

        vm:clear()
        vm:store(po.parseCommandLine({"-v"}, desc))
        vm:notify()
        t:is(vm:get("verbose"), 1, "implicit integer (short)")

        vm:clear()
        vm:store(po.parseCommandLine({"--verbose=2"}, desc))
        vm:notify()
        t:is(vm:get("verbose"), 2, "explicit integer (long)")

        vm:clear()
        vm:store(po.parseCommandLine({"-v", "2"}, desc))
        vm:notify()
        t:is(vm:get("verbose"), 2, "explicit integer (short)")

        t:diesOK(
            function ()
                vm:clear()
                vm:store(po.parseCommandLine({"-v", "foo"}, desc))
                vm:notify()
            end,
            "explicit integer (invalid)")
    end)
