--[[
    Originally created by Global, current author of Perl Classic Units Frame

    Perl Player Buff is now maintained by Leliel AKA :
    - mZHg at curseforge.com
    - Leliel, Yui, Neon, Sahaquile at EU-Eldre'Thalas

    Thanks to sigg for his tutorial on SecureAura Template
    https://www.wowinterface.com/forums/showthread.php?t=36117

    Also Thanks to:
    - https://wow.gamepedia.com
    - https://wowwiki.fandom.com
    - https://github.com/tomrus88/BlizzardInterfaceCode
--]]

local addonName, ns = ...
Perl_Player_Buff_Version = GetAddOnMetadata(addonName, 'Version');

local defaultSettings = {
    enabled = true,
    offsetVertical = 0,
    offsetHorizontal = -30,
    spacingVertical = 2,
    spacingHorizontal = 2,
    scaling = 0.64,
    buffPerRow = 10,
    maxNumberOfRow = 3,
    showNativeCooldown = false,
    showOriginalTextTimer = true,
    showSecond = 2, -- 0 = hidden, 1 = show, 2 = show only under 10 minutes
    weaponBuff = true
}
local settings = { }
local initialized = false
local auraTextHeight = 15
local debuffBaseVerticalOffset = 2
local auraWidth = 30
local playerClass = nil
local SpecialBar = nil;
local IsClassic = false

PPB = CreateFrame("Frame", nil, UIParent)
PPB:SetScript("OnEvent", function(self, event, ...)
    if self[event] then
        return self[event](self, event, ...)
    end
end)
PPB:SetScript("OnUpdate", function(...)
    PPB:Update(...)
end)

PPB:RegisterEvent("ADDON_LOADED")

function PPB:Print(...)
    DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", "|cff00ffffPerl Player Buff|r:", ...))
end
function PPB:Debug(...)
    -- [[
    local arg = {...}
    local t = ""
    for i,v in ipairs(arg) do
        t = t .. " " .. tostring(v)
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cffff3333Perl Player Buff|r:" .. t)
    --]]
end
function PPB:GetTime()
    return (debugprofilestop() / 1000)
end

function PPB:SettingsCanSet()
    if InCombatLockdown() then
        self:Print("Unable to change settings in combat!")
        do
            return false
        end
    else
        return true
    end
end

--[[
    Update layout functions
--]]
function PPB:UpdateEnabled()
    if not InCombatLockdown() then
        if settings.enabled then
            if PPB_FixAnchor and not PPB_FixAnchor:IsShown() then
                PPB_FixAnchor:Show()
            end
            if PPb_Buffs then
                PPb_Buffs:RegisterEvent("UNIT_AURA")
            end
            if PPb_Debuffs then
                PPb_Debuffs:RegisterEvent("UNIT_AURA")
            end
            if BuffFrame then
                BuffFrame:UnregisterAllEvents()
                BuffFrame:Hide()
            end
        else
            if PPB_FixAnchor and PPB_FixAnchor:IsShown() then
                PPB_FixAnchor:Hide()
            end
            if PPb_Buffs then
                PPb_Buffs:UnregisterAllEvents()
            end
            if PPb_Debuffs then
                PPb_Debuffs:UnregisterAllEvents()
            end
            if BuffFrame then
                BuffFrame_OnLoad(BuffFrame)
                BuffFrame:Show()
                BuffFrame_UpdatePositions()
            end
        end
    end
end

function PPB:UpdateWeaponBuff()
    if not InCombatLockdown() then
        if settings.enabled and settings.weaponBuff then
            if PPB_Buffs then
                PPB_Buffs:SetAttribute("includeWeapons", 1)
                PPB_Buffs:SetAttribute("weaponTemplate", "PPB_TempEnchantButtonTemplate")
            end
            if TemporaryEnchantFrame then
                TemporaryEnchantFrame:Hide()
            end
        else
            if PPB_Buffs then
                PPB_Buffs:SetAttribute("includeWeapons", 0)
                PPB_Buffs:SetAttribute("weaponTemplate", "")
            end
            if TemporaryEnchantFrame then
                TemporaryEnchantFrame:Show()
            end
        end
    end
end

function PPB:UpdateFixAnchorLocation()
    if not InCombatLockdown() and PPB_FixAnchor then
        local yOffset = 0
        if SpecialBar ~= nil then
            yOffset = self:SpecBarYOffSet(SpecialBar, yOffset)
        end;
        PPB_FixAnchor:SetPoint('TOPLEFT', Perl_Player_StatsFrame, "BOTTOMLEFT", settings.offsetHorizontal, yOffset + settings.offsetVertical)
    end
end

function PPB:UpdateBuffSpacingHorizontal()
    if not InCombatLockdown() and PPB_Buffs then
        PPB_Buffs:SetAttribute("xOffset", auraWidth + settings.spacingHorizontal)
    end
end
function PPB:UpdateDebuffSpacingHorizontal()
    if not InCombatLockdown() and PPB_Debuffs then
        PPB_Debuffs:SetAttribute("xOffset", auraWidth + settings.spacingHorizontal)
    end
end

