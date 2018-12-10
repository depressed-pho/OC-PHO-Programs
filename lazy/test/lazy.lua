local test = require('tap/test')
local t    = test.new()
t:plan(4)

local lazy = t:requireOK('lazy') or t:bailOut("Can't load program-options")

t:subtest(
    'lazy.require()',
    function ()
        t:plan(2)

        -- We want to unload some libraries and try loading it through
        -- lazy.require(). But it would be too rude to do that on something
        -- not under our control. So we unload the very 'lazy'.
        package.loaded.lazy = nil
        local llazy = lazy.require('lazy')

        -- Metamethods don't seem to be able to fool pairs().
        local function isEmpty(mod)
            -- luacheck: ignore
            for _ in pairs(mod) do
                return false
            end
            return true
        end
        t:ok(isEmpty(llazy), "Lazily loaded module is initially empty")
        t:is(type(llazy.require), "function", "Observing its member actually loads it")
    end)

t:subtest(
    'delay and force',
    function ()
        t:plan(5)

        local evaluated = false
        local delayed   = lazy.delay(
            function ()
                evaluated = true
                return 42
            end)

        t:ok(not evaluated, "Delayed values are initially not evaluated")
        t:is(lazy.force(delayed), 42, "The computed value is correct")
        t:is(delayed(), 42, "Delayed values can also be forced by calling them as functions")

        evaluated = false
        lazy.force(delayed)
        t:ok(not evaluated, "force()'ing the same value doesn't evaluate it again")

        local wrapped = lazy.wrap(42)
        t:is(wrapped(), 42, "wrap")
    end)

t:subtest(
    'map',
    function ()
        t:plan(2)

        local evaluated = false
        local foo = lazy.delay(
            function ()
                evaluated = true
                return 42
            end)
        local bar = foo:map(
            function (x)
                return x+1
            end)

        t:ok(not evaluated, "Delayed values won't be forced simply because they are mapped")
        t:is(bar(), 43, ":map() transforms a delayed value with a function")
    end)
