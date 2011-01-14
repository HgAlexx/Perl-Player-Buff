--[[

Originaly created by Global, current author of Perl Classic Units Frame

Perl Player Buff is now maintained by Leliel AKA :
- Leliel at Curse.com
- Leliel, Yui, Nerv, Neon at EU-Ysondre

A set of new features has been added, all off by default and managed by a separeted config frame.

List of new features (all toggleable):
- Set the number of buffs per line
- Display native blizzard cooldown on buff icon
- Hide perl text timer under buffs icon
- Handle weapon temporary enchant
(- Display castable buffs only)
(- Display curable buffs only)
- Show seconds under 10 minutes even when "hide seconds" is checked
- Adjustable vertical spacing
- Adjustable x offset
- Adjustable y offset

Planned features:
- Adjustable vertical orientation
- Adjustable horizontale orientation

--]]

---------------
-- Variables --
---------------
local addonName, _ = ...;
Perl_Player_Buff_Version = GetAddOnMetadata(addonName, 'Version');


Perl_Player_Buff_Config = {};

-- New Enhanced config table
PPB_Enhanced_Config = {};

-- global wraper
-- local _G = _G;


local Perl_Player_Buff_DebugMode = false;
--@do-not-package@
--Perl_Player_Buff_DebugMode = true;
--@end-do-not-package@

-- Hook Perl Config Function
local Original_Perl_Player_Set_Hide_Class_Level_Frame = nil;
local Original_Perl_Player_XPBar_Display = nil;
local Original_Perl_Player_Set_Show_Paladin_Power_Bar = nil;
local Original_Perl_Player_Set_Show_Shard_Bar_Frame = nil;
local Original_Perl_Player_Set_Show_Eclipse_Bar_Frame = nil;
local Original_Perl_Player_Set_Show_Rune_Frame = nil;
local Original_Perl_Player_Set_Show_Totem_Timers = nil;

local Perl_Player_Buff_Events = {}; -- event manager

-- Default Saved Variables (also set in Perl_Player_Buff_GetVars)
local buffalerts = 1;       -- alerts are enabled by default
local showbuffs = 1;        -- mod is on be default
local scale = 1;        -- default scale
local hideseconds = 0;      -- seconds are shown by default
local horizontalspacing = 10;   -- default horizontal spacing

-- Default Enhanced Saved Variables (also set in Perl_Player_Buff_GetVars_Enhanced)
local PPBEC_BuffPerLine = 10;
local PPBEC_ShowNativeCoolDown = false;
local PPBEC_ShowOriginalTextTimer = true;
local PPBEC_HandleWeaponBuff = false;
local PPBEC_DisplayCastableBuffs = false;
local PPBEC_DisplayCurableDebuff = false;
local PPBEC_ShowSecondUnder10m = false;
local PPBEC_xOffset = 0;
local PPBEC_yOffset = 0;
local PPBEC_VerticalSpacing = 15;   -- default vertical spacing

-- Default Local Variables
local Initialized = 0;    -- waiting to be initialized

local PPBEC_UpdateInterval = 0.1;
local PPBEC_CancelBuffStartTime = 0;

local playerName, playerClass;

local SpecialBar = nil;
local WeaponEnchantDuration = 60*60;

local Perl_Player_Buff_Script_Frame = nil;
local Perl_Player_Buff_DelayedInit = 0;

----------------------
-- Loading Function --
----------------------
function Perl_Player_Buff_OnLoad(self, ...)
   --save script frame
   Perl_Player_Buff_Script_Frame = self;
   -- Events
   self:RegisterEvent("PLAYER_ENTERING_WORLD");
   self:RegisterEvent("PLAYER_LOGIN");
   -- Scripts
   self.TimeSinceLastUpdate = 0;
   self:SetScript("OnEvent", Perl_Player_Buff_OnEvent);
   self:SetScript("OnUpdate", Perl_Player_Buff_OnUpdate);
end

---------------------------
-- Event/Update Handlers --
---------------------------
function Perl_Player_Buff_OnEvent(self, event, ...)
   local func = Perl_Player_Buff_Events[event];
   if (func) then
      func();
   else
      if Perl_Player_Buff_DebugMode then
         DEFAULT_CHAT_FRAME:AddMessage("Perl Player Buff: Report the following event error to the author: "..event);
      end
   end
end
function Perl_Player_Buff_OnUpdate(self, ...)
   if Perl_Player_Buff_DelayedInit ~= 0 then
      if (Perl_Player_Buff_DelayedInit + 2) < GetTime() then
         if Perl_Player_Buff_DebugMode then
            DEFAULT_CHAT_FRAME:AddMessage("|cff0000ff OnUpdate: Initialized=" .. Initialized);
         end
         Perl_Player_Buff_Script_Frame:SetScript("OnUpdate", nil);
         Perl_Player_Buff_Align(true);   -- delayed update of anchors
         Perl_Player_Buff_Align();
      end
   end
end

function Perl_Player_Buff_Events:PLAYER_LOGIN()
   if Perl_Player_Buff_DebugMode then
      DEFAULT_CHAT_FRAME:AddMessage("|cff0000ff PLAYER_LOGIN: Initialized=" .. Initialized);
   end
   Perl_Player_Buff_Initialize();
   Perl_Player_Buff_Script_Frame:UnregisterEvent("PLAYER_LOGIN");
end
function Perl_Player_Buff_Events:PLAYER_ENTERING_WORLD()
   if Perl_Player_Buff_DebugMode then
      DEFAULT_CHAT_FRAME:AddMessage("|cff0000ff PLAYER_ENTERING_WORLD: Initialized=" .. Initialized);
   end
   Perl_Player_Buff_Initialize();
end
function Perl_Player_Buff_Events:PLAYER_TOTEM_UPDATE()
   Perl_Player_Buff_Align(true); -- recompute FixAnchor location related to totem bar
end