function PPB:UpdateBuffSpacingVertical()
    if not InCombatLockdown() and PPB_Buffs then
        if settings.showOriginalTextTimer then
            PPB_Buffs:SetAttribute("wrapYOffset", -auraWidth - auraTextHeight - settings.spacingVertical)
        else
            PPB_Buffs:SetAttribute("wrapYOffset", -auraWidth - settings.spacingVertical)
        end
    end
end
function PPB:UpdateDebuffSpacingVertical()
    if not InCombatLockdown() and PPB_Debuffs then
        if settings.showOriginalTextTimer then
            PPB_Debuffs:SetAttribute("wrapYOffset", -auraWidth - auraTextHeight - settings.spacingVertical)
        else
            PPB_Debuffs:SetAttribute("wrapYOffset", -auraWidth - settings.spacingVertical)
        end
    end
end

function PPB:UpdateBuffPerRow()
    if not InCombatLockdown() and PPB_Buffs then
        PPB_Buffs:SetAttribute("wrapAfter", settings.buffPerRow)
    end
end
function PPB:UpdateDebuffPerRow()
    if not InCombatLockdown() and PPB_Debuffs then
        PPB_Debuffs:SetAttribute("wrapAfter", settings.buffPerRow)
    end
end

function PPB:UpdateBuffMaxNumberOfRow()
    if not InCombatLockdown() and PPB_Buffs then
        PPB_Buffs:SetAttribute("maxWraps", settings.maxNumberOfRow)
    end
end
function PPB:UpdateDebuffMaxNumberOfRow()
    if not InCombatLockdown() and PPB_Debuffs then
        PPB_Debuffs:SetAttribute("maxWraps", settings.maxNumberOfRow)
    end
end

function PPB:UpdateDebuffRelativeAnchorPoint()
    if not InCombatLockdown() and PPB_Debuffs then
        if settings.showOriginalTextTimer then
            PPB_Debuffs:SetPoint('TOPLEFT', PPB_Buffs, "BOTTOMLEFT", 0, -auraTextHeight)
        else
            PPB_Debuffs:SetPoint('TOPLEFT', PPB_Buffs, "BOTTOMLEFT", 0, -debuffBaseVerticalOffset)
        end
    end
end

--[[
    Settings setters
--]]
function PPB:ChangeSettings_Enabled(value)
    if self:SettingsCanSet() then
        if (type(value) == "boolean") then
            settings.enabled = value
            self:UpdateEnabled()
        end
    end
end

function PPB:ChangeSettings_WeaponBuff(value)
    if self:SettingsCanSet() then
        if (type(value) == "boolean") then
            settings.weaponBuff = value
            self:UpdateWeaponBuff()
        end
    end
end

function PPB:ChangeSettings_OffsetVertical(value)
    if self:SettingsCanSet() then
        if value and (type(value) == "number") then
            settings.offsetVertical = value
            self:UpdateFixAnchorLocation()
        end
    end
end
function PPB:ChangeSettings_OffsetHorizontal(value)
    if self:SettingsCanSet() then
        if value and (type(value) == "number") then
            settings.offsetHorizontal = value
            self:UpdateFixAnchorLocation()
        end
    end
end

function PPB:ChangeSettings_SpacingHorizontal(value)
    if self:SettingsCanSet() then
        if value and (type(value) == "number") then
            settings.spacingHorizontal = value
            self:UpdateBuffSpacingHorizontal()
            self:UpdateDebuffSpacingHorizontal()
        end
    end
end
function PPB:ChangeSettings_SpacingVertical(value)
    if self:SettingsCanSet() then
        if value and (type(value) == "number") then
            settings.spacingVertical = value
            self:UpdateBuffSpacingVertical()
            self:UpdateDebuffSpacingVertical()
        end
    end
end

function PPB:ChangeSettings_BuffPerRow(value)
    if self:SettingsCanSet() then
        if value and (type(value) == "number") then
            settings.buffPerRow = value
            self:UpdateBuffPerRow()
            self:UpdateDebuffPerRow()
        end
    end
end

function PPB:ChangeSettings_MaxNumberOfRow(value)
    if self:SettingsCanSet() then
        if value and (type(value) == "number") then
            settings.maxNumberOfRow = value
            self:UpdateBuffMaxNumberOfRow()
            self:UpdateDebuffMaxNumberOfRow()
        end
    end
end

function PPB:ChangeSettings_ShowNativeCooldown(value)
    if self:SettingsCanSet() then
        if (type(value) == "boolean") then
            settings.showNativeCooldown = value
            -- no update function for this setting
        end
    end
end

function PPB:ChangeSettings_ShowOriginalTextTimer(value)
    if self:SettingsCanSet() then
        if (type(value) == "boolean") then
            settings.showOriginalTextTimer = value
            self:UpdateDebuffRelativeAnchorPoint()
            self:UpdateBuffSpacingVertical()
            self:UpdateDebuffSpacingVertical()
            self:UpdateAllAura()
        end
    end
end

function PPB:ChangeSettings_ShowSecond(value)
    if self:SettingsCanSet() then
        if value and (type(value) == "number") then
            settings.showSecond = value
            -- no update function for this setting
        end
    end
