local addonName, ns = ...;

local Core = ns.Core
local Config = ns.Config

local addonNameProper = string.gsub(addonName, "_", " ");

local PPB_DataBroker = LibStub:GetLibrary("LibDataBroker-1.1")
local PPB_DataObject = PPB_DataBroker:NewDataObject(addonName, {
    type = 'launcher',
    label = addonNameProper,
    icon = 'Interface\\AddOns\\Perl_Config\\Perl_Minimap_Button',
    OnClick = function()
        if Settings and Settings.OpenToCategory  then
            Settings.OpenToCategory(Config.category:GetID())
        else
            InterfaceOptionsFrame_OpenToCategory(Config.frame)
            InterfaceOptionsFrame_OpenToCategory(Config.frame)
        end
    end,
    OnTooltipShow = function(tooltip)
        if not tooltip or not tooltip.AddLine then return end
        tooltip:AddLine(addonName)
        tooltip:AddLine("Click to open options")
        tooltip:AddLine('')
        tooltip:AddLine(string.format(PPBEC_Localization["FT_Version"], Core.Version or ""))
    end,
})
