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
addonName = string.gsub(addonName, "_", " ");


PPBECConfigPanelMain = nil;

local FirstOpened = 0;
local panelWidth = 0;

local Perl_Player_Buff_Enhanced_Config_DataBroker = LibStub:GetLibrary("LibDataBroker-1.1")
local Perl_Player_Buff_Enhanced_Config_DataObject = Perl_Player_Buff_Enhanced_Config_DataBroker:NewDataObject(addonName, {
    type = 'launcher',
    label = addonName,
    icon = 'Interface\\AddOns\\Perl_Config\\Perl_Minimap_Button',
    OnClick = function(clickedframe, button)
        if button == 'RightButton' then
            Perl_Player_Buff_Enhanced_Config_ToggleOptions();
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
            tooltip:AddLine(addonName)
            tooltip:AddLine(PPBEC_Localization["PPBEC/ToolTip/LeftButtonDesc"])
            tooltip:AddLine(PPBEC_Localization["PPBEC/ToolTip/RightButtonDesc"])
            tooltip:AddLine('')
            tooltip:AddLine(string.format(PPBEC_Localization["FT_Version"], Perl_Player_Buff_Version))
    end,
})

function Perl_Player_Buff_Enhanced_Config_ToggleOptions()
    if FirstOpened == 0 then
        InterfaceOptionsFrame_OpenToCategory(PPBECConfigPanelMain);
        FirstOpened = 1;
    else
        if PPBECConfigPanelMain:IsVisible() ~= 1 then
            PPBECConfigPanelMain:refresh();
            InterfaceOptionsFrame_OpenToCategory(PPBECConfigPanelMain);
        else
            InterfaceOptionsFrame_OpenToCategory(PPBECConfigPanelMain);
            -- securecall(ToggleGameMenu); -- doesn't work anymore :(
        end
    end
end

local function getCurrentValue(key)
   local vartable = Perl_Player_Buff_GetVars_Enhanced();
   return vartable[key];
end

local function getCurrentValueOriginal(key)
   local vartable = Perl_Player_Buff_GetVars();
   return vartable[key];
end

local function ShowPanelMain(panel)
    local myTitle = panel:MakeTitleTextAndSubText(addonName, PPBEC_Localization["PPBEC/ConfigPanel/TitleDesc"]);
    myTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -10);
    
    local myCheckBoxShowBuffs = panel:MakeToggle(
        'name', PPBEC_Localization["PPBEC/ConfigPanel/ShowBuffs/Name"],
        'description', PPBEC_Localization["PPBEC/ConfigPanel/ShowBuffs/Desc"],
        'default', true,
        'getFunc', function() return (getCurrentValueOriginal("showbuffs")==1) end,
        'setFunc', function(value) Perl_Player_Buff_Set_ShowBuffs(value);  end);
    myCheckBoxShowBuffs:SetPoint("TOPLEFT", myTitle, "BOTTOMLEFT", 0, -40);

    local myCheckBoxHandleWeaponBuff = panel:MakeToggle(
        'name', PPBEC_Localization["PPBEC/ConfigPanel/HandleWeaponBuff/Name"],
        'description', PPBEC_Localization["PPBEC/ConfigPanel/HandleWeaponBuff/Desc"],
        'default', false,
        'getFunc', function() return getCurrentValue("HandleWeaponBuff") end,
        'setFunc', function(value) Perl_Player_Buff_Set_HandleWeaponBuff(value); end);
    myCheckBoxHandleWeaponBuff:SetPoint("TOPLEFT", myCheckBoxShowBuffs, "BOTTOMLEFT", 0, -10);

end

local function ShowPanelPosition(panel)
    local myTitle = panel:MakeTitleTextAndSubText(addonName, PPBEC_Localization["PPBEC/ConfigPanelPosition/TitleDesc"]);
    myTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -10);
    
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
    mySliderXOffset:SetPoint("TOPLEFT", myTitle, "BOTTOMLEFT", 0, -40);
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
    
end

