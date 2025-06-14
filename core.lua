--[[
    Originally created by Global, current author of Perl Classic Units Frame

    Perl Player Buff is now maintained by Leliel AKA :
    - mZHg at curseforge.com

    Thanks to sigg for his tutorial on SecureAura Template
    https://www.wowinterface.com/forums/showthread.php?t=36117

    Also Thanks to:
    - https://wow.gamepedia.com
    - https://wowwiki.fandom.com
    - https://github.com/tomrus88/BlizzardInterfaceCode
--]]

local addonName, ns = ...

-- Imports
local Utility = ns.Utility
local Const = ns.Const

-- removed in wow api >= 10.0.0
local BUFF_FLASH_TIME_ON = BUFF_FLASH_TIME_ON or 0.75
local BUFF_FLASH_TIME_OFF = BUFF_FLASH_TIME_OFF or 0.75
local BUFF_MIN_ALPHA = BUFF_MIN_ALPHA or 0.3

local C_UnitAuras_UnitAura = nil
if UnitAura then
    -- removed in wow api >= 10.2.5
    C_UnitAuras_UnitAura = UnitAura
else
    C_UnitAuras_UnitAura = function(unitToken, index, filter)
        local auraData = C_UnitAuras.GetAuraDataByIndex(unitToken, index, filter);
        if not auraData then
            return nil;
        end
        -- Old names and order: name, icon, count, dType, duration, eTime
        return auraData.name, auraData.icon, auraData.applications, auraData.dispelName, auraData.duration, auraData.expirationTime
    end
end

-- Local namespace
local Core = {}

Core.initialized = false
Core.auraTextHeight = 15
Core.debuffBaseVerticalOffset = 0 -- vertical spacing between buff and debuff frames
Core.buffBaseVerticalOffset = 0 -- vertical spacing between buff and perl frames
Core.auraWidth = 30
Core.playerClass = nil
Core.specialBar = nil
Core.currentScale = 1

Core.BuffFrameFlashTime = 0
Core.BuffFrameFlashState = 1
Core.BuffAlphaValue = 1

Core.Buffs = nil
Core.Debuffs = nil
Core.FixAnchor = nil
Core.BuffFrame = nil

Core.WeaponBuffs = {}

local PPB = CreateFrame("Frame")
Core.PPB = PPB

PPB:SetScript("OnEvent", function(self, event, ...)
    if self[event] then
        return self[event](self, event, ...)
    end
end)
PPB:SetScript("OnUpdate", function(self, elapsed)
    Core:Update(elapsed)
end)


function PPB:ADDON_LOADED(event, addon)
    if addon:lower() ~= "perl_player_buff" then
        return
    end
    self:UnregisterEvent("ADDON_LOADED")

    if C_AddOns and C_AddOns.GetAddOnMetadata then
        Core.Version = C_AddOns.GetAddOnMetadata(addonName, 'Version');
    else
        Core.Version = GetAddOnMetadata(addonName, 'Version');
    end

    -- load saved variables
    Perl_Player_Buff_Settings = setmetatable(Perl_Player_Buff_Settings or {}, { __index = Const.defaultSettings })
    Core.settings = Perl_Player_Buff_Settings


    self.ADDON_LOADED = nil

    if IsLoggedIn() then
        self:PLAYER_LOGIN()
    else
        self:RegisterEvent("PLAYER_LOGIN")
    end
end

function PPB:PLAYER_LOGIN()
    self:UnregisterEvent("PLAYER_LOGIN")

    self:RegisterEvent("PLAYER_LOGOUT")

    self.PLAYER_LOGIN = nil

    _, Core.playerClass = UnitClass("player");


    Core:SpecialBarOffset()

    Core:CreateFrames()


    Core.initialized = true

    Core:UpdateEnabled()

    ---- TODO: move into enabled handler
    --if Core.settings.enabled and BuffFrame then
    --    -- BuffFrame:UnregisterAllEvents()
    --    BuffFrame:UnregisterEvent("UNIT_AURA")
    --    BuffFrame:Hide()
    --end

    Utility.Print(Core.Version, "Loaded!")
end

function PPB:PLAYER_LOGOUT()
    --
end

function PPB:PLAYER_TOTEM_UPDATE()
    -- Here we might need to adjust main anchor for totem bar
    Core:SetPointFixAnchor()
end

function PPB:ACTIVE_TALENT_GROUP_CHANGED()
    -- Here we might need to adjust main anchor for special bar
    Core:SetPointFixAnchor()
end

--[[
    Update layout functions
--]]
function Core:UpdateEnabled()
    if Core.settings.enabled then
        if Core.FixAnchor and not Core.FixAnchor:IsShown() then
            Core.FixAnchor:Show()
        end
        if BuffFrame then
            -- BuffFrame:UnregisterAllEvents()
            BuffFrame:UnregisterEvent("UNIT_AURA")
            BuffFrame:Hide()
        end
        if DebuffFrame then
            -- DebuffFrame:UnregisterAllEvents()
            DebuffFrame:UnregisterEvent("UNIT_AURA")
            DebuffFrame:Hide()
        end
    else
        if Core.FixAnchor and Core.FixAnchor:IsShown() then
            Core.FixAnchor:Hide()
        end
        if BuffFrame then
            BuffFrame:Show()
            BuffFrame:RegisterEvent("UNIT_AURA")
        end
        if DebuffFrame then
            DebuffFrame:Show()
            DebuffFrame:RegisterEvent("UNIT_AURA")
        end
    end
