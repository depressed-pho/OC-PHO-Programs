local array = require('containers/array')
local map   = require('containers/map')
local set   = require('containers/set')
local optionDescription = require('program-options/option-description')
local valueSemantic     = require('program-options/value-semantic')
local optionsDescription = {}
optionsDescription.__index = optionsDescription

function optionsDescription.new(caption)
    checkArg(1, caption, "string", "nil")
    local self = setmetatable({}, optionsDescription)

    self._caption = caption or ""
    self._opts    = array.new() -- array<optionDescription>
    self._groups  = array.new() -- array<optionsDescription>
    self._optMap  = map.new()   -- map<string, optionDescription>

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
        if self._optMap:has(desc:longName()) then
            error("Duplicate option: "..desc:longName(), 2)
        elseif desc:shortName() and self._optMap:has(desc:shortName()) then
            error("Duplicate option: "..desc:shortName(), 2)
        else
            self._opts:push(desc)
            self._optMap:set(desc:longName(), desc)
            if desc:shortName() then
                self._optMap:set(desc:shortName(), desc)
            end
        end
    elseif optionsDescription.isInstance(desc) then
        local inters = self._optMap:intersection(desc._optMap)
        for k, _ in inters:entries() do
            error("Duplicate option: "..k, 2)
        end
        self._groups:push(desc)
        self._optMap = self._optMap:union(desc._optMap)
    else
        error("Not an instance of optionDescription nor optionsDescription: "..desc, 2)
    end
    return self
end

function optionsDescription:addOptions()
    local function helper(...)
        local args = table.pack(...)
        if args.n == 2 then
            if type(args[2]) == "string" then
                local name, description = ...
                local sem = valueSemantic.new():implicit(nil):zeroTokens()
                self:add(
                    optionDescription.new(name, sem, description))
                return helper
            else
                local name, sem = ...
                if not valueSemantic.isInstance(sem) then
                    error("Not an instance of valueSemantic: "..sem, 2)
                end
                self.add(
                    optionDescription.new(name, sem))
            end
        else
            local name, sem, description = ...
            if not valueSemantic.isInstance(sem) then
                error("Not an instance of valueSemantic: "..sem, 2)
            end
            self.add(
                optionDescription.new(name, sem, description))
        end
    end
    return helper
end

-- Returns optionDescription or nil.
function optionsDescription:find(name)
    checkArg(1, name, "string")
    return self._optMap:get(name, nil)
end

-- Returns set<optionDescription> consisting of all the known options.
function optionsDescription:options()
    return self._groups:foldl(
        function (xs, group)
            return xs:union(group:options())
        end,
        set.new(self._opts:values()))
end

return optionsDescription
