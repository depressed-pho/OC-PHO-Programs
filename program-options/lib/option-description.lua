local optionDescription = {}
optionDescription.__index = optionDescription

function optionDescription.new(names, semantic, description)
    checkArg(1, names, "string")
    checkArg(3, description, "string", "nil")
    local self = setmetatable({}, optionDescription)

    self._longName    = nil
    self._shortName   = nil
    self._semantic    = semantic
    self._description = description

    self:_parseNames(names)
    return self
end

function optionDescription.isInstance(obj)
    checkArg(1, obj, "table")
    local meta = getmetatable(obj)
    if meta == optionDescription then
        return true
    elseif type(meta.__index) == "table" then
        return optionDescription.isInstance(meta.__index)
    else
        return false
    end
end

function optionDescription:_parseNames(names)
    local comma = names:find(",")
    if comma then
        -- It has both long and short names.
        self._longName  = names:sub(1, comma-1)
        self._shortName = names:sub(comma+1)

        if #self._shortName ~= 1 then
            error("A short name must be a single letter: "..self._shortName, 3)
        end
    else
        -- It has only a long name.
        self._longName = names
    end
    if #self._longName == 0 then
        error("A long name must be at least 1 letter long: "..self._longName, 3)
    end
    return self
end

function optionDescription:longName()
    return self._longName
end

function optionDescription:shortName()
    return self._shortName
end

function optionDescription:semantic()
    return self._semantic
end

function optionDescription:description()
    return self._description
end

function optionDescription:match(name)
    checkArg(1, name, "string")

    return self._longName == name or self._shortName == name
end

return optionDescription
