local addonName, ns = ...;

local Core = ns.Core
local Config = ns.Config

local addonNameProper = string.gsub(addonName, "_", " ");

local function PPB_OpenOptions()
    if Settings and Settings.OpenToCategory  then
        Settings.OpenToCategory(Config.category:GetID())
    else
        InterfaceOptionsFrame_OpenToCategory(Config.frame)
        InterfaceOptionsFrame_OpenToCategory(Config.frame)
    end
end


local PPB_DataBroker = LibStub:GetLibrary("LibDataBroker-1.1")
local PPB_DataObject = PPB_DataBroker:NewDataObject(addonName, {
    type = 'launcher',
    label = addonNameProper,
    icon = 'Interface\\Icons\\Inv_misc_gem_pearl_01',
    OnClick = function()
        PPB_OpenOptions()
    end,
    OnTooltipShow = function(tooltip)
        if not tooltip or not tooltip.AddLine then return end
        tooltip:SetText(addonNameProper)
        tooltip:AddLine("Click to open options", 1, 1, 1)
        tooltip:AddLine(' ')
        tooltip:AddLine(string.format("Version: %s", Core.Version or ""), 1, 1, 1)
    end,
})

function PPB_OnCompartmentClick(name, mouseButton, menuInputData, menu)
    PPB_OpenOptions()
end

function PPB_OnCompartmentEnter(name, buttonFrame)
    MenuUtil.ShowTooltip(buttonFrame, function(tooltip)
        tooltip:SetOwner(buttonFrame, "ANCHOR_LEFT")
        tooltip:SetText(addonNameProper)
        tooltip:AddLine("Click to open options", 1, 1, 1)
        tooltip:AddLine(' ')
        tooltip:AddLine(string.format("Version: %s", Core.Version or ""), 1, 1, 1)
    end)
end

function PPB_OnCompartmentLeave(addonName, buttonFrame)
    MenuUtil.HideTooltip(buttonFrame)
end
