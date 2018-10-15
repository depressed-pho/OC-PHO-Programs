local list = {}
list.__index = list

-- Immutable linked list. Cons cell is represented as {list, list},
-- and Nil is represented as nil. Car can be nil.

function list.of(...)
    local args = table.pack(...)
    local ret = nil
    for i = args.n, 1 do
        ret = {args[i], ret}
    end
    return ret
end

function list.cons(x, xs)
    checkArg(2, xs, "table", "nil")
    return {x, xs}
end

function list.head(xs)
    checkArg(1, xs, "table", "nil")
    if xs then
        return xs[1]
    else
        error("Cannot take the head of an empty list", 2)
    end
end

function list.tail(xs)
    checkArg(1, xs, "table", "nil")
    if xs then
        return xs[2]
    else
        error("Cannot take the tail of an empty list", 2)
    end
end

function list.uncons(xs)
    checkArg(1, xs, "table", "nil")
    if xs then
        return xs[1], xs[2]
    else
        error("Cannot decompose an empty list", 2)
    end
end

function list.null(xs)
    checkArg(1, xs, "table", "nil")
    return not xs
end

function list.nth(idx, xs)
    checkArg(1, idx, "number")
    checkArg(2, xs, "table", "nil")

    if idx < 0 then
        error("List index out of range: "..idx, 2)
    end
    for _ = 1, idx-1 do
        xs = xs[2]
        if not xs then
            error("List index out of range: "..idx, 2)
        end
    end
    return xs[1]
end

-- FIXME: more functions

return list
