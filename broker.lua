

local addonName, _ = ...;
addonNameProper = string.gsub(addonName, "_", " ");

local PPB_DataBroker = LibStub:GetLibrary("LibDataBroker-1.1")
local PPB_DataObject = PPB_DataBroker:NewDataObject(addonName, {
    type = 'launcher',
    label = addonNameProper,
    icon = 'Interface\\AddOns\\Perl_Config\\Perl_Minimap_Button',
    OnClick = function(clickedframe, button)
        if button == 'RightButton' then

            if PPB_SettingsFrame then
                InterfaceOptionsFrame_OpenToCategory(PPB_SettingsFrame)
                InterfaceOptionsFrame_OpenToCategory(PPB_SettingsFrame)
            end

        elseif button == 'LeftButton' then
            if Perl_Config_Toggle then
                Perl_Config_Toggle();
                if Perl_Config_Frame:IsShown() then
                    -- Perl_Config_Player_Buff_Display();
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
