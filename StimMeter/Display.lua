local _, addon = ...
local c = addon.config
local display = {}
addon.display = display

function display:Init()
    local frame = CreateFrame("Frame", nil, UIParent)
    self.frame = frame
    frame:SetSize(360, 70)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(owner)
        owner:StartMoving()
        self.dragging = true
    end)
    frame:SetScript("OnDragStop", function() self:StopDrag() end)

    self.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    self.text:SetPoint("CENTER")
    self.font = self.text:GetFont()
    self.counter = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.counterFont = self.counter:GetFont()
    self.counter:SetPoint("TOP", self.text, "BOTTOM", 0, -3)
    frame:EnableMouse(false)
    self:Position()
    frame:Hide()
end

function display:StopDrag()
    if not self.dragging then return end
    self.frame:StopMovingOrSizing()
    self.dragging = false
    local x, y = self.frame:GetCenter()
    local centerX, centerY = UIParent:GetCenter()
    if x and centerX then StimMeterDB.x, StimMeterDB.y = x - centerX, y - centerY end
    self:Position()
end

function display:Position()
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", StimMeterDB.x, StimMeterDB.y)
end

function display:SetMoving(moving)
    if not moving then self:StopDrag() end
    self.moving = moving
    self.frame:EnableMouse(moving)
end

function display:Activate()
    local sound = StimMeterDB.sound and SOUNDKIT and SOUNDKIT[c.sound]
    if sound then PlaySound(sound) end
end

function display:Render(meter, now)
    local score = meter.score
    local active = meter.started
    local preview = self.scalePreviewUntil and now < self.scalePreviewUntil
    if (self.moving or preview) and score < c.bands[1].minimum then score = c.previewScore end
    if not active and score < c.bands[1].minimum then
        self.frame:Hide()
        return
    end

    local color, size, amplitude, label
    if active then
        local elapsed = now - active
        label, color, size, amplitude = "YOU'RE STIMMING!", c.modeColor, c.modeSize, c.modePulse
        self.counter:SetText(("%.1fs"):format(elapsed))
        self.counter:Show()
    else
        local band = c.bands[#c.bands]
        for i = #c.bands, 1, -1 do
            if score >= c.bands[i].minimum then band = c.bands[i]; break end
        end
        label = ("Stim: %d%%"):format(math.min(c.maximum - 1, math.floor(score)))
        color = band.color
        size = c.baseSize + c.sizeGrowth * score / c.maximum
        amplitude = band.pulse * score / c.maximum
        self.counter:Hide()
    end

    local scale = StimMeterDB.scale
    local fontSize = math.floor(size + 0.5) * scale
    if self.counterScale ~= scale then
        self.counter:SetFont(self.counterFont, c.counterSize * scale, "OUTLINE")
        self.counterScale = scale
    end
    if self.fontSize ~= fontSize then
        self.text:SetFont(self.font, fontSize, "OUTLINE")
        self.fontSize = fontSize
    end
    local brightness = 1
    if amplitude > 0 then
        brightness = 1 - amplitude * (1 - math.sin(now * c.pulseRate)) / 2
    end
    self.text:SetText(label)
    self.text:SetTextColor(color[1] * brightness, color[2] * brightness, color[3] * brightness)
    self.frame:Show()
end