-------------------------------
-- Loading Settings Function --
-------------------------------
function Perl_Player_Buff_Initialize()
   if Perl_Player_Buff_DebugMode then
      DEFAULT_CHAT_FRAME:AddMessage("|cff0000ff Perl_Player_Buff_Initialize: Initialized=" .. Initialized);
   end
   
   -- Code to be run after zoning or logging in goes here
   if (Initialized == 1) then
      Perl_Player_Buff_Set_Scale();
      Perl_Player_Buff_Align(true);
      Perl_Player_Buff_Align();
      return nil;
   end
   
   -- everything below is called only one time (first load)
   playerName = UnitName("player");
   _, playerClass = UnitClass("player");
   
   -- Check if a previous exists, if not, enable by default.
   if (type(Perl_Player_Buff_Config[playerName]) == "table") then
      Perl_Player_Buff_GetVars();
   else
      Perl_Player_Buff_UpdateVars();
   end
   
   -- Check if a previous exists, if not, enable by default.
   if (type(PPB_Enhanced_Config[playerName]) == "table") then
      Perl_Player_Buff_GetVars_Enhanced();
   else
      Perl_Player_Buff_UpdateVars_Enhanced();
   end
   
   -- hack Perl Config function, so we can update buff location
   Original_Perl_Player_XPBar_Display = Perl_Player_XPBar_Display;
   Perl_Player_XPBar_Display = Enhanced_Perl_Player_XPBar_Display;
   
   if playerClass == "PALADIN" then -- Paladin Power Bar
      Original_Perl_Player_Set_Show_Paladin_Power_Bar = Perl_Player_Set_Show_Paladin_Power_Bar;
      Perl_Player_Set_Show_Paladin_Power_Bar = Enhanced_Perl_Player_Set_Show_Paladin_Power_Bar;
      SpecialBar = PaladinPowerBar;
      elseif playerClass == "WARLOCK" then -- Shard Bar
      Original_Perl_Player_Set_Show_Shard_Bar_Frame = Perl_Player_Set_Show_Shard_Bar_Frame;
      Perl_Player_Set_Show_Shard_Bar_Frame = Enhanced_Perl_Player_Set_Show_Shard_Bar_Frame;
      SpecialBar = ShardBarFrame;
      elseif playerClass == "DRUID" then -- Eclipse Bar
      Original_Perl_Player_Set_Show_Eclipse_Bar_Frame = Perl_Player_Set_Show_Eclipse_Bar_Frame;
      Perl_Player_Set_Show_Eclipse_Bar_Frame = Enhanced_Perl_Player_Set_Show_Eclipse_Bar_Frame;
      SpecialBar = EclipseBarFrame;
      elseif playerClass == "SHAMAN" then -- Totem Timer
      Original_Perl_Player_Set_Show_Totem_Timers = Perl_Player_Set_Show_Totem_Timers;
      Perl_Player_Set_Show_Totem_Timers = Enhanced_Perl_Player_Set_Show_Totem_Timers;
      SpecialBar = TotemFrame;
      -- WeaponEnchantDuration = 60*30; -- Shaman has 30min WeaponEnchant, and what is the player use a oil ? hmm ?
      local Perl_Player_Vars = Perl_Player_GetVars();
      if Perl_Player_Buff_Script_Frame and Perl_Player_Vars and Perl_Player_Vars["totemtimers"] == 1 then
         Perl_Player_Buff_Script_Frame:RegisterEvent("PLAYER_TOTEM_UPDATE"); -- handle totem bar show/hide
      end;
      elseif playerClass == "DEATHKNIGHT" then -- Rune Frame
      Original_Perl_Player_Set_Show_Rune_Frame = Perl_Player_Set_Show_Rune_Frame;
      Perl_Player_Set_Show_Rune_Frame = Enhanced_Perl_Player_Set_Show_Rune_Frame;
      SpecialBar = RuneFrame;
   else
      SpecialBar = nil;
   end;
   
   -- Major config options.
   Perl_Player_BuffFrame:SetBackdropColor(0, 0, 0, 1);
   Perl_Player_BuffFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1);
   Perl_Player_UseBuffs(showbuffs);
   
   hooksecurefunc("BuffFrame_UpdateAllBuffAnchors", Perl_Player_Buff_Align);                           -- handle buff anchor
   hooksecurefunc("DebuffButton_UpdateAnchors", Perl_Player_Buff_DebuffButton_UpdateAnchors);          -- handle debuff anchor
   hooksecurefunc("AuraButton_UpdateDuration", Perl_Player_Buff_AuraButton_UpdateDuration );           -- handle buff, debuff and temp enchant duration
   --hooksecurefunc("BuffFrame_Update", Perl_Player_Buff_BuffFrame_Update);                              -- handle buff type and state (filter -> castable / curable)
   --hooksecurefunc("AuraButton_Update", Perl_Player_Buff_AuraButton_Update);
   
   Initialized = 1;
   
   Perl_Player_Buff_DelayedInit = GetTime();
end


--------------------
-- Buff Functions --
--------------------
function Perl_Player_GetStringTime(timenum)
   -- little fix
   timenum = floor(timenum + 0.5);
   local days, hours, minutes, seconds = ChatFrame_TimeBreakDown(timenum);
   local shours, sminutes, sseconds, smili, timestring;
   
   if seconds < 0 then
      seconds = 0
   end
   
   if (hours>0 and hours < 10) and days > 0 then
      shours = "0"..hours;
   else
      shours = ""..hours;
   end
   if (minutes>0 and minutes < 10) and (hours > 0 or days > 0) then
      sminutes = "0"..minutes;
   else
      sminutes = ""..minutes;
   end
   if (seconds < 10) and (minutes > 0 or hours > 0 or days > 0) then
      sseconds = "0"..seconds;
   else
      sseconds = ""..seconds;
   end
   
   if (days > 0) then
      if (hideseconds == 1) then
         timestring = days.."d"..shours.."h"..sminutes.."m";
      else
         timestring = days..":"..shours..":"..sminutes..":"..sseconds;
      end
   elseif (hours > 0) then
      if (hideseconds == 1) then
         timestring = shours.."h "..sminutes.."m";
      else
         timestring = shours..":"..sminutes..":"..sseconds;
      end
   elseif (minutes > 0) then
      if ((PPBEC_ShowSecondUnder10m and PPBEC_ShowSecondUnder10m == true and minutes < 10) or (hideseconds == 0)) then
         timestring = sminutes..":"..sseconds; -- <9:59
      else
         timestring = sminutes.."m"; -- >10m
      end
   else -- less than a minute
      timestring = sseconds.."s";
   end
   return timestring;
