local _, addon = ...
local c = addon.config
local meter = { score = 0 }
addon.meter = meter

local function saveStreak(self, now)
    if not self.started or self.preview then return end
    local duration = math.min(now, self.deadline) - self.started
    StimMeterDB.longest = math.max(StimMeterDB.longest, duration)
end

function meter:Reset(now)
    saveStreak(self, now)
    self.score, self.updated = 0, now
    self.started, self.deadline, self.preview, self.decayAt = nil, nil, nil, nil
end

function meter:Update(now)
    if self.started then
        saveStreak(self, now)
        if now < self.deadline then return end
        self.started, self.decayAt = nil, self.deadline
        self.updated = self.deadline
    end
    if self.decayAt then
        local elapsed = math.max(0, now - math.max(self.updated, self.decayAt))
        self.score = math.max(0, self.score - elapsed * c.decay)
    end
    self.updated = now
end

function meter:Add(points, now)
    self:Update(now)
    if self.started then
        self.deadline = now + c.inactivity
        return false
    end
    self.score = math.min(c.maximum, self.score + points)
    self.decayAt = now + c.grace
    if self.score < c.maximum then return false end

    self.started, self.deadline = now, now + c.inactivity
    if not self.preview then StimMeterDB.activations = StimMeterDB.activations + 1 end
    return true
end

function meter:Test(points, now)
    self:Reset(now)
    self.preview = true
    return self:Add(points, now)
end