end

function PPB:ChangeSettings_Scaling(value)
    if self:SettingsCanSet() then
        if value and (type(value) == "number") then
            settings.scaling = value
            self:SetBuffScale()
        end
    end
end

function PPB:GetSettingValue(key)
    if key then
        if key == "enabled" then
            return settings.enabled
        end
        if key == "weaponBuff" then
            return settings.weaponBuff
        end
        if key == "showNativeCooldown" then
            return settings.showNativeCooldown
        end
        if key == "showOriginalTextTimer" then
            return settings.showOriginalTextTimer
        end
        if key == "showSecond" then
            return settings.showSecond
        end
        if key == "offsetVertical" then
            return settings.offsetVertical
        end
        if key == "offsetHorizontal" then
            return settings.offsetHorizontal
        end
        if key == "spacingVertical" then
            return settings.spacingVertical
        end
        if key == "spacingHorizontal" then
            return settings.spacingHorizontal
        end
        if key == "scaling" then
            return settings.scaling
        end
        if key == "buffPerRow" then
            return settings.buffPerRow
        end
        if key == "maxNumberOfRow" then
            return settings.maxNumberOfRow
        end
    end
    self:Print("Error! GetSettingValue, invalid key: " .. (key or "nil"))
    return nil
end

function PPB:ResetSettings()
    Perl_Player_Buff_Settings = {}
    Perl_Player_Buff_Settings = setmetatable(Perl_Player_Buff_Settings, { __index = defaultSettings })

    settings.enabled = Perl_Player_Buff_Settings.enabled
    settings.offsetVertical = Perl_Player_Buff_Settings.offsetVertical
    settings.offsetHorizontal = Perl_Player_Buff_Settings.offsetHorizontal
    settings.spacingVertical = Perl_Player_Buff_Settings.spacingVertical
    settings.spacingHorizontal = Perl_Player_Buff_Settings.spacingHorizontal
    settings.scaling = Perl_Player_Buff_Settings.scaling
    settings.buffPerRow = Perl_Player_Buff_Settings.buffPerRow
    settings.maxNumberOfRow = Perl_Player_Buff_Settings.maxNumberOfRow
    settings.showNativeCooldown = Perl_Player_Buff_Settings.showNativeCooldown
    settings.showOriginalTextTimer = Perl_Player_Buff_Settings.showOriginalTextTimer
    settings.showSecond = Perl_Player_Buff_Settings.showSecond
    settings.weaponBuff = Perl_Player_Buff_Settings.weaponBuff

    return settings
end

function PPB:SlashHandler(message, editbox)
    local _, _, cmd, args = string.find(message, "%s?(%w+)%s?(.*)")

    local i
    if cmd == "offsetVertical" then
        i = tonumber(args or defaultSettings.offsetVertical)
        i = math.floor(i)
        self:ChangeSettings_OffsetVertical(i)

    elseif cmd == "offsetHorizontal" then
        i = tonumber(args or defaultSettings.offsetHorizontal)
        i = math.floor(i)
        self:ChangeSettings_OffsetHorizontal(i)

    elseif cmd == "spacingHorizontal" then
        i = tonumber(args or defaultSettings.spacingHorizontal)
        i = math.floor(i)
        self:ChangeSettings_SpacingHorizontal(i)

    elseif cmd == "spacingVertical" then
        i = tonumber(args or defaultSettings.spacingVertical)
        i = math.floor(i)
        self:ChangeSettings_SpacingVertical(i)

    elseif cmd == "buffPerRow" then
        i = tonumber(args or defaultSettings.buffPerRow)
        i = math.floor(i)
        self:UpdateBuffPerRow(i)
    elseif cmd == "maxNumberOfRow" then
        i = tonumber(args or defaultSettings.maxNumberOfRow)
        i = math.floor(i)
        self:UpdateBuffMaxNumberOfRow()
        self:UpdateDebuffMaxNumberOfRow()

    elseif cmd == "showNativeCooldown" then
        i = tonumber(args or 0)
        local b = (i == 1)
        self:ChangeSettings_ShowNativeCooldown(b)

    elseif cmd == "showOriginalTextTimer" then
        i = tonumber(args or 1)
        local b = (i == 1)
        self:ChangeSettings_ShowOriginalTextTimer(b)

    elseif cmd == "showSecond" then
        i = tonumber(args or defaultSettings.showSecond)
        if (i == 0) or (i == 1) or (i == 2) then
            self:ChangeSettings_ShowSecond(i)
        end
    elseif cmd == "scaling" then
        i = tonumber(args or defaultSettings.scaling * 100)
        if i > 0 and i <= 100 then
            i = math.floor(i) / 100
            self:ChangeSettings_Scaling(i)
        end
    else
        self:Print("Usage:")
        self:Print("/ppb enabled: 1 = enabled, 0 = disabled")
        self:Print("/ppb showNativeCooldown: 1 = enabled, 0 = disabled")
        self:Print("/ppb showOriginalTextTimer: 1 = enabled, 0 = disabled")
        self:Print("/ppb showSecond: 0 = hide, 1 = show, 2 = show only under 10 minutes")
        self:Print("/ppb weaponBuff: 1 = enabled, 0 = disabled")
        self:Print("/ppb offsetVertical: any number")
        self:Print("/ppb offsetHorizontal: any number")
        self:Print("/ppb spacingVertical: any number")
        self:Print("/ppb spacingHorizontal: any number")
        self:Print("/ppb scaling: from 10 to 200 (%)")
        self:Print("/ppb buffPerRow: from 1 to 40")
        self:Print("/ppb maxNumberOfRow: from 1 to 10")
        self:Print("If value is omitted, reset to default")
    end
