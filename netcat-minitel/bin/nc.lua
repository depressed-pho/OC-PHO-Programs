local net = require("minitel")

-- THINKME: Maybe we should move this to a separate library.
local function parseOpts(optsDesc, cmd, ...)
   local shell      = require("shell")
   local args, opts = shell.parse(...)
   local res        = {}
   for longOpt, arg in pairs(opts) do
      local desc = optsDesc[longOpt]
      if desc then
         -- It's a known long option.
         opts[longOpt] = nil
         if desc == true then
            -- It takes an argument.
            if arg == true then
               print(cmd..": option --"..longOpt.." takes an argument.")
               return nil
            else
               res[longOpt] = arg
            end
         elseif type(desc) == "string" then
            -- It has a short variant and takes no arguments.
            local shortOpt = desc
            if arg == true then
               opts[shortOpt] = nil
               res[longOpt] = arg
            else
               print(cmd..": option --"..longOpt.." takes no arguments.")
               return nil
            end
         end
      end
   end
   for longOpt, desc in pairs(optsDesc) do
      if type(desc) == "string" then
         -- It's a known short option.
         local shortOpt = desc
         local arg      = opts[desc]
         if arg then
            opts[shortOpt] = nil
            res[longOpt] = arg
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
   print("Usage: "..cmd.." [options] [HOST PORT | -l PORT]")
   print([[
    -h, --help
        Display this message
    -u, --unreliable
        Use unreliable datagram transport instead of stream
    -r, --reliable
        Use reliable unordered datagram transport instead of stream
    -d, --ordered
        Use reliable ordered datagram transport instead of stream
    -v, --verbose
        Turn on verbosity
    -l, --listen
        Behave as a server as opposed to a client
    --output=FILE
        Send a dump of the traffic to the specified file
    --mtu=NUM
        Maximum packet size to be sent without getting fragmented
    --wait=NUM
        Connection timeout in seconds
]])
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

   elseif opts.listen and #args ~= 1 then
      printHelp(cmd)
      return 1

   elseif #args ~= 2 then
      printHelp(cmd)
      return 1
   end

   return 0
end
return main(...)
