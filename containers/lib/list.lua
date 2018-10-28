local adt = require('algebraic-data-types')
local list -- Forward declaration

local function _table(self)
    local ret = {n=0}
    local function loop(xs)
        xs:match {
            Nil  = function () end,
            Cons = function (hd, tl)
                ret[ret.n + 1] = hd
                ret.n = ret.n + 1
                return loop(tl)
            end
        }
    end
    loop(self)
    return ret
end

local function cons(self, x)
    return list.Cons(x, self)
end

local function uncons(self)
    return self:match {
        Nil = function ()
            error("Cannot decompose an empty list", 2)
        end,
        Cons = function (hd, tl)
            return hd, tl
        end
    }
end

local function head(self)
    local hd = self:uncons()
    return hd
end

local function tail(self)
    return select(2, self:uncons())
end

local function __concat(xs, ys)
    return xs:match {
        Nil = function ()
            return ys
        end,
        Cons = function (hd, tl)
            return list.Cons(hd, __concat(tl, ys))
        end
    }
end

local function length(self)
    local len = 0
    while true do
        if self:is(list.Nil) then
            return len
        else
            len  = len+1
            self = self.fields[2]
        end
    end
end

local function null(self)
    return self:is(list.Nil)
end

local function map(self, f)
    checkArg(1, f, "function")
    return self:match {
        Nil = function ()
            return self
        end,
        Cons = function (hd, tl)
            return list.Cons(f(hd), tl:map(f))
        end
    }
end

local function _rev(xs, acc)
    return xs:match {
        Nil = function ()
            return acc
        end,
        Cons = function (hd, tl)
            return _rev(tl, list.Cons(hd, acc))
        end
    }
end
local function reverse(self)
    return _rev(self, list.Nil)
end

local function prependToAll(sep, xs)
    return xs:match {
        Nil = function ()
            return xs
        end,
        Cons = function (hd, tl)
            return list.Cons(sep, list.Cons(hd, prependToAll(sep, tl)))
        end
    }
end
local function intersperse(self, sep)
    return self:match {
        Nil = function ()
            return self
        end,
        Cons = function (x, xs)
            return list.Cons(x, prependToAll(sep, xs))
        end
    }
end

local function intercalate(self, xs)
    return self:intersperse(xs):concat()
end

local function foldl_(f, a, xs)
    return xs:match {
        Nil = function ()
            return a
        end,
        Cons = function (hd, tl)
            return foldl_(f, f(a, hd), tl)
        end
    }
end
local function foldl(self, f, ...)
    checkArg(1, f, "function")
    local args = table.pack(...)
    if args.n == 0 then
        return self:match {
            Nil = function ()
                error("List is empty", 2)
            end,
            Cons = function (x, xs)
                return foldl_(f, x, xs)
            end
        }
    else
        return foldl_(f, args[1], self)
    end
end

local function foldr1(f, xs)
    return xs:match {
        Nil = function ()
            error("List is empty", 2)
        end,
        Cons = function (hd, tl)
            if tl:null() then
                return hd
            else
                return f(hd, foldr1(f, tl))
            end
        end
    }
end
local function foldr_(f, a, xs)
    return xs:match {
        Nil = function ()
            return a
        end,
        Cons = function (hd, tl)
            return f(hd, foldr_(f, a, tl))
        end
    }
end
local function foldr(self, f, ...)
    checkArg(1, f, "function")
    local args = table.pack(...)
    if args.n == 0 then
        return foldr1(f, self)
    else
        return foldr_(f, args[1], self)
    end
end

local function concat(self)
    return self:foldl(__concat, list.Nil)
end

local function concatMap(self, f)
    checkArg(1, f, "function")
    return self:foldl(
        function (a, x)
            return a .. f(x)
        end,
        list.Nil)
end

local function any(self, f)
    checkArg(1, f, "function")
    return self:match {
        Nil = function ()
            return false
        end,
        Cons = function (hd, tl)
            if f(hd) then
                return true
            else
                return tl:any(f)
            end
        end
    }
end

local function all(self, f)
    checkArg(1, f, "function")
    return self:match {
        Nil = function ()
            return true
        end,
        Cons = function (hd, tl)
            if f(hd) then
                return tl:all(f)
            else
                return false
            end
        end
    }
end

local function maximum(self)
    return self:foldl(
        function (max, x)
            return max > x and max or x
        end)
end

local function minimum(self)
    return self:foldl(
        function (min, x)
            return min < x and min or x
        end)
end

local function scanl_(f, a, xs)
    return list.Cons(
        a,
        xs:match {
            Nil = function ()
                return xs
            end,
            Cons = function (hd, tl)
                return scanl_(f, f(a, hd), tl)
            end
        })
end
local function scanl(self, f, ...)
    checkArg(1, f, "function")
    local args = table.pack(...)
    if args.n == 0 then
        return self:match {
            Nil = function ()
                return self
            end,
            Cons = function (x, xs)
                return scanl_(f, x, xs)
            end
        }
    else
        return scanl_(f, args[1], self)
    end