end
SLASH_PPB1 = "/ppb"
SlashCmdList["PPB"] = function(message, editbox)
    PPB:SlashHandler(message, editbox)
end

function PPB:ADDON_LOADED(event, addon)
    if addon:lower() ~= "perl_player_buff" then
        return
    end

    -- internal variables
    self.BuffFrameUpdateTime = 0;
    self.BuffFrameFlashTime = 0;
    self.BuffFrameFlashState = 1;
    self.BuffAlphaValue = 1;

    -- load saved variables
    Perl_Player_Buff_Settings = Perl_Player_Buff_Settings or {}
    Perl_Player_Buff_Settings = setmetatable(Perl_Player_Buff_Settings, { __index = defaultSettings })

    local _, build, toc = GetBuildInfo()
    local currBuild, prevBuild = tonumber(build), Perl_Player_Buff_Settings.build

    if UnitDefense and not UpdateWindow then
        IsClassic = true
    end

    -- load some settings only if we are running the same build
    if prevBuild and (prevBuild == currBuild) then
        -- settings.todo = Perl_Player_Buff_Settings.todo or "default value"
    end

    -- load other settings
    settings.enabled = Perl_Player_Buff_Settings.enabled
    settings.offsetVertical = Perl_Player_Buff_Settings.offsetVertical
    settings.offsetHorizontal = Perl_Player_Buff_Settings.offsetHorizontal
    settings.spacingVertical = Perl_Player_Buff_Settings.spacingVertical
    settings.spacingHorizontal = Perl_Player_Buff_Settings.spacingHorizontal
    settings.scaling = Perl_Player_Buff_Settings.scaling
    settings.buffPerRow = Perl_Player_Buff_Settings.buffPerRow
    settings.maxNumberOfRow = Perl_Player_Buff_Settings.maxNumberOfRow
    settings.showNativeCooldown = Perl_Player_Buff_Settings.showNativeCooldown
    settings.showOriginalTextTimer = Perl_Player_Buff_Settings.showOriginalTextTimer
    settings.showSecond = Perl_Player_Buff_Settings.showSecond
    settings.weaponBuff = Perl_Player_Buff_Settings.weaponBuff

    -- clean saved variables
    Perl_Player_Buff_Settings = {}
    Perl_Player_Buff_Settings.build = currBuild

    Perl_Player_Buff_Settings.enabled = settings.enabled
    Perl_Player_Buff_Settings.offsetVertical = settings.offsetVertical
    Perl_Player_Buff_Settings.offsetHorizontal = settings.offsetHorizontal
    Perl_Player_Buff_Settings.spacingVertical = settings.spacingVertical
    Perl_Player_Buff_Settings.spacingHorizontal = settings.spacingHorizontal
    Perl_Player_Buff_Settings.scaling = settings.scaling
    Perl_Player_Buff_Settings.buffPerRow = settings.buffPerRow
    Perl_Player_Buff_Settings.maxNumberOfRow = settings.maxNumberOfRow
    Perl_Player_Buff_Settings.showNativeCooldown = settings.showNativeCooldown
    Perl_Player_Buff_Settings.showOriginalTextTimer = settings.showOriginalTextTimer
    Perl_Player_Buff_Settings.showSecond = settings.showSecond
    Perl_Player_Buff_Settings.weaponBuff = settings.weaponBuff

    self:UnregisterEvent("ADDON_LOADED")
    self.ADDON_LOADED = nil

    if IsLoggedIn() then
        self:PLAYER_LOGIN()
    else
        self:RegisterEvent("PLAYER_LOGIN")
    end
end

function PPB:PLAYER_LOGIN()
    self:RegisterEvent("PLAYER_LOGOUT")
    -- self:RegisterEvent("PLAYER_REGEN_ENABLED")

    self:UnregisterEvent("PLAYER_LOGIN")
    self.PLAYER_LOGIN = nil

    _, playerClass = UnitClass("player");

    self:SpecialBarOffset()

    self:CreateFrames()

    initialized = true

    self:UpdateBuffs(PPB_Buffs)
    self:UpdateDebuffs(PPB_Debuffs)

    if BuffFrame then
        BuffFrame:UnregisterAllEvents()
        BuffFrame:Hide()
    end

    if Perl_Config_Toggle then
        local o = Perl_Config_Toggle
        Perl_Config_Toggle = function()
            o()
            Perl_Config_Player_Buff_Display = function()
                if PPB_SettingsFrame then
                    InterfaceOptionsFrame_OpenToCategory(PPB_SettingsFrame)
                    InterfaceOptionsFrame_OpenToCategory(PPB_SettingsFrame)
                end
            end
        end
    end

    self:Print("Loaded")
    if IsClassic then
        self:Print("Welcome back to Classic!")
    end
