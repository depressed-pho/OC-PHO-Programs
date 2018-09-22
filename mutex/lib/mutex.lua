local computer = require("computer")
local event    = require("event")
local thread   = require("thread")
local mutex = {}
mutex.__index = mutex

-- Create a mutex. At most one thread can have exclusive ownership,
-- and if any thread does have exclusive ownership, no other threads
-- can have shared or exclusive ownership. Alternatively, many threads
-- may have shared ownership.
function mutex.new()
   local self = setmetatable({}, mutex)

   self.id       = mutex._genMutexID()
   self.exOwner  = nil -- nil | thread | "init"
   self.exLevel  = 0
   self.shOwners = {}  -- {owner=level}

   return self
end

function mutex._genMutexID()
   local id = ""
   for _ = 1, 16 do
      id = id .. string.char(math.random(32, 126))
   end
   return id
end

-- Acquire exclusive ownership. The current thread blocks until
-- ownership can be obtained. A thread that already has exclusive
-- ownership of a given instance of mutex can call this function to
-- acquire an additional level of ownership of the mutex. :unlock()
-- must be called for each level of ownership acquired by a single
-- thread before ownership can be acquired by another thread.
--
-- Return true on sucess, or false when timed out.
function mutex:lock(timeout) -- nil | number
   local me = thread.current() or "init"

   if not self.exOwner then
      -- No one has exclusive ownership on it. But what about shared
      -- ones?
      if self:_hasSharedOwnersExcept(me) then
         return self:_wait_unlock_then(
            timeout,
            function (remaining)
               return self:lock(remaining)
            end)
      else
         self.exOwner = me
         self.exLevel = 1
         return true
      end

   elseif self.exOwner == me then
      -- Recursive locking.
      self.exLevel = self.exLevel + 1
      return true

   else
      -- Someone else has exclusive ownership on it.
      return self:_wait_unlock_then(
         timeout,
         function (remaining)
            return self:lock(remaining)
         end)
   end
end

function mutex:_hasSharedOwnersExcept(thr) -- thread | "init"
   for owner, _ in pairs(self.shOwners) do
      if owner ~= thr then
         return true
      end
   end
   return false
end

function mutex:_wait_unlock_then(timeout, cont) -- (timeout) -> any
   local started = computer.uptime()
   while true do
      local ev, id = event.pull(timeout, "mutex.unlocked")
      if ev then
         if id == self.id then
            -- Continue.
            local elapsed   = computer.uptime() - started
            local remaining = (timeout and timeout - elapsed) or nil
            return cont(remaining)
         end
      else
         -- Timed out.
         return false
      end
   end
end

-- Release exclusive ownership owned by the current thread.
function mutex:unlock()
   local me = thread.current() or "init"

   assert(self.exOwner == me)
   assert(self.exLevel > 0)

   self.exLevel = self.exLevel - 1
   if self.exLevel == 0 then
      self.exOwner = nil
   end
end

-- Like :lock() but instead acquire shared ownership.
function mutex:lock_shared(timeout)
   local me = thread.current() or "init"

   if not self.exOwner or self.exOwner == me then
      -- No one else has exclusive ownership on it. Other threads may
      -- have shared ownership but that doesn't matter.
      local level = self.shOwners[me]
      if level then
         -- Recursive locking.
         self.shOwners[me] = level + 1
      else
         self.shOwners[me] = 1
      end
      return true

   else
      -- Someone else has exclusive ownership on it.
      return self:_wait_unlock_then(
         timeout,
         function (remaining)
            return self:lock_shared(remaining)
         end)
   end
end

-- Like :unlock() but instead release shared ownership.
function mutex:unlock_shared()
   local me = thread.current() or "init"

   local level = self.shOwners[me]
   assert(level ~= nil)

   if level == 0 then
      self.shOwners[me] = nil
   else
      self.shOwners[me] = level - 1
   end
end

return mutex
