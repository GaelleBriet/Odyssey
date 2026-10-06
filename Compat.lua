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

-- The native XP bar is hidden by transparency only (no replaced functions, no taint).
function Compat.setNativeXPBarHidden(hidden)
  local frame = MainMenuExpBar or StatusTrackingBarManager
  if frame and frame.SetAlpha then frame:SetAlpha(hidden and 0 or 1) end
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