end

function PPB:PLAYER_LOGOUT()
    -- save settings
    Perl_Player_Buff_Settings.enabled = settings.enabled
    Perl_Player_Buff_Settings.offsetVertical = settings.offsetVertical
    Perl_Player_Buff_Settings.offsetHorizontal = settings.offsetHorizontal
    Perl_Player_Buff_Settings.spacingVertical = settings.spacingVertical
    Perl_Player_Buff_Settings.spacingHorizontal = settings.spacingHorizontal
    Perl_Player_Buff_Settings.scaling = settings.scaling
    Perl_Player_Buff_Settings.buffPerRow = settings.buffPerRow
    Perl_Player_Buff_Settings.maxNumberOfRow = settings.maxNumberOfRow
    Perl_Player_Buff_Settings.showNativeCooldown = settings.showNativeCooldown
    Perl_Player_Buff_Settings.showOriginalTextTimer = settings.showOriginalTextTimer
    Perl_Player_Buff_Settings.showSecond = settings.showSecond
    Perl_Player_Buff_Settings.weaponBuff = settings.weaponBuff
end

function PPB:PLAYER_TOTEM_UPDATE()
    PPB:UpdateFixAnchorLocation()
end

function PPB:ACTIVE_TALENT_GROUP_CHANGED()
    PPB:UpdateFixAnchorLocation()
end

function PPB:SpecBarYOffSet(frame, yOffset)
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

PPB.Original_Perl_Player_Set_Show_Class_Resource_Frame = nil
PPB.PPB_Perl_Player_Set_Show_Class_Resource_Frame = function(newvalue)
    PPB.Original_Perl_Player_Set_Show_Class_Resource_Frame(newvalue);
    if not IsClassic and (playerClass == "SHAMAN") then
        if (newvalue == 1) then
            PPB:RegisterEvent("PLAYER_TOTEM_UPDATE");
        else
            PPB:UnregisterEvent("PLAYER_TOTEM_UPDATE");
        end;
    end;
    PPB:UpdateFixAnchorLocation()
end

function PPB:SpecialBarOffset()
    local WatchSpec = false;

    if playerClass == "PALADIN" then -- Paladin Power Bar
        SpecialBar = PaladinPowerBarFrame;
        WatchSpec = true;
    elseif playerClass == "WARLOCK" then -- Shard Bar
        SpecialBar = WarlockPowerFrame;
        WatchSpec = true;
    elseif playerClass == "DRUID" then -- Eclipse Bar
        SpecialBar = EclipseBarFrame;
        WatchSpec = true;
    elseif playerClass == "SHAMAN" then -- Totem Timer
        SpecialBar = TotemFrame;
        WatchSpec = true;
        local Perl_Player_Vars = Perl_Player_GetVars();
        if not IsClassic and PPB and Perl_Player_Vars and Perl_Player_Vars["totemtimers"] == 1 then
            PPB:RegisterEvent("PLAYER_TOTEM_UPDATE"); -- handle totem bar show/hide
        end;
    elseif playerClass == "DEATHKNIGHT" then -- Rune Frame
        SpecialBar = RuneFrame;
        WatchSpec = true;
    elseif playerClass == "PRIEST" then -- Priest Frame
        SpecialBar = PriestBarFrame;
        WatchSpec = true;
    elseif playerClass == "MONK" then -- Harmony Frame
        SpecialBar = MonkHarmonyBarFrame;
        WatchSpec = true;
    elseif playerClass == "MAGE" then -- Arcane Frame
        SpecialBar = MageArcaneChargesFrame;
        WatchSpec = true;
    else
        SpecialBar = nil;
    end;

    if SpecialBar ~= nil then
        PPB.Original_Perl_Player_Set_Show_Class_Resource_Frame = Perl_Player_Set_Show_Class_Resource_Frame;
        Perl_Player_Set_Show_Class_Resource_Frame = PPB.PPB_Perl_Player_Set_Show_Class_Resource_Frame;
    end;

    if not IsClassic and WatchSpec then
        PPB:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
    end;
end


local currentScale = 1
function PPB:SetBuffScale()
    if not PPB_BuffFrame then
        return
    end

    local currentScale = 1 - UIParent:GetEffectiveScale() + settings.scaling;    -- run it through the scaling formula introduced in 1.9
    PPB_BuffFrame:SetScale(currentScale)
end

local PPB_Buffs = nil
local PPB_Debuffs = nil
local PPB_FixAnchor = nil
local PPB_BuffFrame = nil

PPB.PPB_Buffs_OnEvent = function(header, event, unit)
    if (unit ~= "player" and unit ~= "vehicle") or event ~= "UNIT_AURA" then
        return
    end
    if settings.enabled then
        PPB:UpdateBuffs(header)
    end
end

