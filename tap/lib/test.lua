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
      io.stdout.write("1.."..numTests)
   end
end

function test:requireOK(module)
   local top = self:_top()
   top.counter = top.counter + 1

   local ok, result, reason = xpcall(require, debug.traceback, module)
   if ok then
      io.stdout:write("ok "..top.counter.." require "..module)
      return result
   else
      io.stdout:write("not ok "..top.counter.." require "..module)
      self:diag(reason)
      return nil
   end
end

function test:bailOut(reason) -- luacheck: ignore self
   io.stdout:write("Bail out!")
   if reason then
      io.stdout:write(" "..reason)
   end
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
