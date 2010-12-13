--[[

Perl Player Buff Enhanced Config is maintained by Leliel AKA :
- Leliel at Curse.com
- Leliel, Yui, Nerv, Neon at EU-Ysondre

Perl Player Buff Enhanced Config :
 - Allow to change new features in Perl Player Buff
 - Support LibDataBroker
 - Using Blizzard Interface Option Frame

--]]
local addonName, _ = ...;
addonName = string.replace(addonName, "_", " ");


PPBECConfigPanel = nil;

local FirstOpened = 0;
local panelWidth = 0;

local Perl_Player_Buff_Enhanced_Config_DataBroker = LibStub:GetLibrary("LibDataBroker-1.1")
local Perl_Player_Buff_Enhanced_Config_DataObject = Perl_Player_Buff_Enhanced_Config_DataBroker:NewDataObject(addonName, {
    type = 'launcher',
    text = addonName,
    icon = 'Interface\\AddOns\\Perl_Config\\Perl_Minimap_Button',
    OnClick = function(clickedframe, button)
        if button == 'RightButton' then
            if FirstOpened == 0 then
                InterfaceOptionsFrame_OpenToCategory(PPBECConfigPanel);
                FirstOpened = 1;
            else
                if PPBECConfigPanel:IsVisible() ~= 1 then
                    PPBECConfigPanel:refresh();
                    InterfaceOptionsFrame_OpenToCategory(PPBECConfigPanel);
                else
                    ToggleGameMenu();
                end
            end
        elseif button == 'LeftButton' then
            if Perl_Config_Toggle then
                Perl_Config_Toggle();
                if Perl_Config_Frame:IsShown() then
                    Perl_Config_Player_Buff_Display();
                end
            end
        end
    end,
    OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
            tooltip:AddLine('Perl Player Buff Enhanced Config')
            tooltip:AddLine(PPBEC_Localization["PPBEC/ToolTip/LeftButtonDesc"])
            tooltip:AddLine(PPBEC_Localization["PPBEC/ToolTip/RightButtonDesc"])
            tooltip:AddLine('')
            tooltip:AddLine(string.format(PPBEC_Localization["FT_Version"], Perl_Player_Buff_Version))
    end,
})
-- PPBEC_Localization[]
function getCurrentValue(key)
    local vartable = Perl_Player_Buff_GetVars_Enhanced();
    return vartable[key];
end

