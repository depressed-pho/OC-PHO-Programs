local test  = require("tap/test")
local t     = test.new()
t:plan(1)

-- See if the mutex module can be loaded.
local mutex = t:requireOK("mutex") or t:bailOut("Can't load mutex")
t:diag(mutex)