local function ShowPanelStyle(panel)
    local myTitle = panel:MakeTitleTextAndSubText(addonName, PPBEC_Localization["PPBEC/ConfigPanelStyle/TitleDesc"]);
    myTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -10);
    
    local mySliderScale = panel:MakeSlider(
        'name', PPBEC_Localization["PPBEC/ConfigPanel/Scale/Name"],
        'description', PPBEC_Localization["PPBEC/ConfigPanel/Scale/Desc"],
        'minText', '1',
        'maxText', '150',
        'minValue', 1,
        'maxValue', 150,
        'step', 1,
        'default', 100,
        'current', getCurrentValueOriginal("scale")*100,
        'setFunc', function(value) Perl_Player_Buff_Set_Scale(value) end,
        'currentTextFunc', function(value) return value end);
    mySliderScale:SetPoint("TOPLEFT", myTitle, "BOTTOMLEFT", 0, -40);
    mySliderScale:SetPoint("RIGHT", panel, "RIGHT", -10, 0);
    
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
        'setFunc', function(value) Perl_Player_Buff_Set_BuffPerLine(value) end,
        'currentTextFunc', function(value) return value end);
    mySliderBuffPerLine:SetPoint("TOPLEFT", mySliderScale, "BOTTOMLEFT", 0, -40);
    mySliderBuffPerLine:SetPoint("RIGHT", panel, "RIGHT", -10, 0);
    
    local mySliderHorizontalSpacing = panel:MakeSlider(
        'name', PPBEC_Localization["PPBEC/ConfigPanel/HorizontalSpacing/Name"],
        'description', PPBEC_Localization["PPBEC/ConfigPanel/HorizontalSpacing/Desc"],
        'minText', '-100',
        'maxText', '100',
        'minValue', -100,
        'maxValue', 100,
        'step', 1,
        'default', 10,
        'current', getCurrentValueOriginal("horizontalspacing"),
        'setFunc', function(value) Perl_Player_Buff_Set_Horizontal_Spacing(value) end,
        'currentTextFunc', function(value) return value end);
    mySliderHorizontalSpacing:SetPoint("TOPLEFT", mySliderBuffPerLine, "BOTTOMLEFT", 0, -40);
    mySliderHorizontalSpacing:SetPoint("RIGHT", panel, "RIGHT", -10, 0);
    
    local mySliderVerticalSpacing = panel:MakeSlider(
        'name', PPBEC_Localization["PPBEC/ConfigPanel/VerticalSpacing/Name"],
        'description', PPBEC_Localization["PPBEC/ConfigPanel/VerticalSpacing/Desc"],
        'minText', '-100',
        'maxText', '100',
        'minValue', -100,
        'maxValue', 100,
        'step', 1,
        'default', 15,
        'current', getCurrentValue("VerticalSpacing"),
        'setFunc', function(value) Perl_Player_Buff_Set_Vertical_Spacing(value); end,
        'currentTextFunc', function(value) return value end);
    mySliderVerticalSpacing:SetPoint("TOPLEFT", mySliderHorizontalSpacing, "BOTTOMLEFT", 0, -40);
    mySliderVerticalSpacing:SetPoint("RIGHT", panel, "RIGHT", -10, 0);
    
    local myCheckBoxShowNativeCoolDown = panel:MakeToggle(
        'name', PPBEC_Localization["PPBEC/ConfigPanel/ShowNativeCoolDown/Name"],
        'description', PPBEC_Localization["PPBEC/ConfigPanel/ShowNativeCoolDown/Desc"],
        'default', false,
        'getFunc', function() return getCurrentValue("ShowNativeCoolDown") end,
        'setFunc', function(value) Perl_Player_Buff_Set_ShowNativeCoolDown(value) end);
    myCheckBoxShowNativeCoolDown:SetPoint("TOPLEFT", mySliderVerticalSpacing, "BOTTOMLEFT", 0, -40);
    
    local myCheckBoxShowOriginalTextTimer = panel:MakeToggle(
        'name', PPBEC_Localization["PPBEC/ConfigPanel/ShowOriginalTextTimer/Name"],
        'description', PPBEC_Localization["PPBEC/ConfigPanel/ShowOriginalTextTimer/Desc"],
        'default', true,
        'getFunc', function() return getCurrentValue("ShowOriginalTextTimer"); end,
        'setFunc', function(value) Perl_Player_Buff_Set_ShowOriginalTextTimer(value); end);
    myCheckBoxShowOriginalTextTimer:SetPoint("TOPLEFT", myCheckBoxShowNativeCoolDown, "BOTTOMLEFT", 0, -5);
    
    local myCheckBoxShowSecond = panel:MakeToggle(
        'name', PPBEC_Localization["PPBEC/ConfigPanel/ShowSecond/Name"],
        'description', PPBEC_Localization["PPBEC/ConfigPanel/ShowSecond/Desc"],
        'default', true,
        'getFunc', function() return (getCurrentValueOriginal("hideseconds") == 0) end,
        'setFunc', function(value) Perl_Player_Buff_Set_Hide_Seconds(not value); end);
    myCheckBoxShowSecond:SetPoint("TOPLEFT", myCheckBoxShowOriginalTextTimer, "BOTTOMLEFT", 0, -5);

    local myCheckBoxShowSecondUnder10m = panel:MakeToggle(
        'name', PPBEC_Localization["PPBEC/ConfigPanel/ShowSecondUnder10m/Name"],
        'description', PPBEC_Localization["PPBEC/ConfigPanel/ShowSecondUnder10m/Desc"],
        'default', false,
        'getFunc', function() return getCurrentValue("ShowSecondUnder10m") end,
        'setFunc', function(value) Perl_Player_Buff_Set_ShowSecondUnder10m(value); end);
    myCheckBoxShowSecondUnder10m:SetPoint("TOPLEFT", myCheckBoxShowSecond, "BOTTOMLEFT", 0, -5);

