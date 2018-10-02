local array = require('containers/array')
local optionDescription = require('program-options/option-description')
local optionsDescription = {}
optionsDescription.__index = optionsDescription

function optionsDescription.new(caption)
    checkArg(1, caption, "string", "nil")
    local self = setmetatable({}, optionsDescription)

    self._caption = caption or ""
    self._opts    = array.new() -- array<optionDescription>
    self._groups  = array.new() -- array<optionsDescription>

    return self
end

function optionsDescription.isInstance(obj)
    checkArg(1, obj, "table")
    local meta = getmetatable(obj)
    if meta == optionsDescription then
        return true
    elseif type(meta.__index) == "table" then
        return optionsDescription.isInstance(meta.__index)
    else
        return false
    end
end

function optionsDescription:add(desc)
    if optionDescription.isInstance(desc) then
        self._opts:push(desc)

    elseif optionsDescription.isInstance(desc) then
        self._groups:push(desc)
    else
        error("Not an instance of optionDescription nor optionsDescription: "..desc, 2)
    end
    self:_verifyNoDuplicates()
    return self
end

--function optionsDescription:_verifyNoDuplicates()
--end

return optionsDescription
