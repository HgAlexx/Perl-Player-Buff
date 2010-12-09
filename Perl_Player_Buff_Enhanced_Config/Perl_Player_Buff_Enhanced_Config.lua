--[[

Perl Player Buff Enhanced Config is maintained by Leliel AKA :
- Leliel at Curse.com
- Leliel, Yui, Nerv, Neon at EU-Ysondre

Perl Player Buff Enhanced Config :
 - Allow to change new features in Perl Player Buff
 - Support LibDataBroker
 - Using Blizzard Interface Option Frame

--]]

local Perl_Player_Buff_Enhanced_Config_Version = GetAddOnMetadata('Perl_Player_Buff_Enhanced_Config', 'Version');

PPBECConfigPanel = nil;

local FirstOpened = 0;
local panelWidth = 0;

local Perl_Player_Buff_Enhanced_Config_DataBroker = LibStub:GetLibrary("LibDataBroker-1.1")
local Perl_Player_Buff_Enhanced_Config_DataObject = Perl_Player_Buff_Enhanced_Config_DataBroker:NewDataObject("Perl Player Buff Enhanced Config", {
    type = 'launcher',
    text = 'Perl Player Buff Enhanced Config v',
    icon = 'Interface\\AddOns\\Perl_Config\\Perl_Minimap_Button',
    OnClick = function(clickedframe, button)
        --if button == 'RightButton' then
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
        --end
    end,
    OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
            tooltip:AddLine('Perl Player Buff Enhanced Config')
            tooltip:AddLine('|cFFFFFFFF <Right Click>|r Open the options menu')
            tooltip:AddLine('')
            tooltip:AddLine('Version: |cFFFFFFFF '.. Perl_Player_Buff_Enhanced_Config_Version .. '|r')
            
    end,
})

function getCurrentValue(key)
    local vartable = Perl_Player_Buff_GetVars_Enhanced();
    return vartable[key];
end

function ShowPanel(panel)
    panelWidth = 250;
    if panelWidth < 200 then panelWidth = 250 end
    
    local myTitle = panel:MakeTitleTextAndSubText("Perl Player Buff Enhanced", "Change all new settings here.");
    myTitle:SetWidth(panelWidth);
    myTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -10);
    
    local mySliderBuffPerLine = panel:MakeSlider(
        'name', 'Buff per line',
        'description', 'How many buff do you want per line ?',
        'minText', '1',
        'maxText', '40',
        'minValue', 1,
        'maxValue', 40,
        'step', 1,
        'default', 10,
        'current', getCurrentValue("BuffPerLine"),
        'setFunc', function(value) Perl_Player_Buff_Set_BuffPerLine(value); end,
        'currentTextFunc', function(value) return value end);
    --mySliderBuffPerLine:SetWidth(panelWidth);
    mySliderBuffPerLine:SetPoint("TOPLEFT", myTitle, "BOTTOMLEFT", 0, -40);
    mySliderBuffPerLine:SetPoint("RIGHT", panel, "RIGHT", -10, 0);
    
    local mySliderXOffset = panel:MakeSlider(
        'name', 'X Offset',
        'description', 'X Offset from the anchor frame',
        'minText', '-200',
        'maxText', '200',
        'minValue', -200,
        'maxValue', 200,
        'step', 1,
        'default', 0,
        'current', getCurrentValue("XOffset"),
        'setFunc', function(value) Perl_Player_Buff_Set_XOffset(value); end,
        'currentTextFunc', function(value) return value end);
    --mySliderXOffset:SetWidth(panelWidth);
    mySliderXOffset:SetPoint("TOPLEFT", mySliderBuffPerLine, "BOTTOMLEFT", 0, -40);
    mySliderXOffset:SetPoint("RIGHT", panel, "RIGHT", -10, 0);
    
    local mySliderYOffset = panel:MakeSlider(
        'name', 'Y Offset',
        'description', 'Y Offset from the anchor frame',
        'minText', '-200',
        'maxText', '200',
        'minValue', -200,
        'maxValue', 200,
        'step', 1,
        'default', 0,
        'current', getCurrentValue("YOffset"),
        'setFunc', function(value) Perl_Player_Buff_Set_YOffset(value); end,
        'currentTextFunc', function(value) return value end);
    --mySliderYOffset:SetWidth(panelWidth);
    mySliderYOffset:SetPoint("TOPLEFT", mySliderXOffset, "BOTTOMLEFT", 0, -40);
    mySliderYOffset:SetPoint("RIGHT", panel, "RIGHT", -10, 0);
    
    local mySliderVerticalSpacing = panel:MakeSlider(
        'name', 'Vertical Spacing',
        'description', 'Y space between buff/debuff',
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
        'name', 'Show Native CoolDown',
        'description', 'Check this to add blizzard cooldown on buff icon.',
        'default', false,
        'getFunc', function() return getCurrentValue("ShowNativeCoolDown") end,
        'setFunc', function(value) Perl_Player_Buff_Set_ShowNativeCoolDown(value) end);
    myCheckBoxShowNativeCoolDown:SetPoint("TOPLEFT", mySliderVerticalSpacing, "BOTTOMLEFT", 0, -10);
    
    local myCheckBoxShowOriginalTextTimer = panel:MakeToggle(
        'name', 'Show Original Text Timer',
        'description', 'Uncheck this to hide original perl player buff timer',
        'default', true,
        'getFunc', function() return getCurrentValue("ShowOriginalTextTimer"); end,
        'setFunc', function(value) Perl_Player_Buff_Set_ShowOriginalTextTimer(value); end);
    myCheckBoxShowOriginalTextTimer:SetPoint("TOPLEFT", myCheckBoxShowNativeCoolDown, "BOTTOMLEFT", 0, -10);
    
    local myCheckBoxHandleWeaponBuff = panel:MakeToggle(
        'name', 'Handle Weapon Buff',
        'description', 'Check this to add weapon buff under Perl Player Frame',
        'default', false,
        'getFunc', function() return getCurrentValue("HandleWeaponBuff") end,
        'setFunc', function(value) Perl_Player_Buff_Set_HandleWeaponBuff(value); end);
    myCheckBoxHandleWeaponBuff:SetPoint("TOPLEFT", myCheckBoxShowOriginalTextTimer, "BOTTOMLEFT", 0, -10);
    
    local myCheckBoxShowSecondUnder10m = panel:MakeToggle(
        'name', 'Show Seconds Under 10 Minutes',
        'description', 'Even when you check "Hide Seconds", they are displayed under 10 minutes, just because the text size is fine in this case :)',
        'default', false,
        'getFunc', function() return getCurrentValue("ShowSecondUnder10m") end,
        'setFunc', function(value) Perl_Player_Buff_Set_ShowSecondUnder10m(value); end);
    myCheckBoxShowSecondUnder10m:SetPoint("TOPLEFT", myCheckBoxHandleWeaponBuff, "BOTTOMLEFT", 0, -10);
    
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

PPBECConfigPanel = LibStub("LibSimpleOptions-1.0").AddOptionsPanel("Perl Player Buff Enhanced", ShowPanel);

function PPBECConfigPanel:Print(...)
    DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", "|cFF33FF99Perl Player Buff Enhanced|r:", ...));
end
