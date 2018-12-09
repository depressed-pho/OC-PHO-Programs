--local harness = require("tap/harness")
local po      = require("program-options")

-- THINKME: Might be worth moving to a separate library.
local function catch(main, onError)
    checkArg(1, main, "function")
    checkArg(2, onError, "function")

    local ok, result = pcall(main)
    if ok then
        return result
    else
        return onError(result)
    end
end

local function main(args)
    local misc = po.optionsDescription.new("Miscellaneous")
    misc:addOptions()
        ("h"        , "print this help")
        ("help"     , "show the man page of this program")
        ("verbose,v", "print all test lines")
        ("dry,D"    , "show tests that would have run, without actually running")

    local tests = po.optionsDescription.new("Selecting tests to run")
    tests:addOptions()
        ("recurse,r", "recursively descend into directories")

    local hidden = po.optionsDescription.new():hidden()
    hidden:add(
        po.optionDescription.new(
            "file",
            po.sequence(po.string()):name("FILE-OR-DIR")))

    local desc = po.optionsDescription.new()
    desc:add(misc):add(tests):add(hidden)

    local posDesc = po.positionalOptionsDescription.new()
    posDesc:add("file", math.huge)

    local parser = po.commandLineParser.new():options(desc):positional(posDesc)
    local help   = po.commandLineHelp.new("prove"):options(desc):positional(posDesc)

    local vm = po.variablesMap.new()
    catch(
        function ()
            vm:store(parser:run(args))
        end,
        function (e)
            io.stderr:write(e, "\n")
            help:print(io.stderr)
            os.exit(1)
        end)
    vm:notify()

    if vm:has("h") then
        help:print()
        os.exit(0)

    elseif vm:has("help") then
        os.execute("man prove")
        os.exit(0)
    end
end

main({...})

--[[
local parser = require("tap/parser")

local file = io.open("test.tap", "r")
for result in parser(file) do
   print(result:tostring())
end
]]

--local h = harness.new()
--h:runTests({"/usr/test/mutex.lua"})