end

function Perl_Player_DisableWeaponHandle()
   for i=1, 3 do
      local buff = _G["TempEnchant"..i];
      if buff then
         -- reset anchors
         if ( buff.parent ~= TemporaryEnchantFrame ) then
            buff:SetParent(TemporaryEnchantFrame);
            buff.parent = TemporaryEnchantFrame;
         end
         buff:ClearAllPoints();
         if i == 1 then
            buff:SetPoint("TOPRIGHT", TemporaryEnchantFrame, 0, 0);
         elseif i == 2 then
            buff:SetPoint("RIGHT", _G["TempEnchant1"], "LEFT", -5, 0);
         elseif i == 3 then
            buff:SetPoint("RIGHT", _G["TempEnchant2"], "LEFT", -5, 0);
         end
         if buff.cdInitiated then
            local cooldownFrame = _G[buff:GetName().."Cooldown"];
            if cooldownFrame then
               CooldownFrame_SetTimer(cooldownFrame, 0, 0, 0);
            end
            buff.cdInitiated = false;
         end
      end
   end -- for
end

function Perl_Player_EnableWeaponHandle()
   --[[
   for i=1, 3 do
      local buff = _G["TempEnchant"..i];
      if buff then
         
      end
   end
   --]]
end

function Perl_Player_DisableDebuff()
  for i=1, DEBUFF_MAX_DISPLAY do
    local debuff = _G["DebuffButton" .. i];
    if debuff then
      debuff:ClearAllPoints();
      if ( debuff.parent ~= BuffFrame ) then
        debuff:SetParent(BuffFrame);
        debuff.parent = BuffFrame;
      end
    end
  end
end

function Perl_Player_UseBuffs(useperlbuffs)
   if (useperlbuffs == 1) then
      SetCVar("buffDurations", 0); -- be sure this is off -> save cpu
      SetCVar("consolidateBuffs", 0);
      if PPBEC_HandleWeaponBuff == true then
         --
      else
         Perl_Player_DisableWeaponHandle();
      end
      if Initialized then -- if called from config panel, refresh alignement and scale
         Perl_Player_Buff_Set_Scale();
         Perl_Player_Buff_Align(true);   -- update anchor location
         Perl_Player_Buff_Align();  -- update buffs locations
         securecall(BuffFrame_Update);
      end
   else
      SetCVar("buffDurations", 1); -- set on back, well, we don't really know the previous state :p
      SetCVar("consolidateBuffs", 1);
      Perl_Player_DisableWeaponHandle();
      Perl_Player_DisableDebuff();
      securecall(BuffFrame_Update);
   end;
end

-- Compatibility wrapper
function Perl_Player_Buff_Allign()
   Perl_Player_Buff_Align(true);
   Perl_Player_Buff_Align();
end

function Perl_Player_Buff_SpecBarYOffSet(frame, yFirstOffset)
    --[[
    check if the special bar is:
    - not nil
    - visible
    - anchor to Perl_Player_Frame
    - in visible screen zone ( x > 0 ) (Pler Player move the bar outside screen to hide it)
    --]]
   if frame and frame:IsVisible() and frame:GetParent():GetName() == "Perl_Player_Frame" and select(4, frame:GetPoint()) >= 0 then
      yFirstOffset = yFirstOffset - (frame:GetHeight()) ;
   end
   return yFirstOffset;
end


-- yFirstOffset values :
--  TRUE  = update anchor location
--  FALSE = update buffs locations (defaults)
function Perl_Player_Buff_Align(yFirstOffset)
   yFirstOffset = yFirstOffset or false;
   if yFirstOffset then
      Perl_Player_Buff_BuffFrameFixAnchor_UpdateAnchor();
   else
      securecall(Perl_Player_Buff_BuffFrame_UpdateAllBuffAnchors);
   end
end

--------------------------------
-- Buff Positioning Functions --
--------------------------------

-- adjust the FixAnchor offset values (X and Y)
function Perl_Player_Buff_BuffFrameFixAnchor_UpdateAnchor()
   
   if Perl_Player_Buff_DebugMode then
      DEFAULT_CHAT_FRAME:AddMessage("|cff0000ff Perl: Perl_Player_Buff_BuffFrameFixAnchor_UpdateAnchor called: ".. PPBEC_xOffset .. "|" .. PPBEC_yOffset);
   end
   
   if showbuffs ~= 1 then
      return
   end
   
   local xFirstOffset = PPBEC_xOffset;
   local yFirstOffset = PPBEC_yOffset;
   
   -- Perl StatFrame Height
   yFirstOffset = yFirstOffset - Perl_Player_StatsFrame:GetHeight();
   
   -- TODO orientation: skip that is going UP
   if SpecialBar ~= nil then
      yFirstOffset = Perl_Player_Buff_SpecBarYOffSet(SpecialBar, yFirstOffset)
   end;
   
   -- init first anchor relatively to the most left displayed frame, which is Perl_Player_NameFrame
   Perl_Player_BuffFrameFixAnchor:ClearAllPoints();
   Perl_Player_BuffFrameFixAnchor:SetPoint("TOPLEFT", Perl_Player_NameFrame, "BOTTOMLEFT", xFirstOffset, yFirstOffset);
   
   Perl_Player_BuffFrame:ClearAllPoints();
   Perl_Player_BuffFrame:SetPoint("TOPLEFT", Perl_Player_BuffFrameFixAnchor, "TOPLEFT", 0, 0);
   
end

