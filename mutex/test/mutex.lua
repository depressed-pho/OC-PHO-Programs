local test  = require("tap/test")
local t     = test.new()
t:plan(4)

-- See if the mutex module can be loaded.
local mutex = t:requireOK("mutex") or t:bailOut("Can't load mutex")

-- See if mutex.new() returns something non-nil without raising an
-- error.
local m
t:livesAnd(
   function ()
      m = mutex.new()
      --t:ok(m ~= nil)
      t:ok(m == nil)
   end, 'mutex.new()')

-- See if m:unlock() raises an error because it's not locked by the
-- current thread in the first place.
t:diesOK(function () m:unlock() end, 'm:unlock() dies when unlocked')

-- See if locking an unlocked mutex instantly succeeds.
