local _, addon = ...
local c, meter, movement, display = addon.config, addon.meter, addon.movement, addon.display
local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")

local function blocked()
    return InCombatLockdown() or UnitAffectingCombat("player")
        or IsFlying() or IsSwimming() or IsMounted() or UnitIsDeadOrGhost("player")
end

local function say(message)
    DEFAULT_CHAT_FRAME:AddMessage("StimMeter: " .. message)
end

local function update()
    local now = GetTime()
    meter:Update(now)
    if blocked() then
        movement:Reset()
    else
        local points = movement:Sample(now)
        if points > 0 then
            if meter.preview and not meter.started then meter:Reset(now) end
            if meter:Add(points, now) then display:Activate() end
        end
    end
    display:Render(meter, now)
end

local function validScale(value)
    return value and value >= c.minScale and value <= c.maxScale
end

local function slash(message)
    local command, argument = message:lower():match("^%s*(%S*)%s*(.-)%s*$")
    local now = GetTime()
    if command == "test" then
        local points = argument == "" and c.maximum or tonumber(argument)
        if not points or points < 0 or points > c.maximum then
            say(("Enter a test value from 0 to %d."):format(c.maximum))
            return
        end
        if blocked() then
            say("Test while alive, on foot, and out of combat.")
            return
        end
        if meter:Test(points, now) then display:Activate() end
    elseif command == "sound" then
        StimMeterDB.sound = not StimMeterDB.sound
        say(StimMeterDB.sound and "Activation sound enabled." or "Activation sound disabled.")
    elseif command == "scale" then
        if argument == "" then
            say(("Text scale is %g. Use /stim scale %g-%g to adjust it."):format(
                StimMeterDB.scale, c.minScale, c.maxScale))
            return
        end
        local scale = tonumber(argument)
        if not validScale(scale) then
            say(("Enter a scale from %g to %g."):format(c.minScale, c.maxScale))
            return
        end
        StimMeterDB.scale = scale
        display.scalePreviewUntil = now + c.scalePreviewDuration
        say(("Text scale set to %g."):format(scale))
    elseif command == "move" or command == "unlock" then
        display:SetMoving(true)
        say("Drag the text, then type /stim lock.")
    elseif command == "lock" then
        display:SetMoving(false)
    elseif command == "center" then
        display:StopDrag()
        StimMeterDB.x, StimMeterDB.y = c.defaultX, c.defaultY
        display:Position()
    elseif command == "reset" then
        display.scalePreviewUntil = nil
        meter:Reset(now)
        movement:Reset()
    elseif command == "stats" then
        meter:Update(now)
        say(("Intensity %d%% | Activations %d | Longest streak %.1fs"):format(
            math.floor(meter.score), StimMeterDB.activations, StimMeterDB.longest))
    else
        say("/stim test [0-100], sound, scale [0.5-2], move, lock, center, reset, stats")
    end
    display:Render(meter, now)
end

driver:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        StimMeterDB = StimMeterDB or {}
        StimMeterDB.x = tonumber(StimMeterDB.x) or c.defaultX
        StimMeterDB.y = tonumber(StimMeterDB.y) or c.defaultY
        StimMeterDB.longest = tonumber(StimMeterDB.longest) or 0
        StimMeterDB.activations = tonumber(StimMeterDB.activations) or 0
        StimMeterDB.sound = StimMeterDB.sound == true
        local scale = tonumber(StimMeterDB.scale)
        StimMeterDB.scale = validScale(scale) and scale or c.defaultScale
        display:Init()
        meter:Reset(GetTime())
        movement:Reset()
        hooksecurefunc("JumpOrAscendStart", function()
            if not blocked() then movement:JumpPressed(GetTime()) end
        end)
        SLASH_STIMMETER1, SLASH_STIMMETER2 = "/stim", "/stimmeter"
        SlashCmdList.STIMMETER = slash
        self:UnregisterEvent("PLAYER_LOGIN")
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("PLAYER_REGEN_DISABLED")
        self:RegisterEvent("PLAYER_LOGOUT")
        self:SetScript("OnUpdate", update)
    elseif event == "PLAYER_LOGOUT" then
        meter:Update(GetTime())
        display:StopDrag()
    else
        movement:Reset()
        if event == "PLAYER_ENTERING_WORLD" then meter:Reset(GetTime()) end
    end
end)