end

function Core:UpdateWeaponBuff()
    if not InCombatLockdown() then
        if Core.settings.enabled and Core.settings.weaponBuff then
            if Core.Buffs then
                Core.Buffs:SetAttribute("includeWeapons", 1)
            end
            if TemporaryEnchantFrame then
                TemporaryEnchantFrame:Hide()
            end
        else
            if Core.Buffs then
                Core:HideAllWeaponBuffs()
                Core.Buffs:SetAttribute("includeWeapons", 0)
            end
            if TemporaryEnchantFrame then
                TemporaryEnchantFrame:Show()
            end
        end
    end
end

--[[
    Settings setters
--]]

function Core:SettingsCanSet()
    if InCombatLockdown() then
        Utility.Print("Unable to change settings in combat!")
        do
            return false
        end
    else
        return true
    end
end

function Core:ChangeSettings_Enabled(value)
    if Core:SettingsCanSet() then
        if (type(value) == "boolean") then
            Core.settings.enabled = value
            Core:UpdateEnabled()
            Core:UpdateWeaponBuff()
        end
    end
end

function Core:ChangeSettings_WeaponBuff(value)
    if Core:SettingsCanSet() then
        if (type(value) == "boolean") then
            Core.settings.weaponBuff = value
            Core:UpdateWeaponBuff()
        end
    end
end

function Core:ChangeSettings_OffsetVertical(value)
    if Core:SettingsCanSet() then
        if value and (type(value) == "number") then
            Core.settings.offsetVertical = value
            Core:SetPointFixAnchor()
        end
    end
end

function Core:ChangeSettings_OffsetHorizontal(value)
    if Core:SettingsCanSet() then
        if value and (type(value) == "number") then
            Core.settings.offsetHorizontal = value
            Core:SetPointFixAnchor()
        end
    end
end

function Core:ChangeSettings_SpacingHorizontal(value)
    if Core:SettingsCanSet() then
        if value and (type(value) == "number") then
            Core.settings.spacingHorizontal = value
            Core:SetHeaderAttribute_xOffset(Core.Buffs)
            Core:SetHeaderAttribute_xOffset(Core.Debuffs)
        end
    end
end

function Core:ChangeSettings_SpacingVertical(value)
    if Core:SettingsCanSet() then
        if value and (type(value) == "number") then
            Core.settings.spacingVertical = value
            Core:SetHeaderAttribute_wrapYOffset(Core.Buffs)
            Core:SetHeaderAttribute_wrapYOffset(Core.Debuffs)
        end
    end
end

function Core:ChangeSettings_Scaling(value)
    if Core:SettingsCanSet() then
        if value and (type(value) == "number") then
            Core.settings.scaling = value
            Core:SetBuffScale()
        end
    end
end

function Core:ChangeSettings_BuffPerRow(value)
    if Core:SettingsCanSet() then
        if value and (type(value) == "number") then
            Core.settings.buffPerRow = value
            Core:SetHeaderAttribute_wrapAfter(Core.Buffs)
            Core:SetHeaderAttribute_wrapAfter(Core.Debuffs)
        end
    end
end

function Core:ChangeSettings_MaxNumberOfRow(value)
    if Core:SettingsCanSet() then
        if value and (type(value) == "number") then
            Core.settings.maxNumberOfRow = value
            Core:SetHeaderAttribute_maxWraps(Core.Buffs)
            Core:SetHeaderAttribute_maxWraps(Core.Debuffs)
        end
    end
end

function Core:ChangeSettings_ShowNativeCooldown(value)
    if Core:SettingsCanSet() then
        if (type(value) == "boolean") then
            Core.settings.showNativeCooldown = value
            -- no update function for this setting
        end
    end
end

function Core:ChangeSettings_ShowOriginalTextTimer(value)
    if Core:SettingsCanSet() then
        if (type(value) == "boolean") then
            Core.settings.showOriginalTextTimer = value
            Core:SetFramesPoints()
            Core:SetHeaderAttribute_wrapYOffset(Core.Buffs)
            Core:SetHeaderAttribute_wrapYOffset(Core.Debuffs)
        end
    end
end

function Core:ChangeSettings_ShowSecond(value)
    if Core:SettingsCanSet() then
        if value and (type(value) == "number") then
            Core.settings.showSecond = value
            -- no update function for this setting
        end
    end
end

function Core:ChangeSettings_AnchorLocation(value)
    if Core:SettingsCanSet() then
        if value and (type(value) == "number") then
            Core.settings.anchorLocation = value
            Core:SetFramesPoints()
            Core:SetHeaderAttributeBuffs()
            Core:SetHeaderAttributeDebuffs()
        end
    end
end

