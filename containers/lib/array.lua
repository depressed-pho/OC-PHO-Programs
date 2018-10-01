local array = {}
array.__index = array

function array.new(...)
    local self = setmetatable({}, array)

    self.xs = table.pack(...)

    return self
end

function array.from(...)
    local args = table.pack(...)
    checkArg(1, args[1], "table", "function")

    local self = array.new()
    if type(args[1]) == "table" then
        self.xs = table.pack(table.unpack(args[1]))
    else
        for i, v in table.unpack(args) do
            self.xs[i] = v
            self.xs.n  = math.max(self.xs.n, i)
        end
    end
    return self
end

function array:get(idx)
    checkArg(1, idx, "number")

    if idx > 0 and idx <= self.xs.n then
        return self.xs[idx]
    else
        error("Array index out of range: "..idx, 2)
    end
end

function array:set(idx, x)
    checkArg(1, idx, "number")

    if idx > 0 and idx <= self.xs.n then
        self.xs[idx] = x
    else
        error("Array index out of range: "..idx, 2)
    end
    return self
end

function array:length()
    return self.xs.n
end

function array:table()
    -- Return a shallow copy of self.xs so the caller cannot
    -- accidentally break it.
    local ret = {n = self.xs.n}
    for i = 1, self.xs.n do
        ret[i] = self.xs[i]
    end
    return ret
end

function array:clone()
    local ret = array.new()
    for k, v in pairs(self.xs) do
        ret.xs[k] = v
    end
    return ret
end

function array:concat(xs)
    checkArg(1, xs, "table")

    return self:clone():_concatInplace(xs)
end
function array:_concatInplace(xs)
    for i = 1, xs.xs.n do
        self:push(xs.xs[i])
    end
    return self
end

function array:entries()
    return function (_, i)
        i = i + 1
        if i <= self.xs.n then
            return i, self.xs[i]
        else
            return nil
        end
    end, nil, 0
end

function array:all(p)
    checkArg(1, p, "function")

    for i = 1, self.xs.n do
        if not p(self.xs[i], i) then
            return false
        end
    end
    return true
end

function array:any(p)
    checkArg(1, p, "function")

    for i = 1, self.xs.n do
        if p(self.xs[i], i) then
            return true
        end
    end
    return false
end

function array:filter(f)
    checkArg(1, f, "function")

    local ret = array.new()
    for i = 1, self.xs.n do
        if f(self.xs[i], i) then
            ret:push(self.xs[i])
        end
    end
    return ret
end

function array:find(f)
    checkArg(1, f, "function")

    for i = 1, self.xs.n do
        if f(self.xs[i], i) then
            return self.xs[i], i
        end
    end
    return nil
end

function array:concatMap(f)
    checkArg(1, f, "function")

    local ret = array.new()
    for i = 1, self.xs.n do
        local ys = f(self.xs[i], i)
        ret:push(table.unpack(ys.xs))
    end
    return ret
end

function array:includes(x, idx)
    return self:indexOf(x, idx) ~= nil
end

function array:indexOf(x, idx)
    checkArg(2, idx, "number", "nil")
    idx = idx or 1

    for i = idx, self.xs.n do
        if self.xs[i] == x then
            return i
        end
    end
    return nil
end

function array:lastIndexOf(x, idx)
    checkArg(2, idx, "number", "nil")
    idx = idx or self.xs.n

    for i = idx, 1, -1 do
        if self.xs[i] == x then
            return i
        end
    end
    return nil
end

function array:map(f)
    checkArg(1, f, "function")

    local ret = array.new()
    for i = 1, self.xs.n do
        local y = f(self.xs[i], i)
        ret:push(y)
    end
    return ret
end

function array:pop()
    if self.xs.n == 0 then
        error("Array is empty", 2)
    else
        local ret = self.xs[self.xs.n]
        self.xs.n = self.xs.n - 1
        return ret
    end
end

function array:push(...)
    local xs = table.pack(...)
    for i = 1, xs.n do
        self.xs[self.xs.n + 1] = xs[i]
        self.xs.n = self.xs.n + 1
    end
    return self
end

