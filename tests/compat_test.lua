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

test("a quest XP message is not a kill (localized global string)", function()
  withGlobals({
    COMBATLOG_XP_GAIN_FIRST_PERSON_UNNAMED = "Vous gagnez %d points d'expérience.",
  }, function()
    eq(Compat.isKillXPMessage("Vous gagnez 600 points d'expérience."), false)
    eq(Compat.isKillXPMessage("Manouvrier de la KapitalRisk meurt, vous gagnez 130 points d'expérience."), true)
  end)
end)

test("without the global string every XP message counts as a kill", function()
  withGlobals({ COMBATLOG_XP_GAIN_FIRST_PERSON_UNNAMED = false }, function()
    eq(Compat.isKillXPMessage("You gain 600 experience."), true)
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
    Compat.setNativeXPBarHidden(false)
  end)
end)

local function fakeNative()
  local f = { shown = true, calls = {} }
  function f:Hide() self.shown = false; self.calls[#self.calls + 1] = "Hide" end
  function f:Show() self.shown = true; self.calls[#self.calls + 1] = "Show" end
  function f:IsShown() return self.shown end
  function f:HookScript(event, fn) self.onShow = fn end
  return f
end

test("the native bar is hidden for real, and kept hidden if the game shows it again", function()
  local f = fakeNative()
  withGlobals({ MainMenuExpBar = false, StatusTrackingBarManager = f }, function()
    Compat.setNativeXPBarHidden(true)
    eq(f.shown, false)
    f.shown = true
    f.onShow(f) -- the game shows it again
    eq(f.shown, false)
    Compat.setNativeXPBarHidden(false)
    eq(f.shown, true)
    f.onShow(f)
    eq(f.shown, true) -- no longer forced hidden
  end)
end)

test("the native bar is never touched when Odyssey did not hide it", function()
  local f = fakeNative()
  withGlobals({ MainMenuExpBar = false, StatusTrackingBarManager = f }, function()
    Compat.setNativeXPBarHidden(false)
    Compat.setNativeXPBarHidden(false)
    eq(f.calls, {})
  end)
end)

test("watched faction through the modern API", function()
  withGlobals({
    C_Reputation = { GetWatchedFactionData = function()
      return { name = "Orgrimmar", factionID = 76, reaction = 5, currentReactionThreshold = 3000,
        nextReactionThreshold = 9000, currentStanding = 4500 }
    end },
    GetWatchedFactionInfo = false,
  }, function()
    eq(Compat.watchedFaction(), { name = "Orgrimmar", factionID = 76, standing = 5, min = 3000, max = 9000, value = 4500 })
  end)
end)

test("watched faction through the classic API", function()
  withGlobals({
    C_Reputation = false,
    GetWatchedFactionInfo = function() return "Orgrimmar", 5, 3000, 9000, 4500, 76 end,
  }, function()
    eq(Compat.watchedFaction(), { name = "Orgrimmar", factionID = 76, standing = 5, min = 3000, max = 9000, value = 4500 })
  end)
end)

test("no watched faction, no API, or a throwing API gives nil", function()
  withGlobals({ C_Reputation = false, GetWatchedFactionInfo = function() return nil end }, function()
    eq(Compat.watchedFaction(), nil)
  end)
  withGlobals({ C_Reputation = false, GetWatchedFactionInfo = false }, function()
    eq(Compat.watchedFaction(), nil)
  end)
  withGlobals({ C_Reputation = { GetWatchedFactionData = function() error("boom") end }, GetWatchedFactionInfo = false }, function()
    eq(Compat.watchedFaction(), nil)
  end)
end)

test("standing label and colour come from the game, with fallbacks", function()
  withGlobals({ FACTION_STANDING_LABEL5 = "Amical", FACTION_BAR_COLORS = { [5] = { r = 0, g = 0.6, b = 0.1 } } }, function()
    eq(Compat.standingLabel(5), "Amical")
    eq(Compat.standingColor(5), { 0, 0.6, 0.1 })
  end)
  withGlobals({ FACTION_STANDING_LABEL5 = false, FACTION_BAR_COLORS = false }, function()
    eq(Compat.standingLabel(5), "5")
    eq(#Compat.standingColor(5), 3)
    eq(#Compat.standingColor(99), 3)
  end)
end)

test("an empty modern faction record counts as no watched faction", function()
  withGlobals({ C_Reputation = { GetWatchedFactionData = function() return { name = "", factionID = 0 } end },
    GetWatchedFactionInfo = false }, function()
    eq(Compat.watchedFaction(), nil)
  end)
end)

test("faction list (modern API): headers skipped, watched one marked", function()
  local watched
  withGlobals({
    C_Reputation = {
      GetNumFactions = function() return 3 end,
      GetFactionDataByIndex = function(i)
        return ({ { name = "Horde", isHeader = true }, { name = "Orgrimmar", isWatched = true }, { name = "Ratchet" } })[i]
      end,
      SetWatchedFactionByIndex = function(i) watched = i end,
    },
    GetNumFactions = false,
  }, function()
    eq(Compat.factionList(), { { name = "Orgrimmar", index = 2, watched = true }, { name = "Ratchet", index = 3, watched = false } })
    Compat.watchFaction(3)
    eq(watched, 3)
  end)
end)

test("faction list without any API is empty", function()
  withGlobals({ C_Reputation = false, GetNumFactions = false }, function()
    eq(Compat.factionList(), {})
  end)
end)

test("chat insertion: into the open chat box, otherwise opens the chat with the text", function()
  local inserted, opened
  local box = { Insert = function(_, text) inserted = text end }
  withGlobals({ ChatEdit_GetActiveWindow = function() return box end, ChatFrame_OpenChat = function(t) opened = t end }, function()
    Compat.insertChat("hello")
    eq(inserted, "hello")
    eq(opened, nil)
  end)
  withGlobals({ ChatEdit_GetActiveWindow = function() return nil end, ChatFrame_OpenChat = function(t) opened = t end }, function()
    Compat.insertChat("again")
    eq(opened, "again")
  end)
end)

test("player state helpers tolerate missing APIs", function()
  withGlobals({ IsResting = false, IsInInstance = false, UnitIsDeadOrGhost = false, InCombatLockdown = false }, function()
    eq(Compat.isResting(), false)
    eq(Compat.inInstance(), false)
    eq(Compat.isDead(), false)
    eq(Compat.inCombat(), false)
  end)
  withGlobals({ IsInInstance = function() return true, "party" end, IsResting = function() return 1 end }, function()
    eq(Compat.inInstance(), true)
    eq(Compat.isResting(), true)
  end)
  withGlobals({ IsInInstance = function() return false, "none" end }, function()
    eq(Compat.inInstance(), false)
  end)
end)

test("watching a faction by name finds its current row", function()
  local watched
  withGlobals({
    C_Reputation = {
      GetNumFactions = function() return 2 end,
      GetFactionDataByIndex = function(i) return ({ { name = "Ratchet" }, { name = "Orgrimmar" } })[i] end,
      SetWatchedFactionByIndex = function(i) watched = i end,
    },
  }, function()
    eq(Compat.watchFactionByName("Orgrimmar"), true)
    eq(watched, 2)
    eq(Compat.watchFactionByName("Gone"), false)
  end)
end)
