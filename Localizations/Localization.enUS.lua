PPBEC_Localization = {};

function PPBEC_LocalizationIndexFunction(t, key)
    return "[no translation for " .. (key or "unknown") .. "]";
end
setmetatable(PPBEC_Localization, {__index=PPBEC_LocalizationIndexFunction});

--@do-not-package@
PPBEC_Localization["FT_Version"] = "Version: %s"
PPBEC_Localization["PPBEC/ConfigPanel/BuffPerLine/Desc"] = "How many buff do you want per line ?"
PPBEC_Localization["PPBEC/ConfigPanel/BuffPerLine/Name"] = "Buff per line"
PPBEC_Localization["PPBEC/ConfigPanel/HandleWeaponBuff/Desc"] = "Move weapon enchantment under the player frame like with buffs."
PPBEC_Localization["PPBEC/ConfigPanel/HandleWeaponBuff/Name"] = "Handle weapon enchantment"
PPBEC_Localization["PPBEC/ConfigPanel/HorizontalSpacing/Desc"] = "Horizontal space between buff/debuff icons"
PPBEC_Localization["PPBEC/ConfigPanel/HorizontalSpacing/Name"] = "Horizontal Spacing"
PPBEC_Localization["PPBEC/ConfigPanel/Scale/Desc"] = "Adjust the scale of buffs and debuffs."
PPBEC_Localization["PPBEC/ConfigPanel/Scale/Name"] = "Scale"
PPBEC_Localization["PPBEC/ConfigPanel/ShowBuffs/Desc"] = "Move buffs and debuffs under the player frame."
PPBEC_Localization["PPBEC/ConfigPanel/ShowBuffs/Name"] = "Handle buffs and debuffs"
PPBEC_Localization["PPBEC/ConfigPanel/ShowNativeCoolDown/Desc"] = "Add cooldown visual effect on buff and debuff, better result if you use with another addon like OmniCC."
PPBEC_Localization["PPBEC/ConfigPanel/ShowNativeCoolDown/Name"] = "Show native cooldown"
PPBEC_Localization["PPBEC/ConfigPanel/ShowOriginalTextTimer/Desc"] = "Show original text timer under buff icon."
PPBEC_Localization["PPBEC/ConfigPanel/ShowOriginalTextTimer/Name"] = "Show original text timer"
PPBEC_Localization["PPBEC/ConfigPanel/ShowSecond/Desc"] = "Show seconds on the original text timer"
PPBEC_Localization["PPBEC/ConfigPanel/ShowSecond/Name"] = "Show seconds"
PPBEC_Localization["PPBEC/ConfigPanel/ShowSecondUnder10m/Desc"] = "If original timers are displayed, and even if you have checked \"Hide Seconds\" into perl options, under 10 minutes, second will be display again."
PPBEC_Localization["PPBEC/ConfigPanel/ShowSecondUnder10m/Name"] = "Show seconds under 10 minutes"
PPBEC_Localization["PPBEC/ConfigPanel/TitleDesc"] = "Change all new settings here."
PPBEC_Localization["PPBEC/ConfigPanel/VerticalSpacing/Desc"] = "Vertical space between buff/debuff rows"
PPBEC_Localization["PPBEC/ConfigPanel/VerticalSpacing/Name"] = "Vertical Spacing"
PPBEC_Localization["PPBEC/ConfigPanel/XOffset/Desc"] = "X Offset from the parent frame"
PPBEC_Localization["PPBEC/ConfigPanel/XOffset/Name"] = "X Offset"
PPBEC_Localization["PPBEC/ConfigPanel/YOffset/Desc"] = "Y Offset from the parent frame"
PPBEC_Localization["PPBEC/ConfigPanel/YOffset/Name"] = "Y Offset"
PPBEC_Localization["PPBEC/ConfigPanelFilter/TitleDesc"] = "Settings related to filters."
PPBEC_Localization["PPBEC/ConfigPanelPosition/TitleDesc"] = "Settings related to position."
PPBEC_Localization["PPBEC/ConfigPanelStyle/TitleDesc"] = "Settings related to style."
PPBEC_Localization["PPBEC/ToolTip/LeftButtonDesc"] = "|cFFFFFFFF <Left Click>|r Open Perl Classic Unit Frames options menu|r"
PPBEC_Localization["PPBEC/ToolTip/RightButtonDesc"] = "|cFFFFFFFF <Right Click>|r Open Perl Player Buff Enhanced options menu|r"
--@end-do-not-package@

--@localization(locale="enUS", format="lua_additive_table", handle-unlocalized="english", table-name="PPBEC_Localization")@
