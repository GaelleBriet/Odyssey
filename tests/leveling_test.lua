local ns = newNamespace()
loadAddonFile("Calc.lua", ns)
loadAddonFile("Defaults.lua", ns)
loadAddonFile("Texts.lua", ns)
loadAddonFile("Visibility.lua", ns)
loadAddonFile("Alerts.lua", ns)
loadAddonFile("Characters.lua", ns)
loadAddonFile("Backup.lua", ns)
local Texts, Visibility, Alerts, Characters, Backup, Calc =
  ns.Texts, ns.Visibility, ns.Alerts, ns.Characters, ns.Backup, ns.Calc

local L = setmetatable({
  ["chat.xp"] = "chat.xp:%d:%s:%s:%s:%s", ["chat.rested"] = "chat.rested:%s", ["chat.max"] = "chat.max:%d",
  ["chat.rep"] = "chat.rep:%s:%s:%s:%s:%s", ["summary.levelup"] = "summary.levelup:%d:%s",
  ["summary.pace"] = "summary.pace:%d",
}, { __index = function(_, k) return k end })
local opts = { number = { thousands = "," }, units = { d = "d", h = "h", m = "m", s = "s" } }

local function xpSnap(overrides)
  local s = { level = 20, xp = 15040, xpMax = 23200, remaining = 8160, percent = 64.8, isMaxLevel = false,
    rested = 4740, quests = { total = 1010 } }
  for k, v in pairs(overrides or {}) do s[k] = v end
  return s
end

-- --------------------------------------------------------------- chat lines

test("XP progress line for the chat", function()
  eq(Texts.chatLine("xp", xpSnap(), opts, L), "chat.xp:20:65%:15,040:23,200:8,160 | chat.rested:4,740")
end)

test("XP progress line without rested XP, and at max level", function()
  eq(Texts.chatLine("xp", xpSnap({ rested = 0 }), opts, L), "chat.xp:20:65%:15,040:23,200:8,160")
  eq(Texts.chatLine("xp", xpSnap({ isMaxLevel = true }), opts, L), "chat.max:20")
end)

test("reputation progress line, and nothing without a faction", function()
  local rep = { none = false, name = "Orgrimmar", standingLabel = "Friendly", current = 1500, max = 6000, percent = 25 }
  eq(Texts.chatLine("rep", rep, opts, L), "chat.rep:Orgrimmar:Friendly:1,500:6,000:25%")
  eq(Texts.chatLine("rep", { none = true }, opts, L), nil)
end)

-- ------------------------------------------------------------------ alerts

test("quests would level you up when their XP covers what is left", function()
  eq(Alerts.questsWouldLevel(xpSnap({ quests = { total = 8160 } })), true)
  eq(Alerts.questsWouldLevel(xpSnap({ quests = { total = 1010 } })), false)
  eq(Alerts.questsWouldLevel(xpSnap({ quests = nil })), false)
  eq(Alerts.questsWouldLevel(xpSnap({ quests = { total = 9000 }, isMaxLevel = true })), false)
end)

test("the quest level-up alert fires once per level", function()
  local tracker = Alerts.newTracker()
  local ready = xpSnap({ quests = { total = 9000 } })
  eq(tracker:questsReady(ready), true)
  eq(tracker:questsReady(ready), false)
  eq(tracker:questsReady(xpSnap({ quests = { total = 10 } })), false)
  eq(tracker:questsReady(xpSnap({ level = 21, quests = { total = 99999 } })), true)
end)

test("level-up summary", function()
  local record = { level = 20, duration = 4020 }
  eq(Alerts.levelUpSummary(record, 12.4, opts, L), "summary.levelup:21:1h 07m | summary.pace:12")
  eq(Alerts.levelUpSummary(record, nil, opts, L), "summary.levelup:21:1h 07m")
end)

-- -------------------------------------------------------------- visibility

local function vis(extra)
  local s = { visibility = "always", fadedAlpha = 0, locked = true, barAlpha = 1,
    combatMode = "show", instanceMode = "show", hideWhenDead = false }
  for k, v in pairs(extra or {}) do s[k] = v end
  return s
