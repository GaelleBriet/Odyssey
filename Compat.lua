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

-- The native XP bar is hidden by transparency only (no replaced functions, no taint).
function Compat.setNativeXPBarHidden(hidden)
  local frame = MainMenuExpBar or StatusTrackingBarManager
  if frame and frame.SetAlpha then frame:SetAlpha(hidden and 0 or 1) end
end
