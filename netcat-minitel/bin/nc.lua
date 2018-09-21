local net     = require("minitel")
local options = require("netcat-minitel/options")

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
        Connection timeout in seconds]])
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
   local args, opts = options.parse(optsDesc, cmd, ...)

   if not opts then
      printHelp(cmd)
      return 1

   elseif opts.help then
      printHelp(cmd)
      return 0

   else
      if opts.listen then
         if #args ~= 1 or tonumber(args[1]) == nil then
            printHelp(cmd)
            return 1
         end
         opts.port = tonumber(args[1])

      else
         if #args ~= 2 or tonumber(args[2]) == nil then
            printHelp(cmd)
            return 1
         end
         opts.host = args[1]
         opts.port = tonumber(args[2])
      end
   end

   if tonumber(opts.mtu) == nil then
      printHelp(cmd)
      return 1
   else
      opts.mtu = tonumber(opts.mtu)
   end

   if tonumber(opts.wait) == nil then
      printHelp(cmd)
      return 1
   else
      opts.wait = tonumber(opts.wait)
   end

   -- Now we are going to modify global parameters of minitel. Take
   -- extra care to restore them even when something goes wrong.
   local saved = {
      mtu         = minitel.mtu,
      streamdelay = minitel.streamdelay
   }
   minitel.mtu         = opts.mtu
   minitel.streamdelay = opts.wait
   local ok, result, reason = xpcall(protected_main, debug.traceback, opts)
   minitel.mtu         = saved.mtu
   minitel.streamdelay = saved.streamdelay
   if not ok then
      error(reason, 0)
   end

   return result
end

local function protected_main(opts)
   local sock -- buffer
   if opts.unreliable then
      -- FIXME
   elseif opts.reliable then
      -- FIXME
   elseif opts.ordered then
      -- FIXME
   else
      if opts.listen then
         local server = require("netcat-minitel/buffer/stream/server")
         sock = server.open(opts.port)
      else
         -- FIXME
      end
   end

   -- We need to read from two sources at the same time, a socket and
   -- stdin. And since buffer:read() is a blocking call, we spawn 2
   -- threads for them.
end

return main(...)
