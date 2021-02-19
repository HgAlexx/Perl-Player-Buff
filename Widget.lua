local _, ns = ...

-- Imports
local Utility = ns.Utility

-- Local namespace
local Widget = {}

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
    local checkButton = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    checkButton.Text:SetText(text)
    checkButton.tiptext = tooltip
    checkButton:SetChecked(initValue)
    checkButton:SetScript("OnClick", onClick)

    return checkButton
end

Widget.CreateSlider = function(parent, text, tooltip, minVal, maxVal, onChanged)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
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
    slider.tiptext = tooltip
    slider.currentValue = nil
    slider:SetScript("OnValueChanged", function(self, value)
        if self.currentValue ~= value then
            onChanged(self, value, self.currentValue)
            self.currentValue = value
        end
    end)

    return slider
end


-- Export
ns.Widget = Widget
