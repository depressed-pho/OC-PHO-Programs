local event      = require("event")
local parser     = require("tap/parser")
local statistics = require("tap/statistics")
local term       = require("term")
local harness = {}
harness.__index = harness

function harness.new(opts)
   local self = setmetatable({}, harness)
   opts = opts or {}

   self.verbosity = opts.verbosity or 0 -- -3 - 1
   self.isTTY     = io.output().tty

   return self
end

-- Run TAP producers (i.e. tests) with statistics
function harness:runTests(files) -- [file]
   local stats = statistics.new()

   -- Install an interrupt handler so users can terminate tests. It
   -- will also print out statistics even though it would only be
   -- partial.
   local function interrupted()
      error("FIXME: interrupted")
   end
   event.listen("interrupted", interrupted)

   for _, file in ipairs(files) do
      self:_runTest(stats, file)
   end
   self:_write(-2, io.stdout, stats:result())

   event.ignore("interrupted", interrupted)
end

function harness:_runTest(stats, file)
   local pipe = io.popen(file, "r")
   if not pipe then
      self:_write(0, io.stderr, "File not found: "..file.."\n")
      return
   end

   self:_write(-1, io.stdout, file.." ... ")
   local savedCursX, savedCursY
   if self.isTTY then
      savedCursX, savedCursY = term.getCursor()
   end

   for r in parser(pipe) do
      self:_write(1, io.stdout, r:as_string())

      if r:isPlan() then
         if r:hasSkip() then
            stats:plan(file, r:testsPlanned(), r:reason())
         else
            stats:plan(file, r:testsPlanned(), nil)
         end

      elseif r:isTest() then
         if r:hasSkip() then
            stats:test(file, r:isOK(), r:number(), r:description(), r:reason(), nil)

         elseif r:hasTodo() then
            stats:test(file, r:isOK(), r:number(), r:description(), nil, r:reason())

         else
            stats:test(file, r:isOK(), r:number(), r:description(), nil, nil)
         end

         if self.verbosity == 0 and self.isTTY then
            term.setCursor(savedCursX, savedCursY)
            term.write(stats:progress(file), false) -- no wrap
         end

      elseif r:isBailout() then
         stats:bailOut(file, r:reason())

         if self.verbosity == 0 and self.isTTY then
            term.setCursor(savedCursX, savedCursY)
            term.write(r:as_string(), true) -- wrap
         end
      end
   end
   io.close(pipe)

   if stats:isOK(file) then
      self:_write(-1, io.stdout, " ok\n")
   else
      self:_write(-1, io.stdout, " failed\n")
   end
end

function harness:_write(threashold, buffer, message)
   if self.verbosity >= threashold then
      buffer:write(message)
   end
end

return harness
