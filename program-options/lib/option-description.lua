local valueSemantic = require('program-options/value-semantic')

local optionDescription = {}
optionDescription.__index = optionDescription

function optionDescription.new(...)
    local self = setmetatable({}, optionDescription)
    self._longName    = nil
    self._shortName   = nil
    self._semantic    = nil
    self._description = nil
    self._required    = false

    local args = table.pack(...)
    if args.n == 1 then
        checkArg(1, args[1], "string")
        self:_parseNames(args[1])
        self._semantic = valueSemantic.new():implicit(true):noArgs()
    elseif args.n == 2 then
        if type(args[2]) == "string" then
            checkArg(1, args[1], "string")
            self:_parseNames(args[1])
            self._semantic = valueSemantic.new():implicit(true):noArgs()
            self._description = args[2]
        else
            checkArg(1, args[1], "string")
            self:_parseNames(args[1])
            if valueSemantic.isInstance(args[2]) then
                error("Not an instance of valueSemantic: "..tostring(args[2]), 2)
            else
                self._semantic = args[2]
            end
        end
    elseif args.n == 3 then
        checkArg(1, args[1], "string")
        checkArg(3, args[3], "string")
        self:_parseNames(args[1])
        if valueSemantic.isInstance(args[2]) then
            error("Not an instance of valueSemantic: "..tostring(args[2]), 2)
        else
            self._semantic = args[2]
        end
        self._description = args[3]
    else
        error("wrong number of arguments", 2)
    end
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

-- State that the occurence of the option is mandatory, within a
-- single call of vm:store().
function optionDescription:required()
    self._required = true
    return self
end

function optionDescription:isRequired()
    return self._required
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