function Core:SlashHandler(message, editbox)
    local _, _, cmd, args = string.find(message, "%s?(%w+)%s?(.*)")

    local i

    if cmd == "enabled" then
        i = tonumber(args or Const.defaultSettings.enabled)
        local b = (i == 1)
        self:ChangeSettings_Enabled(b)

    elseif cmd == "offsetVertical" then
        i = tonumber(args or Const.defaultSettings.offsetVertical)
        i = math.floor(i)
        self:ChangeSettings_OffsetVertical(i)

    elseif cmd == "offsetHorizontal" then
        i = tonumber(args or Const.defaultSettings.offsetHorizontal)
        i = math.floor(i)
        self:ChangeSettings_OffsetHorizontal(i)

    elseif cmd == "spacingHorizontal" then
        i = tonumber(args or Const.defaultSettings.spacingHorizontal)
        i = math.floor(i)
        self:ChangeSettings_SpacingHorizontal(i)

    elseif cmd == "spacingVertical" then
        i = tonumber(args or Const.defaultSettings.spacingVertical)
        i = math.floor(i)
        self:ChangeSettings_SpacingVertical(i)

    elseif cmd == "buffPerRow" then
        i = tonumber(args or Const.defaultSettings.buffPerRow)
        i = math.floor(i)
        self:ChangeSettings_BuffPerRow(i)

    elseif cmd == "maxNumberOfRow" then
        i = tonumber(args or Const.defaultSettings.maxNumberOfRow)
        i = math.floor(i)
        self:ChangeSettings_MaxNumberOfRow(i)

    elseif cmd == "showNativeCooldown" then
        i = tonumber(args or 0)
        local b = (i == 1)
        self:ChangeSettings_ShowNativeCooldown(b)

    elseif cmd == "showOriginalTextTimer" then
        i = tonumber(args or 1)
        local b = (i == 1)
        self:ChangeSettings_ShowOriginalTextTimer(b)

    elseif cmd == "showSecond" then
        i = tonumber(args or Const.defaultSettings.showSecond)
        if (i == 0) or (i == 1) or (i == 2) then
            self:ChangeSettings_ShowSecond(i)
        end
    elseif cmd == "scaling" then
        i = tonumber(args or Const.defaultSettings.scaling * 100)
        if i > 0 and i <= 100 then
            i = math.floor(i) / 100
            self:ChangeSettings_Scaling(i)
        end
    else
        Utility.Print("Usage: /ppb command <value>")
        Utility.Print("/ppb enabled: 1 = enabled, 0 = disabled")
        Utility.Print("/ppb showNativeCooldown: 1 = enabled, 0 = disabled")
        Utility.Print("/ppb showOriginalTextTimer: 1 = enabled, 0 = disabled")
        Utility.Print("/ppb showSecond: 0 = hide, 1 = show, 2 = show only under 10 minutes")
        Utility.Print("/ppb weaponBuff: 1 = enabled, 0 = disabled")
        Utility.Print("/ppb offsetVertical: any number")
        Utility.Print("/ppb offsetHorizontal: any number")
        Utility.Print("/ppb spacingVertical: any number")
        Utility.Print("/ppb spacingHorizontal: any number")
        Utility.Print("/ppb scaling: from 10 to 200 (%)")
        Utility.Print("/ppb buffPerRow: from 1 to 40")
        Utility.Print("/ppb maxNumberOfRow: from 1 to 40")
        Utility.Print("If value is omitted, reset to default")
    end
end
SLASH_PPB1 = "/ppb"
SlashCmdList["PPB"] = function(message, editbox)
    Core:SlashHandler(message, editbox)
end

function Core:SpecBarYOffSet(frame, yOffset)
    --[[
    check if the special bar is:
    - not nil
    - visible
    - anchor to Perl_Player_Frame
    - in visible screen zone ( y < UIParent.Height ) (Perl Player move the bar outside screen to hide it)
    --]]
    if frame and frame:IsVisible() and frame:GetParent():GetName() == "Perl_Player_Frame" and math.abs(select(4, frame:GetPoint())) < UIParent:GetHeight() then
        yOffset = yOffset - (frame:GetHeight());
    end
    return yOffset;
end

Core.Original_Perl_Player_Set_Show_Class_Resource_Frame = nil
Core.PPB_Perl_Player_Set_Show_Class_Resource_Frame = function(newvalue)
    Core.Original_Perl_Player_Set_Show_Class_Resource_Frame(newvalue);
    if not Utility.IsClassic and (Core.playerClass == "SHAMAN") then
        if (newvalue == 1) then
            PPB:RegisterEvent("PLAYER_TOTEM_UPDATE");
        else
            PPB:UnregisterEvent("PLAYER_TOTEM_UPDATE");
        end;
    end;
    Core:SetPointFixAnchor()
end

