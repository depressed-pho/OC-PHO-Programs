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
        error("Tests already have a plan: "..top.plan, 2)
    else
        top.plan = numTests
        io.stdout:write(self:indent().."1.."..numTests.."\n")
    end
end

function test:subtest(name, thunk)
    checkArg(1, name , "string"  )
    checkArg(2, thunk, "function")

    -- A subtest is a test too, which is why we increment the counter
    -- here.
    local top = self:_top()
    top.counter = top.counter + 1

    self:note("Subtest: "..name)
    self:_push()
    thunk()
    self:_pop()
end

function test:ok(ok, description)
    checkArg(1, ok         , "boolean")
    checkArg(2, description, "string", "nil")

    local top = self:_top()
    if self:_isRoot() and not top.plan then
        error("Due to a current limitation in the library, subtests have to "..
                  "declare a plan before doing any tests.", 2)
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

-- Find out the first module/line outside of tap/test.
function test:_calledAt() -- luacheck: ignore self
    local i = 2
    while true do
        local frame = debug.getinfo(i, "Sl")
        if frame then
            if (frame.short_src:find("%.lua$") and
                not frame.short_src:find("/tap/test%.lua$")) then
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

    local ok, result = pcall(require, module)
    self:ok(ok, "require "..module)
    if ok then
        return result
    else
        self:diag(result)
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
    local ok, result = xpcall(thunk, debug.traceback)
    self.ok = savedRealOK

    if ok then
        if top.counter == ctr + 1 then
            return result
        else
            error("Misuse of test:livesAnd(): there must be one and "..
                      "only one predicate in the thunk.", 2)
        end
    else
        self:ok(false, description)
        self:diag(result)
    end
end

function test:livesOK(thunk, description)
    checkArg(1, thunk      , "function")
    checkArg(2, description, "string", "nil")

    local ok, result = xpcall(thunk, debug.traceback)
    if self:ok(ok, description) then
        return result
    else
        self:diag(result)
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

function test:pass(description)
    checkArg(1, description, "string", "nil")

    self:ok(true, description)
end

function test:fail(description)
    checkArg(1, description, "string", "nil")

    self:ok(false, description)
end

local function _isDeeply(stk)
    local a = stk[#stk].a
    local b = stk[#stk].b
    local t = type(a)

    if t ~= type(b) then
        return false

    elseif t == "nil" or t == "number" or t == "string" or t == "boolean" then
        return a == b

    elseif t == "table" then
        -- See if we are already evaluating the same "a" or "b". Doing
        -- it again would end up in an infinite loop.
        for i, ent in ipairs(stk) do
            -- If "a" has a circular reference, the only way to test
            -- the equality is to compare the previous "b" shallowly
            -- with the current "b". Of course this may lead to a
            -- false negative but it's better than non-termination.
            if i < #stk then
                if a == ent.a then
                    return b == ent.b
                elseif b == ent.b then
                    return a == ent.a
                end
            end
        end

        local keySet = {}
        for k, _ in pairs(a) do keySet[k] = 1 end
        for k, _ in pairs(b) do keySet[k] = 1 end

        for k, _ in pairs(keySet) do
            table.insert(stk, {idx = k, a = a[k], b = b[k]})
            if _isDeeply(stk) then
                table.remove(stk)
            else
                return false
            end
        end
        return true
    else
        error("Unknown type: "..t, 2)
    end
end

local function _formatDeepStack(stk)
    local ref = ""
    for _, ent in ipairs(stk) do
        if ent.idx then
            ref = ref.."["..serialization.serialize(ent.idx, true).."]"
        end
    end
    return "    Structures begin differing at:\n"..
        "           got"..ref.." = "..serialization.serialize(stk[#stk].a).."\n"..
        "      expected"..ref.." = "..serialization.serialize(stk[#stk].b).."\n"
end

function test:isDeeply(got, expected, description)
    checkArg(3, description, "string", "nil")

    local stack = { {idx = nil, a = got, b = expected} }
    if _isDeeply(stack) then
        self:pass(description)
    else
        self:fail(description)
        self:diag(_formatDeepStack(stack))
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
        error("Unknown operator `"..op.."'", 2)
    end

    if not self:ok(f(valueA, valueB), description) then
        self:diag("    "..serialization.serialize(valueA, true))
        self:diag("        "..op)
        self:diag("    "..serialization.serialize(valueB, true))
    end
end

function test:bailOut(reason) -- luacheck: ignore self
    checkArg(1, reason, "string", "nil")

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

-- FIXME: Implement SKIP and TODO emitters

return test
