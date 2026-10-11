local addonName, ns = ...
-- https://www.wowinterface.com/forums/showthread.php?t=40444


-- Imports
local Core = ns.Core
local Utility = ns.Utility
local Const = ns.Const
local Widget = ns.Widget

local Config = {}
local addonNameProper = "Perl Player Buff"

Config.title = nil
Config.subtitle = nil

Config.cbEnabled = nil
Config.cbHideBlizzardBuffFrame = nil
Config.cbHandleWeaponBuff = nil
Config.cbShowOriginalTextTimer = nil
Config.cbShowNativeCooldown = nil

Config.sliderShowSecond = nil

Config.sliderAnchorLocation = nil
Config.sliderOffsetVertical = nil
Config.sliderOffsetHorizontal = nil

Config.sliderSpacingVertical = nil
Config.sliderSpacingHorizontal = nil

Config.sliderScaling = nil
Config.sliderCooldownScale = nil

Config.sliderBuffPerRow = nil
Config.sliderMaxNumberOfRow = nil


local frame_base = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
frame_base.name = "Perl Player Buff"
frame_base:Hide()
frame_base:SetScript("OnShow", function()
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame_base, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", -27, 0)

    local frame = CreateFrame("Frame")
    scrollFrame:SetScrollChild(frame)
    frame:SetWidth(frame_base:GetWidth()-18)
    frame:SetHeight(1)

    Config.title, Config.subtitle = Widget.CreateHeaderTitle(
        frame,
        "Perl Player Buff",
        "This panel allows you to configure all settings."
    )

    Config.cbEnabled = Widget.CreateCheckbox(
        frame, "Enabled", "Check this to enabled Perl Player Buff", Core.settings.enabled,
        function (self)
            if self:GetChecked() then
                Core:ChangeSettings_Enabled(true)
            else
                Core:ChangeSettings_Enabled(false)
            end
        end)
    Config.cbEnabled:SetPoint("TOPLEFT", Config.subtitle, "BOTTOMLEFT", 0, -16)

    Config.cbHideBlizzardBuffFrame = Widget.CreateCheckbox(
        frame, "Hide Blizzard Buff Frame", "Check this to hide the Blizzard buff and debuff frames",
        Core.settings.hideBlizzardBuffFrame,
        function (self)
            Core:ChangeSettings_HideBlizzardBuffFrame(self:GetChecked())
        end)
    Config.cbHideBlizzardBuffFrame:SetPoint("TOPLEFT", Config.cbEnabled, "BOTTOMLEFT", 0, -10)

    Config.cbHandleWeaponBuff = Widget.CreateCheckbox(
        frame, "Handle Weapons Buffs", "Check this to handle weapon's buffs", Core.settings.weaponBuff,
        function (self)
            if self:GetChecked() then
                Core:ChangeSettings_WeaponBuff(true)
            else
                Core:ChangeSettings_WeaponBuff(false)
            end
        end)
    Config.cbHandleWeaponBuff:SetPoint("TOPLEFT", Config.cbEnabled, "TOPLEFT", 200, 0)

    Config.cbShowOriginalTextTimer = Widget.CreateCheckbox(
        frame, "Show Original Text Timer", "Check this to show original text timer", Core.settings.showOriginalTextTimer,
        function (self)
            if self:GetChecked() then
                Core:ChangeSettings_ShowOriginalTextTimer(true)
            else
                Core:ChangeSettings_ShowOriginalTextTimer(false)
            end
        end)
    Config.cbShowOriginalTextTimer:SetPoint("TOPLEFT", Config.cbHideBlizzardBuffFrame, "BOTTOMLEFT", 0, -10)

    -- parent, text, tooltip, minVal, maxVal, initValue, onChanged
    Config.sliderShowSecond = Widget.CreateSlider(
        frame, "Show seconds", "Show or hide seconds for original timer", 1, 3,
        function(self, value, preValue)
            if value then
                if value == 1 then
                    self.Text:SetText("Hide seconds")
                end
                if value == 2 then
                    self.Text:SetText("Show seconds")
                end
                if value == 3 then
                    self.Text:SetText("Only show seconds under 10 minutes")
                end
                if value >= 1 and value <= 3 then
                    Core:ChangeSettings_ShowSecond(value-1)
                end
            end
        end)
    Config.sliderShowSecond.Low:SetText("")
    Config.sliderShowSecond.High:SetText("")
    Config.sliderShowSecond:SetWidth(100)
    Config.sliderShowSecond:SetPoint("BOTTOMLEFT", Config.cbShowOriginalTextTimer, "BOTTOMLEFT", 200, 0)
    Config.sliderShowSecond:SetValue(Core.settings.showSecond + 1)

    Config.cbShowNativeCooldown = Widget.CreateCheckbox(
        frame, "Show Native Cooldown", "Check this to show native cooldown", Core.settings.showNativeCooldown,
        function (self)
            if self:GetChecked() then
                Core:ChangeSettings_ShowNativeCooldown(true)
            else
                Core:ChangeSettings_ShowNativeCooldown(false)
            end
        end)
    Config.cbShowNativeCooldown:SetPoint("TOPLEFT", Config.cbShowOriginalTextTimer, "BOTTOMLEFT", 0, -10)

    Config.sliderAnchorLocation = Widget.CreateSlider(
        frame,"Anchor location", "Choose the frame anchor location", 1, 4,
        function(self, value, preValue)
            if value then
                if value == 1 then
                    self.Text:SetText("Anchor point: Bottom left")
                end
                if value == 2 then
                    self.Text:SetText("Anchor point: Bottom right")
                end
                if value == 3 then
                    self.Text:SetText("Anchor point: Top left")
                end
                if value == 4 then
                    self.Text:SetText("Anchor point: Top right")
                end
                if value >= 1 and value <= 4 then
                    Core:ChangeSettings_AnchorLocation(value)
                end
            end
        end)
    Config.sliderAnchorLocation.Low:SetText("")
    Config.sliderAnchorLocation.High:SetText("")
    Config.sliderAnchorLocation:SetWidth(100)
    Config.sliderAnchorLocation:SetPoint("TOPLEFT", Config.cbShowNativeCooldown, "BOTTOMLEFT", 0, -30)
    Config.sliderAnchorLocation:SetValue(Core.settings.anchorLocation)

    Config.sliderOffsetVertical = Widget.CreateSlider(
        frame,"Offset - vertical", "Adjust the vertical position of the buff and debuff frames.", -250, 250,
        function(self, value, preValue)
            self.Text:SetText("Offset - vertical: " .. tostring(value))
            Core:ChangeSettings_OffsetVertical(value)
        end)
    Config.sliderOffsetVertical:SetPoint("TOPLEFT", Config.sliderAnchorLocation, "BOTTOMLEFT", 0, -20)
    Config.sliderOffsetVertical:SetValue(Core.settings.offsetVertical)

    Config.sliderOffsetHorizontal = Widget.CreateSlider(
        frame, "Offset - horizontal", "Adjust the horizontal position of the buff and debuff frames.", -250, 250,
        function(self, value, preValue)
            self.Text:SetText("Offset - horizontal: " .. tostring(value))
            Core:ChangeSettings_OffsetHorizontal(value)
        end)
    Config.sliderOffsetHorizontal:SetPoint("TOPLEFT", Config.sliderOffsetVertical, "BOTTOMLEFT", 0, -30)
    Config.sliderOffsetHorizontal:SetValue(Core.settings.offsetHorizontal)

    Config.sliderSpacingVertical = Widget.CreateSlider(
        frame, "Spacing - vertical", "Adjust the vertical gap between rows of buffs or debuffs.", -100, 100,
        function(self, value, preValue)
            self.Text:SetText("Spacing - vertical: " .. tostring(value))
            Core:ChangeSettings_SpacingVertical(value)
        end)
    Config.sliderSpacingVertical:SetPoint("TOPLEFT", Config.sliderOffsetHorizontal, "BOTTOMLEFT", 0, -30)
    Config.sliderSpacingVertical:SetValue(Core.settings.spacingVertical)

    Config.sliderSpacingHorizontal = Widget.CreateSlider(
        frame, "Spacing - horizontal", "Adjust the horizontal gap between buffs or debuffs.", -100, 100,
        function(self, value, preValue)
            self.Text:SetText("Spacing - horizontal: " .. tostring(value))
            Core:ChangeSettings_SpacingHorizontal(value)
        end)
    Config.sliderSpacingHorizontal:SetPoint("TOPLEFT", Config.sliderSpacingVertical, "BOTTOMLEFT", 0, -30)
    Config.sliderSpacingHorizontal:SetValue(Core.settings.spacingHorizontal)

    Config.sliderScaling = Widget.CreateSlider(
        frame, "Scaling", "Adjust the overall size of the buff and debuff frames.", 10, 200,
        function(self, value, preValue)
            self.Text:SetText("Scaling: " .. tostring(value) .. "%")
            if value >= 10 and value <= 200 then
                Core:ChangeSettings_Scaling(value / 100)
            end
        end)
    Config.sliderScaling:SetPoint("TOPLEFT", Config.sliderSpacingHorizontal, "BOTTOMLEFT", 0, -30)
    Config.sliderScaling:SetValue(Core.settings.scaling * 100)

    Config.sliderCooldownScale = Widget.CreateSlider(
        frame, "Cooldown scaling", "Adjust the size of the cooldown.", 10, 200,
        function(self, value, preValue)
            self.Text:SetText("Cooldown scaling: " .. tostring(value) .. "%")
            if value >= 10 and value <= 200 then
                Core:ChangeSettings_CooldownScale(value / 100)
            end
        end)
    Config.sliderCooldownScale:SetPoint("TOPLEFT", Config.sliderScaling, "BOTTOMLEFT", 0, -30)
    Config.sliderCooldownScale:SetValue(Core.settings.cooldownScale * 100)

    Config.sliderBuffPerRow = Widget.CreateSlider(
        frame, "Buff per row", "Set the maximum number of buffs or debuffs displayed in each row.", 1, 40,
        function(self, value, preValue)
            self.Text:SetText("Buff per row: " .. tostring(value))
            if value >= 1 and value <= 40 then
                Core:ChangeSettings_BuffPerRow(value)
            end
        end)
    Config.sliderBuffPerRow:SetPoint("TOPLEFT", Config.sliderCooldownScale, "BOTTOMLEFT", 0, -30)
    Config.sliderBuffPerRow:SetValue(Core.settings.buffPerRow)

    Config.sliderMaxNumberOfRow = Widget.CreateSlider(
        frame, "Maximum number of row", "Set the maximum number of rows of buffs or debuffs to display.", 1, 40,
        function(self, value, preValue)
            self.Text:SetText("Maximum number of row: " .. tostring(value))
            if value >= 1 and value <= 40 then
                Core:ChangeSettings_MaxNumberOfRow(value)
            end
        end)
    Config.sliderMaxNumberOfRow:SetPoint("TOPLEFT", Config.sliderBuffPerRow, "BOTTOMLEFT", 0, -30)
    Config.sliderMaxNumberOfRow:SetValue(Core.settings.maxNumberOfRow)

    frame_base:SetScript("OnShow", nil)
end)

Config.frame = frame_base

local category = nil

if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    category = Settings.RegisterCanvasLayoutCategory(Config.frame, Config.frame.name)
    Settings.RegisterAddOnCategory(category)
else
    InterfaceOptions_AddCategory(Config.frame)
end

Config.category = category
Config.originalPerlConfigToggle = nil

function Config:HookPerlConfigToggle()
    if Perl_Config_Toggle then
        Config.originalPerlConfigToggle = Perl_Config_Toggle
        Perl_Config_Toggle = function()
            Config.originalPerlConfigToggle()
            if Perl_Config_Player_Buff_Display then
                Perl_Config_Player_Buff_Display = function()
                    Perl_Config_Toggle()
                    if Settings and Settings.OpenToCategory  then
                        Settings.OpenToCategory(Config.category:GetID())
                    else
                        InterfaceOptionsFrame_OpenToCategory(Config.frame)
                        InterfaceOptionsFrame_OpenToCategory(Config.frame)
                    end
                end
                -- unhook when done
                Perl_Config_Toggle = Config.originalPerlConfigToggle
                Config.originalPerlConfigToggle = nil
            end
        end
    end
end

-- Export
ns.Config = Config