function Core:SpecialBarOffset()
    local WatchSpec = false;

    if Core.playerClass == "PALADIN" then -- Paladin Power Bar
        Core.specialBar = PaladinPowerBarFrame;
        WatchSpec = true;
    elseif Core.playerClass == "WARLOCK" then -- Shard Bar
        Core.specialBar = WarlockPowerFrame;
        WatchSpec = true;
    elseif Core.playerClass == "DRUID" then -- Eclipse Bar
        Core.specialBar = EclipseBarFrame;
        WatchSpec = true;
    elseif Core.playerClass == "SHAMAN" then -- Totem Timer
        Core.specialBar = TotemFrame;
        WatchSpec = true;
        local Perl_Player_Vars = Perl_Player_GetVars();
        if not Utility.IsClassic and PPB and Perl_Player_Vars and Perl_Player_Vars["totemtimers"] == 1 then
            PPB:RegisterEvent("PLAYER_TOTEM_UPDATE"); -- handle totem bar show/hide
        end;
    elseif Core.playerClass == "DEATHKNIGHT" then -- Rune Frame
        Core.specialBar = RuneFrame;
        WatchSpec = true;
    elseif Core.playerClass == "PRIEST" then -- Priest Frame
        Core.specialBar = PriestBarFrame;
        WatchSpec = true;
    elseif Core.playerClass == "MONK" then -- Harmony Frame
        Core.specialBar = MonkHarmonyBarFrame;
        WatchSpec = true;
    elseif Core.playerClass == "MAGE" then -- Arcane Frame
        Core.specialBar = MageArcaneChargesFrame;
        WatchSpec = true;
    else
        Core.specialBar = nil;
    end;

    if Core.specialBar ~= nil then
        Core.Original_Perl_Player_Set_Show_Class_Resource_Frame = Perl_Player_Set_Show_Class_Resource_Frame;
        Perl_Player_Set_Show_Class_Resource_Frame = Core.PPB_Perl_Player_Set_Show_Class_Resource_Frame;
    end;

    if WatchSpec then
        if Utility.IsRetail or Utility.IsWLK or Utility.IsCataclysm then
            PPB:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
        end
    end
end

function Core:SetBuffScale()
    if not Core.BuffFrame then
        return
    end

    local currentScale = 1 - UIParent:GetEffectiveScale() + Core.settings.scaling;    -- run it through the scaling formula introduced in 1.9
    Core.BuffFrame:SetScale(currentScale)
end

function Core:SetHeaderAttributeBuffs()
    if Core.Buffs then
        Core:SetHeaderAttribute(Core.Buffs, "HELPFUL", "PPB_BuffButtonTemplate")
    end
end
function Core:SetHeaderAttributeDebuffs()
    if Core.Debuffs then
        Core:SetHeaderAttribute(Core.Debuffs, "HARMFUL", "PPB_DebuffButtonTemplate")
    end
end

function Core:CreateFrames()
    Core.FixAnchor = CreateFrame("Frame", nil, Perl_Player_Frame)
    Core.FixAnchor:SetSize(1, 1)

    Core.BuffFrame = CreateFrame("Frame", nil, Core.FixAnchor)
    Core.BuffFrame:SetSize(1, 1)

    Core.Buffs = CreateFrame("Frame", nil, Core.BuffFrame, "SecureAuraHeaderTemplate")

    Core.Debuffs = CreateFrame("frame", nil, Core.BuffFrame, "SecureAuraHeaderTemplate")

    -- update all anchors
    Core:SetFramesPoints()

    Core:SetBuffScale()

    Core.FixAnchor:Show()
    Core.BuffFrame:Show()

    Core:SetHeaderAttributeBuffs()
    Core:UpdateWeaponBuff() -- set weapon attributes if needed
    Core.Buffs:HookScript("OnAttributeChanged", Core.HeaderAttributeChanged)
    Core.Buffs:Show()

    Core:SetHeaderAttributeDebuffs()
    Core.Debuffs:HookScript("OnAttributeChanged", Core.HeaderAttributeChanged)
    Core.Debuffs:Show()
end

function Core:SetPointFixAnchor()
    local fixAnchorParent
    local fixAnchorPoint
    local fixAnchorParentPoint

    -- BOTTOMLEFT
    if Core.settings.anchorLocation == 1 then
        fixAnchorParent = Perl_Player_StatsFrame
        fixAnchorPoint = "TOPLEFT"
        fixAnchorParentPoint = "BOTTOMLEFT"
    end

    -- BOTTOMRIGHT
    if Core.settings.anchorLocation == 2 then
        fixAnchorParent = Perl_Player_StatsFrame
        fixAnchorPoint = "TOPRIGHT"
        fixAnchorParentPoint = "BOTTOMRIGHT"
    end

    -- TOPLEFT
    if Core.settings.anchorLocation == 3 then
        fixAnchorParent = Perl_Player_Frame
        fixAnchorPoint = "BOTTOMLEFT"
        fixAnchorParentPoint = "TOPLEFT"
    end

    -- TOPRIGHT
    if Core.settings.anchorLocation == 4 then
        fixAnchorParent = Perl_Player_Frame
        fixAnchorPoint = "BOTTOMRIGHT"
        fixAnchorParentPoint = "TOPRIGHT"
    end

    Core.FixAnchor:ClearAllPoints()
    Core.FixAnchor:SetPoint(fixAnchorPoint, fixAnchorParent, fixAnchorParentPoint, Core.settings.offsetHorizontal, Core.settings.offsetVertical)
end

