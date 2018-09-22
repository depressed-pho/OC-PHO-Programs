local buffer = require("buffer")
local thread = require("thread")
local server = {}
server.__index = server

-- Open a buffer representing a stream socket in the server mode. This
-- function does not block.
function server.open(verbose, port)
   checkArg(1, port, "number")

   local self = setmetatable({}, server)
   self.verbose = verbose
   self.port    = port
   thread.create(self._listen, self):detach()

   return buffer.new("rw", self)
end

function server:_listen()
   print("FIXME: Spawn a thread that listens on the port: "..self.port)
end

-- Called by the buffer library.
function server:close()
   print("FIXME: buffer.stream.server:close")
   return self
end

-- Called by the buffer library. May block.
function server:write(octets)
   print("FIXME: buffer.stream.server:write: "..octets)
   return self
end

-- Called by the buffer library. May block.
function server:read(numOctets)
   print("FIXME: buffer.stream.server:read: "..numOctets)
   return self
end

-- Called by the buffer library. Will never block.
function server:seek(whence, offset) -- luacheck: ignore self
   return nil, "buffer.stream.server: operation not supported: seek "
      ..whence..", "..offset
end

return server
