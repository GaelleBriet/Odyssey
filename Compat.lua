local ADDON, ns = ...

local Compat = {}
ns.Compat = Compat

-- feature -> reason it is unavailable (read by /odyssey dump)
Compat.missing = {}

function Compat.isMaxLevel()
  if IsPlayerAtEffectiveMaxLevel then return IsPlayerAtEffectiveMaxLevel() and true or false end
  if GetMaxPlayerLevel then return UnitLevel("player") >= GetMaxPlayerLevel() end
  if MAX_PLAYER_LEVEL then return UnitLevel("player") >= MAX_PLAYER_LEVEL end
  return false
end

function Compat.xpApi()
  return {
    unitXP = function() return UnitXP("player") end,
    unitXPMax = function() return UnitXPMax("player") end,
    unitLevel = function() return UnitLevel("player") end,
    restedXP = function() return GetXPExhaustion() end,
    isMaxLevel = Compat.isMaxLevel,
    isResting = Compat.isResting,
    now = GetTime,
  }
end

local function collectModern()
  local ready = C_QuestLog.ReadyForTurnIn or C_QuestLog.IsComplete
  local list = {}
  for i = 1, C_QuestLog.GetNumQuestLogEntries() do
    local info = C_QuestLog.GetInfo(i)
    if info and not info.isHeader and info.questID and ready(info.questID) then
      local xp = GetQuestLogRewardXP(info.questID)
      if xp and xp > 0 then list[#list + 1] = { title = info.title, xp = xp } end
    end
  end
  return list
end

local function collectClassic()
  local list = {}
  local previous = GetQuestLogSelection and GetQuestLogSelection()
  for i = 1, (GetNumQuestLogEntries()) do
    local title, _, _, isHeader, _, isComplete = GetQuestLogTitle(i)
    if title and not isHeader and isComplete and isComplete > 0 then
      SelectQuestLogEntry(i)
      local xp = GetQuestLogRewardXP()
      if xp and xp > 0 then list[#list + 1] = { title = title, xp = xp } end
    end
  end
  if previous and SelectQuestLogEntry then SelectQuestLogEntry(previous) end
  return list
end

-- Completed quests with their XP reward, or nil if this client cannot tell us.
function Compat.completedQuestXP()
  local collect
  if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo
     and (C_QuestLog.ReadyForTurnIn or C_QuestLog.IsComplete) and GetQuestLogRewardXP then
    collect = collectModern
  elseif GetNumQuestLogEntries and GetQuestLogTitle and SelectQuestLogEntry and GetQuestLogRewardXP then
    collect = collectClassic
  else
    Compat.missing.quests = "quest log API not found"
    return nil
  end
  local ok, result = pcall(collect)
  if not ok then
    Compat.missing.quests = tostring(result)
    return nil
  end
  Compat.missing.quests = nil
  return result
end

-- Turns a GlobalStrings format ("You gain %d experience.") into an anchored Lua pattern.
local function formatToPattern(fmt)
  local escaped = fmt:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
  escaped = escaped:gsub("%%%%d", "%%d+"):gsub("%%%%s", ".+")
  return "^" .. escaped .. "$"
end

-- CHAT_MSG_COMBAT_XP_GAIN also fires for quest rewards ("You gain 600 experience.").
-- The client's own localized string tells the two apart, so this works in every language.
function Compat.isKillXPMessage(msg)
  local fmt = COMBATLOG_XP_GAIN_FIRST_PERSON_UNNAMED
  if not fmt or not msg then return true end
  return not msg:find(formatToPattern(fmt))
end

-- The native XP bar is hidden with Hide (no invisible frame left catching the mouse) and kept
-- hidden if the game shows it again; it is shown back only if Odyssey hid it. No Blizzard
-- function is replaced (no taint): the OnShow hook only hides it again.
local nativeHidden, hooked = false, {}

function Compat.setNativeXPBarHidden(hidden)
  local frame = MainMenuExpBar or StatusTrackingBarManager
  if not frame or not frame.Hide then return end
  if hidden then
    if not hooked[frame] and frame.HookScript then
      frame:HookScript("OnShow", function(self) if nativeHidden then self:Hide() end end)
      hooked[frame] = true
    end
    nativeHidden = true
    if frame:IsShown() then frame:Hide() end
  elseif nativeHidden then
    nativeHidden = false
    frame:Show()
  end
end

-- ---------------------------------------------------------------- reputation

local function readWatched()
  if C_Reputation and C_Reputation.GetWatchedFactionData then
    local data = C_Reputation.GetWatchedFactionData()
    if not data or not data.name or data.name == "" then return nil end
    return {
      name = data.name, factionID = data.factionID, standing = data.reaction,
      min = data.currentReactionThreshold, max = data.nextReactionThreshold, value = data.currentStanding,
    }
  end
  if GetWatchedFactionInfo then
    local name, standing, min, max, value, factionID = GetWatchedFactionInfo()
    if not name or name == "" then return nil end
    return { name = name, factionID = factionID, standing = standing, min = min, max = max, value = value }
  end
  return nil
end

-- The faction shown "as experience bar" in the game, or nil; modern and classic APIs.
function Compat.watchedFaction()
  local ok, faction = pcall(readWatched)
  if not ok then
    Compat.missing.reputation = tostring(faction)
    return nil
  end
  return faction
end

function Compat.standingLabel(standing)
  return _G["FACTION_STANDING_LABEL" .. tostring(standing)] or tostring(standing)
end

-- Hated .. Exalted, used when the game does not expose FACTION_BAR_COLORS.
local STANDING_COLORS = {
  { 0.8, 0.13, 0.13 }, { 0.8, 0.13, 0.13 }, { 0.75, 0.27, 0 }, { 0.9, 0.7, 0 },
  { 0, 0.6, 0.1 }, { 0, 0.6, 0.1 }, { 0, 0.6, 0.1 }, { 0, 0.6, 0.1 },
}

function Compat.standingColor(standing)
  local c = FACTION_BAR_COLORS and FACTION_BAR_COLORS[standing]
  if c then return { c.r, c.g, c.b } end
  local fallback = STANDING_COLORS[standing] or STANDING_COLORS[4]
  return { fallback[1], fallback[2], fallback[3] }
end

function Compat.repApi()
  return { watched = Compat.watchedFaction, label = Compat.standingLabel, now = GetTime }
end

-- ------------------------------------------------------------- player state

function Compat.isResting() return IsResting and IsResting() and true or false end
function Compat.inCombat() return InCombatLockdown and InCombatLockdown() and true or false end
function Compat.isDead() return UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") and true or false end

function Compat.inInstance()
  if not IsInInstance then return false end
  local inside, kind = IsInInstance()
  return (inside and kind ~= "none") and true or false
end

-- ------------------------------------------------------------ factions, chat

-- Factions the player can watch (headers left out), modern or classic API.
function Compat.factionList()
  local list = {}
  if C_Reputation and C_Reputation.GetNumFactions and C_Reputation.GetFactionDataByIndex then
    for i = 1, C_Reputation.GetNumFactions() do
      local data = C_Reputation.GetFactionDataByIndex(i)
      if data and data.name and not data.isHeader then
        list[#list + 1] = { name = data.name, index = i, watched = data.isWatched and true or false }
      end
    end
  elseif GetNumFactions and GetFactionInfo then
    for i = 1, GetNumFactions() do
      local name, _, _, _, _, _, _, _, isHeader, _, _, isWatched = GetFactionInfo(i)
      if name and not isHeader then
        list[#list + 1] = { name = name, index = i, watched = isWatched and true or false }
      end
    end
  end
  return list
end

-- Watches a faction by name, looking up its row at click time (rows move when headers fold).
function Compat.watchFactionByName(name)
  for _, faction in ipairs(Compat.factionList()) do
    if faction.name == name then
      Compat.watchFaction(faction.index)
      return true
    end
  end
  return false
end

function Compat.watchFaction(index)
  if C_Reputation and C_Reputation.SetWatchedFactionByIndex then
    C_Reputation.SetWatchedFactionByIndex(index)
  elseif SetWatchedFactionIndex then
    SetWatchedFactionIndex(index)
  end
end

-- Puts text into the chat box (the open one, or opens it); never sends anything by itself.
function Compat.insertChat(text)
  local box = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
  if box then
    box:Insert(text)
  elseif ChatFrame_OpenChat then
    ChatFrame_OpenChat(text)
  end
end

function Compat.openReputation()
  if ToggleCharacter then ToggleCharacter("ReputationFrame") end
end
