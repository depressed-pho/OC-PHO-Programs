local result = require("tap/parser/result")

local function _parseDescAndDir(tail)
    local skipDesc, skipReason = string.match(
        tail, "^([^#]*)%s*#%s*[Ss][Kk][Ii][Pp]%s+(.*)$")
    if skipDesc then
        local desc = skipDesc
        local dir  = {skip = skipReason}
        return desc, dir
    end

    local todoDesc, todoReason = string.match(
        tail, "^([^#]*)%s*#%s*[Tt][Oo][Dd][Oo]%s+(.*)$")
    if todoDesc then
        local desc = todoDesc
        local dir  = {todo = todoReason}
        return desc, dir
    end

    return tail, nil
end

local function _parse(line)
    local ver = string.match(line, "^TAP version (%d+)$")
    if ver then
        return result.version.new(tonumber(ver))
    end

    local plan, planDirective = string.match(line, "^%s*1%.%.(%d+)(.*)$")
    if plan then
        local dir
        local skipReason = string.match(
            planDirective, "^%s*#%s*[Ss][Kk][Ii][Pp][^%s]*%s+(.*)$")
        if skipReason then
            dir = {skip = skipReason}
        end
        return result.plan.new(tonumber(plan), dir)
    end

    local comment = string.match(line, "^%s*#%s*(.*)$")
    if comment then
        return result.comment.new(comment)
    end

    local goodNum, goodTail =
        string.match(line, "^%s*ok%s+(%d+)%s*(.*)$")
    if goodNum then
        local desc, dir = _parseDescAndDir(goodTail)
        return result.test.new(true, tonumber(goodNum), desc, dir)
    end

    local badNum, badTail =
        string.match(line, "^%s*not%s+ok%s+(%d+)%s*(.*)$")
    if badNum then
        local desc, dir = _parseDescAndDir(badTail)
        return result.test.new(false, tonumber(badNum), desc, dir)
    end

    local bailReason = string.match(line, "^%s*Bail out!%s*(.*)$")
    if bailReason then
        return result.bailOut.new(bailReason)
    end

    return result.unknown.new(line)
end

-- Create a TAP parser. The argument 'source' must be an instance of
-- buffer, such as io.stdin. It returns an iterator function so that
-- you can use it in a for loop like this:
--
--    for result in parser(io.stdin) do
--        print(result:tostring())
--    end
local function parser(source)
    return function ()
        local line = source:read()
        if line then
            return _parse(line)
        else
            return nil
        end
    end
end

return parser