function array:foldl(f, ...)
    checkArg(1, f, "function")
    local args = table.pack(...)
    local idx, acc
    if args.n == 0 then
        if self.xs.n == 0 then
            error("Array is empty", 2)
        else
            idx, acc = 2, self.xs[1]
        end
    else
        idx, acc = 1, args[1]
    end
    for i = idx, self.xs.n do
        acc = f(acc, self.xs[i])
    end
    return acc
end

function array:foldr(f, ...)
    checkArg(1, f, "function")
    local args = table.pack(...)
    local idx, acc
    if args.n == 0 then
        if self.xs.n == 0 then
            error("Array is empty", 2)
        else
            idx, acc = self.xs.n-1, self.xs[self.xs.n]
        end
    else
        idx, acc = self.xs.n, args[1]
    end
    for i = idx, 1, -1 do
        acc = f(self.xs[i], acc)
    end
    return acc
end

function array:reverse()
    return self:clone():_reverseInplace()
end
function array:_reverseInplace()
    local i = 1
    local j = self.xs.n
    while i < j do
        local tmp  = self.xs[i]
        self.xs[i] = self.xs[j]
        self.xs[j] = tmp
        i = i + 1
        j = j - 1
    end
    return self
end

function array:shift()
    if self.xs.n == 0 then
        error("Array is empty", 2)
    else
        local ret = self.xs[1]
        for i = 2, self.xs.n do
            self.xs[i-1] = self.xs[i]
        end
        self.xs.n = self.xs.n - 1
        return ret
    end
end

function array:slice(s, e)
    checkArg(1, s, "number")
    checkArg(2, s, "number", "nil")
    e = e or self.xs.n
    e = math.min(e, self.xs.n)

    if s < 1 then
        error("Array index out of range: "..s, 2)
    end

    local ret = array.new()
    for i = s, e do
        ret:push(self.xs[i])
    end
    return ret
end

function array:sort(cmpLE)
    checkArg(1, cmpLE, "function", "nil")
    cmpLE = cmpLE or function (x, y) return x <= y end

    if self.xs.n == 0 or self.xs.n == 1 then
        -- Special cases: the array is trivially sorted
        return self:clone()
    else
        -- This is an implementation of a simplified variant of
        -- Timsort, cf. https://en.wikipedia.org/wiki/Timsort
        return self:_timsort(cmpLE)
    end
end
function array:_minrun()
    -- First calculate the bit length of self.xs.n.
    local bLen = 0
    local tmpN = self.xs.n
    while tmpN > 1 do
        bLen = bLen + 1
        tmpN = tmpN >> 1
    end

    -- Then take the first 6 bits of it, and add 1 if there are any
    -- remaining bits that are set.
    local minrun = self.xs.n
    local rem = bLen - 6
    if rem > 0 then
        minrun = minrun >> rem
        local mask = (1 << rem) - 1
        if self.xs.n & mask > 0 then
            minrun = minrun + 1
        end
    end
    return minrun