end

local function ShowPanelFilter(panel)
    local myTitle = panel:MakeTitleTextAndSubText(addonName, PPBEC_Localization["PPBEC/ConfigPanelFilter/TitleDesc"]);
    myTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -10);
    
    local myCheckBoxDisplayCastableBuffs = panel:MakeToggle(
        'name', 'Display Castable Buffs Only NOT WORKING',
        'description', 'Display only buff you can cast. NOT WORKING',
        'default', false,
        'getFunc', function() return getCurrentValue("DisplayCastableBuffs") end,
        'setFunc', function(value) Perl_Player_Buff_Set_DisplayCastableBuffs(value); end);
    myCheckBoxDisplayCastableBuffs:SetPoint("TOPLEFT", myTitle, "BOTTOMLEFT", 0, -40);
    
    local myCheckBoxDisplayCurableDebuff = panel:MakeToggle(
        'name', 'Display Curable Debuff Only NOT WORKING',
        'description', 'Display only debuff you can cure. NOT WORKING',
        'default', false,
        'getFunc', function() return getCurrentValue("DisplayCurableDebuff") end,
        'setFunc', function(value) Perl_Player_Buff_Set_DisplayCurableDebuff(value); end);
    myCheckBoxDisplayCurableDebuff:SetPoint("TOPLEFT", myCheckBoxDisplayCastableBuffs, "BOTTOMLEFT", 0, -10);
end

PPBECConfigPanelMain = LibStub("LibSimpleOptions-1.0").AddOptionsPanel(addonName, ShowPanelMain);
-- PPBECConfigPanelFilter = LibStub("LibSimpleOptions-1.0").AddSuboptionsPanel(addonName, "Filter", ShowPanelFilter)
PPBECConfigPanelPosition = LibStub("LibSimpleOptions-1.0").AddSuboptionsPanel(addonName, "Position", ShowPanelPosition)
PPBECConfigPanelStyle = LibStub("LibSimpleOptions-1.0").AddSuboptionsPanel(addonName, "Style", ShowPanelStyle)

function PPBECConfigPanelMain:Print(...)
    DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", "|cFF33FF99" .. addonName .. "|r:", ...));
end