local TopLeftAnchorBuff  = nil; -- the first frame of current line, needed to anchor the first of the next line
local CurrentAnchorBuff  = nil; -- the last frame anchored, needed to anchor the next
function Perl_Player_Buff_BuffFrame_UpdateAllBuffAnchors()
   if Perl_Player_Buff_DebugMode then
      DEFAULT_CHAT_FRAME:AddMessage("|cff0000ff Perl: Perl_Player_Buff_BuffFrame_UpdateAllBuffAnchors called: " .. BUFF_ACTUAL_DISPLAY);
   end
   
   if showbuffs ~= 1 then
      return
   end
   
   local buff;
   
   -- reset variables
   TopLeftAnchorBuff = nil;
   CurrentAnchorBuff = nil;
   
   -- for all TempEnchant
   local enchantCount = 0;
   if PPBEC_HandleWeaponBuff then
      for buffButtonIndex=1, 3 do
         buff = _G["TempEnchant"..buffButtonIndex];
         if buff then
            local cooldownFrame = _G["TempEnchant"..buffButtonIndex.."Cooldown"];
            if cooldownFrame then
               CooldownFrame_SetTimer(cooldownFrame, 0, 0, 0);
               buff.CoolDownIsRuuning = false;
               if Perl_Player_Buff_DebugMode then
                  DEFAULT_CHAT_FRAME:AddMessage("|cff0000ff UpdateAllBuffAnchors: " .. buff:GetName() .. " cdInitiated to false");
               end
            end;
            if buff:IsShown() then
               enchantCount = enchantCount + 1;
               -- move to location
               if ( buff.parent ~= Perl_Player_BuffFrame ) then
                  buff:SetParent(Perl_Player_BuffFrame);
                  buff.parent = Perl_Player_BuffFrame;
               end
               buff:ClearAllPoints();
               if (enchantCount == 1) then
                  buff:SetPoint("TOPLEFT", Perl_Player_BuffFrame, "TOPLEFT", 0, 0);
                  TopLeftAnchorBuff = buff;
               elseif ((buffButtonIndex-1)%PPBEC_BuffPerLine) == 0 then
                  -- new line, Set Current to topleft
                  CurrentAnchorBuff = TopLeftAnchorBuff;
                  
                  -- and Set next Topleft to current one
                  TopLeftAnchorBuff = buff;
                  
                  -- Set Next Button Anchor and Position, always on CurrentAnchorBuff
                  buff:SetPoint("TOPLEFT", CurrentAnchorBuff, "BOTTOMLEFT", 0, -PPBEC_VerticalSpacing); -- TODO orientation: do not negate verticalSpacing if going UP
               else
                  -- Set Next Button Anchor and Position, always on CurrentAnchorBuff
                  buff:SetPoint("TOPLEFT", CurrentAnchorBuff, "TOPRIGHT", horizontalspacing, 0);
               end
               -- Set current for next :)
               CurrentAnchorBuff = buff;
            end
         end;
      end -- for
   end
   
   for buffButtonIndex=1+enchantCount,BUFF_ACTUAL_DISPLAY+enchantCount do
      buff = _G["BuffButton"..(buffButtonIndex-enchantCount)];
      if ( buff.parent ~= Perl_Player_BuffFrame ) then
         buff:SetParent(Perl_Player_BuffFrame);
         buff.parent = Perl_Player_BuffFrame;
      end
      buff:ClearAllPoints();
      if ( buffButtonIndex == 1 ) then
         buff:SetPoint("TOPLEFT", Perl_Player_BuffFrame, "TOPLEFT", 0, 0);
         TopLeftAnchorBuff = buff;
         elseif ((buffButtonIndex-1)%PPBEC_BuffPerLine) == 0 then
         -- new line, Set Current to topleft
         CurrentAnchorBuff = TopLeftAnchorBuff;
         
         -- and Set next Topleft to current one
         TopLeftAnchorBuff = buff;
         
         -- Set Next Button Anchor and Position, always on CurrentAnchorBuff
         buff:SetPoint("TOPLEFT", CurrentAnchorBuff, "BOTTOMLEFT", 0, -PPBEC_VerticalSpacing); -- TODO orientation: do not negate verticalSpacing if going UP
      else
         -- Set Next Button Anchor and Position, always on CurrentAnchorBuff
         buff:SetPoint("TOPLEFT", CurrentAnchorBuff, "TOPRIGHT", horizontalspacing, 0);
      end
      
      -- Set current for next :)
      CurrentAnchorBuff = buff;
      
      local cooldownFrame = _G["BuffButton"..(buffButtonIndex-enchantCount).."Cooldown"];
      if cooldownFrame then
         CooldownFrame_SetTimer(cooldownFrame, 0, 0, 0);
         buff.CoolDownIsRuuning = false;
         if Perl_Player_Buff_DebugMode then
            DEFAULT_CHAT_FRAME:AddMessage("|cff0000ff UpdateAllBuffAnchors: " .. buff:GetName() .. " cdInitiated to false");
         end
      end;
   end -- for
end

local TopLeftAnchorDeBuff = nil; -- the first frame of current line, needed to anchor the first of the next line
local CurrentAnchorDeBuff = nil;
function Perl_Player_Buff_DebuffButton_UpdateAnchors(buttonName, index)
   if Perl_Player_Buff_DebugMode then
      DEFAULT_CHAT_FRAME:AddMessage("|cff0000ff Perl: Perl_Player_Buff_DebuffButton_UpdateAnchors called: " .. index);
   end
   
   if showbuffs ~= 1 then
      return
   end
   
   local buff = _G[buttonName..index];
   if (buff.parent ~= Perl_Player_BuffFrame) then
      buff:SetParent(Perl_Player_BuffFrame);
      buff.parent = Perl_Player_BuffFrame;
   end;
   buff:ClearAllPoints();
   if not buff.ButtonStyleIsSetup or buff.ButtonStyleIsSetup == false then
      local border = _G[buttonName..index.."Border"];
      if border then
        border:SetWidth(buff:GetWidth());
        border:SetHeight(buff:GetHeight());
        buff:SetWidth(buff:GetWidth()-2);
        buff:SetHeight(buff:GetHeight()-2);
        buff.ButtonStyleIsSetup = true;
      end
   end
   
   if (index == 1) then
      -- anchor to the first Buff on last row
      if BUFF_ACTUAL_DISPLAY > 0 then
         buff:SetPoint("TOPLEFT", TopLeftAnchorBuff, "BOTTOMLEFT", 0, -PPBEC_VerticalSpacing);
      else
         buff:SetPoint("TOPLEFT", Perl_Player_BuffFrame, "TOPLEFT", 0, 0);
      end
   elseif ((index-1)%PPBEC_BuffPerLine) == 0 then
      -- new line, Set Current to topleft
      CurrentAnchorDeBuff = TopLeftAnchorDeBuff;
      
      -- and Set next Topleft to current one
      TopLeftAnchorDeBuff = buff;
      
      -- Set Next Button Anchor and Position
      buff:ClearAllPoints();
      buff:SetPoint("TOPLEFT", CurrentAnchorDeBuff, "BOTTOMLEFT", 0, -PPBEC_VerticalSpacing);
   else
      -- Set Next Button Anchor and Position
      buff:ClearAllPoints();
      buff:SetPoint("TOPLEFT", _G[buttonName..(index-1)], "TOPRIGHT", horizontalspacing, 0);
   end
   
   -- border color is handled by blizzard code
   -- nothing to do
   
   -- if not buff.timeLeft or buff.timeLeft <= 0 then
   if buff.CoolDownIsRuuning and buff.CoolDownIsRuuning == true then
      local cooldownFrame = _G[buttonName..index.."Cooldown"];
      if cooldownFrame then
         CooldownFrame_SetTimer(cooldownFrame, 0, 0, 0);
         buff.CoolDownIsRuuning = false;
      end;
   end;
