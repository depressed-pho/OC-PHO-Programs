local array = require('containers/array')
local positionalOptionsDescription = {}
positionalOptionsDescription.__index = positionalOptionsDescription

function positionalOptionsDescription.new()
    local self = setmetatable({}, positionalOptionsDescription)

    self._finiteOpts    = array.new() -- array<string>
    self._infiniteOpt   = nil         -- string|nil
    self._maxTotalCount = 0

    return self
end

function positionalOptionsDescription.isInstance(obj)
    checkArg(1, obj, "table")
    local meta = getmetatable(obj)
    if meta == positionalOptionsDescription then
        return true
    elseif meta and type(meta.__index) == "table" then
        return positionalOptionsDescription.isInstance(meta.__index)
    else
        return false
    end
end

function positionalOptionsDescription:add(name, maxCount)
    checkArg(1, name, "string")
    checkArg(2, maxCount, "number")

    if self._maxTotalCount == math.huge then
        error("There are already infinitely many positional options.", 2)
    else
        if maxCount == math.huge then
            self._infiniteOpt   = name
        else
            if maxCount <= 0 then
                error("Value out of range: "..maxCount, 2)
            end
            for _ = self._maxTotalCount + 1, self._maxTotalCount + maxCount do
                self._finiteOpts:push(name)
            end
        end
        self._maxTotalCount = self._maxTotalCount + maxCount
        return self
    end
end

-- Get the name of option that should be associated with a given
-- position. May return nil.
function positionalOptionsDescription:nameForPosition(position)
    checkArg(1, position, "number")

    if position <= #self._finiteOpts then
        return self._finiteOpts:get(position)
    else
        return self._infiniteOpt
    end
end

-- Return an iterator producing (pos, name) where pos is the position
-- and name is the option name.  If there is an option that can appear
-- infinitely many times, its position will be denoted as math.huge.
function positionalOptionsDescription:entries()
    return function (_, i)
        i = i + 1
        if i <= #self._finiteOpts then
            return i, self._finiteOpts:get(i)
        elseif i < math.huge then
            return math.huge, self._infiniteOpt
        else
            return nil
        end
    end, nil, 0
end

return positionalOptionsDescription
