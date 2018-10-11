local optionDescription = {}
optionDescription.__index = optionDescription

function optionDescription.new(names, semantic, description)
    checkArg(1, names, "string")
    checkArg(2, semantic, "table")
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
    elseif meta and type(meta.__index) == "table" then
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
    elseif #names == 1 then
        -- It has only a short name.
        self._shortName = names
    else
        -- It has only a long name.
        self._longName = names
    end

    if self._longName and #self._longName <= 1 then
        error("A long name must be at least 2 letters long: "..self._longName, 3)
    end
    if self._shortName and #self._shortName ~= 1 then
        error("A short name must be a single letter: "..self._shortName, 3)
    end
    return self
end

-- Canonical name of the option to be used in variablesMap.
function optionDescription:canonicalName()
    if self._longName then
        return self._longName
    else
        return self._shortName
    end
end

-- Long names don't necessarily exist. May return nil.
function optionDescription:longName()
    return self._longName
end

-- Short names don't necessarily exist. May return nil.
function optionDescription:shortName()
    return self._shortName
end

function optionDescription:semantic()
    return self._semantic
end

-- Human-readable description of the option. May return nil.
function optionDescription:description()
    return self._description
end

function optionDescription:match(name)
    checkArg(1, name, "string")

    return self._longName == name or self._shortName == name
end

return optionDescription
