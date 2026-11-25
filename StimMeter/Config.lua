local _, addon = ...
addon.config = {
    maximum = 100,
    grace = 2,
    decay = 4,
    inactivity = 5,
    jump = 2,
    rotations = { 10, 25, 50 }, -- cumulative within one turn sequence
    strafe = 5, -- reserved for future detection
    circle = 8,
    multiplier = 1.5,
    turnDegrees = 357, -- tolerate a small undershoot, as in SimpleController: Spin
    turnPause = 0.65,
    sampleGap = 0.25,
    jumpWindow = 0.3,
    stationarySpeed = 0.1,
    bands = {
        { minimum = 20, color = { 0.3, 1, 0.4 }, pulse = 0 },
        { minimum = 40, color = { 1, 0.9, 0.2 }, pulse = 0 },
        { minimum = 60, color = { 1, 0.55, 0.15 }, pulse = 0.07 },
        { minimum = 80, color = { 1, 0.2, 0.2 }, pulse = 0.10 },
    },
    modeColor = { 1, 0.15, 0.15 },
    modePulse = 0.10,
    pulseRate = 3,
    baseSize = 17,
    sizeGrowth = 16,
    modeSize = 40,
    counterSize = 14,
    defaultX = 0,
    defaultY = -150,
    previewScore = 60,
    scalePreviewDuration = 3,
    defaultScale = 1,
    minScale = 0.5,
    maxScale = 2,
    sound = "IG_QUEST_LIST_COMPLETE",
}