function Core:SetPointBuffFrame()
    local buffFrameAnchorPoint
    local buffFrameAnchorParentPoint

    -- BOTTOMLEFT
    if Core.settings.anchorLocation == 1 then
        buffFrameAnchorPoint = "TOPLEFT"
        buffFrameAnchorParentPoint = "TOPLEFT"
    end

    -- BOTTOMRIGHT
    if Core.settings.anchorLocation == 2 then
        buffFrameAnchorPoint = "TOPRIGHT"
        buffFrameAnchorParentPoint = "TOPRIGHT"
    end

    -- TOPLEFT
    if Core.settings.anchorLocation == 3 then
        buffFrameAnchorPoint = "BOTTOMLEFT"
        buffFrameAnchorParentPoint = "BOTTOMLEFT"
    end

    -- TOPRIGHT
    if Core.settings.anchorLocation == 4 then
        buffFrameAnchorPoint = "BOTTOMRIGHT"
        buffFrameAnchorParentPoint = "BOTTOMRIGHT"
    end

    Core.BuffFrame:ClearAllPoints()
    Core.BuffFrame:SetPoint(buffFrameAnchorPoint, Core.FixAnchor, buffFrameAnchorParentPoint, 0, 0)
end

function Core:SetPointBuffs()
    local buffsAnchorPoint
    local buffsAnchorParentPoint
    local buffsOffsetVertical

    -- BOTTOMLEFT
    if Core.settings.anchorLocation == 1 then
        buffsAnchorPoint = "TOPLEFT"
        buffsAnchorParentPoint = "TOPLEFT"
        buffsOffsetVertical = 0
    end

    -- BOTTOMRIGHT
    if Core.settings.anchorLocation == 2 then
        buffsAnchorPoint = "TOPRIGHT"
        buffsAnchorParentPoint = "TOPRIGHT"
        buffsOffsetVertical = 0
    end

    -- TOPLEFT
    if Core.settings.anchorLocation == 3 then
        buffsAnchorPoint = "BOTTOMLEFT"
        buffsAnchorParentPoint = "BOTTOMLEFT"
        buffsOffsetVertical = Core.buffBaseVerticalOffset
        if Core.settings.showOriginalTextTimer then
            buffsOffsetVertical = Core.auraTextHeight
        end
    end

    -- TOPRIGHT
    if Core.settings.anchorLocation == 4 then
        buffsAnchorPoint = "BOTTOMRIGHT"
        buffsAnchorParentPoint = "BOTTOMRIGHT"
        buffsOffsetVertical = Core.buffBaseVerticalOffset
        if Core.settings.showOriginalTextTimer then
            buffsOffsetVertical = Core.auraTextHeight
        end
    end

    Core.Buffs:ClearAllPoints()
    Core.Buffs:SetPoint(buffsAnchorPoint, Core.BuffFrame, buffsAnchorParentPoint, 0, buffsOffsetVertical)
end

function Core:SetPointDebuffs()
    local debuffsAnchorPoint
    local debuffsAnchorParentPoint
    local debuffsOffsetVertical

    -- BOTTOMLEFT
    if Core.settings.anchorLocation == 1 then
        debuffsAnchorPoint = "TOPLEFT"
        debuffsAnchorParentPoint = "BOTTOMLEFT"

        debuffsOffsetVertical = -Core.debuffBaseVerticalOffset
        if Core.settings.showOriginalTextTimer then
            debuffsOffsetVertical = -Core.auraTextHeight
        end
    end

    -- BOTTOMRIGHT
    if Core.settings.anchorLocation == 2 then
        debuffsAnchorPoint = "TOPRIGHT"
        debuffsAnchorParentPoint = "BOTTOMRIGHT"

        debuffsOffsetVertical = -Core.debuffBaseVerticalOffset
        if Core.settings.showOriginalTextTimer then
            debuffsOffsetVertical = -Core.auraTextHeight
        end
    end

    -- TOPLEFT
    if Core.settings.anchorLocation == 3 then
        debuffsAnchorPoint = "BOTTOMLEFT"
        debuffsAnchorParentPoint = "TOPLEFT"
        debuffsOffsetVertical = Core.debuffBaseVerticalOffset
        if Core.settings.showOriginalTextTimer then
            debuffsOffsetVertical = Core.auraTextHeight
        end
    end

    -- TOPRIGHT
    if Core.settings.anchorLocation == 4 then
        debuffsAnchorPoint = "BOTTOMRIGHT"
        debuffsAnchorParentPoint = "TOPRIGHT"
        debuffsOffsetVertical = Core.debuffBaseVerticalOffset
        if Core.settings.showOriginalTextTimer then
            debuffsOffsetVertical = Core.auraTextHeight
        end
    end

    Core.Debuffs:ClearAllPoints()
    Core.Debuffs:SetPoint(debuffsAnchorPoint, Core.Buffs, debuffsAnchorParentPoint, 0, debuffsOffsetVertical)
end

function Core:SetFramesPoints()
    Core:SetPointFixAnchor()
    Core:SetPointBuffFrame()
    Core:SetPointBuffs()
    Core:SetPointDebuffs()
end

function Core:HideAllWeaponBuffs()
    for i = 1, 3 do
        local child = Core.Buffs:GetAttribute("tempEnchant" .. i)
        if child and child:IsShown() then
            Core:SetTimeleftText(child, 0)
            Core:SetCoolDown(child, 0, 0)
            Core:SetAuraAlpha(child, BUFF_WARNING_TIME + 1)
            child:Hide()
        end
    end
end

