local map = {}
map.__index = map

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

function map.new(...)
    local args = table.pack(...)
    checkArg(1, args[1], "table", "function", "nil")

    local self = setmetatable({}, map)
    self.m  = {}
    self.sz = 0

    if type(args[1]) == "table" then
        for k, v in pairs(args[1]) do
            self.m[k] = v
            if v then
                self.sz = self.sz + 1
            end
        end
    elseif type(args[1]) == "function" then
        for k, v in table.unpack(args) do
            self.m[k] = _nil2NIL(v)
            self.sz = self.sz + 1
        end
    end
    return self
end

function map:size()
    return self.sz
end

function map:has(key)
    return self.m[key] ~= nil
end

function map:get(key, ...)
    if self.m[key] == nil then
        local args = table.pack(...)
        if args.n > 0 then
            return args[1]
        else
            error("Key not found: "..tostring(key))
        end
    else
        return _NIL2nil(self.m[key])
    end
end

function map:set(key, value, combine)
    checkArg(3, combine, "function", "nil")

    if self.m[key] == nil then
        self.m[key] = _nil2NIL(value)
        self.sz     = self.sz + 1
    elseif combine then
        self.m[key] = _nil2NIL(combine(_NIL2nil(self.m[key]), value, key))
    else
        self.m[key] = _nil2NIL(value)
    end
    return self
end

function map:table()
    -- Return a shallow copy of self.m so the caller cannot
    -- accidentally break it.
    local ret = {}
    for k, v in pairs(self.m) do
        ret[k] = _NIL2nil(v)
    end
    return ret
end

function map:clone()
    local ret = map.new()
    for k, v in pairs(self.m) do
        ret.m[k] = v
    end
    ret.sz = self.sz
    return ret
end

function map:clear()
    self.m  = {}
    self.sz = 0
    return self
end

function map:delete(key)
    if self.m[key] ~= nil then
        self.m[key] = nil
        self.sz     = self.sz - 1
    end
    return self
end

function map:entries()
    local f, s, var = pairs(self.m)
    return function (s1, var1)
        local key, value = f(s1, var1)
        if key == nil then
            return nil
        else
            return key, _NIL2nil(value)
        end
    end, s, var
end

function map:union(xs, combine)
    checkArg(1, xs, "table")
    checkArg(2, combine, "function", "nil")

    local ret = self:clone()
    for k, v in pairs(xs.m) do
        if ret.m[k] == nil then
            ret.m[k] = v
            ret.sz   = ret.sz + 1
        elseif combine then
            ret.m[k] = _nil2NIL(combine(_NIL2nil(ret.m[k]), v, k))
        end
    end
    return ret
end

function map:difference(xs)
    checkArg(1, xs, "table")

    local ret = map.new()
    for k, v in pairs(self.m) do
        if xs.m[k] == nil then
            ret.m[k] = v
            ret.sz   = ret.sz + 1
        end
    end
    return ret
end

function map:intersection(xs, combine)
    checkArg(1, xs, "table")
    checkArg(2, combine, "function", "nil")

    local ret = map.new()
    for k, v in pairs(self.m) do
        if xs.m[k] ~= nil then
            if combine then
                ret.m[k] = _nil2NIL(combine(_NIL2nil(v), _NIL2nil(xs.m[k]), k))
            else
                ret.m[k] = v
            end
            ret.sz = ret.sz + 1
        end
    end
    return ret
end

function map:map(f)
    checkArg(1, f, "function")

    local ret = map.new()
    for k, v in pairs(self.m) do
        ret.m[k] = _nil2NIL(f(_NIL2nil(v), k))
    end
    ret.sz = self.sz
    return ret
end

function map:filter(p)
    checkArg(1, p, "function")

    local ret = map.new()
    for k, v in pairs(self.m) do
        if p(_NIL2nil(v), k) then
            ret.m[k] = v
            ret.sz   = ret.sz + 1
        end
    end
    return ret
end

function map:partition(p)
    checkArg(1, p, "function")

    local a, b = map.new(), map.new()
    for k, v in pairs(self.m) do
        if p(_NIL2nil(v), k) then
            a.m[k] = v
            a.sz   = a.sz + 1
        else
            b.m[k] = v
            b.sz   = b.sz + 1
        end
    end
    return a, b
end

return map
