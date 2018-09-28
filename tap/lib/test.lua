local serialization = require("serialization")
local test = {}
test.__index = test

function test.new()
    local self = setmetatable({}, test)

    self.subtests = {}
    self:_push()

    return self
end

function test:_push()
    local subtest = {
        counter = 0,
        plan    = nil
    }
    table.insert(self.subtests, subtest)
    return subtest
end

function test:_pop()
    assert(#self.subtests > 1)
    return table.remove(self.subtests)
end

function test:_top()
    return self.subtests[#self.subtests]
end

function test:_isRoot()
    return #self.subtests == 1
end

function test:indent()
    return string.rep("    ", #self.subtests - 1)
end

function test:plan(numTests)
    checkArg(1, numTests, "number")

    local top = self:_top()
    if top.plan then
        error("Tests already have a plan: "..top.plan)
    else
        top.plan = numTests
        io.stdout:write(self:indent().."1.."..numTests.."\n")
    end
end

function test:subtest(name, thunk)
    checkArg(1, name , "string"  )
    checkArg(2, thunk, "function")

    -- A subtest is also a test, which is why we increment the counter
    -- here.
    local top = self:_top()
    top.counter = top.counter + 1

    self:_push()
    self:note("Subtest: "..name)
    thunk()
    self:_pop()
end

function test:ok(ok, description)
    checkArg(1, ok         , "boolean")
    checkArg(2, description, "string", "nil")

    local top = self:_top()
    if self:_isRoot() and not top.plan then
        error("Due to a current limitation in the library, subtests have to "..
                  "declare a plan before doing any tests.")
    end
    top.counter = top.counter + 1

    if ok then
        io.stdout:write(self:indent().."ok ")
    else
        io.stdout:write(self:indent().."not ok ")
    end

    io.stdout:write(top.counter)

    if description then
        io.stdout:write(" "..description.."\n")
    else
        io.stdout:write("\n")
    end

    if not ok then
        local msg = "  Failed test "
        if description then
            msg = msg.."`"..description.."'\n"
            msg = msg.."  "
        end
        local file, line = self:_calledAt()
        msg = msg.."in "..file.." at line "..line.."."
        self:diag(msg)
    end

    return ok
end

-- Find out the first function outside of this module.
local shortSrcOfMe = debug.getinfo(1, "S").short_src
assert(shortSrcOfMe)
function test:_calledAt() -- luacheck: ignore self
    local i = 1
    while true do
        local frame = debug.getinfo(i, "Sl")
        if frame then
            if frame.short_src ~= shortSrcOfMe then
                return frame.short_src, frame.currentline
            end
            i = i + 1
        else
            return "(unknown)", 0
        end
    end
end

function test:requireOK(module)
    checkArg(1, module, "string")

    local ok, result, reason = xpcall(require, debug.traceback, module)
    self:ok(ok, "require "..module)
    if ok then
        return result
    else
        self:diag(reason)
        return nil
    end
end

function test:livesAnd(thunk, description)
    checkArg(1, thunk      , "function")
    checkArg(2, description, "string", "nil")

    local top = self:_top()
    local ctr = top.counter

    -- While evaluating the thunk we have to replace test:ok() so it
    -- uses the description passed to this function. This assumes
    -- functions like is() all use ok() ultimately.
    local savedOK     = self.ok
    local savedRealOK = rawget(self, "ok") -- expected to be nil
    self.ok = function (self, ok) -- luacheck: ignore self
        return savedOK(self, ok, description)
    end
    local ok, result, reason = xpcall(thunk, debug.traceback)
    self.ok = savedRealOK

    if ok then
        if top.counter == ctr + 1 then
            return result
        else
            error("Misuse of test:livesAnd(): there must be one and "..
                      "only one predicate in the thunk.")
        end
    else
        self:ok(false, description)
        self:diag(reason)
    end
end

function test:livesOK(thunk, description)
    checkArg(1, thunk      , "function")
    checkArg(2, description, "string", "nil")

    local ok, result, reason = xpcall(thunk, debug.traceback)
    if self:ok(ok, description) then
        return result
    else
        self:diag(reason)
        return nil
    end
end

function test:diesOK(thunk, description)
    checkArg(1, thunk      , "function")
    checkArg(2, description, "string", "nil")

    local ok, result, _ = xpcall(thunk, debug.traceback)
    self:ok(not ok, description)
    return result
end

function test:is(got, expected, description)
    checkArg(3, description, "string", "nil")

    if not self:ok(got == expected, description) then
        self:diag("         got: "..serialization.serialize(got     , true))
        self:diag("    expected: "..serialization.serialize(expected, true))
    end
end

function test:isnt(got, unexpected, description)
    checkArg(3, description, "string", "nil")

    if not self:ok(got ~= unexpected, description) then
        self:diag("         got: "..serialization.serialize(got, true))
        self:diag("    expected: anything else")
    end
end

local cmpOps = {
    ['==' ] = function (a, b) return a ==  b end,
    ['~=' ] = function (a, b) return a ~=  b end,
    ['<'  ] = function (a, b) return a <   b end,
    ['<=' ] = function (a, b) return a <=  b end,
    ['>'  ] = function (a, b) return a >   b end,
    ['>=' ] = function (a, b) return a >=  b end,
    ['and'] = function (a, b) return a and b end,
    ['or' ] = function (a, b) return a or  b end
}
function test:cmpOK(valueA, op, valueB, description)
    checkArg(3, description, "string", "nil")

    local f = cmpOps[op]
    if not f then
        error("Unknown operator `"..op.."'")
    end

    if not self:ok(f(valueA, valueB), description) then
        self:diag("    "..serialization.serialize(valueA, true))
        self:diag("        "..op)
        self:diag("    "..serialization.serialize(valueB, true))
    end
end

function test:bailOut(reason) -- luacheck: ignore self
    checkArg(3, reason, "string", "nil")

    io.stdout:write("Bail out!")
    if reason then
        io.stdout:write(" "..reason.."\n")
    end
    os.exit(255)
end

-- THINKME: Move this to a separate library?
local function split(str, sepPat)
    local idx = 1
    return function ()
        if idx then
            local from, to = str:find(sepPat, idx)
            if from then
                local seg = str:sub(idx, from - 1)
                idx = to + 1
                return seg
            else
                local seg = str:sub(idx)
                idx = nil
                return seg
            end
        else
            return nil
        end
    end
end

function test:diag(msg)
    if type(msg) == "string" then
        for line in split(msg, "\n") do
            io.stderr:write(self:indent().."# "..line.."\n")
        end
    else
        self:diag(serialization.serialize(msg, true))
    end
end

function test:note(msg)
    if type(msg) == "string" then
        for line in split(msg, "\n") do
            io.stdout:write(self:indent().."# "..line.."\n")
        end
    else
        self:note(serialization.serialize(msg, true))
    end
end

return test