function Core:HeaderAttributeChanged(name, data)
    if name and data then
        if string.match(name, "^child") then
            local child = data
            if child:IsShown() then
                child.filter = self.filter
                child:SetScript("OnAttributeChanged", function(self, attribute, value)
                    if attribute == "index" then
                        if self.filter == "HELPFUL" then
                            Core:UpdateBuff(self, value)
                        elseif self.filter == "HARMFUL" then
                            Core:UpdateDebuff(self, value)
                        end
                    end
                end)
                child:SetScript("OnUpdate", function(self, elapsed)
                    Core:UpdateTime(self, elapsed)
                end)
            end
        elseif string.match(name, "^tempenchant") then
            local child = data
            if child:IsShown() then
                child.filter = "TEMP"
                child:SetScript("OnAttributeChanged", function(self, attribute, value)
                    if attribute == "target-slot" then
                        Core:UpdateTempEnchant(self, value)
                        if Utility.IsClassic then
                            self.updateRequired = Utility.GetTime()
                        end
                    end
                end)
                child:SetScript("OnUpdate", function(self, elapsed)
                    Core:UpdateTime(self, elapsed)
                end)
            end
        elseif name == "includeWeapons" and data == 0 then
            Core:HideAllWeaponBuffs()
        end
    end
end

function Core:UpdateBuff(child, index)
    local name, icon, count, dType, duration, eTime = C_UnitAuras_UnitAura("player", child:GetID(), child.filter)
    if name then
        Core:UpdateAura(child, name, icon, count, duration, eTime)
    end
end

function Core:GetWeaponBuffInfo(id, expiration)
    local d = (expiration / 1000)
    if not Core.WeaponBuffs[id] then
        local n = GetSpellInfo(id)
        Core.WeaponBuffs[id] = {
            name = n,
            duration = d
        }
    end
    -- store the greatest duration
    if Core.WeaponBuffs[id].duration < d then
        Core.WeaponBuffs[id].duration = d
    end

    return Core.WeaponBuffs[id]
end

function Core:UpdateTempEnchant(child, slotid)
    local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantId = GetWeaponEnchantInfo()

    local duration = 0
    local name, icon, count, eTime = nil, nil, 0, 0
    if (slotid == 16) and hasMainHandEnchant then
        local buffInfo = Core:GetWeaponBuffInfo(mainHandEnchantID, mainHandExpiration)
        name = buffInfo.name
        icon = GetInventoryItemTexture("player", slotid)
        count = mainHandCharges or 0
        duration = buffInfo.duration
        eTime = (Utility.GetTime() + (mainHandExpiration / 1000)) or 0
    elseif (slotid == 17) and hasOffHandEnchant then
        local buffInfo = Core:GetWeaponBuffInfo(offHandEnchantId, offHandExpiration)
        name = buffInfo.name
        icon = GetInventoryItemTexture("player", slotid)
        count = offHandCharges or 0
        duration = buffInfo.duration
        eTime = (Utility.GetTime() + (offHandExpiration / 1000)) or 0
    end

    if icon then
        Core:UpdateAura(child, name, icon, count, duration, eTime)
    end
end

function Core:UpdateDebuff(child, index)
    local name, icon, count, dType, duration, eTime = C_UnitAuras_UnitAura("player", child:GetID(), child.filter)
    if name then
        Core:UpdateAura(child, name, icon, count, duration, eTime)
        -- Set color of debuff border based on dispel class.
        local debuffSlot = child.Border -- _G[child:GetName().."Border"]
        local color = DebuffTypeColor["none"]
        if ( debuffSlot ) then
            if ( dType ) then
                color = DebuffTypeColor[dType];
                if ( ENABLE_COLORBLIND_MODE == "1" ) then
                    child.symbol:Show();
                    child.symbol:SetText(DebuffTypeSymbol[debuffType] or "")
                else
                    child.symbol:Hide()
                end
            else
                child.symbol:Hide()
                color = DebuffTypeColor["none"]
            end
            debuffSlot:SetVertexColor(color.r, color.g, color.b)
        else
            color = DebuffTypeColor["none"]
            debuffSlot:SetVertexColor(color.r, color.g, color.b)
        end
    end
end

function Core:UpdateAura(child, name, icon, count, duration, eTime)
    local currentTime = Utility.GetTime()
    child.lastUpdate = currentTime
    local ic = child.Icon -- _G[child:GetName().."Icon"]
    if ic then
        ic:SetTexture(icon)
        ic:Show()
    end
    Core:SetCountText(child, count)
    child.buffName = name
    if not child.buffDuration or child.buffDuration < duration then
        child.buffDuration = duration
    end
    child.eTime = eTime or 0
    local timeLeft = child.eTime - currentTime
    child.timeLeft = timeLeft
    if Core.settings.showOriginalTextTimer then
        Core:SetTimeleftText(child, timeLeft)
    else
        Core:SetTimeleftText(child, 0)
    end
    if Core.settings.showNativeCooldown then
        Core:SetCoolDown(child, 0, 0)
        Core:SetCoolDown(child, eTime, duration)
    else
        Core:SetCoolDown(child, 0, 0)
    end
    Core:SetAuraAlpha(child, timeLeft)
end

