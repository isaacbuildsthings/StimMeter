-- Run from the repository root with lua tests/smoke.lua.
local now, combat, sounds = 0, false, 0
local airborne, facing, speed = false, 0, 0
local driver, jumpHook
local function noop() end

function GetTime() return now end
function InCombatLockdown() return combat end
UnitAffectingCombat = InCombatLockdown
function IsFlying() return false end
IsSwimming, IsMounted, UnitIsDeadOrGhost = IsFlying, IsFlying, IsFlying
function IsFalling() return airborne end
function GetPlayerFacing() return facing end
function GetUnitSpeed() return speed end
function hooksecurefunc(_, callback) jumpHook = callback end
function PlaySound() sounds = sounds + 1 end

UIParent, SlashCmdList = {}, {}
DEFAULT_CHAT_FRAME = { AddMessage = noop }
SOUNDKIT = { IG_QUEST_LIST_COMPLETE = 1 }

local methods = {}
function methods:SetScript(name, callback) self[name] = callback end
function methods:CreateFontString() return CreateFrame() end
function methods:GetFont() return "native" end
function methods:SetFont(_, size)
    self.fontSize = size
    self.fontChanges = (self.fontChanges or 0) + 1
end
function methods:SetPoint(...)
    self.point = { ... }
    self.anchorChanges = (self.anchorChanges or 0) + 1
end
function methods:SetText(label) self.label = label end
function methods:SetTextColor(...) self.color = table.concat({ ... }, ",") end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:EnableMouse(enabled) self.mouse = enabled end

for _, name in ipairs({
    "SetSize", "SetMovable", "SetClampedToScreen", "RegisterForDrag", "RegisterEvent",
    "UnregisterEvent", "ClearAllPoints",
}) do
    methods[name] = noop
end

function CreateFrame()
    local frame = setmetatable({}, { __index = methods })
    driver = driver or frame
    return frame
end

local function login()
    driver = nil
    local addon = {}
    for _, name in ipairs({ "Config", "Meter", "Movement", "Display", "Core" }) do
        assert(loadfile("StimMeter/" .. name .. ".lua"))("StimMeter", addon)
    end
    driver:OnEvent("PLAYER_LOGIN")
    driver:OnEvent("PLAYER_ENTERING_WORLD")
    return addon
end

StimMeterDB = { x = 34, y = -75, longest = 12, activations = 4 }
local addon = login()
local meter, hud = addon.meter, addon.display
local text, counter, frame = hud.text, hud.counter, hud.frame
local slash = SlashCmdList.STIMMETER

assert(StimMeterDB.scale == 1 and StimMeterDB.sound == false)
assert(StimMeterDB.longest == 12 and StimMeterDB.activations == 4)
assert(frame.point[4] == 34 and frame.point[5] == -75)

slash("test 19")
assert(not frame.shown)
for _, score in ipairs({ 20, 40, 60, 80, 100 }) do
    slash("test " .. score)
    local color, changes = text.color, text.fontChanges
    now = now + 0.5
    driver:OnUpdate()
    assert((color ~= text.color) == (score >= 60))
    assert(text.fontChanges == changes and text.anchorChanges == 1)
end
assert(sounds == 0 and counter.shown)
slash("sound")
slash("test")
assert(sounds == 1)
local started, deadline = meter.started, meter.deadline
slash("scale 2")
assert(text.fontSize == 80 and counter.fontSize == 28)
assert(meter.started == started and meter.deadline == deadline and sounds == 1)
assert(frame.anchorChanges == 1 and StimMeterDB.x == 34 and StimMeterDB.y == -75)
now = deadline + 0.5
driver:OnUpdate()
assert(meter.score == 98 and not counter.shown and sounds == 1)

slash("reset")
slash("scale 0.5")
assert(frame.shown and meter.score == 0 and not frame.mouse)
assert(counter.fontSize == 7)
slash("scale 0.49")
slash("scale 2.01")
slash("scale invalid")
slash("scale")
assert(StimMeterDB.scale == 0.5)
now = now + 3
driver:OnUpdate()
assert(not frame.shown and meter.score == 0)
slash("unlock")
assert(frame.shown and frame.mouse)
slash("lock")
assert(not frame.shown and not frame.mouse)
assert(StimMeterDB.longest == 12 and StimMeterDB.activations == 4)

addon = login()
meter, slash = addon.meter, SlashCmdList.STIMMETER
assert(StimMeterDB.sound and StimMeterDB.scale == 0.5)
assert(addon.display.frame.point[4] == 34 and addon.display.frame.point[5] == -75)
slash("sound")
slash("test")
assert(sounds == 1)
slash("reset")
combat = true
jumpHook()
airborne = true
driver:OnUpdate()
assert(meter.score == 0)

combat, airborne = false, false
driver:OnUpdate()
jumpHook()
airborne = true
now = now + 0.05
driver:OnUpdate()
assert(meter.score == 2)
for i = 1, 12 do
    now = now + 0.05
    facing = math.rad((i * 30) % 360)
    driver:OnUpdate()
end
assert(meter.score == 18)
slash("reset")
airborne = false
driver:OnUpdate()
for i = 1, 36 do
    now = now + 0.05
    facing = math.rad((i * 30) % 360)
    driver:OnUpdate()
    if i == 12 then assert(meter.score == 10) end
    if i == 24 then assert(meter.score == 25) end
end
assert(meter.score == 50)
speed = 7
for i = 1, 12 do
    now = now + 0.05
    facing = math.rad((i * 30) % 360)
    driver:OnUpdate()
end
assert(meter.score == 50)
local lastAward = now - 0.6
meter:Update(lastAward + 3)
assert(math.abs(meter.score - 46) < 0.001)

meter:Reset(30)
assert(meter:Add(100, 30))
assert(not meter:Add(2, 34))
meter:Update(39.5)
assert(not meter.started and meter.score == 98)
assert(StimMeterDB.activations == 5)
print("StimMeter smoke tests passed.")
