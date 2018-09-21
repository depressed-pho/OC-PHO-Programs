local shell   = require("shell")
local options = {}

function options.parse(optsDesc, cmd, ...)
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

return options
