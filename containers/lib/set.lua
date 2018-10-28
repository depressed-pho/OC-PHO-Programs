local set = {}
set.__index = set

-- Used for equality tests to see if a value represents nil.
local NIL = {}

local function _NIL2nil(x)
    if x == NIL then
        return nil
    else
        return x
    end
end

local function _nil2NIL(x)
    if x == nil then
        return NIL
    else
        return x
    end
end

function set.new(...)
    local args = table.pack(...)
    checkArg(1, args[1], "table", "function", "nil")

    local self = setmetatable({}, set)
    self.m  = {}
    self.sz = 0

    if type(args[1]) == "table" then
        for i = 1, #args[1] do
            local v = _nil2NIL(args[1][i])
            if not self.m[v] then
                self.m[v] = 1
                self.sz   = self.sz + 1
            end
        end
    elseif type(args[1]) == "function" then
        for v in table.unpack(args) do
            self.m[v] = true
            self.sz   = self.sz + 1
        end
    end
    return self
end

function set:__len()
    return self.sz
end

function set:has(val)
    return self.m[_nil2NIL(val)] ~= nil
end

function set:insert(val)
    if not self.m[_nil2NIL(val)] then
        self.m[_nil2NIL(val)] = true
        self.sz = self.sz + 1
    end
    return self
end

function set:table()
    local ret = {n = self.sz}
    local i   = 0
    for v, _ in pairs(self.m) do
        i      = i + 1
        ret[i] = _NIL2nil(v)
    end
    return ret
end

function set:clone()
    local ret = set.new()
    for k, v in pairs(self.m) do
        ret.m[k] = v
    end
    ret.sz = self.sz
    return ret
end

function set:clear()
    self.m  = {}
    self.sz = 0
    return self
end

function set:delete(key)
    local v = _nil2NIL(key)
    if self.m[v] then
        self.m[v] = nil
        self.sz   = self.sz - 1
    end
    return self
end

function set:values()
    local f, s, var = pairs(self.m)
    return function (s1, var1)
        local v, _ = f(s1, var1)
        if v == nil then
            return nil
        elseif v == NIL then
            -- We believe an error is still better than a silent
            -- truncation of data...
            error("The set has a nil element. Method :values() cannot work correctly.", 2)
        else
            return v
        end
    end, s, var
end

function set:isSubsetOf(xs)
    checkArg(1, xs, "table")
    if self.sz <= xs.sz then
        return self:_isSubsetOf(xs)
    else
        return false
    end
end

function set:isProperSubsetOf(xs)
    checkArg(1, xs, "table")
    if self.sz < xs.sz then
        return self:_isSubsetOf(xs)
    else
        return false
    end
end

function set:_isSubsetOf(xs)
    for v, _ in pairs(self.m) do
        if not xs.m[v] then
            return false
        end
    end
    return true
end

function set:isDisjointTo(xs)
    checkArg(1, xs, "table")
    for v, _ in pairs(self.m) do
        if xs.m[v] then
            return false
        end
    end
    return true
end

function set:union(xs)
    checkArg(1, xs, "table")

    local ret = self:clone()
    for v, _ in pairs(xs.m) do
        if not ret.m[v] then
            ret.m[v] = true
            ret.sz   = ret.sz + 1
        end
    end
    return ret
end

function set:difference(xs)
    checkArg(1, xs, "table")

    local ret = set.new()
    for v, _ in pairs(self.m) do
        if not xs.m[v] then
            ret.m[v] = true
            ret.sz   = ret.sz + 1
        end
    end
    return ret
end

function set:intersection(xs)
    checkArg(1, xs, "table")

    local ret = set.new()
    for v, _ in pairs(self.m) do
        if xs.m[v] then
            ret.m[v] = true
            ret.sz   = ret.sz + 1
        end
    end
    return ret
end

function set:map(f)
    checkArg(1, f, "function")

    local ret = set.new()
    for v, _ in pairs(self.m) do
        ret:insert(f(v))
    end
    return ret
end

function set:filter(p)
    checkArg(1, p, "function")

    local ret = set.new()
    for v, _ in pairs(self.m) do
        if p(_NIL2nil(v)) then
            ret.m[v] = true
            ret.sz   = ret.sz + 1
        end
    end
    return ret
end

function set:partition(p)
    checkArg(1, p, "function")

    local a, b = set.new(), set.new()
    for v, _ in pairs(self.m) do
        if p(_NIL2nil(v)) then
            a.m[v] = true
            a.sz   = a.sz + 1
        else
            b.m[v] = true
            b.sz   = b.sz + 1
        end
    end
    return a, b
end

return set
