local test  = require("tap/test")
local t     = test.new()
t:plan(4)

-- The mutex module should be able to be loaded.
local mutex = t:requireOK("mutex") or t:bailOut("Can't load mutex")

-- mutex.new() should return something non-nil without raising an
-- error.
local m
t:livesAnd(
   function ()
      m = mutex.new()
      t:isnt(m, nil)
   end, 'mutex.new() should return non-nil')

-- m:unlock() should raise an error because it's not locked by the
-- current thread in the first place.
t:diesOK(function () m:unlock() end, 'm:unlock() dies when m is unlocked')

-- Locking an unlocked mutex should instantly succeed.
t:is(m:lock(), true, 'm:lock() succeeds when m is unlocked')
