local ADDON, ns = ...
local Defaults, Compat, History = ns.Defaults, ns.Compat, ns.History
local L = ns.L

-- ---------------------------------------------------------------- saved data

function ns.CharKey()
  return GetRealmName() .. "-" .. UnitName("player")
end

local historyChecked = {} -- per session: saved history is repaired once per character

function ns.CharData()
  local key = ns.CharKey()
  if type(OdysseyDB.chars[key]) ~= "table" then OdysseyDB.chars[key] = {} end
  local data = OdysseyDB.chars[key]
  if not historyChecked[key] then
    data.history = History.sanitize(data.history)
    historyChecked[key] = true
  end
  if data.settings ~= nil and type(data.settings) ~= "table" then data.settings = nil end
  return data
end

-- The active settings: per character when the account asks for it, otherwise account-wide.
function ns.Settings()
  if OdysseyDB.perCharacter then
    local data = ns.CharData()
    if not data.settings then data.settings = Defaults.copy(OdysseyDB.account) end
    return data.settings
  end
  return OdysseyDB.account
end

-- The reputation bar's settings, seen through the "same style as the XP bar" link.
function ns.RepSettings()
  return Defaults.repView(ns.Settings())
end

function ns.FormatOptions(settings)
  return {
    number = { abbreviated = (settings or ns.Settings()).abbreviate, thousands = L["NUMBER_THOUSANDS"], decimal = L["NUMBER_DECIMAL"] },
    units = { d = L["UNIT_D"], h = L["UNIT_H"], m = L["UNIT_M"], s = L["UNIT_S"] },
  }
end

-- Re-applies settings after any change made by the options panel or a slash command.
function ns.Refresh()
  for _, bar in ipairs({ ns.bar, ns.repBar }) do bar:ApplySettings(); bar:Update() end
  for _, preview in pairs(ns.previewBars or {}) do
    if preview.frame:IsShown() then preview:ApplySettings(); preview:Update() end
  end
  if ns.Options and ns.Options.Refresh then ns.Options.Refresh() end
end

-- ------------------------------------------------------------- /played (quiet)

local after = (C_Timer and C_Timer.After) or function(_, fn) fn() end
local suppressing = false

local function setChatPlayed(enabled)
  for i = 1, (NUM_CHAT_WINDOWS or 10) do
    local frame = _G["ChatFrame" .. i]
    if frame then
      if enabled then frame:RegisterEvent("TIME_PLAYED_MSG") else frame:UnregisterEvent("TIME_PLAYED_MSG") end
    end
  end
end

local function restoreChatPlayed()
  if suppressing then
    suppressing = false
    setChatPlayed(true)
  end
end

-- Asks for /played without printing the reply in chat. A safety timer restores the chat
-- frames if no reply ever arrives, so a manual /played keeps working.
local function requestPlayed()
  if suppressing then return end
  suppressing = true
  setChatPlayed(false)
  after(10, restoreChatPlayed)
  RequestTimePlayed()
end

-- --------------------------------------------------------------------- quests

local questRefreshPending = false

local function scheduleQuestRefresh()
  if questRefreshPending then return end
  questRefreshPending = true
  after(0.5, function()
    questRefreshPending = false
    ns.source:setQuests(Compat.completedQuestXP())
  end)
end

-- --------------------------------------------------------------------- events

local handlers = {}

function handlers.PLAYER_XP_UPDATE() ns.source:onXPUpdate() end
function handlers.UPDATE_EXHAUSTION() ns.source:onRestedUpdate() end
function handlers.CHAT_MSG_COMBAT_XP_GAIN(msg)
  if Compat.isKillXPMessage(msg) then ns.source:onKillXPMessage() end
end
function handlers.PLAYER_LEVEL_UP(newLevel)
  ns.source:onLevelUp(newLevel)
  requestPlayed()
end
function handlers.QUEST_LOG_UPDATE() scheduleQuestRefresh() end
function handlers.UPDATE_FACTION() ns.repSource:onUpdate() end

