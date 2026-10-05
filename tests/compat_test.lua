local ns = newNamespace()
loadAddonFile("Compat.lua", ns)
local Compat = ns.Compat

local function withGlobals(globals, fn)
  local saved = {}
  for k, v in pairs(globals) do saved[k] = _G[k]; _G[k] = v end
  local ok, err = pcall(fn)
  for k in pairs(globals) do _G[k] = saved[k] end
  if not ok then error(err, 0) end
end

test("no quest API at all returns nil without raising", function()
  withGlobals({ C_QuestLog = false, GetNumQuestLogEntries = false, GetQuestLogRewardXP = false }, function()
    eq(Compat.completedQuestXP(), nil)
    truthy(Compat.missing.quests)
  end)
end)

test("modern quest API lists only completed quests with XP", function()
  withGlobals({
    C_QuestLog = {
      GetNumQuestLogEntries = function() return 4 end,
      GetInfo = function(i)
        return ({
          { title = "Header", isHeader = true },
          { title = "Wolves", questID = 1 },
          { title = "Boars", questID = 2 },
          { title = "Gift", questID = 3 },
        })[i]
      end,
      ReadyForTurnIn = function(id) return id == 1 or id == 3 end,
    },
    GetQuestLogRewardXP = function(id) return id == 1 and 450 or (id == 2 and 300 or 0) end,
  }, function()
    eq(Compat.completedQuestXP(), { { title = "Wolves", xp = 450 } })
  end)
end)

test("a throwing quest API is caught", function()
  withGlobals({
    C_QuestLog = {
      GetNumQuestLogEntries = function() error("boom") end,
      GetInfo = function() end,
      IsComplete = function() return true end,
    },
    GetQuestLogRewardXP = function() return 0 end,
  }, function()
    eq(Compat.completedQuestXP(), nil)
    truthy(Compat.missing.quests:find("boom"))
  end)
end)

test("classic quest API path", function()
  local selected = 0
  withGlobals({
    C_QuestLog = false,
    GetNumQuestLogEntries = function() return 3 end,
    GetQuestLogTitle = function(i)
      if i == 1 then return "Header", 0, 0, true, false, nil end
      if i == 2 then return "Wolves", 10, 0, false, false, 1 end
      return "Boars", 10, 0, false, false, -1
    end,
    SelectQuestLogEntry = function(i) selected = i end,
    GetQuestLogSelection = function() return 1 end,
    GetQuestLogRewardXP = function() return selected == 2 and 450 or 300 end,
  }, function()
    eq(Compat.completedQuestXP(), { { title = "Wolves", xp = 450 } })
    eq(selected, 1)
  end)
end)

test("isMaxLevel prefers IsPlayerAtEffectiveMaxLevel", function()
  withGlobals({ IsPlayerAtEffectiveMaxLevel = function() return true end }, function()
    eq(Compat.isMaxLevel(), true)
  end)
end)

test("isMaxLevel falls back to the level cap constants, then to false", function()
  withGlobals({
    IsPlayerAtEffectiveMaxLevel = false, GetMaxPlayerLevel = function() return 60 end,
    UnitLevel = function() return 60 end,
  }, function() eq(Compat.isMaxLevel(), true) end)
  withGlobals({
    IsPlayerAtEffectiveMaxLevel = false, GetMaxPlayerLevel = false, MAX_PLAYER_LEVEL = false,
    UnitLevel = function() return 10 end,
  }, function() eq(Compat.isMaxLevel(), false) end)
end)

test("hiding the native bar tolerates missing frames", function()
  withGlobals({ MainMenuExpBar = false, StatusTrackingBarManager = false }, function()
    Compat.setNativeXPBarHidden(true)
  end)
end)

test("hiding the native bar sets its alpha", function()
  local alpha
  local frame = { SetAlpha = function(_, a) alpha = a end }
  withGlobals({ MainMenuExpBar = frame }, function()
    Compat.setNativeXPBarHidden(true)
    eq(alpha, 0)
    Compat.setNativeXPBarHidden(false)
    eq(alpha, 1)
  end)
end)
