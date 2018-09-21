local buffer = require("buffer")
local server = {}
server.__index = server

-- Open a buffer representing a stream socket in the server mode. This
-- function does not block.
function server.open(port)
   checkArg(1, port, "number")

   local self = setmetatable({}, server)
   self.port = port

   print("FIXME: Spawn a thread that listens on the port: "..port)

   return buffer.new("rw", self)
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
function server:seek(whence, offset)
   return nil, "buffer.stream.server: operation not supported: seek "
      ..whence..", "..offset
end

return server