PPB.PPB_Debuffs_OnEvent = function(header, event, unit)
    if (unit ~= "player" and unit ~= "vehicle") or event ~= "UNIT_AURA" then
        return
    end
    if settings.enabled then
        PPB:UpdateDebuffs(header)
    end
end

function PPB:CreateFrames()
    PPB_FixAnchor = CreateFrame("Frame", "PPB_FixAnchor", Perl_Player_Frame)
    PPB_FixAnchor:ClearAllPoints()
    PPB_FixAnchor:SetSize(1, 1)
    PPB_FixAnchor:SetPoint('TOPLEFT', Perl_Player_StatsFrame, "BOTTOMLEFT", settings.offsetHorizontal, settings.offsetVertical)
    PPB_FixAnchor:Show()

    PPB_BuffFrame = CreateFrame("Frame", "PPB_BuffFrame", PPB_FixAnchor)
    PPB_BuffFrame:ClearAllPoints()
    PPB_BuffFrame:SetSize(1, 1)
    PPB_BuffFrame:SetPoint('TOPLEFT', PPB_FixAnchor, "TOPLEFT", 0, 0)
    self:SetBuffScale()
    PPB_BuffFrame:Show()

    PPB_Buffs = CreateFrame("Frame", "PPB_Buffs", PPB_BuffFrame, "SecureAuraHeaderTemplate")
    PPB_Buffs:ClearAllPoints()
    self:SetHeaderAttribute(PPB_Buffs, "HELPFUL", "PPB_BuffButtonTemplate")
    self:UpdateWeaponBuff() -- set weapon attributes if needed
    PPB_Buffs:SetPoint('TOPLEFT', PPB_BuffFrame, "TOPLEFT", 0, 0)
    PPB_Buffs:HookScript("OnEvent", PPB.PPB_Buffs_OnEvent)
    PPB_Buffs:Show()

    PPB_Debuffs = CreateFrame("frame","PPB_Debuffs",PPB_Buffs,"SecureAuraHeaderTemplate")
    PPB_Debuffs:ClearAllPoints()
    self:SetHeaderAttribute(PPB_Debuffs, "HARMFUL", "PPB_DebuffButtonTemplate")
    local yOffset = -debuffBaseVerticalOffset
    if settings.showOriginalTextTimer then
        yOffset = -auraTextHeight
    end
    PPB_Debuffs:SetPoint('TOPLEFT', PPB_Buffs, "BOTTOMLEFT", 0, yOffset)
    PPB_Debuffs:HookScript("OnEvent", PPB.PPB_Debuffs_OnEvent)
    PPB_Debuffs:Show()
end

function PPB:SetHeaderAttribute(frame, filter, template)

    frame:SetAttribute("unit", "player")
    frame:SetAttribute("template", template)
    frame:SetAttribute("filter", filter);
    frame:SetAttribute("minWidth", 0.1);
    frame:SetAttribute("minHeight", 0.1);

    frame:SetAttribute("point", "TOPLEFT");
    frame:SetAttribute("xOffset", auraWidth + settings.spacingHorizontal);
    frame:SetAttribute("yOffset", 0);
    frame:SetAttribute("wrapAfter", settings.buffPerRow);
    frame:SetAttribute("wrapXOffset", 0);

    if settings.showOriginalTextTimer then
        frame:SetAttribute("wrapYOffset", -auraWidth - auraTextHeight - settings.spacingVertical)
    else
        frame:SetAttribute("wrapYOffset", -auraWidth - settings.spacingVertical)
    end
    frame:SetAttribute("maxWraps", settings.maxNumberOfRow);

    -- sorting
    frame:SetAttribute("sortMethod", "INDEX"); -- INDEX or NAME or TIME
    frame:SetAttribute("sortDirection", "+"); -- - to reverse
end

local lastUpdate = 0
function PPB:Update(self, elapsed)
    if not initialized then
        return
    end

    if not settings.enabled then
        return
    end

    if ( self.BuffFrameUpdateTime > 0 ) then
        self.BuffFrameUpdateTime = self.BuffFrameUpdateTime - elapsed;
    else
        self.BuffFrameUpdateTime = self.BuffFrameUpdateTime + TOOLTIP_UPDATE_TIME;
    end

    self.BuffFrameFlashTime = self.BuffFrameFlashTime - elapsed;
    if ( self.BuffFrameFlashTime < 0 ) then
        local overtime = -self.BuffFrameFlashTime;
        if ( self.BuffFrameFlashState == 0 ) then
            self.BuffFrameFlashState = 1;
            self.BuffFrameFlashTime = BUFF_FLASH_TIME_ON;
        else
            self.BuffFrameFlashState = 0;
            self.BuffFrameFlashTime = BUFF_FLASH_TIME_OFF;
        end
        if ( overtime < self.BuffFrameFlashTime ) then
            self.BuffFrameFlashTime = self.BuffFrameFlashTime - overtime;
        end
    end
    if ( self.BuffFrameFlashState == 1 ) then
        self.BuffAlphaValue = (BUFF_FLASH_TIME_ON - self.BuffFrameFlashTime) / BUFF_FLASH_TIME_ON;
    else
        self.BuffAlphaValue = self.BuffFrameFlashTime / BUFF_FLASH_TIME_ON;
    end
    self.BuffAlphaValue = (self.BuffAlphaValue * (1 - BUFF_MIN_ALPHA)) + BUFF_MIN_ALPHA;

    local currentTime = self:GetTime()
    if lastUpdate + 0.05 > currentTime then
        return
    end

    self:UpdateAllAura()

    lastUpdate = currentTime
