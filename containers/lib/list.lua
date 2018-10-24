local adt = require('algebraic-data-types')

local list = adt.define(
    adt.constructor('Nil'),
    adt.constructor('Cons', adt.field('head'), adt.field('tail')))

local function checkList(pos, arg)
    if type(arg) ~= "table" or not arg:is(list) then
        error("bad argument #"..pos.." (List expected, got "..type(arg)..")", 3)
    end
end

function list.of(...)
    local args = table.pack(...)
    local ret  = list.Nil
    for i = args.n, 1 do
        ret = list.Cons(args[i], ret)
    end
    return ret
end

function list.cons(x, xs)
    checkList(2, xs)
    return list.Cons(x, xs)
end

function list.head(xs)
    checkList(1, xs)
    if xs:is(list.Cons) then
        return xs.head
    else
        error("Cannot take the head of an empty list", 2)
    end
end

function list.tail(xs)
    checkList(1, xs)
    if xs:is(list.Cons) then
        return xs.tail
    else
        error("Cannot take the tail of an empty list", 2)
    end
end

function list.uncons(xs)
    checkList(1, xs)
    if xs:is(list.Cons) then
        return xs.head, xs.tail
    else
        error("Cannot decompose an empty list", 2)
    end
end

function list.null(xs)
    checkList(1, xs)
    return xs:is(list.Nil)
end

function list.nth(idx, xs)
    checkArg(1, idx, "number")
    checkList(2, xs)

    if idx < 0 then
        error("List index out of range: "..idx, 2)
    end

    for _ = 1, idx-1 do
        if xs:is(list.Cons) then
            xs = xs.tail
        else
            error("List index out of range: "..idx, 2)
        end
    end

    if xs:is(list.Cons) then
        return xs.head
    else
        error("List index out of range: "..idx, 2)
    end
end

-- FIXME: more functions

return list
