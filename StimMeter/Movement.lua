-- Rotation sampling informed by SimpleController: Spin, Copyright (c) 2026 Piefayth (MIT).
local _, addon = ...
local c = addon.config
local movement = {}
addon.movement = movement

local turn = math.rad(c.turnDegrees)
local tau = 2 * math.pi

local function resetTurn(self)
    self.angle, self.low, self.high, self.laps = 0, 0, 0, 0
    self.turnedAt = nil
end

function movement:Reset()
    self.facing, self.sampledAt, self.air, self.pending = nil, nil, nil, nil
    self.confirmed, self.bonus, self.eligible = false, false, false
    resetTurn(self)
end

function movement:JumpPressed(now)
    -- The hook is an input signal. Require observed airtime before awarding points.
    if not IsFalling() then self.pending = now end
end

local function readable(value)
    return (not issecretvalue or not issecretvalue(value)) and type(value) == "number"
end

function movement:Sample(now)
    local air = IsFalling()
    local facing = GetPlayerFacing()
    if not readable(facing) then facing = nil end
    local speed = facing and not air and GetUnitSpeed and GetUnitSpeed("player")
    local jump = air and self.pending and now - self.pending <= c.jumpWindow

    if jump then
        self.confirmed, self.bonus, self.pending = true, false, nil
    elseif not air then
        self.confirmed, self.bonus = false, false
    end
    if self.pending and now - self.pending > c.jumpWindow then self.pending = nil end

    local points = jump and c.jump or 0
    local eligible = facing and (self.confirmed or (not air and readable(speed) and speed <= c.stationarySpeed))
    local continuous = self.eligible and eligible and self.air == air and not jump
        and now - self.sampledAt <= c.sampleGap
    local previous = self.facing
    self.facing, self.sampledAt, self.air, self.eligible = facing, now, air, eligible
    if not continuous then
        resetTurn(self)
        return points
    end

    local delta = (facing - previous + math.pi) % tau - math.pi
    if self.turnedAt and now - self.turnedAt > c.turnPause then resetTurn(self) end
    if delta == 0 then return points end
    self.turnedAt = now
    self.angle = self.angle + delta
    self.low = math.min(self.low, self.angle)
    self.high = math.max(self.high, self.angle)
    if self.high - self.low < turn then return points end

    -- Keep fractional overshoot and discard the already scored arc.
    if delta > 0 then
        self.low = self.low + turn
    else
        self.high = self.high - turn
    end
    local previousTotal = c.rotations[self.laps] or 0
    self.laps = self.laps + 1
    local award = c.rotations[self.laps] - previousTotal
    if self.laps == #c.rotations then self.laps = 0 end
    if self.confirmed then
        award = award * c.multiplier
        if not self.bonus then
            self.bonus = true
            award = award + c.jump * (c.multiplier - 1)
        end
    end
    return points + award
end