end

-- copy of the original blizzard function, for planned feature, maybe
function Perl_Player_Buff_TemporaryEnchantFrame_OnUpdate(self, elapsed)
   if showbuffs ~= 1 then
      return
   end
   
   if ( not PlayerFrame.unit or PlayerFrame.unit ~= "player" ) then
      -- don't show temporary enchants when the player isn't controlling himself
      TemporaryEnchantFrame_Hide();
      return;
   end
   
   TemporaryEnchantFrame_Update(GetWeaponEnchantInfo());
end


local UpdateDurationLastTime = 0;
function Perl_Player_Buff_AuraButton_UpdateDuration(auraButton, timeLeft)
   if showbuffs ~= 1 then
      local cooldownFrame = _G[auraButton:GetName().."Cooldown"];
      if cooldownFrame and cooldownFrame:IsShown() then
         CooldownFrame_SetTimer(cooldownFrame, 0, 0, 0);
      end
      return nil;
   end
   
   local duration = auraButton.duration;
   local name = auraButton:GetName();
   local CoolDownCreated = false;
   
   if ( PPBEC_ShowOriginalTextTimer == true and timeLeft and timeLeft > 0) then
      duration:SetText(Perl_Player_GetStringTime(timeLeft));
      if ( timeLeft < BUFF_DURATION_WARNING_TIME ) then
         duration:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
      else
         duration:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
      end
      duration:Show();
   else
      duration:Hide();
   end
   
   -- COOLDOWN BELOW
   
   local cooldownFrame = _G[auraButton:GetName().."Cooldown"];
   
   if (PPBEC_ShowNativeCoolDown and PPBEC_ShowNativeCoolDown == true) then
      if cooldownFrame == nil then
         cooldownFrame = CreateFrame("Cooldown", "$parentCooldown", auraButton, "CooldownFrameTemplate");
         CoolDownCreated = true;
      end
      
      if (name == "TempEnchant1") or (name == "TempEnchant2") or (name == "TempEnchant3") then
         if PPBEC_HandleWeaponBuff then
            if timeLeft and timeLeft > 0 then
               if not auraButton.CoolDownIsRuuning or auraButton.CoolDownIsRuuning == false then
                  local startTime = (GetTime()-WeaponEnchantDuration+timeLeft);
                  CooldownFrame_SetTimer(cooldownFrame, startTime, WeaponEnchantDuration, 1);
                  auraButton.CoolDownIsRuuning = true;
                  if Perl_Player_Buff_DebugMode then
                     DEFAULT_CHAT_FRAME:AddMessage("|cff0000ff UpdateDuration: " .. auraButton:GetName() .. " cdInitiated to true");
                  end
               end
            else
               CooldownFrame_SetTimer(cooldownFrame, 0, 0, 0);
               auraButton.CoolDownIsRuuning = false;
               if Perl_Player_Buff_DebugMode then
                  DEFAULT_CHAT_FRAME:AddMessage("|cff0000ff UpdateDuration: " .. auraButton:GetName() .. " cdInitiated to false");
               end
            end
         else
            if auraButton.CoolDownIsRuuning and auraButton.CoolDownIsRuuning == true then
               CooldownFrame_SetTimer(cooldownFrame, 0, 0, 0);
               auraButton.CoolDownIsRuuning = false;
               if Perl_Player_Buff_DebugMode then
                  DEFAULT_CHAT_FRAME:AddMessage("|cff0000ff UpdateDuration: " .. auraButton:GetName() .. " cdInitiated to false");
               end
            end
         end
      else
         if auraButton.expirationTime and timeLeft and timeLeft > 0 then
            if not auraButton.CoolDownIsRuuning or auraButton.CoolDownIsRuuning == false then
               CooldownFrame_SetTimer(cooldownFrame, auraButton.expirationTime - timeLeft, timeLeft, 1);
               auraButton.CoolDownIsRuuning = true;
            end
         else
            if cooldownFrame:IsShown() then
               CooldownFrame_SetTimer(cooldownFrame, 0, 0, 0);
               auraButton.CoolDownIsRuuning = false;
               -- should never pas here, since blizzard filter call to the function
            end;
         end
      end
   else
      if cooldownFrame ~= nil and auraButton:IsShown() then
         CooldownFrame_SetTimer(cooldownFrame, 0, 0, 0);
         auraButton.CoolDownIsRuuning = false;
      end
   end
   
   -- if has just been initiated, adjust to his buff frame
   if CoolDownCreated then
      cooldownFrame:SetWidth(auraButton:GetWidth());
      cooldownFrame:SetHeight(auraButton:GetHeight());
      cooldownFrame:SetFrameLevel(auraButton:GetFrameLevel()+1);
      cooldownFrame:SetFrameStrata(auraButton:GetFrameStrata());
      cooldownFrame:SetAllPoints(auraButton);
      cooldownFrame:SetReverse(true);
      if not auraButton.CoolDownIsRuuning or auraButton.CoolDownIsRuuning == false then
         CooldownFrame_SetTimer(cooldownFrame, 0, 0, 0); -- Hide CD is not show (but created))
      end;
   end;
