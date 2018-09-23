-- base
local result = {}
result.__index = result

function result.new(resultType)
   local self = setmetatable({}, result)

   self.type = resultType

   return self
end

function result:isVersion()
   return self.type == "version"
end

function result:isPlan()
   return self.type == "plan"
end

function result:isTest()
   return self.type == "test"
end

function result:isBailOut()
   return self.type == "bailOut"
end

function result:isOK() -- luacheck: ignore self
   return true
end

function result:hasSkip() -- luacheck: ignore self
   return false
end

function result:hasTodo() -- luacheck: ignore self
   return false
end

function result:as_string() -- luacheck: ignore self
   error("This method has to be overridden")
end

-- version
result.version = setmetatable({}, result)
result.version.__index = result.version

function result.version.new(version)
   local self = result.new("version")
   setmetatable(self, result.version)

   self.version = version

   return self
end

function result.version:as_string()
   return "TAP version "..self.version
end

-- plan
result.plan = setmetatable({}, result)
result.plan.__index = result.plan

function result.plan.new(planned, directive)
   local self = result.new("plan")
   setmetatable(self, result.plan)

   self.planned   = planned
   self.directive = directive or {}

   return self
end

function result.plan:testsPlanned()
   return self.planned
end

function result.plan:hasSkip()
   return not not self.directive.skip
end

function result.plan:hasTodo()
   return not not self.directive.todo
end

function result:reason()
   return self.directive.skip
end

function result.plan:as_string()
   local str = "1.."..self.planned
   if self.directive.skip then
      str = str.." # SKIP "..self.directive.skip
   end
   return str
end

-- test
result.test = setmetatable({}, result)
result.test.__index = result.test

function result.test.new(ok, number, description, directive)
   local self = result.new("test")
   setmetatable(self, result.test)

   self.ok        = ok
   self.num       = number
   self.desc      = description
   self.directive = directive or {}

   return self
end

function result.test:isOK()
   return self.ok
end

function result.test:number()
   return self.num
end

function result.test:description()
   return self.desc
end

function result.test:hasSkip()
   return not not self.directive.skip
end

function result.test:reason()
   return self.directive.skip
end

function result.test:as_string()
   local str = ""

   if not self.ok then
      str = str.."not "
   end
   str = str.."ok "..self.num

   if #self.description > 0 then
      str = str.." "..self.desc
   end

   if self.directive.skip then
      str = str.." # SKIP "..self.directive.skip

   elseif self.directive.todo then
      str = str.." # TODO "..self.directive.todo
   end

   return str
end

-- bailOut
result.bailOut = setmetatable({}, result)
result.bailOut.__index = result.bailOut

function result.bailOut.new(reason)
   local self = result.new("bailOut")
   setmetatable(self, result.bailOut)

   self.reason = reason

   return self
end

function result.bailOut:reason()
   return self.reason
end

function result.bailOut:as_string()
   local str = "Bail out!"
   if #self.reason > 0 then
      str = str.." "..self.reason
   end
   return str
end

return result
