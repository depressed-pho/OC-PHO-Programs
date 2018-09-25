local serialization = require("serialization")
local test = {}
test.__index = test

function test.new()
   local self = setmetatable({}, test)

   self.subtests = {}
   self:_push()

   return self
end

function test:_push()
   local subtest = {
      counter = 0,
      plan    = nil
   }
   table.insert(self.subtests, subtest)
end

function test:_pop()
   table.remove(self.subtests)
end

function test:_top()
   return self.subtests[#self.subtests]
end

function test:plan(numTests)
   local top = self:_top()
   if top.plan then
      error("Tests already have a plan: "..top.plan)
   else
      top.plan = numTests
      io.stdout:write("1.."..numTests.."\n")
   end
end

function test:ok(ok, description)
   local top = self:_top()
   top.counter = top.counter + 1

   if ok then
      io.stdout:write("ok ")
   else
      io.stdout:write("not ok ")
   end

   io.stdout:write(top.counter)

   if description then
      io.stdout:write(" "..description.."\n")
   else
      io.stdout:write("\n")
   end
end

function test:requireOK(module)
   local ok, result, reason = xpcall(require, debug.traceback, module)
   self:ok(ok, "require "..module)
   if ok then
      return result
   else
      self:diag(reason)
      return nil
   end
end

function test:livesAnd(thunk, description)
   local top = self:_top()
   local ctr = top.counter

   local ok, result, reason = xpcall(thunk, debug.traceback, module)
   if ok then
      if top.counter == ctr + 1 then
         return result
      else
         error("Misuse of test:livesAnd(): there must be one and "..
                  "only one predicate in the thunk.")
      end
   else
      self:ok(false, description)
      self:diag(reason)
   end
end

function test:bailOut(reason) -- luacheck: ignore self
   io.stdout:write("Bail out!")
   if reason then
      io.stdout:write(" "..reason.."\n")
   end
   os.exit(255)
end

function test:diag(msg)
   if type(msg) == "table" then
      self:diag(serialization.serialize(msg, true))
   else
      for line in string.gmatch(msg, "([^\n]+)") do
         io.stderr:write("# "..line.."\n")
      end
   end
end

return test
