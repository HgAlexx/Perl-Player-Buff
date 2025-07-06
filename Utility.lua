local _, ns = ...

-- Local namespace
local Utility = {}
local addonName = "Perl Player Buff"
local coloredAddonName = "|cFF00FFFF" .. addonName .. "|r:"
local debugColoredAddonName = "|cFF33BB99" .. addonName .. "|r:"

-- Localize functions
local string_match = string.match
local string_find = string.find

-- Parameters
do
    Utility.DebugStatus = false
    --@debug@
    Utility.DebugStatus = true
    --@end-debug@

    Utility.Mode = 1
    Utility.IsClassic = false
    Utility.IsTBC = false
    Utility.IsWLK = false
    Utility.IsCataclysm = false
    Utility.IsMists = false
    Utility.IsRetail = false

    local _, _, _, interfaceVersion = GetBuildInfo()
    if interfaceVersion >= 10000 and interfaceVersion < 20500 then
        Utility.IsClassic = true
    elseif interfaceVersion >= 20500 and interfaceVersion < 30000 then
        Utility.IsTBC = true
    elseif interfaceVersion >= 30000 and interfaceVersion < 40000 then
        Utility.IsWLK = true
    elseif interfaceVersion >= 40000 and interfaceVersion < 50000 then
        Utility.IsCataclysm = true
    elseif interfaceVersion >= 50000 and interfaceVersion < 60000 then
        Utility.IsMists = true
    elseif interfaceVersion >= 90000 then
        Utility.IsRetail = true
    end
end

function Utility.GetTime()
    return (debugprofilestop() / 1000)
end

function Utility.Print(...)
    if Utility.Mode == 2 then
        print(coloredAddonName, ...)
    else
        DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", coloredAddonName, ...))
    end
end

function Utility.Debug(...)
    --@debug@
    if not Utility.DebugStatus then
        return
    end

    if Utility.Mode == 2 then
        print(debugColoredAddonName, ...)
    else
        local arg = {...}
        local t = ""
        for i, v in ipairs(arg) do
            if type(v) == "table" then
                for k, w in pairs(v) do
                    t = t .. ", " .. k .. "=" .. tostring(w)
                end
            else
                t = t .. " " .. tostring(v)
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage(debugColoredAddonName .. t)
    end
    --@end-debug@
end

function Utility.BoolToStr(value)
    if value then
        return "Yes"
    end
    return "No"
end

function Utility.Trim(s)
    return string_match(s,'^()%s*$') and '' or string_match(s,'^%s*(.*%S)')
end

function Utility.StringContains(string, needle)
    if string and needle then
        local found = string_find(string, needle, 1, true)
        if found == nil then
            return false
        end
        return true
    end
    return false
end

function Utility.StringSplit(str, pattern)
    local result = {}
    for each in str:gmatch(pattern) do
        table.insert(result, each)
    end
    return result
end

function Utility.TableCount(table)
    local c = 0
    if table then
        for _, v in pairs(table) do
            if v then
                c = c + 1
            end
        end
    end
    return c
end

-- Export
ns.Utility = Utility