function Core:UpdateTime(child, elapsed)
    local currentTime = Utility.GetTime()
    if Utility.IsClassic then
        if child.filter == "TEMP" and child.updateRequired then
            if child.updateRequired + 1 < currentTime then
                Core:UpdateTempEnchant(child, child:GetAttribute("target-slot"))
                child.updateRequired = currentTime
            end
        end
    end

    if child.eTime then
        local timeLeft = child.eTime - currentTime
        child.timeLeft = timeLeft

        child.lastUpdate = child.lastUpdate or 0
        if child.lastUpdate + 0.1 > currentTime then
            return -- save some cpu time
        end

        if Core.settings.showOriginalTextTimer then
            Core:SetTimeleftText(child, timeLeft)
        else
            Core:SetTimeleftText(child, 0)
        end
        if Core.settings.showNativeCooldown then
            Core:SetCoolDown(child, child.eTime, child.buffDuration)
        else
            Core:SetCoolDown(child, 0, 0)
        end
        Core:SetAuraAlpha(child, timeLeft)

        child.lastUpdate = currentTime
    end
end

function Core:SetHeaderAttribute_point(frame)
    if Core.settings.anchorLocation == 1 then
        frame:SetAttribute("point", "TOPLEFT");
    end
    if Core.settings.anchorLocation == 2 then
        frame:SetAttribute("point", "TOPRIGHT");
    end
    if Core.settings.anchorLocation == 3 then
        frame:SetAttribute("point", "BOTTOMLEFT");
    end
    if Core.settings.anchorLocation == 4 then
        frame:SetAttribute("point", "BOTTOMRIGHT");
    end
end

function Core:SetHeaderAttribute_xOffset(frame)
    local xOffset = Core.auraWidth + Core.settings.spacingHorizontal

    if Core.settings.anchorLocation == 1 then
        frame:SetAttribute("xOffset", xOffset);
    end
    if Core.settings.anchorLocation == 2 then
        frame:SetAttribute("xOffset", -xOffset);
    end
    if Core.settings.anchorLocation == 3 then
        frame:SetAttribute("xOffset", xOffset);
    end
    if Core.settings.anchorLocation == 4 then
        frame:SetAttribute("xOffset", -xOffset);
    end
end
function Core:SetHeaderAttribute_yOffset(frame)
    frame:SetAttribute("yOffset", 0);
end
function Core:SetHeaderAttribute_wrapXOffset(frame)
    if Core.settings.anchorLocation == 1 then
        frame:SetAttribute("wrapXOffset", 0);
    end
    if Core.settings.anchorLocation == 2 then
        frame:SetAttribute("wrapXOffset", 0);
    end
    if Core.settings.anchorLocation == 3 then
        frame:SetAttribute("wrapXOffset", 0);
    end
    if Core.settings.anchorLocation == 4 then
        frame:SetAttribute("wrapXOffset", 0);
    end
end
function Core:SetHeaderAttribute_wrapYOffset(frame)
    local wrapYOffset = Core.auraWidth + Core.settings.spacingVertical -- aura are square

    if Core.settings.showOriginalTextTimer then
        wrapYOffset = wrapYOffset + Core.auraTextHeight
    end

    if Core.settings.anchorLocation == 1 then
        frame:SetAttribute("wrapYOffset", -wrapYOffset)
    end
    if Core.settings.anchorLocation == 2 then
        frame:SetAttribute("wrapYOffset", -wrapYOffset)
    end
    if Core.settings.anchorLocation == 3 then
        frame:SetAttribute("wrapYOffset", wrapYOffset)
    end
    if Core.settings.anchorLocation == 4 then
        frame:SetAttribute("wrapYOffset", wrapYOffset)
    end
end
function Core:SetHeaderAttribute_wrapAfter(frame)
    frame:SetAttribute("wrapAfter", Core.settings.buffPerRow);
end
function Core:SetHeaderAttribute_maxWraps(frame)
    frame:SetAttribute("maxWraps", Core.settings.maxNumberOfRow);
end

function Core:SetHeaderAttribute(frame, filter, template)
    frame.filter = filter
    frame:SetAttribute("unit", "player")
    frame:SetAttribute("template", template)

    if filter == "HELPFUL" then
        frame:SetAttribute("weaponTemplate", "PPB_TempEnchantButtonTemplate")
    end

    frame:SetAttribute("filter", filter);
    frame:SetAttribute("minWidth", 0.1);
    frame:SetAttribute("minHeight", 0.1);

    Core:SetHeaderAttribute_point(frame)
    Core:SetHeaderAttribute_xOffset(frame)
    Core:SetHeaderAttribute_yOffset(frame)
    Core:SetHeaderAttribute_wrapXOffset(frame)
    Core:SetHeaderAttribute_wrapYOffset(frame)
    Core:SetHeaderAttribute_wrapAfter(frame)
    Core:SetHeaderAttribute_maxWraps(frame)

    -- sorting
    frame:SetAttribute("sortMethod", "INDEX"); -- INDEX or NAME or TIME
    frame:SetAttribute("sortDirection", "+"); -- - to reverse
end