function handlers.PLAYER_ENTERING_WORLD()
  ns.source:rebase()
  ns.repSource:rebase()
  requestPlayed()
  scheduleQuestRefresh()
end

function handlers.TIME_PLAYED_MSG(total, levelTime)
  ns.source:onPlayed(total, levelTime)
  -- The source's level is synced from PLAYER_LEVEL_UP, so it is right even when UnitLevel lags.
  History.onPlayed(ns.CharData().history, ns.source.level, total, levelTime, UnitXPMax("player"), time())
  restoreChatPlayed()
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    if ... ~= ADDON then return end
    frame:UnregisterEvent("ADDON_LOADED")
    if type(OdysseyDB) ~= "table" then OdysseyDB = {} end
    Defaults.migrate(OdysseyDB)
    Defaults.merge(OdysseyDB, Defaults.root)
    frame:RegisterEvent("PLAYER_LOGIN")
  elseif event == "PLAYER_LOGIN" then
    frame:UnregisterEvent("PLAYER_LOGIN")
    Defaults.merge(ns.Settings(), Defaults.settings)
    ns.CharData()
    ns.Fonts.registerBundled(ns.Fonts.lsm())
    ns.source = ns.XPSource.new(Compat.xpApi())
    ns.repSource = ns.RepSource.new(Compat.repApi())
    if ns.Bar then
      ns.bar = ns.Bar.create(ns.source)
      ns.repBar = ns.Bar.create(ns.repSource, { kind = "rep", name = "OdysseyRepBar", settings = ns.RepSettings })
    end
    if ns.Options then ns.Options.create() end
    for name in pairs(handlers) do frame:RegisterEvent(name) end
  else
    handlers[event](...)
  end
end)

-- ------------------------------------------------------------- slash commands

local function say(text) print("|cff9966ffOdyssey|r: " .. text) end

local function dump()
  local snap = ns.source:Get()
  say(("level %d, XP %d/%d (%.1f%%), rested %d"):format(snap.level, snap.xp, snap.xpMax, snap.percent, snap.rested))
  say(("session: +%d XP in %ds, rate %s, last gain %s, kills to level %s"):format(
    snap.session.xpGained, snap.session.seconds, tostring(snap.session.xpPerHour),
    tostring(snap.lastGain), tostring(snap.killsToLevel)))
  if snap.played then
    say(("played: total %ds, this level %ds, average per level %s"):format(
      snap.played.total, snap.played.levelTime, tostring(snap.played.averagePerLevel)))
  else
    say("played: no reply yet")
  end
  if snap.quests then
    say(("quests ready: %d, +%d XP (%.1f%% of the bar)"):format(snap.quests.count, snap.quests.total, snap.quests.percent))
    for _, q in ipairs(snap.quests.list) do say(("  %s: %d"):format(q.title, q.xp)) end
  else
    say("quests: unavailable (" .. tostring(Compat.missing.quests) .. ")")
  end
  local entries = History.entries(ns.CharData().history)
  say(("history: %d completed level(s) recorded"):format(#entries))
end

SLASH_ODYSSEY1 = "/odyssey"
SlashCmdList["ODYSSEY"] = function(msg)
  local cmd = (msg or ""):lower():match("^%s*(%S*)")
  if cmd == "probe" then
    ns.RunProbe()
  elseif cmd == "dump" then
    dump()
  elseif cmd == "lock" or cmd == "unlock" then
    ns.Settings().locked = (cmd == "lock")
    ns.Settings().rep.locked = (cmd == "lock")
    say(ns.Settings().locked and L["Bar locked."] or L["Bar unlocked. Drag it with the mouse."])
    ns.Refresh()
  elseif cmd == "reset" then
    ns.source:resetSession()
    ns.repSource:resetSession()
    say(L["Session reset."])
  elseif cmd == "" or cmd == "options" then
    if ns.OpenOptions then ns.OpenOptions() else say(L["Commands: /odyssey [lock|unlock|reset|dump|probe]"]) end
  else
    say(L["Commands: /odyssey [lock|unlock|reset|dump|probe]"])
  end
end
