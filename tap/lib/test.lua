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

   if not ok then
      io.stderr:write("#   Failed test ")
      if description then
         io.stderr:write("`"..description.."'\n")
         io.stderr:write("#   ")
      end
      local file, line = self:_calledAt()
      io.stderr:write("in "..file.." at line "..line..".\n")
   end
end

-- Find out the first function outside of this module.
local shortSrcOfMe = debug.getinfo(1, "S").short_src
assert(shortSrcOfMe)
function test:_calledAt() -- luacheck: ignore self
   local i = 1
   while true do
      local frame = debug.getinfo(i, "Sl")
      if frame then
         if frame.short_src ~= shortSrcOfMe then
            return frame.short_src, frame.currentline
         end
         i = i + 1
      else
         return "(unknown)", 0
      end
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

   -- While evaluating the thunk we have to replace test:ok() so it
   -- uses the description passed to this function. This assumes
   -- functions like is() all use ok() ultimately.
   local savedOK     = self.ok
   local savedRealOK = rawget(self, "ok") -- expected to be nil
   self.ok = function (self, ok) -- luacheck: ignore self
      return savedOK(self, ok, description)
   end
   local ok, result, reason = xpcall(thunk, debug.traceback)
   self.ok = savedRealOK

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

function test:diesOK(thunk, description)
   local ok, result, _ = xpcall(thunk, debug.traceback)
   self:ok(not ok, description)
   return result
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