end
local function _invariantHolds(runs)
    assert(#runs >= 3)
    local X = runs[#runs-2]
    local Y = runs[#runs-1]
    local Z = runs[#runs]
    return Z.xs.n > Y.xs.n + X.xs.n and Y.xs.n > X.xs.n
end
local function _merge(cmpLE, runA, runB)
    assert(runA.xs.n > 0)
    assert(runB.xs.n > 0)
    -- THINKME: In the original Timsort, these runs are merged in a
    -- much more fancy way (galloping). But for now we use a simpler
    -- algorithm.
    local ret = array.new()
    local idxA, idxB = 1, 1
    while true do
        if idxA > runA.xs.n then
            -- It's the end of runA.
            ret:_concatInplace(runB:slice(idxB))
            break
        elseif idxB > runB.xs.n then
            -- It's the end of runB.
            ret:_concatInplace(runA:slice(idxA))
            break
        else
            if cmpLE(runA.xs[idxA], runB.xs[idxB]) then
                ret:push(runA.xs[idxA])
                idxA = idxA + 1
            else
                ret:push(runB.xs[idxB])
                idxB = idxB + 1
            end
        end
    end
    assert(ret.xs.n == runA.xs.n + runB.xs.n)
    return ret
end
function array:_timsort(cmpLE)
    local minrun = self:_minrun()
    local runs = {}
    local start = 1

    while true do
        ::redo::
        if #runs < 3 or _invariantHolds(runs) then
            if start <= self.xs.n then
                local run, nextRun = self:_nextRun(cmpLE, minrun, start)
                table.insert(runs, run)
                start = nextRun
                goto redo
            end
        end

        assert(#runs > 0)
        if #runs == 1 then
            return runs[1]
        elseif #runs == 2 then
            return _merge(cmpLE, runs[1], runs[2])
        else
            -- The invariant does not hold here.
            local X = runs[#runs-2]
            local Y = runs[#runs-1]
            local Z = runs[#runs]
            if X.xs.n < Z.xs.n then
                runs[#runs-2] = _merge(cmpLE, X, Y)
                table.remove(runs, #runs-1)
            else
                runs[#runs-1] = _merge(cmpLE, Y, Z)
                runs[#runs] = nil
            end
        end
    end
end
function array:_nextRun(cmpLE, minrun, start)
    if start == self.xs.n then
        -- Special case: a singleton run.
        return self:slice(start), start + 1
    end

    -- Find the end of a natural run.
    local dsc = not cmpLE(self.xs[start], self.xs[start+1])
    local fin
    for i = start+1, self.xs.n do
        if i == self.xs.n then
            -- It's the end of the entire array.
            fin = i
            break
        elseif dsc and cmpLE(self.xs[i], self.xs[i+1]) then
            -- It's the end of a strictly descending natural run.
            fin = i
            break
        elseif not cmpLE(self.xs[i], self.xs[i+1]) then
            -- It's the end of a non-descending natural run.
            fin = i
            break
        end
    end
    assert(fin ~= nil)

    -- Reverse the order if it is strictly descending.
    local run = self:slice(start, fin)
    if dsc then
        run:_reverseInplace()
    end

    -- Perform a binary insertion sort until the length of run
    -- reaches minrun.
    run:_binInsSort(cmpLE, self:slice(fin + 1, fin + 1 + minrun))

    -- Done forming a single run.
    return run, start + run.xs.n
end
function array:_binInsSort(cmpLE, ins)
    for i = 1, ins.xs.n do
        -- Find out where to insert the element ins.xs[i].
        local lower, upper = 1, self.xs.n
        while true do
            local needle = lower + math.floor((upper - lower) / 2)
            if needle == lower then
                -- The needle cannot go forward.
                if cmpLE(self.xs[needle], ins.xs[i]) then
                    if needle == upper then
                        -- The needle cannot go backward.
                        self:splice(needle+1, 0, ins.xs[i])
                        break
                    else
                        lower = lower + 1
                    end
                else
                    self:splice(needle, 0, ins.xs[i])
                    break
                end
            elseif cmpLE(self.xs[needle-1], ins.xs[i]) then
                if cmpLE(self.xs[needle], ins.xs[i]) then
                    lower = needle
                else
                    self:splice(needle, 0, ins.xs[i])
                    break
                end
            else
                upper = needle
            end
        end
    end
end
function array:_insert(idx, elem)
    assert(idx > 0)
    assert(idx <= self.xs.n + 1)

    if idx <= self.xs.n then
        -- Allocate a space for the element to be inserted.
        for i = self.xs.n+1, idx+1 do
            self.xs[i] = self.xs[i-1]
        end
    end
    self.xs[idx] = elem
    self.xs.n = self.xs.n + 1
    return self
end

function array:splice(start, count, ...)
    checkArg(1, start, "number")
    checkArg(2, count, "number", "nil")
    count = count or 0

    if start < 1 then
        error("Array index out of range: "..start, 2)
    end
    start = math.min(start, self.xs.n+1)

    local ret = self:slice(1, start-1)
    ret:push(...)

    local rest = self:slice(start + count)
    ret:_concatInplace(rest)

    self.xs = ret.xs
    return self
end

function array:unshift(...)
    return self:splice(1, 0, ...)
end

return array