function ShowPanel(panel)
    panelWidth = 250;
    if panelWidth < 200 then panelWidth = 250 end
    
    local myTitle = panel:MakeTitleTextAndSubText(addonName, PPBEC_Localization["PPBEC/ConfigPanel/TitleDesc"]);
    myTitle:SetWidth(panelWidth);
    myTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -10);
    
    local mySliderBuffPerLine = panel:MakeSlider(
        'name', PPBEC_Localization["PPBEC/ConfigPanel/BuffPerLine/Name"],
        'description', PPBEC_Localization["PPBEC/ConfigPanel/BuffPerLine/Desc"],
        'minText', '1',
        'maxText', '40',
        'minValue', 1,
        'maxValue', 40,
        'step', 1,
        'default', 10,
        'current', getCurrentValue("BuffPerLine"),
        'setFunc', function(value) Perl_Player_Buff_Set_BuffPerLine(value); end,
        'currentTextFunc', function(value) return value end);
    mySliderBuffPerLine:SetPoint("TOPLEFT", myTitle, "BOTTOMLEFT", 0, -40);
    mySliderBuffPerLine:SetPoint("RIGHT", panel, "RIGHT", -10, 0);
    
    local mySliderXOffset = panel:MakeSlider(
        'name', PPBEC_Localization["PPBEC/ConfigPanel/XOffset/Name"],
        'description', PPBEC_Localization["PPBEC/ConfigPanel/XOffset/Desc"],
        'minText', '-200',
        'maxText', '200',
        'minValue', -200,
        'maxValue', 200,
        'step', 1,
        'default', 0,
        'current', getCurrentValue("XOffset"),
        'setFunc', function(value) Perl_Player_Buff_Set_XOffset(value); end,
        'currentTextFunc', function(value) return value end);
    mySliderXOffset:SetPoint("TOPLEFT", mySliderBuffPerLine, "BOTTOMLEFT", 0, -40);
    mySliderXOffset:SetPoint("RIGHT", panel, "RIGHT", -10, 0);
    
    local mySliderYOffset = panel:MakeSlider(
        'name', PPBEC_Localization["PPBEC/ConfigPanel/YOffset/Name"],
        'description', PPBEC_Localization["PPBEC/ConfigPanel/YOffset/Desc"],
        'minText', '-200',
        'maxText', '200',
        'minValue', -200,
        'maxValue', 200,
        'step', 1,
        'default', 0,
        'current', getCurrentValue("YOffset"),
        'setFunc', function(value) Perl_Player_Buff_Set_YOffset(value); end,
        'currentTextFunc', function(value) return value end);
    mySliderYOffset:SetPoint("TOPLEFT", mySliderXOffset, "BOTTOMLEFT", 0, -40);
    mySliderYOffset:SetPoint("RIGHT", panel, "RIGHT", -10, 0);
    
    local mySliderVerticalSpacing = panel:MakeSlider(
        'name', PPBEC_Localization["PPBEC/ConfigPanel/VerticalSpacing/Name"],
        'description', PPBEC_Localization["PPBEC/ConfigPanel/VerticalSpacing/Desc"],
        'minText', '0',
        'maxText', '100',
        'minValue', 0,
        'maxValue', 100,
        'step', 1,
        'default', 15,
        'current', getCurrentValue("VerticalSpacing"),
        'setFunc', function(value) Perl_Player_Buff_Set_Vertical_Spacing(value); end,
        'currentTextFunc', function(value) return value end);
    mySliderVerticalSpacing:SetPoint("TOPLEFT", mySliderYOffset, "BOTTOMLEFT", 0, -40);
    mySliderVerticalSpacing:SetPoint("RIGHT", panel, "RIGHT", -10, 0);
    
    local myCheckBoxShowNativeCoolDown = panel:MakeToggle(
        'name', PPBEC_Localization["PPBEC/ConfigPanel/ShowNativeCoolDown/Name"],
        'description', PPBEC_Localization["PPBEC/ConfigPanel/ShowNativeCoolDown/Desc"],
        'default', false,
        'getFunc', function() return getCurrentValue("ShowNativeCoolDown") end,
        'setFunc', function(value) Perl_Player_Buff_Set_ShowNativeCoolDown(value) end);
    myCheckBoxShowNativeCoolDown:SetPoint("TOPLEFT", mySliderVerticalSpacing, "BOTTOMLEFT", 0, -5);
    
    local myCheckBoxShowOriginalTextTimer = panel:MakeToggle(
        'name', PPBEC_Localization["PPBEC/ConfigPanel/ShowOriginalTextTimer/Name"],
        'description', PPBEC_Localization["PPBEC/ConfigPanel/ShowOriginalTextTimer/Desc"],
        'default', true,
        'getFunc', function() return getCurrentValue("ShowOriginalTextTimer"); end,
        'setFunc', function(value) Perl_Player_Buff_Set_ShowOriginalTextTimer(value); end);
    myCheckBoxShowOriginalTextTimer:SetPoint("TOPLEFT", myCheckBoxShowNativeCoolDown, "BOTTOMLEFT", 0, -5);
    
    local myCheckBoxHandleWeaponBuff = panel:MakeToggle(
        'name', PPBEC_Localization["PPBEC/ConfigPanel/HandleWeaponBuff/Name"],
        'description', PPBEC_Localization["PPBEC/ConfigPanel/HandleWeaponBuff/Desc"],
        'default', false,
        'getFunc', function() return getCurrentValue("HandleWeaponBuff") end,
        'setFunc', function(value) Perl_Player_Buff_Set_HandleWeaponBuff(value); end);
    myCheckBoxHandleWeaponBuff:SetPoint("TOPLEFT", myCheckBoxShowOriginalTextTimer, "BOTTOMLEFT", 0, -5);
    
    local myCheckBoxShowSecondUnder10m = panel:MakeToggle(
        'name', PPBEC_Localization["PPBEC/ConfigPanel/ShowSecondUnder10m/Name"],
        'description', PPBEC_Localization["PPBEC/ConfigPanel/ShowSecondUnder10m/Desc"],
        'default', false,
        'getFunc', function() return getCurrentValue("ShowSecondUnder10m") end,
        'setFunc', function(value) Perl_Player_Buff_Set_ShowSecondUnder10m(value); end);
    myCheckBoxShowSecondUnder10m:SetPoint("TOPLEFT", myCheckBoxHandleWeaponBuff, "BOTTOMLEFT", 0, -5);
    
    --[[
    local myCheckBoxDisplayCastableBuffs = panel:MakeToggle(
        'name', 'Display Castable Buffs Only',
        'description', 'Display only buff you can cast.',
        'default', false,
        'getFunc', function() return getCurrentValue("DisplayCastableBuffs") end,
        'setFunc', function(value) Perl_Player_Buff_Set_DisplayCastableBuffs(value); end);
    myCheckBoxDisplayCastableBuffs:SetPoint("TOPLEFT", myCheckBoxHandleWeaponBuff, "BOTTOMLEFT", 0, -10);
    
    local myCheckBoxDisplayCurableDebuff = panel:MakeToggle(
        'name', 'Display Curable Debuff Only',
        'description', 'Display only debuff you can cure.',
        'default', false,
        'getFunc', function() return getCurrentValue("DisplayCurableDebuff") end,
        'setFunc', function(value) Perl_Player_Buff_Set_DisplayCurableDebuff(value); end);
    myCheckBoxDisplayCurableDebuff:SetPoint("TOPLEFT", myCheckBoxDisplayCastableBuffs, "BOTTOMLEFT", 0, -10);
    --]]
end

PPBECConfigPanel = LibStub("LibSimpleOptions-1.0").AddOptionsPanel(addonName, ShowPanel);

function PPBECConfigPanel:Print(...)
    DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", "|cFF33FF99Perl Player Buff|r:", ...));
end
