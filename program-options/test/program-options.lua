local test = require('tap/test')
local t    = test.new()
t:plan(1)

local po = t:requireOK('program-options') or t:bailOut("Can't load program-options")

-- Options for a hypothetical grep(1).
local misc = po.optionsDescription.new("Miscellaneous")
misc:addOptions()
    ("help,h"        , "produce help message")
    ("verbose,V"     , po.integer():default(0):implicit(1), "set the verbosity level")
    ("invert-match,v", po.boolSwitch(), "select non-matching lines")

local outputCtrl = po.optionsDescription.new("Output control")
outputCtrl:addOptions()
    ("color"    , po.boolean(), "whether to enable colored output")
    ("devices,D", po.enum("read", "skip"):default("read"):name("ACTION"), "how to handle devices")
    ("exclude"  , po.sequence(po.string()):name("PATTERN"), "skip files that match the pattern")

local desc = po.optionsDescription.new()
desc:add(misc):add(outputCtrl)

t:subtest(
    "-h, --help",
    function ()
        t:plan(3)

        local vm = po.variablesMap.new()
        vm:store(po.parseCommandLine({"--help"}, desc))
        vm:notify()
        t:is(vm:has("help"), true, "nil option (long)")

        -- Can it also recognize short options?
        vm:clear()
        vm:store(po.parseCommandLine({"-h"}, desc))
        vm:notify()
        t:is(vm:has("help"), true, "nil option (short)")

        -- Does it reject arguments?
        t:diesOK(
            function ()
                vm:clear()
                vm:store(po.parseCommandLine({"--help=yes"}, desc))
                vm:notify()
            end,
            "nil option (invalid)")
    end)

t:subtest(
    "-V, --verbose",
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
        vm:store(po.parseCommandLine({"-V"}, desc))
        vm:notify()
        t:is(vm:get("verbose"), 1, "implicit integer (short)")

        vm:clear()
        vm:store(po.parseCommandLine({"--verbose=2"}, desc))
        vm:notify()
        t:is(vm:get("verbose"), 2, "explicit integer (long)")

        vm:clear()
        vm:store(po.parseCommandLine({"-V", "2"}, desc))
        vm:notify()
        t:is(vm:get("verbose"), 2, "explicit integer (short)")

        t:diesOK(
            function ()
                vm:clear()
                vm:store(po.parseCommandLine({"-V", "foo"}, desc))
                vm:notify()
            end,
            "explicit integer (invalid)")
    end)

t:subtest(
    "--color",
    function ()
        t:plan(2)

        local vm = po.variablesMap.new()
        vm:store(po.parseCommandLine({"--color=yes"}, desc))
        vm:notify()
        t:is(vm:get("color"), true, "explicit boolean (long)")

        t:diesOK(
            function ()
                vm:clear()
                vm:store(po.parseCommandLine({"--color"}, desc))
                vm:notify()
            end,
            "implicit boolean")
    end)

t:subtest(
    "-v, --invert-match",
    function ()
        t:plan(3)

        local vm = po.variablesMap.new()
        vm:store(po.parseCommandLine({}, desc))
        vm:notify()
        t:is(vm:get("invert-match"), false, "default boolSwitch")

        vm:clear()
        vm:store(po.parseCommandLine({"-v"}, desc))
        vm:notify()
        t:is(vm:get("invert-match"), true, "implicit boolSwitch")

        t:diesOK(
            function ()
                vm:clear()
                vm:store(po.parseCommandLine({"--invert-match=true"}, desc))
                vm:notify()
            end,
            "invalid boolSwitch")
    end)

t:subtest(
    "-D, --devices",
    function ()
        t:plan(2)

        local vm = po.variablesMap.new()
        vm:store(po.parseCommandLine({"-D", "skip"}, desc))
        vm:notify()
        t:is(vm:get("devices"), "skip", "explicit enum")

        t:diesOK(
            function ()
                vm:clear()
                vm:store(po.parseCommandLine({"-D", "destroy"}, desc))
                vm:notify()
            end,
            "invalid enum")
    end)

t:subtest(
    "--exclude",
    function ()
        t:plan(3)

        local vm = po.variablesMap.new()
        vm:store(po.parseCommandLine({}, desc))
        vm:notify()
        t:isDeeply(vm:get("exclude"), {}, "default seq<str>")

        vm:clear()
        vm:store(po.parseCommandLine({"--exclude=foo"}, desc))
        vm:notify()
        t:isDeeply(vm:get("exclude"), {"foo"}, "explicit seq<str>")

        vm:clear()
        vm:store(po.parseCommandLine({"--exclude=foo", "--exclude=bar"}, desc))
        vm:notify()
        t:isDeeply(vm:get("exclude"), {"foo", "bar"}, "explicit seq<str> (appending)")
    end)

t:subtest(
    "combined short options",
    function ()
        t:plan(2)

        local vm = po.variablesMap.new()
        vm:store(po.parseCommandLine({"-Dv", "skip"}, desc))
        vm:notify()
        t:is(vm:get("devices"), "skip", "-D skip")
        t:is(vm:get("invert-match"), true, "-v")
    end)

-- FIXME: Test for positional arguments
-- FIXME: Test for required()'ed values
