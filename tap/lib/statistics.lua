local statistics = {}
statistics.__index = statistics

-- forFile
statistics.forFile = {}
statistics.forFile.__index = statistics.forFile

function statistics.forFile.new(parent)
    local self = setmetatable({}, statistics.forFile)

    self.planned     = nil
    self.passed      = 0
    self.failed      = {}
    self.skipped     = 0
    self.todoPassed  = {}
    self.todoFailed  = 0
    self.lastNumber  = 0
    self.bailedOut   = nil
    self.parent      = parent
    self.child       = nil

    return self
end

function statistics.forFile:_currentLeaf()
    if self.child then
        return self.child:_currentLeaf()
    else
        return self
    end
end

function statistics.forFile:plan(planned, skipReason)
    -- Does the file already have a plan?
    if self.planned then
        -- Then it means this is a start of a subtest. But if it has a
        -- skip reason, we know actual tests will not be
        -- executed. Note that a subtest is also a test, so we need to
        -- increment the counter here.
        self.lastNumber = self.lastNumber + 1

        if skipReason then
            self.planned = self.planned + planned
            self.skipped = self.skipped + planned
        else
            local subtest = statistics.forFile.new(self)
            subtest.planned = planned
            self:_currentLeaf().child = subtest
        end
    else
        -- This is the plan of the tests that are going to be executed
        -- from now.
        self.planned = planned
        if skipReason then
            self.skipped = planned
        end
    end
end

function statistics.forFile:_formatStack(number)
    local str = tostring(number)

    if self.parent then
        return self.parent:_formatStack(self.parent.lastNumber + 1).."."..str
    else
        return str
    end
end

function statistics.forFile:test(isOK, number, description, skipReason, todoReason)
    -- Is it in a subtest?
    if self.child then
        self:_currentLeaf():test(isOK, number, description, skipReason, todoReason)
    else
        if skipReason then
            self.skipped = self.skipped + 1

        elseif todoReason then
            if isOK then
                table.insert(self.todoPassed, self:_formatStack(number).." "..description)
            else
                self.todoFailed = self.todoFailed + 1
            end

        else
            if isOK then
                self.passed = self.passed + 1
            else
                table.insert(self.failed, self:_formatStack(number).." "..description)
            end
        end

        self.lastNumber = number

        -- If this was the last planned test in the subtest, then the
        -- result of it should be propagated to the parent.
        if self.planned == number then
            if self.parent then
                self.parent.passed = self.parent.passed + self.passed
                for _, failed in ipairs(self.failed) do
                    table.insert(self.parent.failed, failed)
                end
                self.parent.skipped = self.parent.skipped + self.skipped
                for _, todoPassed in ipairs(self.todoPassed) do
                    table.insert(self.parent.todoPassed, todoPassed)
                end
                self.parent.todoFailed = self.parent.todoFailed + self.todoFailed
                self.parent.child = nil
            end
        end
    end
end

function statistics.forFile:progress()
    if self.planned then
        return self.lastNumber.."/"..self.planned
    else
        return self.lastNumber
    end
end

function statistics.forFile:bailOut(reason)
    self.bailedOut = reason
end

function statistics.forFile:finished()
    if self.planned then
        -- If the number of the last executed test doesn't match the
        -- plan, it should be considered to be a failure.
        if self.lastNumber ~= self.planned then
            table.insert(self.failed, "Planned " .. self.planned..
                             " tests but ran "..self.lastNumber..".")
        end
    end
end

function statistics.forFile:isOK()
    if self.bailedOut then
        return false

    elseif #self.failed == 0 then
        return true

    else
        return false
    end
end

-- statistics
function statistics.new()
    local self = setmetatable({}, statistics)

    self.files = {}

    return self
end

function statistics:_forFile(file)
    if not self.files[file] then
        self.files[file] = statistics.forFile.new()
    end
    return self.files[file]
end

function statistics:plan(file, planned, skipReason)
    self:_forFile(file):plan(planned, skipReason)
end

function statistics:test(file, isOK, number, description, skipReason, todoReason)
    self:_forFile(file):test(isOK, number, description, skipReason, todoReason)
end

function statistics:progress(file)
    return self:_forFile(file):progress()
end

function statistics:bailOut(file, reason)
    self:_forFile(file):bailOut(reason)
end

function statistics:finished(file)
    self:_forFile(file):finished()
end

function statistics:isOK(file)
    return self:_forFile(file):isOK()
end

function statistics:result()
    local result     = ""
    local passed     = 0
    local failed     = 0
    local skipped    = 0
    local todoPassed = 0
    local todoFailed = 0
    local total      = 0
    for file, forFile in pairs(self.files) do
        for _, failed_ in ipairs(forFile.failed) do
            result = result..file.." -- failed: "..failed_.."\n"
        end
        for _, todoPassed_ in ipairs(forFile.todoPassed) do
            result = result..file.." -- passed unexpectedly: "..todoPassed_.."\n"
        end
        passed     = passed     + forFile.passed
        failed     = failed     + #forFile.failed
        skipped    = skipped    + forFile.skipped
        todoPassed = todoPassed + #forFile.todoPassed
        todoFailed = todoFailed + forFile.todoFailed
        total      = total  + forFile.passed + #forFile.failed + forFile.skipped +
            #forFile.todoPassed + forFile.todoFailed
    end
    result = result..passed.."/"..total.." passed"
    result = result..", "..failed.."/"..total.." failed"
    if skipped > 0 then
        result = result..", "..skipped.."/"..total.." skipped"
    end
    if todoPassed > 0 then
        result = result..", "..todoPassed.."/"..total.." passed unexpectedly"
    end
    if todoFailed > 0 then
        result = result..", "..todoFailed.."/"..total.." failed expectedly"
    end
    return result..".\n"
end

return statistics
