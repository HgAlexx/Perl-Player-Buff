-- https://www.wowinterface.com/forums/showthread.php?t=40444

local addonName, ns = ...
addonNameProper = string.gsub(addonName, "_", " ");

-- The Settings Frame
PPB_SettingsFrame = CreateFrame("FRAME", addonName .. "Settings", UIParent);
PPB_SettingsFrame.name = addonNameProper;
PPB_SettingsFrame:SetBackdrop({
    bgFile = "Interface/RAIDFRAME/UI-RaidFrame-GroupBg",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = false, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
});
PPB_SettingsFrame:SetBackdropColor(0, 0, 0, 1);
PPB_SettingsFrame.refresh = function()
    PPB_SettingsFrame:Refresh()
end
PPB_SettingsFrame.default = function()
    local s = PPB:ResetSettings()
    PPB_SettingsFrame:Refresh()

    PPB:ChangeSettings_Enabled(s.enabled)
    PPB:ChangeSettings_WeaponBuff(s.weaponBuff)

    PPB:ChangeSettings_ShowNativeCooldown(s.showNativeCooldown)
    PPB:ChangeSettings_ShowOriginalTextTimer(s.showOriginalTextTimer)
    PPB:ChangeSettings_ShowSecond(s.showSecond)

    PPB:ChangeSettings_OffsetHorizontal(s.offsetHorizontal)
    PPB:ChangeSettings_OffsetVertical(s.offsetVertical)

    PPB:ChangeSettings_SpacingHorizontal(s.spacingHorizontal)
    PPB:ChangeSettings_SpacingVertical(s.spacingVertical)

    PPB:ChangeSettings_Scaling(s.scaling)

    PPB:ChangeSettings_BuffPerRow(s.buffPerRow)
    PPB:ChangeSettings_MaxNumberOfRow(s.maxNumberOfRow)
end

PPB_SettingsFrame.CreateCheckbox = function(self, name, text, click)
    local checkButton = CreateFrame("CheckButton", self:GetName() .. name, self, "InterfaceOptionsCheckButtonTemplate")
    checkButton:SetScript("OnClick", click)
    checkButton.Text:SetText(text)
    return checkButton;
end
PPB_SettingsFrame.CreateSlider = function(self, name, text, minVal, maxVal, onChanged)
    local fullname = self:GetName() .. name
    local slider = CreateFrame("Slider", fullname, self, "OptionsSliderTemplate")
    slider:SetWidth(500)
    slider:SetOrientation('HORIZONTAL')
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider.valueStep = 1
    slider.text = _G[fullname.."Text"]
    slider.text:SetText(text)
    slider.text:SetPoint("BOTTOMLEFT", slider, "TOPLEFT")
    slider.textLow = _G[fullname.."Low"]
    slider.textHigh = _G[fullname.."High"]
    slider.textLow:SetText(minVal)
    slider.textHigh:SetText(maxVal)
    slider.currentValue = nil
    slider:SetScript("OnValueChanged", function(self, value)
        if self.currentValue ~= value then
            onChanged(self, value, self.currentValue)
            self.currentValue = value
        end
    end)
    return slider;
end

local title = PPB_SettingsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", PPB_SettingsFrame, "TOPLEFT", 10, -30)
title:SetJustifyH("LEFT")
title:SetText("Perl Player Buff Settings")
title:Show()

local cbEnabled = PPB_SettingsFrame:CreateCheckbox("Enabled","Enabled", function(self)
    local value = self:GetChecked() or false
    PPB:ChangeSettings_Enabled(value)
end)
cbEnabled:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)

local cbHandleWeaponBuff = PPB_SettingsFrame:CreateCheckbox("HandleWeaponBuff","Handle Weapons Buffs", function(self)
    local value = self:GetChecked() or false
    PPB:ChangeSettings_WeaponBuff(value)
end)
cbHandleWeaponBuff:SetPoint("TOPLEFT", cbEnabled, "BOTTOMLEFT", 0, -10)

local cbShowNativeCooldown = PPB_SettingsFrame:CreateCheckbox("ShowNativeCooldown","Show Native Cooldown", function(self)
    local value = self:GetChecked() or false
    PPB:ChangeSettings_ShowNativeCooldown(value)
end)
cbShowNativeCooldown:SetPoint("TOPLEFT", cbHandleWeaponBuff, "BOTTOMLEFT", 0, -10)

local cbShowOriginalTextTimer = PPB_SettingsFrame:CreateCheckbox("ShowOriginalTextTimer","Show Original Text Timer", function(self)
    local value = self:GetChecked() or false
    PPB:ChangeSettings_ShowOriginalTextTimer(value)
end)
cbShowOriginalTextTimer:SetPoint("TOPLEFT", cbShowNativeCooldown, "BOTTOMLEFT", 0, -10)


