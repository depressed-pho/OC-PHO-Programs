local os     = require('os')
local test   = require('tap/test')
local thread = require('thread')
local t      = test.new()
t:plan(6)

-- The mutex module should be able to be loaded.
local mutex = t:requireOK("mutex") or t:bailOut("Can't load mutex")

-- mutex.new() should return something non-nil without raising an
-- error.
t:livesAnd(
    function ()
        t:isnt(mutex.new(), nil)
    end, 'mutex.new() should return non-nil')

t:subtest(
    'single thread lock/unlock',
    function ()
        t:plan(4)

        local m = mutex.new()
        t:is(m:lock(), true, 'm:lock() succeeds when m is unlocked')
        t:is(m:lock(), true, 'm:lock() also succeeds when the caller already has an ownership')
        t:livesOK(
            function ()
                m:unlock()
                m:unlock()
            end, 'm:unlock() succeeds when the caller has an ownership')
        t:diesOK(function () m:unlock() end, 'm:unlock() dies when m is unlocked')
    end)

t:subtest(
    'multithread lock/unlock',
    function ()
        t:plan(2)

        -- The main thread spawns another thread while holding an
        -- ownership. The spawned thread updates the variable v before
        -- and after waiting for the mutex to be unlocked. Before the
        -- main thread unlocks the mutex, v is supposed to be updated
        -- only once.
        local m   = mutex.new()
        m:lock()
        local v   = 0
        local thr = thread.create(
            function ()
                v = 1
                m:lock()
                v = 2
                m:unlock()
            end)
        t:is(v, 1, 'before unlock()')
        m:unlock()
        thr:join()
        t:is(v, 2, 'after unlock()')
    end)

t:subtest(
    'shared locks',
    function ()
        t:plan(2)

        -- The main thread spawns another thread while holding a
        -- shared lock. The spawned thread first acquires a shared
        -- lock, and then updates the variable v before and after
        -- acquiring an exclusive ownership. Before the main thread
        -- unlocks the mutex, v is supposed to be updated once and
        -- only once.
        local m   = mutex.new()
        m:lockShared()
        local v   = 0
        local thr = thread.create(
            function ()
                m:lockShared()
                v = 1
                m:lock() -- This essentially upgrades the ownership.
                v = 2
                m:unlock()
                m:unlockShared()
            end)
        t:is(v, 1, 'before unlockShared()')
        m:unlockShared()
        thr:join()
        t:is(v, 2, 'after unlockShared()')
    end)

t:subtest(
    'timed wait',
    function ()
        t:plan(2)

        -- The main thread spawns another thread without an
        -- ownership. The spawned thread locks the mutex before
        -- exiting. The main thread tries to lock it too, but should
        -- block because of the lock taken by the spawned thread.
        local m   = mutex.new()
        local thr = thread.create(
            function ()
                m:lock()
                os.sleep(math.huge)
                -- It will never unlock the mutex!
            end)
        local t1 = os.time()
        t:is(m:lock(0.5), false, 'm:lock() times out')
        local t2 = os.time()
        local dt = os.difftime(t2, t1)
        t:cmpOK(dt, '>=', 0.5, 'after taking at least 0.5 seconds')
        thr:kill()
    end)
