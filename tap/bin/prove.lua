local filesystem = require("filesystem")
local harness    = require("tap/harness")
local po         = require("program-options")

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

local function collectTests(vm)
    local tests = {}
    local function recurse(dir)
        for file in filesystem.list(dir) do
            local path = filesystem.concat(dir, file)
            if filesystem.isDirectory(path) then
                recurse(path)
            else
                table.insert(tests, path)
            end
        end
    end
    for _, path in ipairs(vm:get("file")) do
        if filesystem.isDirectory(path) then
            if vm:has("recurse") then
                recurse(path)
            else
                -- Let harness complain about this.
                table.insert(tests, path)
            end
        else
            table.insert(tests, path)
        end
    end
    return tests
end

local function main(args)
    local miscDesc = po.optionsDescription.new("Miscellaneous")
    miscDesc:addOptions()
        ("h"        , "print this help")
        ("help"     , "show the man page of this program")
        ("verbose,v", "print all test lines")
        ("dry,D"    , "show tests that would have run, without actually running")

    local testsDesc = po.optionsDescription.new("Selecting tests to run")
    testsDesc:addOptions()
        ("recurse,r", "recursively descend into directories")

    local hiddenDesc = po.optionsDescription.new():hidden()
    hiddenDesc:add(
        po.optionDescription.new(
            "file",
            po.sequence(po.string()):name("FILE-OR-DIR")))

    local desc = po.optionsDescription.new()
    desc:add(miscDesc):add(testsDesc):add(hiddenDesc)

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
    else
        local tests = collectTests(vm)
        if #tests == 0 then
            io.write("No tests to run.\n")
            io.write("See `prove -h' for the usage.\n");
            os.exit(0)
        elseif vm:has("dry") then
            for _, test in ipairs(tests) do
                io.write(test, "\n")
            end
            os.exit(0)
        else
            local hOpts = {
                verbosity = 0
            }
            if vm:has("verbose") then
                hOpts.verbosity = 1
            end
            local h = harness.new(hOpts)
            if h:runTests(tests) then
                os.exit(0)
            else
                os.exit(1)
            end
        end
    end
end

main({...})