end

function PPB:SetTimeleftText(button, timeLeft)
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

function PPB:SetCountText(button, count)
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

function PPB:SetAuraAlpha(buff, timeLeft)
    if (timeLeft and timeLeft >=0 and timeLeft < BUFF_WARNING_TIME) then
        buff:SetAlpha(self.BuffAlphaValue);
    else
        buff:SetAlpha(1.0);
    end
end

function PPB:UpdateAllAura()
    local currentTime = GetTime()

    for i = 1, BUFF_MAX_DISPLAY do
        local child = PPB_Buffs:GetAttribute("child" .. i)
        if child and child:IsShown() then
            child.filter = "HELPFUL"
            local name, icon, count, dType, duration, eTime = UnitAura("player", child:GetID(), "HELPFUL")
            local ic = _G[child:GetName().."Icon"]
            if ic then
                ic:SetTexture(icon)
                ic:Show()
            end
            self:SetCountText(child, count)
            local timeLeft = (eTime or 0) - currentTime
            if settings.showOriginalTextTimer then
                self:SetTimeleftText(child, timeLeft)
            else
                self:SetTimeleftText(child, 0)
            end
            if settings.showNativeCooldown then
                self:SetCoolDown(child, eTime, timeLeft)
            else
                self:SetCoolDown(child, 0, 0)
            end
            self:SetAuraAlpha(child, timeLeft)
        end
    end

    if settings.weaponBuff then
        hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantId = GetWeaponEnchantInfo()
        for i = 1, 2 do
            local child = PPB_Buffs:GetAttribute("tempEnchant" .. i)
            if child and child:IsShown() then
                local slotid = child:GetAttribute("target-slot")
                child.filter = "TEMP"

                local eTime, count = 0, 0
                if (slotid == 16) and hasMainHandEnchant then
                    count = mainHandCharges
                    eTime = currentTime + (mainHandExpiration / 1000)
                end
                if (slotid == 17) and hasOffHandEnchant then
                    count = offHandCharges
                    eTime = currentTime + (offHandExpiration / 1000)
                end
                self:SetCountText(child, count)
                local timeLeft = (eTime or 0) - currentTime
                if settings.showOriginalTextTimer then
                    self:SetTimeleftText(child, timeLeft)
                else
                    self:SetTimeleftText(child, 0)
                end
                if settings.showNativeCooldown then
                    self:SetCoolDown(child, eTime, timeLeft)
                else
                    self:SetCoolDown(child, 0, 0)
                end
                self:SetAuraAlpha(child, timeLeft)
            end
        end
    end

    for i = 1, DEBUFF_MAX_DISPLAY do
        local child = PPB_Debuffs:GetAttribute("child" .. i)
        if child and child:IsShown() then
            child.filter = "HARMFUL"
            local name, icon, count, dType, duration, eTime = UnitAura("player", child:GetID(), "HARMFUL")
            local ic = _G[child:GetName().."Icon"]
            if ic then
                ic:SetTexture(icon)
                ic:Show()
            end
            self:SetCountText(child, count)
            local timeLeft = (eTime or 0) - currentTime
            if settings.showOriginalTextTimer then
                self:SetTimeleftText(child, timeLeft)
            else
                self:SetTimeleftText(child, 0)
            end
            if settings.showNativeCooldown then
                self:SetCoolDown(child, eTime, timeLeft)
            else
                self:SetCoolDown(child, 0, 0)
            end
            self:SetAuraAlpha(child, timeLeft)
        end
    end
end


function PPB:HideAllAura()
    local currentTime = GetTime()

    for i = 1, BUFF_MAX_DISPLAY do
        local child = PPB_Buffs:GetAttribute("child" .. i)
        if child and child:IsShown() then
            child:Hide()
        end
    end

    if settings.weaponBuff then
        for i = 1, 2 do
            local child = PPB_Buffs:GetAttribute("tempEnchant" .. i)
            if child and child:IsShown() then
                child:Hide()
            end
        end
    end

    for i = 1, DEBUFF_MAX_DISPLAY do
        local child = PPB_Debuffs:GetAttribute("child" .. i)
        if child and child:IsShown() then
            child:Hide()
        end
    end
end


