local ns = newNamespace()
loadAddonFile("Calc.lua", ns)
loadAddonFile("Texts.lua", ns)
local Texts = ns.Texts

local L = setmetatable({}, { __index = function(_, k) return k end })
local opts = { number = { thousands = "," }, units = { d = "d", h = "h", m = "m", s = "s" } }

local function snap(overrides)
  local s = {
    level = 23, xp = 12340, xpMax = 45000, remaining = 32660, percent = 27.42,
    isMaxLevel = false, rested = 4500, restedPercent = 10,
    session = { xpGained = 5000, seconds = 1800, xpPerHour = 10000, timeToLevel = 11760 },
    lastGain = 90, killsToLevel = 363,
    quests = { total = 4200, percent = 9.3, count = 2, list = {} },
  }
  for k, v in pairs(overrides or {}) do s[k] = v end
  return s
end

test("every key renders to a string", function()
  for _, key in ipairs(Texts.KEYS) do
    eq(type(Texts.render(key, snap(), opts, L)), "string")
  end
end)

test("render values", function()
  eq(Texts.render("none", snap(), opts, L), "")
  eq(Texts.render("level", snap(), opts, L), "Level 23")
  eq(Texts.render("percent", snap(), opts, L), "27.4%")
  eq(Texts.render("current_max", snap(), opts, L), "12,340 / 45,000")
  eq(Texts.render("current_max_percent", snap(), opts, L), "12,340 / 45,000 (27%)")
  eq(Texts.render("remaining", snap(), opts, L), "32,660 remaining")
  eq(Texts.render("rested", snap(), opts, L), "Rested 4,500 (10%)")
  eq(Texts.render("xp_per_hour", snap(), opts, L), "10,000 XP/h")
  eq(Texts.render("time_to_level", snap(), opts, L), "3h 16m to level")
  eq(Texts.render("kills", snap(), opts, L), "~363 kills")
  eq(Texts.render("quests", snap(), opts, L), "+4,200 from quests")
end)

test("missing data renders as an empty string", function()
  local s = snap()
  s.rested, s.killsToLevel, s.quests = 0, nil, nil -- `snap(overrides)` cannot override with nil
  s.session = { xpGained = 0, seconds = 5, xpPerHour = nil, timeToLevel = nil }
  eq(Texts.render("rested", s, opts, L), "")
  eq(Texts.render("kills", s, opts, L), "")
  eq(Texts.render("quests", s, opts, L), "")
  eq(Texts.render("xp_per_hour", s, opts, L), "")
  eq(Texts.render("time_to_level", s, opts, L), "")
end)

test("zero quest XP renders as an empty string", function()
  eq(Texts.render("quests", snap({ quests = { total = 0, percent = 0, count = 0, list = {} } }), opts, L), "")
end)

test("an unknown key renders as an empty string", function()
  eq(Texts.render("bogus", snap(), opts, L), "")
end)

local function repSnap()
  return {
    none = false, name = "Orgrimmar", standing = 5, standingLabel = "Friendly",
    current = 1500, max = 6000, percent = 25, remaining = 4500, toExalted = 37500, isMax = false,
    session = { gained = 300, seconds = 1800, perHour = 600, timeToNext = 27000 }, lastGain = 25,
  }
end

test("reputation keys are listed apart from the XP keys", function()
  eq(Texts.REP_KEYS[1], "none")
  for _, key in ipairs(Texts.REP_KEYS) do eq(type(Texts.render(key, repSnap(), opts, L)), "string") end
end)

test("reputation texts", function()
  eq(Texts.render("faction", repSnap(), opts, L), "Orgrimmar")
  eq(Texts.render("standing", repSnap(), opts, L), "Friendly")
  eq(Texts.render("rep_current_max", repSnap(), opts, L), "1,500 / 6,000")
  eq(Texts.render("rep_current_max_percent", repSnap(), opts, L), "1,500 / 6,000 (25%)")
  eq(Texts.render("rep_percent", repSnap(), opts, L), "25.0%")
  eq(Texts.render("rep_remaining", repSnap(), opts, L), "4,500 remaining")
  eq(Texts.render("to_exalted", repSnap(), opts, L), "37,500 to Exalted")
  eq(Texts.render("rep_per_hour", repSnap(), opts, L), "600 rep/h")
end)

test("reputation texts without data are empty", function()
  local s = repSnap()
  s.toExalted, s.session.perHour = 0, nil
  eq(Texts.render("to_exalted", s, opts, L), "")
  eq(Texts.render("rep_per_hour", s, opts, L), "")
  local none = { none = true, percent = 0, current = 0, max = 0, remaining = 0, toExalted = 0, session = { gained = 0 } }
  eq(Texts.render("faction", none, opts, L), "")
  eq(Texts.render("rep_current_max", none, opts, L), "")
end)