local sliderShowSecond = PPB_SettingsFrame:CreateSlider("ShowSecond","Show seconds", 1, 3,function(self, value, preValue)
    if value then
        PPB:ChangeSettings_ShowSecond(value - 1)
        if value == 1 then
            self.text:SetText("Hide seconds")
        end
        if value == 2 then
            self.text:SetText("Show seconds")
        end
        if value == 3 then
            self.text:SetText("Only show seconds under 10 minutes")
        end
    end
end)
sliderShowSecond.textLow:SetText("")
sliderShowSecond.textHigh:SetText("")
sliderShowSecond:SetWidth(100)
sliderShowSecond:SetPoint("TOPLEFT", cbShowOriginalTextTimer, "BOTTOMLEFT", 50, -20)

local sliderOffsetVertical = PPB_SettingsFrame:CreateSlider("OffsetVertical","Offset - vertical", -250, 250,function(self, value, preValue)
    PPB:ChangeSettings_OffsetVertical(value)
    self.text:SetText("Offset - vertical: " .. tostring(value))
end)
sliderOffsetVertical:SetPoint("TOPLEFT", sliderShowSecond, "BOTTOMLEFT", -40, -20)

local sliderOffsetHorizontal = PPB_SettingsFrame:CreateSlider("OffsetHorizontal","Offset - horizontal", -250, 250,function(self, value, preValue)
    PPB:ChangeSettings_OffsetHorizontal(value)
    self.text:SetText("Offset - horizontal: " .. tostring(value))
end)
sliderOffsetHorizontal:SetPoint("TOPLEFT", sliderOffsetVertical, "BOTTOMLEFT", 0, -30)

local sliderSpacingVertical = PPB_SettingsFrame:CreateSlider("SpacingVertical","Spacing - vertical", -100, 100,function(self, value, preValue)
    PPB:ChangeSettings_SpacingVertical(value)
    self.text:SetText("Spacing - vertical: " .. tostring(value))
end)
sliderSpacingVertical:SetPoint("TOPLEFT", sliderOffsetHorizontal, "BOTTOMLEFT", 0, -20)

local sliderSpacingHorizontal = PPB_SettingsFrame:CreateSlider("SpacingHorizontal","Spacing - horizontal", -100, 100,function(self, value, preValue)
    PPB:ChangeSettings_SpacingHorizontal(value)
    self.text:SetText("Spacing - horizontal: " .. tostring(value))
end)
sliderSpacingHorizontal:SetPoint("TOPLEFT", sliderSpacingVertical, "BOTTOMLEFT", 0, -30)

local sliderScaling = PPB_SettingsFrame:CreateSlider("Scaling","Scaling", 10, 200,function(self, value, preValue)
    PPB:ChangeSettings_Scaling(value / 100)
    self.text:SetText("Scaling: " .. tostring(value) .. "%")
end)
sliderScaling:SetPoint("TOPLEFT", sliderSpacingHorizontal, "BOTTOMLEFT", 0, -30)

local sliderBuffPerRow = PPB_SettingsFrame:CreateSlider("BuffPerRow","Buff per row", 1, 40,function(self, value, preValue)
    PPB:ChangeSettings_BuffPerRow(value)
    self.text:SetText("Buff per row: " .. tostring(value))
end)
sliderBuffPerRow:SetPoint("TOPLEFT", sliderScaling, "BOTTOMLEFT", 0, -30)

local sliderMaxNumberOfRow = PPB_SettingsFrame:CreateSlider("MaxNumberOfRow","Maximum number of row", 1, 10,function(self, value, preValue)
    PPB:ChangeSettings_MaxNumberOfRow(value)
    self.text:SetText("Maximum number of row: " .. tostring(value))
end)
sliderMaxNumberOfRow:SetPoint("TOPLEFT", sliderBuffPerRow, "BOTTOMLEFT", 0, -30)



function PPB_SettingsFrame:Refresh()
    local v = PPB:GetSettingValue("enabled")
    cbEnabled:SetChecked(v)

    local v = PPB:GetSettingValue("weaponBuff")
    cbHandleWeaponBuff:SetChecked(v)

    local v = PPB:GetSettingValue("showNativeCooldown")
    cbShowNativeCooldown:SetChecked(v)

    local v = PPB:GetSettingValue("showOriginalTextTimer")
    cbShowOriginalTextTimer:SetChecked(v)

    local v = PPB:GetSettingValue("showSecond")
    sliderShowSecond:SetValue(v + 1)


    local v = PPB:GetSettingValue("offsetVertical")
    sliderOffsetVertical:SetValue(v)

    local v = PPB:GetSettingValue("offsetHorizontal")
    sliderOffsetHorizontal:SetValue(v)


    local v = PPB:GetSettingValue("spacingVertical")
    sliderSpacingVertical:SetValue(v)

    local v = PPB:GetSettingValue("spacingHorizontal")
    sliderSpacingHorizontal:SetValue(v)


    local v = math.floor(PPB:GetSettingValue("scaling") * 100)
    sliderScaling:SetValue(v)


    local v = PPB:GetSettingValue("buffPerRow")
    sliderBuffPerRow:SetValue(v)

    local v = PPB:GetSettingValue("maxNumberOfRow")
    sliderMaxNumberOfRow:SetValue(v)
end

InterfaceOptions_AddCategory(PPB_SettingsFrame);
