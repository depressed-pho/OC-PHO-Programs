local test  = require("tap/test")
local t     = test.new()
t:plan(3)

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

t:subtest(
    'single thread lock/unlock',
    function ()
        t:plan(4)

        t:is(m:lock(), true, 'm:lock() succeeds when m is unlocked')
        t:is(m:lock(), true, 'm:lock() also succeeds when the caller already has an ownership')
        t:livesOK(
            function ()
                m:unlock()
                m:unlock()
            end, 'm:unlock() succeeds when the caller has an ownership')
        t:diesOK(function () m:unlock() end, 'm:unlock() dies when m is unlocked')
    end)