end

--------------------------
-- GUI Config Functions --
--------------------------
function Perl_Player_Buff_Set_ShowBuffs(newvalue)
   if newvalue == true then newvalue = 1; end
   if newvalue == false then newvalue = 0; end
   showbuffs = newvalue;
   Perl_Player_Buff_UpdateVars();
   Perl_Player_UseBuffs(showbuffs);
   Perl_Player_Buff_Align(true);
end

function Perl_Player_Buff_Set_Alerts(newvalue)
   buffalerts = newvalue;
   Perl_Player_Buff_UpdateVars();
end

function Perl_Player_Buff_Set_Hide_Seconds(newvalue)
   if newvalue == true then newvalue = 1; end
   if newvalue == false then newvalue = 0; end
   hideseconds = newvalue;
   Perl_Player_Buff_UpdateVars();
end

function Perl_Player_Buff_Set_Horizontal_Spacing(number)
   if (number ~= nil) then
      horizontalspacing = number;
   else
      horizontalspacing = 10;
   end
   Perl_Player_Buff_UpdateVars();
   Perl_Player_Buff_Align();
end

function Perl_Player_Buff_Set_Scale(number)
   local unsavedscale;
   if (number ~= nil) then
      scale = (number / 100);                 -- convert the user input to a wow acceptable value
   end
   unsavedscale = 1 - UIParent:GetEffectiveScale() + scale;    -- run it through the scaling formula introduced in 1.9
   Perl_Player_BuffFrame:SetScale(unsavedscale);
   Perl_Player_Buff_UpdateVars();
end

-----------------------------------
-- GUI Enhanced Config Functions --
-----------------------------------

function Perl_Player_Buff_Set_BuffPerLine(number)
   if (number ~= nil) then
      PPBEC_BuffPerLine = number;
   else
      PPBEC_BuffPerLine = 10;
   end
   Perl_Player_Buff_UpdateVars_Enhanced();
   Perl_Player_Buff_Align();
end

function Perl_Player_Buff_Set_ShowNativeCoolDown(newvalue)
   PPBEC_ShowNativeCoolDown = newvalue;
   Perl_Player_Buff_UpdateVars_Enhanced();
end

local lastHS, lastVS = 10, 15;
function Perl_Player_Buff_Set_ShowOriginalTextTimer(newvalue)
   PPBEC_ShowOriginalTextTimer = newvalue;
   Perl_Player_Buff_UpdateVars_Enhanced();
   -- Perl_Player_Buff_Align();
end

function Perl_Player_Buff_Set_HandleWeaponBuff(newvalue)
   PPBEC_HandleWeaponBuff = newvalue;
   Perl_Player_Buff_UpdateVars_Enhanced();
   Perl_Player_UseBuffs(showbuffs);
end

function Perl_Player_Buff_Set_DisplayCastableBuffs(newvalue)
   PPBEC_DisplayCastableBuffs = newvalue;
   Perl_Player_Buff_UpdateVars_Enhanced();
   -- Perl_Player_Buff_BuffFrame_Update();
end

function Perl_Player_Buff_Set_DisplayCurableDebuff(newvalue)
   PPBEC_DisplayCurableDebuff = newvalue;
   Perl_Player_Buff_UpdateVars_Enhanced();
   -- Perl_Player_Buff_BuffFrame_Update();
end

function Perl_Player_Buff_Set_ShowSecondUnder10m(newvalue)
   PPBEC_ShowSecondUnder10m = newvalue;
   Perl_Player_Buff_UpdateVars_Enhanced();
end

function Perl_Player_Buff_Set_XOffset(number)
   if (number ~= nil) then
      PPBEC_xOffset = number;
   else
      PPBEC_xOffset = 0;
   end
   Perl_Player_Buff_UpdateVars_Enhanced();
   Perl_Player_Buff_Align(true);
end

function Perl_Player_Buff_Set_YOffset(number)
   if (number ~= nil) then
      PPBEC_yOffset = number;
   else
      PPBEC_yOffset = 0;
   end
   Perl_Player_Buff_UpdateVars_Enhanced();
   Perl_Player_Buff_Align(true);
end

function Perl_Player_Buff_Set_Vertical_Spacing(number)
   if (number ~= nil) then
      PPBEC_VerticalSpacing = number;
   else
      PPBEC_VerticalSpacing = 15;
   end
   Perl_Player_Buff_UpdateVars_Enhanced();
   Perl_Player_Buff_Align();
end

-- Hook Player Config Function for hideclasslevelframe Update
function Enhanced_Perl_Player_Set_Hide_Class_Level_Frame(newvalue)
   Original_Perl_Player_Set_Hide_Class_Level_Frame(newvalue);
   Perl_Player_Buff_Align(true);
end

-- Hook Player Config Function for xpbarstate Update
function Enhanced_Perl_Player_XPBar_Display(newvalue)
   Original_Perl_Player_XPBar_Display(newvalue);
   Perl_Player_Buff_Align(true);
end

-- Hook Player Config Function for paladinpowerbar Update
function Enhanced_Perl_Player_Set_Show_Paladin_Power_Bar(newvalue)
   Original_Perl_Player_Set_Show_Paladin_Power_Bar(newvalue);
   Perl_Player_Buff_Align(true);
end

-- Hook Player Config Function for shardbarframe Update
function Enhanced_Perl_Player_Set_Show_Shard_Bar_Frame(newvalue)
   Original_Perl_Player_Set_Show_Shard_Bar_Frame(newvalue);
   Perl_Player_Buff_Align(true);
end

-- Hook Player Config Function for eclipsebarframe Update
function Enhanced_Perl_Player_Set_Show_Eclipse_Bar_Frame(newvalue)
   Original_Perl_Player_Set_Show_Eclipse_Bar_Frame(newvalue);
   Perl_Player_Buff_Align(true);
end

-- Hook Player Config Function for totemtimer Update
function Enhanced_Perl_Player_Set_Show_Totem_Timers(newvalue)
   Original_Perl_Player_Set_Show_Totem_Timers(newvalue);
   if newvalue == 1 then
      Perl_Player_Buff_Script_Frame:RegisterEvent("PLAYER_TOTEM_UPDATE");
   else
      Perl_Player_Buff_Script_Frame:UnRegisterEvent("PLAYER_TOTEM_UPDATE");
   end;
   Perl_Player_Buff_Align(true);
