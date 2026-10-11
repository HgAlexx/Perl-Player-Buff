local _, ns = ...

-- Imports
local Utility = ns.Utility

-- Local namespace
local Widget = {}

local GameTooltip = GameTooltip
local function HideTooltip()
    GameTooltip:Hide()
end
local function ShowTooltip(self)
    if self.title then
        GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 25)
        GameTooltip:SetText(self.title)
        if self.tiptext then
            GameTooltip:AddLine(self.tiptext, 1, 1, 1)
        end
        if self.isSlider then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Scroll to change value.", 1, 1, 1)
        end
        GameTooltip:Show()
    end
end

-- From Buffet which itself use tekKonfigHeading
Widget.CreateHeaderTitle = function(parent, text, subtext)
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetPoint("RIGHT", -16, 0)
    title:SetText(text)
    title:SetJustifyH("LEFT")

    local lines = Utility.StringSplit(subtext, "[^\r\n]+")
    local count = Utility.TableCount(lines)

    if count <= 0 then
        count = 1
    end

    local subtitle = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    subtitle:SetHeight(count * 16)
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetPoint("RIGHT", parent, -16, 0)
    subtitle:SetNonSpaceWrap(true)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetJustifyV("TOP")
    subtitle:SetText(subtext)

    return title, subtitle
end

Widget.CreateCheckbox = function(parent, text, tooltip, initValue, onClick)
    local checkButton = CreateFrame("CheckButton", nil, parent, "ChatConfigCheckButtonTemplate")
    checkButton.Text:SetText(text)
    checkButton.title = text
    checkButton.tiptext = tooltip
    checkButton:SetChecked(initValue)
    checkButton:SetScript("OnClick", onClick)
    checkButton:SetScript("OnEnter", ShowTooltip)
    checkButton:SetScript("OnLeave", HideTooltip)

    return checkButton
end

Widget.CreateSlider = function(parent, text, tooltip, minVal, maxVal, onChanged)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider.isSlider = true
    slider:SetWidth(500)
    slider:SetOrientation('HORIZONTAL')
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider.valueStep = 1
    slider.Text:SetText(text)
    slider.Text:SetPoint("BOTTOMLEFT", slider, "TOPLEFT")
    slider.Low:SetText(minVal)
    slider.High:SetText(maxVal)
    slider.title = text
    slider.tiptext = tooltip
    slider.currentValue = nil
    slider:SetScript("OnValueChanged", function(self, value)
        if self.currentValue ~= value then
            onChanged(self, value, self.currentValue)
            self.currentValue = value
        end
    end)
    slider:SetScript("OnMouseWheel", function(self, delta)
        local value = self.currentValue;
        if (delta > 0) then
            value = value + 1
        end
        if (delta < 0) then
            value = value -1
        end
        self.SetValue(self, value)
    end)
    slider:SetScript("OnEnter", ShowTooltip)
    slider:SetScript("OnLeave", HideTooltip)

    return slider
end


-- Export
ns.Widget = Widget
