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

   elseif opts.listen and #args ~= 1 then
      printHelp(cmd)
      return 1

   elseif #args ~= 2 then
      printHelp(cmd)
      return 1
   end

   -- We need to read from two sources at the same time, a socket and
   -- stdin. And since term.read() is a blocking call, we spawn 2
   -- threads for them.

   local sock -- buffer
   if opts.unreliable then
      -- FIXME
   elseif opts.reliable then
      -- FIXME
   elseif opts.ordered then
      -- FIXME
   else
      if opts.listen then
         sock = require("netcat-minitel/buffer/stream/server")
      else
         -- FIXME
      end
   end

   return 0
end
return main(...)