end

-- Hook Player Config Function for runeframe Update
function Enhanced_Perl_Player_Set_Show_Rune_Frame(newvalue)
   Original_Perl_Player_Set_Show_Rune_Frame(newvalue);
   Perl_Player_Buff_Align(true);
end

------------------------------
-- Saved Variable Functions --
------------------------------
function Perl_Player_Buff_GetVars(name, updateflag)
   if (name == nil) then
      name = playerName;
   end
   
   buffalerts = Perl_Player_Buff_Config[name]["buffalerts"];
   showbuffs = Perl_Player_Buff_Config[name]["showbuffs"];
   scale = Perl_Player_Buff_Config[name]["scale"];
   hideseconds = Perl_Player_Buff_Config[name]["hideseconds"];
   horizontalspacing = Perl_Player_Buff_Config[name]["horizontalspacing"];
   
   if (buffalerts == nil) then
      buffalerts = 1;
   end
   if (showbuffs == nil) then
      showbuffs = 1;
   end
   if (scale == nil) then
      scale = 1;
   end
   if (hideseconds == nil) then
      hideseconds = 0;
   end
   if (horizontalspacing == nil) then
      horizontalspacing = 10;
   end
   
   if (updateflag == 1) then
      -- Save the new values
      Perl_Player_Buff_UpdateVars();
      
      -- Call any code we need to activate them
      Perl_Player_UseBuffs(showbuffs);
      Perl_Player_Buff_Set_Scale();
      return;
   end
   
   local vars = {
      ["buffalerts"] = buffalerts,
      ["showbuffs"] = showbuffs,
      ["scale"] = scale,
      ["hideseconds"] = hideseconds,
      ["horizontalspacing"] = horizontalspacing,
   }
   return vars;
end

function Perl_Player_Buff_UpdateVars(vartable)
   if (vartable ~= nil) then
      -- Sanity checks in case you use a load from an old version
      if (vartable["Global Settings"] ~= nil) then
         if (vartable["Global Settings"]["BuffAlerts"] ~= nil) then
            buffalerts = vartable["Global Settings"]["BuffAlerts"];
         else
            buffalerts = nil;
         end
         if (vartable["Global Settings"]["ShowBuffs"] ~= nil) then
            showbuffs = vartable["Global Settings"]["ShowBuffs"];
         else
            showbuffs = nil;
         end
         if (vartable["Global Settings"]["Scale"] ~= nil) then
            scale = vartable["Global Settings"]["Scale"];
         else
            scale = nil;
         end
         if (vartable["Global Settings"]["HideSeconds"] ~= nil) then
            hideseconds = vartable["Global Settings"]["HideSeconds"];
         else
            hideseconds = nil;
         end
         if (vartable["Global Settings"]["HorizontalSpacing"] ~= nil) then
            horizontalspacing = vartable["Global Settings"]["HorizontalSpacing"];
         else
            horizontalspacing = nil;
         end
      end
      
      -- Set the new values if any new values were found, same defaults as above
      if (buffalerts == nil) then
         buffalerts = 1;
      end
      if (showbuffs == nil) then
         showbuffs = 1;
      end
      if (scale == nil) then
         scale = 1;
      end
      if (hideseconds == nil) then
         hideseconds = 0;
      end
      if (horizontalspacing == nil) then
         horizontalspacing = 10;
      end
      
      -- Call any code we need to activate them
      Perl_Player_UseBuffs(showbuffs);
      Perl_Player_Buff_Set_Scale();
   end
   
   Perl_Player_Buff_Config[playerName] = {
      ["buffalerts"] = buffalerts,
      ["showbuffs"] = showbuffs,
      ["scale"] = scale,
      ["hideseconds"] = hideseconds,
      ["horizontalspacing"] = horizontalspacing,
   };
end

-- Enhanced Config Functions duplicate
function Perl_Player_Buff_GetVars_Enhanced(name, updateflag)
   if (name == nil) then
      name = playerName;
   end
   
   PPBEC_BuffPerLine = PPB_Enhanced_Config[name]["BuffPerLine"];
   PPBEC_ShowNativeCoolDown = PPB_Enhanced_Config[name]["ShowNativeCoolDown"];
   PPBEC_ShowOriginalTextTimer = PPB_Enhanced_Config[name]["ShowOriginalTextTimer"];
   PPBEC_HandleWeaponBuff = PPB_Enhanced_Config[name]["HandleWeaponBuff"];
   PPBEC_DisplayCastableBuffs = PPB_Enhanced_Config[name]["DisplayCastableBuffs"];
   PPBEC_DisplayCurableDebuff = PPB_Enhanced_Config[name]["DisplayCurableDebuff"];
   PPBEC_ShowSecondUnder10m = PPB_Enhanced_Config[name]["ShowSecondUnder10m"];
   PPBEC_xOffset = PPB_Enhanced_Config[name]["XOffset"];
   PPBEC_yOffset = PPB_Enhanced_Config[name]["YOffset"];
   PPBEC_VerticalSpacing = PPB_Enhanced_Config[name]["VerticalSpacing"];
   
   if (PPBEC_BuffPerLine == nil) then
      PPBEC_BuffPerLine = 10;
   end
   if (PPBEC_ShowNativeCoolDown == nil) then
      PPBEC_ShowNativeCoolDown = false;
   end
   if (PPBEC_ShowOriginalTextTimer == nil) then
      PPBEC_ShowOriginalTextTimer = true;
   else
      if (PPBEC_ShowOriginalTextTimer == false) then
         PPBEC_VerticalSpacing = PPBEC_VerticalSpacing or 1;
      else
         PPBEC_VerticalSpacing = PPBEC_VerticalSpacing or 15;
      end
   end
   if (PPBEC_HandleWeaponBuff == nil) then
      PPBEC_HandleWeaponBuff = false;
   end
   if (PPBEC_DisplayCastableBuffs == nil) then
      PPBEC_DisplayCastableBuffs = false;
   end
   if (PPBEC_DisplayCurableDebuff == nil) then
      PPBEC_DisplayCurableDebuff = false;
   end
   if (PPBEC_ShowSecondUnder10m == nil) then
      PPBEC_ShowSecondUnder10m = false;
   end
   if (PPBEC_xOffset == nil) then
      PPBEC_xOffset = 0;
   end
   if (PPBEC_yOffset == nil) then
      PPBEC_yOffset = 0;
   end
   if (PPBEC_VerticalSpacing == nil) then
      PPBEC_VerticalSpacing = 1;
   end
   
   if (updateflag == 1) then
      -- Save the new values
      Perl_Player_Buff_UpdateVars_Enhanced();
      
      -- Call any code we need to activate them
      Perl_Player_UseBuffs(showbuffs);
      Perl_Player_Buff_Align(true);
      Perl_Player_Buff_Align();
      return;
   end
   
   local vars = {
      ["BuffPerLine"] = PPBEC_BuffPerLine,
      ["ShowNativeCoolDown"] = PPBEC_ShowNativeCoolDown,
      ["ShowOriginalTextTimer"] = PPBEC_ShowOriginalTextTimer,
      ["HandleWeaponBuff"] = PPBEC_HandleWeaponBuff,
      ["DisplayCastableBuffs"] = PPBEC_DisplayCastableBuffs,
      ["DisplayCurableDebuff"] = PPBEC_DisplayCurableDebuff,
      ["ShowSecondUnder10m"] = PPBEC_ShowSecondUnder10m,
      ["XOffset"] = PPBEC_xOffset,
      ["YOffset"] = PPBEC_yOffset,
      ["VerticalSpacing"] = PPBEC_VerticalSpacing,
   }
   return vars;