function PPB:SetCoolDown(buff, eTime, timeLeft)
    local cooldownFrame = _G[buff:GetName().."Cooldown"];
    if not cooldownFrame then
        cooldownFrame = CreateFrame("Cooldown", "$parentCooldown", buff, "CooldownFrameTemplate")
        cooldownFrame:SetWidth(buff:GetWidth())
        cooldownFrame:SetHeight(buff:GetHeight())
        cooldownFrame:SetFrameLevel(buff:GetFrameLevel()+1)
        cooldownFrame:SetFrameStrata(buff:GetFrameStrata())
        cooldownFrame:SetAllPoints(buff)
        cooldownFrame:SetReverse(true)
    end

    if eTime and timeLeft > 0 then
        if not buff.CoolDownIsRunning then
            CooldownFrame_Set(cooldownFrame, eTime - timeLeft, timeLeft, 1)
            cooldownFrame:Show()
            buff.CoolDownIsRunning = true
        end
    else
        CooldownFrame_Set(cooldownFrame, 0, 0, 0)
        cooldownFrame:Hide()
        buff.CoolDownIsRunning = false
    end
end

function PPB:UpdateBuffs(header)
    local currentTime = GetTime()
    for i = 1, BUFF_MAX_DISPLAY do
        local child = header:GetAttribute("child" .. i)
        if child and child:IsShown() then
            child.filter = "HELPFUL"
            local name, icon, count, dType, duration, eTime = UnitAura("player", child:GetID(), "HELPFUL")
            local ic = _G[child:GetName().."Icon"]
            if ic then
                ic:SetTexture(icon)
                ic:Show()
            end
            self:SetCountText(child, count)
            local timeLeft = (eTime or 0) - currentTime
            if settings.showOriginalTextTimer then
                self:SetTimeleftText(child, timeLeft)
            else
                self:SetTimeleftText(child, 0)
            end
            if settings.showNativeCooldown then
                self:SetCoolDown(child, eTime, timeLeft)
            else
                self:SetCoolDown(child, 0, 0)
            end
        end
    end

    if settings.weaponBuff then
        hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantId = GetWeaponEnchantInfo()
        for i = 1, 2 do
            local child = header:GetAttribute("tempEnchant" .. i)
            if child and child:IsShown() then
                local slotid = child:GetAttribute("target-slot")
                child.filter = "TEMP"

                local eTime = 0
                local count = 0
                local icon = nil

                if (slotid == 16) and hasMainHandEnchant then
                    local id = GetInventorySlotInfo("MAINHANDSLOT")
                    icon = GetInventoryItemTexture("player", id)
                    count = mainHandCharges
                    eTime = mainHandExpiration
                end
                if (slotid == 17) and hasOffHandEnchant then
                    local id = GetInventorySlotInfo("SECONDARYHANDSLOT")
                    icon = GetInventoryItemTexture("player", id)
                    count = offHandCharges
                    eTime = offHandExpiration
                end

                if icon then
                    local ic = _G[child:GetName().."Icon"]
                    if ic then
                        ic:SetTexture(icon)
                        ic:Show()
                    end
                end
                self:SetCountText(child, count)

                local timeLeft = (eTime or 0) - currentTime
                if settings.showOriginalTextTimer then
                    self:SetTimeleftText(child, timeLeft)
                else
                    self:SetTimeleftText(child, 0)
                end
                if settings.showNativeCooldown then
                    self:SetCoolDown(child, eTime, timeLeft)
                else
                    self:SetCoolDown(child, 0, 0)
                end
            end
        end
    end
end

function PPB:UpdateDebuffs(header)
    local currentTime = GetTime()
    for i = 1, DEBUFF_MAX_DISPLAY do
        local child = header:GetAttribute("child" .. i)
        if child and child:IsShown() then
            child.filter = "HARMFUL"
            local name, icon, count, dType, duration, eTime = UnitAura("player", child:GetID(), "HARMFUL")
            local ic = _G[child:GetName().."Icon"]
            if ic then
                ic:SetTexture(icon)
                ic:Show()
            end
            self:SetCountText(child, count)
            -- Set color of debuff border based on dispel class.
            local debuffSlot = _G[child:GetName().."Border"]
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
            local timeLeft = (eTime or 0) - currentTime
            if settings.showOriginalTextTimer then
                self:SetTimeleftText(child, timeLeft)
            else
                self:SetTimeleftText(child, 0)
            end
            if settings.showNativeCooldown then
                self:SetCoolDown(child, eTime, timeLeft)
            else
                self:SetCoolDown(child, 0, 0)
            end
        end
    end
end

function PPB:GetStringTime(timenum)
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
        --if (settings.showSecond ~= 1) then
        --    timestring = days.."d"..shours.."h"..sminutes.."m";
        --else
        --    timestring = days..":"..shours..":"..sminutes..":"..sseconds;
        --end
        timestring = days.."d"..shours.."h";
    elseif (hours > 0) then
        --if (settings.showSecond ~= 1) then
        --    timestring = shours.."h "..sminutes.."m";
        --else
        --    timestring = shours..":"..sminutes..":"..sseconds;
        --end
        timestring = shours.."h "..sminutes.."m";
    elseif (minutes > 0) then
        if settings.showSecond == 1 then
            timestring = sminutes..":"..sseconds; -- 59:59
        elseif settings.showSecond == 2 and minutes < 10 then
            timestring = sminutes..":"..sseconds; -- <9:59
        else
            timestring = sminutes.."m"; -- >10m
        end
    else -- less than a minute
        timestring = sseconds.."s";
    end

    return timestring;
end

