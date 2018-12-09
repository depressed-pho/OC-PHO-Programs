local ansi       = require("ansi-terminal")
local event      = require("event")
local filesystem = require("filesystem")
local parser     = require("tap/parser")
local statistics = require("tap/statistics")
local harness = {}
harness.__index = harness

function harness.new(opts)
    local self = setmetatable({}, harness)
    opts = opts or {}

    self.verbosity = opts.verbosity or 0 -- -3 - 1
    self.isTTY     = ansi.supportsANSI(io.stdout)

    return self
end

-- Run TAP producers (i.e. tests) with statistics
function harness:runTests(files) -- [file]
    local stats = statistics.new()

    -- Install an interrupt handler so users can terminate tests. It
    -- will also print out statistics even though it would only be
    -- partial.
    local function interrupted()
        error("FIXME: interrupted")
    end
    event.listen("interrupted", interrupted)

    local allOK = true
    for _, file in ipairs(files) do
        if filesystem.isDirectory(file) then
            io.stderr:write(file..": is a directory")
            allOK = false
        elseif filesystem.exists(file) then
            if not self:_runTest(stats, file) then
                allOK = false
            end
        else
            io.stderr:write(file..": file not found")
            allOK = false
        end
    end
    self:_write(-2, io.stdout, stats:result())

    event.ignore("interrupted", interrupted)

    return allOK
end

function harness:_runTest(stats, file)
    local pipe = io.popen(file, "r")

    self:_write(-1, io.stdout, file.." ... ")

    for r in parser(pipe) do
        self:_write(1, io.stdout, r:tostring())

        if r:isPlan() then
            if r:hasSkip() then
                stats:plan(file, r:testsPlanned(), r:reason())
            else
                stats:plan(file, r:testsPlanned(), nil)
            end

        elseif r:isTest() then
            if r:hasSkip() then
                stats:test(file, r:isOK(), r:number(), r:description(), r:reason(), nil)

            elseif r:hasTodo() then
                stats:test(file, r:isOK(), r:number(), r:description(), nil, r:reason())

            else
                stats:test(file, r:isOK(), r:number(), r:description(), nil, nil)
            end

            if self.verbosity == 0 and self.isTTY then
                ansi.saveCursor(io.stdout)
                io.stdout:write(stats:progress(file))
                ansi.restoreCursor(io.stdout)
            end

        elseif r:isBailOut() then
            stats:bailOut(file, r:reason())
            self:_write(0, io.stdout, r:tostring())
        end
    end
    stats:finished(file)
    io.close(pipe)

    if stats:isOK(file) then
        self:_write(-1, io.stdout, stats:progress(file).." ok\n")
        return true
    else
        self:_write(-1, io.stdout, stats:progress(file).." failed\n")
        return false
    end
end

function harness:_write(threashold, buffer, message)
    if self.verbosity >= threashold then
        buffer:write(message)
    end
end

return harness