-- Mostly taken from BuffFrame_OnUpdate Blizzard function to reproduce alpha cycle
function Core:Update(elapsed)
    if not Core.initialized then
        return
    end

    if not Core.settings.enabled then
        return
    end

    Core.BuffFrameFlashTime = Core.BuffFrameFlashTime - elapsed;
    if ( Core.BuffFrameFlashTime < 0 ) then
        local overtime = -Core.BuffFrameFlashTime;
        if ( Core.BuffFrameFlashState == 0 ) then
            Core.BuffFrameFlashState = 1;
            Core.BuffFrameFlashTime = BUFF_FLASH_TIME_ON;
        else
            Core.BuffFrameFlashState = 0;
            Core.BuffFrameFlashTime = BUFF_FLASH_TIME_OFF;
        end
        if ( overtime < Core.BuffFrameFlashTime ) then
            Core.BuffFrameFlashTime = Core.BuffFrameFlashTime - overtime;
        end
    end
    if ( Core.BuffFrameFlashState == 1 ) then
        Core.BuffAlphaValue = (BUFF_FLASH_TIME_ON - Core.BuffFrameFlashTime) / BUFF_FLASH_TIME_ON;
    else
        Core.BuffAlphaValue = Core.BuffFrameFlashTime / BUFF_FLASH_TIME_ON;
    end
    Core.BuffAlphaValue = (Core.BuffAlphaValue * (1 - BUFF_MIN_ALPHA)) + BUFF_MIN_ALPHA;
end

function Core:SetTimeleftText(button, timeLeft)
    if timeLeft and timeLeft > 0 then
        local timetext = self:GetStringTime(timeLeft)
        if timetext ~= "" then
            button.duration:SetText(timetext)
            if ( timeLeft < BUFF_DURATION_WARNING_TIME ) then
                button.duration:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
            else
                button.duration:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
            end
            button.duration:Show()
            do
                return
            end
        end
    end
    button.duration:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    button.duration:SetText("")
    button.duration:Hide()
end

function Core:SetCountText(button, count)
    if count and count > 1 then
        local counttext = tostring(count)
        if counttext ~= "" then
            button.count:SetText(counttext)
            button.count:Show()
            do
                return
            end
        end
    end
    button.count:SetText("")
    button.count:Hide()
end

function Core:SetAuraAlpha(buff, timeLeft)
    if (timeLeft and timeLeft >=0 and timeLeft < BUFF_WARNING_TIME) then
        buff:SetAlpha(self.BuffAlphaValue);
    else
        buff:SetAlpha(1.0);
    end
end

function Core:SetCoolDown(buff, eTime, duration)
    local cooldownFrame = buff.Cooldown -- _G[buff:GetName().."Cooldown"]
    if not cooldownFrame then
        cooldownFrame = CreateFrame("Cooldown", "$parentCooldown", buff, "CooldownFrameTemplate")
        cooldownFrame:SetAllPoints(buff)
        cooldownFrame:SetWidth(buff:GetWidth())
        cooldownFrame:SetHeight(buff:GetHeight())
        cooldownFrame:SetFrameLevel(buff:GetFrameLevel()+1)
        cooldownFrame:SetFrameStrata(buff:GetFrameStrata())
        cooldownFrame:SetReverse(true)
        buff.Cooldown = cooldownFrame
        buff.CoolDownIsRunning = false
    end

    if eTime and duration > 0 then
        local startTime
        startTime = eTime - duration
        if not buff.CoolDownIsRunning then
            CooldownFrame_Set(cooldownFrame, startTime, duration, 1)
            cooldownFrame:Show()
            buff.CoolDownIsRunning = true
        end
    else
        CooldownFrame_Set(cooldownFrame, 0, 0, 0)
        cooldownFrame:Hide()
        buff.CoolDownIsRunning = false
    end
end

function Core:GetStringTime(timenum)
    timenum = floor(timenum + 0.5);

    if timenum <=0 then
        return ""
    end

    local days, hours, minutes, seconds = ChatFrame_TimeBreakDown(timenum);
    local shours, sminutes, sseconds, timestring;

    if seconds < 0 then
        seconds = 0
    end
    if minutes < 0 then
        minutes = 0
    end
    if hours < 0 then
        hours = 0
    end
    if days < 0 then
        days = 0
    end

    if (hours >= 0 and hours < 10) and days > 0 then
        shours = "0"..hours;
    else
        shours = ""..hours;
    end
    if (minutes >= 0 and minutes < 10) and (hours > 0 or days > 0) then
        sminutes = "0"..minutes;
    else
        sminutes = ""..minutes;
    end
    if (seconds < 10) and (minutes > 0 or hours > 0 or days > 0) then
        sseconds = "0"..seconds;
    else
        sseconds = ""..seconds;
    end

    if (days > 0) then
        timestring = days.."d"..shours.."h";
    elseif (hours > 0) then
        timestring = shours.."h "..sminutes.."m";
    elseif (minutes > 0) then
        if Core.settings.showSecond == 1 then
            timestring = sminutes..":"..sseconds; -- 59:59
        elseif Core.settings.showSecond == 2 and minutes < 10 then
            timestring = sminutes..":"..sseconds; -- <9:59
        else
            timestring = sminutes.."m"; -- >10m
        end
    elseif (seconds > 0) then -- less than a minute
        timestring = sseconds.."s";
    else
        timestring = ""
    end

    return timestring;
end


PPB:RegisterEvent("ADDON_LOADED")

-- Export
ns.Core = Core