end

local function scanr1(f, xs)
    return xs:match {
        Nil = function ()
            return xs
        end,
        Cons = function (hd, tl)
            if tl:null() then
                return xs
            else
                -- tl isn't null so qs is guaranteed to be non-null.
                local qs = scanr1(f, tl)
                return list.Cons(f(hd, qs:head()), qs)
            end
        end
    }
end
local function scanr_(f, a, xs)
    return xs:match {
        Nil = function ()
            return list.of(a)
        end,
        Cons = function (hd, tl)
            -- qs can never be non-null.
            local qs = scanr_(f, a, tl)
            return list.Cons(f(hd, qs:head()), qs)
        end
    }
end
local function scanr(self, f, ...)
    checkArg(1, f, "function")
    local args = table.pack(...)
    if args.n == 0 then
        return scanr1(f, self)
    else
        return scanr_(f, args[1], self)
    end
end

local function take(self, n)
    checkArg(1, n, "number")
    if n <= 0 then
        return list.Nil
    elseif self:null() then
        return self
    else
        return list.Cons(self:head(), self:tail():take(n-1))
    end
end

local function drop(self, n)
    checkArg(1, n, "number")
    if n <= 0 then
        return self
    elseif self:null() then
        return self
    else
        return self:tail():drop(n-1)
    end
end

local function splitAt_(n, xs)
    return xs:match {
        Nil = function ()
            return xs, xs
        end,
        Cons = function (hd, tl)
            if n == 1 then
                return list.of(hd), tl
            else
                local ys, zs = splitAt_(n-1, tl)
                return list.Cons(hd, ys), zs
            end
        end
    }
end
local function splitAt(self, n)
    checkArg(1, n, "number")
    if n <= 0 then
        return list.Nil, self
    else
        return splitAt_(n, self)
    end
end

local function takeWhile(self, p)
    checkArg(1, p, "function")
    return self:match {
        Nil = function ()
            return self
        end,
        Cons = function (hd, tl)
            if p(hd) then
                return list.Cons(hd, tl:takeWhile(p))
            else
                return list.Nil
            end
        end
    }
end

local function dropWhile(self, p)
    checkArg(1, p, "function")
    return self:match {
        Nil = function ()
            return self
        end,
        Cons = function (hd, tl)
            if p(hd) then
                return tl:dropWhile(p)
            else
                return self
            end
        end
    }
end

local function span(self, p)
    checkArg(1, p, "function")
    return self:match {
        Nil = function ()
            return self, self
        end,
        Cons = function (hd, tl)
            if p(hd) then
                local ys, zs = tl:span(p)
                return list.Cons(hd, ys), zs
            else
                return list.Nil, self
            end
        end
    }
end

local function nth(self, n)
    checkArg(1, n, "number")
    if n <= 0 then
        error("List index out of range: "..n, 2)
    else
        return self:match {
            Nil = function ()
                error("List index out of range: "..n, 2)
            end,
            Cons = function (hd, tl)
                if n == 1 then
                    return hd
                else
                    return tl:nth(n-1)
                end
            end
        }
    end
end

-- NOTE: There are obviously more functions to be added, but I'm tired
-- of doing this. Maybe I will do it later.

list = adt.define(
    adt.constructor('Nil'),
    adt.constructor('Cons', adt.field(), adt.field()),
    adt.method('table', _table),
    adt.method('cons', cons),
    adt.method('uncons', uncons),
    adt.metamethod('__concat', __concat),
    adt.method('head', head),
    adt.method('tail', tail),
    adt.method('null', null),
    adt.metamethod('__len', length),
    adt.method('map', map),
    adt.method('reverse', reverse),
    adt.method('intersperse', intersperse),
    adt.method('intercalate', intercalate),
    adt.method('foldl', foldl),
    adt.method('foldr', foldr),
    adt.method('concat', concat),
    adt.method('concatMap', concatMap),
    adt.method('any', any),
    adt.method('all', all),
    adt.method('maximum', maximum),
    adt.method('minimum', minimum),
    adt.method('scanl', scanl),
    adt.method('scanr', scanr),
    adt.method('take', take),
    adt.method('drop', drop),
    adt.method('splitAt', splitAt),
    adt.method('takeWhile', takeWhile),
    adt.method('dropWhile', dropWhile),
    adt.method('span', span),
    adt.method('nth', nth))

-- This is just an alias.
list.empty = list.Nil

function list.of(...)
    local args = table.pack(...)
    local self = list.Nil
    for i = args.n, 1, -1 do
        self = list.Cons(args[i], self)
    end
    return self
end

function list.from(...)
    local args = table.pack(...)
    checkArg(1, args[1], "table", "function")

    local self = list.Nil
    if type(args[1]) == "table" then
        local seq = args[1]
        for i = #seq, 1, -1 do
            self = list.Cons(seq[i], self)
        end
    else
        for _, v in table.unpack(args) do
            self = list.Cons(v, self)
        end
        self = self:reverse()
    end
    return self
end

return list
