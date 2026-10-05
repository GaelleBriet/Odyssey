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