end

function Perl_Player_Buff_UpdateVars_Enhanced(vartable)
   if (vartable ~= nil) then
      -- Sanity checks in case you use a load from an old version
      if (vartable["Global Settings"] ~= nil) then
         -- Enhanced Config
         if (vartable["Global Settings"]["BuffPerLine"] ~= nil) then
            PPBEC_BuffPerLine = vartable["Global Settings"]["BuffPerLine"];
         else
            PPBEC_BuffPerLine = nil;
         end
         if (vartable["Global Settings"]["ShowNativeCoolDown"] ~= nil) then
            PPBEC_ShowNativeCoolDown = vartable["Global Settings"]["ShowNativeCoolDown"];
         else
            PPBEC_ShowNativeCoolDown = nil;
         end
         if (vartable["Global Settings"]["ShowOriginalTextTimer"] ~= nil) then
            PPBEC_ShowOriginalTextTimer = vartable["Global Settings"]["ShowOriginalTextTimer"];
         else
            PPBEC_ShowOriginalTextTimer = nil;
         end
         if (vartable["Global Settings"]["HandleWeaponBuff"] ~= nil) then
            PPBEC_HandleWeaponBuff = vartable["Global Settings"]["HandleWeaponBuff"];
         else
            PPBEC_HandleWeaponBuff = nil;
         end
         if (vartable["Global Settings"]["DisplayCastableBuffs"] ~= nil) then
            PPBEC_DisplayCastableBuffs = vartable["Global Settings"]["DisplayCastableBuffs"];
         else
            PPBEC_DisplayCastableBuffs = nil;
         end
         if (vartable["Global Settings"]["DisplayCurableDebuff"] ~= nil) then
            PPBEC_DisplayCurableDebuff = vartable["Global Settings"]["DisplayCurableDebuff"];
         else
            PPBEC_DisplayCurableDebuff = nil;
         end
         if (vartable["Global Settings"]["ShowSecondUnder10m"] ~= nil) then
            ShowSecondUnder10m = vartable["Global Settings"]["ShowSecondUnder10m"];
         else
            ShowSecondUnder10m = nil;
         end
      end
      
      -- Set the new values for Enhanced config
      if (PPBEC_BuffPerLine == nil) then
         PPBEC_BuffPerLine = 10;
      end
      if (PPBEC_ShowNativeCoolDown == nil) then
         PPBEC_ShowNativeCoolDown = false;
      end
      if (PPBEC_ShowOriginalTextTimer == nil) then
         PPBEC_ShowOriginalTextTimer = 1;
      end
      if (PPBEC_HandleWeaponBuff == nil) then
         PPBEC_HandleWeaponBuff = false;
      end
      if (PPBEC_DisplayCastableBuffs == nil) then
         PPBEC_DisplayCastableBuffs = false;
      end
      if (PPBEC_DisplayCurableDebuff == nil) then
         PPBEC_DisplayCurableDebuff = false;
      end
      if (PPBEC_ShowSecondUnder10m == nil) then
         PPBEC_ShowSecondUnder10m = false;
      end
      if (PPBEC_xOffset == nil) then
         PPBEC_xOffset = 0;
      end
      if (PPBEC_yOffset == nil) then
         PPBEC_yOffset = 0;
      end
      if (PPBEC_VerticalSpacing == nil) then
         PPBEC_VerticalSpacing = 1;
      end
      
      -- Call any code we need to activate them
      Perl_Player_UseBuffs(showbuffs);
      Perl_Player_Buff_Set_Scale();
      Perl_Player_Buff_Align(true);
      Perl_Player_Buff_Align();
   end
   
   PPB_Enhanced_Config[playerName] = {
      ["BuffPerLine"] = PPBEC_BuffPerLine,
      ["ShowNativeCoolDown"] = PPBEC_ShowNativeCoolDown,
      ["ShowOriginalTextTimer"] = PPBEC_ShowOriginalTextTimer,
      ["HandleWeaponBuff"] = PPBEC_HandleWeaponBuff,
      ["DisplayCastableBuffs"] = PPBEC_DisplayCastableBuffs,
      ["DisplayCurableDebuff"] = PPBEC_DisplayCurableDebuff,
      ["ShowSecondUnder10m"] = PPBEC_ShowSecondUnder10m,
      ["XOffset"] = PPBEC_xOffset,
      ["YOffset"] = PPBEC_yOffset,
      ["VerticalSpacing"] = PPBEC_VerticalSpacing,
   };
end