end

test("combat and instance conditions hide or fade the bar", function()
  eq(Visibility.alpha(vis({ combatMode = "hide" }), { combat = true }), 0)
  near(Visibility.alpha(vis({ combatMode = "fade" }), { combat = true }), 0.3)
  eq(Visibility.alpha(vis({ combatMode = "hide" }), {}), 1)
  eq(Visibility.alpha(vis({ instanceMode = "hide" }), { instance = true }), 0)
  eq(Visibility.alpha(vis({ hideWhenDead = true }), { dead = true }), 0)
end)

test("a hidden condition also turns the mouse off; mouseover alone does not", function()
  eq(Visibility.blocked(vis({ combatMode = "hide" }), { combat = true }), true)
  eq(Visibility.blocked(vis({ combatMode = "fade" }), { combat = true }), false)
  eq(Visibility.blocked(vis({ visibility = "mouseover" }), {}), false)
end)

test("an unlocked bar ignores the conditions so it can be placed", function()
  eq(Visibility.alpha(vis({ combatMode = "hide", locked = false }), { combat = true }), 1)
end)

-- ------------------------------------------------------------------- rested

test("rested timing in an inn and outside", function()
  local inn = Calc.restedTiming(4640, 23200, true)
  eq(inn.max, 34800)
  eq(inn.percent, 20)
  near(inn.timeToFull, (34800 - 4640) / (23200 * 0.05 / 28800))
  local outside = Calc.restedTiming(4640, 23200, false)
  near(outside.timeToFull, inn.timeToFull * 4)
  eq(Calc.restedTiming(34800, 23200, true).timeToFull, 0)
  eq(Calc.restedTiming(0, 0, true).timeToFull, nil)
end)

test("alts: estimated rested XP since their last logout, capped at 150 %", function()
  local store = {}
  Characters.record(store, "Realm-Bob", { name = "Bob", class = "WARRIOR", level = 18, rested = 0, xpMax = 10000, resting = true }, 0)
  Characters.record(store, "Realm-Eve", { name = "Eve", class = "MAGE", level = 30, rested = 14000, xpMax = 10000, resting = false }, 0)
  Characters.record(store, "Realm-Max", { name = "Max", class = "ROGUE", level = 60, rested = 0, xpMax = 0, resting = true, maxLevel = true }, 0)
  local list = Characters.list(store, 8 * 3600, "Realm-Me")
  eq(#list, 2) -- max-level characters are left out
  eq(list[1].name, "Eve")
  eq(list[1].restedPercent, 141) -- 140 % + 8 h outside a resting area (1.25 %)
  eq(list[2].name, "Bob")
  eq(list[2].restedPercent, 5)
  eq(Characters.list(store, 999999999, "Realm-Me")[1].restedPercent, 150)
  eq(#Characters.list(store, 0, "Realm-Bob"), 1) -- the current character is not listed
end)

-- ------------------------------------------------------------------- backup

test("backup restores the leveling history when the main save comes back empty", function()
  local charDB = {}
  Backup.save(charDB, { history = { levels = { [10] = { level = 10 } } }, profile = "Main" })
  local db = { chars = {} }
  eq(Backup.restore(db, charDB, "Realm-A"), "restored")
  eq(db.chars["Realm-A"].history.levels[10].level, 10)
end)

test("backup does nothing when the main save is fine, or when there is no backup", function()
  local charDB = {}
  Backup.save(charDB, { history = { levels = { [10] = { level = 10 } } } })
  local db = { chars = { ["Realm-A"] = { history = { levels = { [11] = { level = 11 } } } } } }
  eq(Backup.restore(db, charDB, "Realm-A"), "ok")
  eq(db.chars["Realm-A"].history.levels[10], nil)
  eq(Backup.restore({ chars = {} }, {}, "Realm-A"), "ok")
  eq(Backup.restore({ chars = {} }, nil, "Realm-A"), "ok")
end)
