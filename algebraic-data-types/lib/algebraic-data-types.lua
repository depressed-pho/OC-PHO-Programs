local adt = {}

function adt.define(...)
    -- Create a table whose keys are the name of constructor specs,
    -- and values are actual constructors.
    local tab  = {}
    local args = table.pack(...)

    local ctors = {}
    local meta  = {}
    for i = 1, args.n do
        if getmetatable(args[i]) == adt.constructor then
            table.insert(ctors, args[i])

        elseif getmetatable(args[i]) == adt.metamethod then
            table.insert(meta, args[i])

        else
            error("bad argument #"..i.." (constructor or metamethod expected, got "..
                      type(args[i])..")", 2)
        end
    end

    for tag = 1, #ctors do
        local ctorSpec = args[tag]

        -- We want constructors to be callable, but if it is nullary
        -- we also want it to be usable without calling it.
        local ctor = {}

        if #ctorSpec.fields == 0 then
            ctor.fields = {n = 0}
        end

        for _, m in ipairs(meta) do
            ctor[m.name] = m.func
        end

        setmetatable(
            ctor,
            {
                __call = function (cls, ...)
                    local self = {}

                    -- Values will have a property ".fields" which is
                    -- {[idx]=value}. It is also callable as a method
                    -- which just unpacks the fields.
                    self.fields = ctorSpec:acceptFields(...)
                    setmetatable(
                        self.fields,
                        {
                            __call = function ()
                                return table.unpack(self.fields)
                            end
                        })

                    return setmetatable(self, cls)
                end
            })

        -- Values will have a method ":is" to compare the equality of
        -- a tag or a type.
        function ctor:is(obj) -- luacheck: ignore self
            return ctor == obj or tab == obj
        end

        -- Values will have a method ":match" to perform a miserably
        -- crude form of patterh matching.
        function ctor:match(cases)
            checkArg(1, cases, "table")
            local case = cases[ctorSpec.name]
            if case then
                return case(table.unpack(self.fields))
            elseif cases._ then
                return cases._(self)
            else
                error("No case for the constructor "..ctorSpec.name.." exists", 2)
            end
        end

        -- Values will have accessor properties if its fields are
        -- named.
        function ctor.__index(self, name)
            -- self.__index isn't ctor. It's this function so we have
            -- to do the redirection ourselves.
            if name == "is" then
                return ctor.is

            elseif name == "match" then
                return ctor.match
            else
                local idx = ctorSpec.indexOf[name]
                if idx then
                    return self.fields[idx]
                else
                    error("Constructor "..ctorSpec.name..
                              " does not have a field named "..tostring(name), 2)
                end
            end
        end
        function ctor.__newindex(self, name, value)
            local idx = ctorSpec.indexOf[name]
            if idx then
                self.fields[idx] = value
            else
                error("Constructor "..ctorSpec.name..
                          " does not have a field named "..tostring(name), 2)
            end
        end

        tab[ctorSpec.name] = ctor
    end
    return tab
end

-- Constructor specs
adt.constructor = {}
adt.constructor.__index = adt.constructor

setmetatable(
    adt.constructor,
    {
        __call = function (cls, name, ...)
            checkArg(1, name, "string")
            -- The rest of the arguments are field specs.
            local args = table.pack(...)

            local self = setmetatable({}, cls)
            self.name    = name
            self.fields  = args
            self.indexOf = {}

            for i = 1, args.n do
                if getmetatable(args[i]) ~= adt.field then
                    error("bad argument #"..(i+1).." (field expected, got "..type(args[i])..")", 2)
                end
                if args[i].name then
                    self.indexOf[args[i].name] = i
                end
            end
            return self
        end
    })

function adt.constructor:acceptFields(...)
    local args = table.pack(...)

    if args.n == #self.fields then
        -- 'args' is a sequence of field values.
        return args

    elseif args.n == 1 and type(args[1]) == "table" then
        -- Got a map.
        local values = args[1]
        local named  = {}
        local fields = {n = #self.fields}
        for idx, fldSpec in ipairs(self.fields) do
            if fldSpec.name then
                fields[idx] = values[fldSpec.name]
                named[fldSpec.name] = fldSpec
            else
                error("Field #"..idx.." of constructor "..self.name.." is unnamed", 2)
            end
        end
        -- Verify that there are no extra fields in 'values'.
        for name, _ in pairs(values) do
            if not named[name] then
                error("Constructor "..self.name.." does not have a field named "..tostring(name), 2)
            end
        end
        return fields

    else
        error("Arguments for a constructor must either be field values or a single table", 2)
    end
end

-- Field specs
adt.field = {}
adt.field.__index = adt.field

setmetatable(
    adt.field,
    {
        __call = function (cls, name)
            checkArg(1, name, "string", "nil")

            local self = setmetatable({}, cls)
            self.name = name

            return self
        end
    })

-- Metamethods
adt.metamethod = {}
adt.metamethod.__index = adt.metamethod

setmetatable(
    adt.metamethod,
    {
        __call = function (cls, name, func)
            checkArg(1, name, "string")
            checkArg(2, func, "function")
            assert(name:find("^__"))

            local self = setmetatable({}, cls)
            self.name = name
            self.func = func

            return self
        end
    })

return adt
