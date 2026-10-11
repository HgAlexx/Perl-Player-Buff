local _, ns = ...

-- Local namespace
local Const = {}

Const.defaultSettings = {
    enabled = true,
    hideBlizzardBuffFrame = true,
    offsetVertical = 0,
    offsetHorizontal = 0,
    spacingVertical = 1,
    spacingHorizontal = 1,
    scaling = 0.7,
    buffPerRow = 10,
    maxNumberOfRow = 4,
    showNativeCooldown = false,
    cooldownScale = 0.7,
    showOriginalTextTimer = true,
    showSecond = 2, -- 0 = hidden, 1 = show, 2 = show only under 10 minutes
    weaponBuff = true,
    anchorLocation = 1 -- 1 = BOTTOMLEFT, 2 = BOTTOMRIGHT, 3 = TOPLEFT, 4 = TOPRIGHT
}

-- Export
ns.Const = Const
