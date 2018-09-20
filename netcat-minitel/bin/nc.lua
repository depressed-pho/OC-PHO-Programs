local net = require("minitel")

-- THINKME: Maybe we should move this to a separate library.
local function parseOpts(optsDesc, cmd, ...)
   local shell      = require("shell")
   local args, opts = shell.parse(...)
   for opt, arg in pairs(opts) do
      local desc = optsDesc[opt]
      if desc then
         -- It's a known long option.
         if desc == true then
            -- It takes an argument.
            if arg == true then
               print(cmd..": option --"..opt.." takes an argument.")
               return nil
            end
         elseif type(desc) == "string" then
            -- It has a short variant and takes no arguments.
            if arg == true then
               opts[desc] = nil
            else
               print(cmd..": option --"..opt.." takes no arguments.")
               return nil
            end
         end
      else
         print(cmd..": unknown option: --"..opt)
         return nil
      end
   end
   for opt, desc in pairs(optsDesc) do
      if type(desc) == "string" then
         local arg = opts[desc]
         if arg then
            -- It's a known short option.
            opts[opt ] = arg
            opts[desc] = nil
         end
      end
   end
   -- Any of the remaining pairs are unknown.
   for opt, arg in pairs(opts) do
      if #opt == 1 then
         print(cmd..": unknown option: -"..opt)
      else
         print(cmd..": unknown option: --"..opt)
      end
      return nil
   end
   return args, opts
end

local function printHelp(cmd)
   print("Usage: "...cmd..." [options] [HOST PORT | -l PORT]"
end

local function main(...)
   local optsDesc = {
      help       = "h",
      unreliable = "u",
      reliable   = "r",
      ordered    = "d",
      verbose    = "v",
      listen     = "l",
      output     = true, -- takes an argument
      mtu        = true,
      wait       = true
   }
   local cmd = "nc"
   local args, opts = parseOpts(optsDesc, cmd, ...)

   if not opts then
      printHelp(cmd)
      return 1

   elseif opts.help then
      printHelp(cmd)
      return 0

   elseif opts.listen and #args =~ 1 then
      printHelp(cmd)
      return 1

   elseif #args =~ 2 then
      printHelp(cmd)
      return 1
   end

   return 0
end
return main(...)
