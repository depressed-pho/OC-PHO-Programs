local test  = require("tap/test")
local t     = test.new()
t:plan(2)

-- See if the mutex module can be loaded.
local mutex = t:requireOK("mutex") or t:bailOut("Can't load mutex")
t:diag(mutex)

-- See if mutex.new() returns something non-nil without raising an
-- error.
local m
t:livesAnd(
   function ()
      m = mutex.new()
      t:ok(m)
   end, 'mutex.new()')
