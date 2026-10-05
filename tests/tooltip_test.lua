local ns = newNamespace()
loadAddonFile("Calc.lua", ns)
loadAddonFile("History.lua", ns)
loadAddonFile("Tooltip.lua", ns)
local Tooltip = ns.Tooltip

local L = setmetatable({}, { __index = function(_, k) return k end })
local opts = { number = { thousands = "," }, units = { d = "d", h = "h", m = "m", s = "s" } }

local function fakeTooltip()
  local tt = { lines = {} }
  function tt:AddLine(text) self.lines[#self.lines + 1] = text end
  function tt:AddDoubleLine(left, right) self.lines[#self.lines + 1] = left .. " | " .. right end
  function tt:text() return table.concat(self.lines, "\n") end
  return tt
end

local function settings()
  return {
    questListMax = 2,
    tooltip = { level = true, rested = true, quests = true, kills = true, session = true, played = true, history = true },
  }
end

local function snap(overrides)
  local s = {
    level = 23, xp = 12340, xpMax = 45000, remaining = 32660, percent = 27.42, isMaxLevel = false,
    rested = 4500, restedPercent = 10,
    session = { xpGained = 5000, seconds = 1800, xpPerHour = 10000, timeToLevel = 11760 },
    lastGain = 90, killsToLevel = 363,
    played = { total = 90000, levelTime = 5000, averagePerLevel = 3863 },
    quests = {
      total = 900, percent = 2, count = 3,
      list = {
        { title = "Wolves", xp = 450, percent = 1 },
        { title = "Boars", xp = 300, percent = 0.7 },
        { title = "Bears", xp = 150, percent = 0.3 },
      },
    },
  }
  for k, v in pairs(overrides or {}) do s[k] = v end
  return s
end

local function fullStore()
  return { levels = {
    [21] = { level = 21, duration = 3600, xpMax = 36000, rate = 36000 },
    [22] = { level = 22, duration = 1800, xpMax = 36000, rate = 72000 },
  } }
end

test("full tooltip lists every block", function()
  local tt = fakeTooltip()
  Tooltip.fill(tt, snap(), settings(), fullStore(), opts, L, "BAR")
  local text = tt:text()
  truthy(text:find("Experience - Level 23", 1, true))
  truthy(text:find("Level total | 45,000", 1, true))
  truthy(text:find("Done | 12,340 (27%)", 1, true))
  truthy(text:find("Remaining | 32,660", 1, true))
  truthy(text:find("Rested | 4,500 (10%)", 1, true))
  truthy(text:find("Quests ready to turn in: +900 (2%)", 1, true))
  truthy(text:find("Wolves | 450 (1%)", 1, true))
  truthy(text:find("Kills to level | ~363", 1, true))
  truthy(text:find("Session", 1, true))
  truthy(text:find("XP per hour | 10,000", 1, true))
  truthy(text:find("Total played | 1d 1h", 1, true))
  truthy(text:find("Leveling history", 1, true))
  truthy(text:find("Level 21 | |TBAR:8:", 1, true))
end)

test("quest list is capped with an 'and more' line", function()
  local tt = fakeTooltip()
  Tooltip.fill(tt, snap(), settings(), nil, opts, L, "BAR")
  local text = tt:text()
  truthy(text:find("Wolves", 1, true))
  truthy(text:find("Boars", 1, true))
  truthy(not text:find("Bears", 1, true))
  truthy(text:find("… and 1 more", 1, true))
end)

test("blocks can be switched off", function()
  local tt = fakeTooltip()
  local s = settings()
  s.tooltip = { level = false, rested = false, quests = false, kills = false, session = false, played = false, history = false }
  Tooltip.fill(tt, snap(), s, fullStore(), opts, L, "BAR")
  eq(tt.lines, { "Experience - Level 23" })
end)

test("blocks without data disappear", function()
  local tt = fakeTooltip()
  local s = snap()
  s.rested, s.killsToLevel, s.lastGain, s.played, s.quests = 0, nil, nil, nil, nil
  s.session = { xpGained = 0, seconds = 5, xpPerHour = nil, timeToLevel = nil }
  Tooltip.fill(tt, s, settings(), { levels = {} }, opts, L, "BAR")
  local text = tt:text()
  truthy(not text:find("Rested", 1, true))
  truthy(not text:find("Quests", 1, true))
  truthy(not text:find("Kills", 1, true))
  truthy(not text:find("Time played", 1, true))
  truthy(not text:find("Leveling history", 1, true))
  truthy(not text:find("XP per hour", 1, true))
end)

test("pace compares the session rate with the history average", function()
  local tt = fakeTooltip()
  -- history average = 72000 XP over 5400 s = 48000 XP/h; session rate 10000 XP/h = -79%
  Tooltip.fill(tt, snap(), settings(), fullStore(), opts, L, "BAR")
  truthy(tt:text():find("Pace | -79% vs your average", 1, true))
end)

test("max level shows the level-cap line and skips level blocks", function()
  local tt = fakeTooltip()
  Tooltip.fill(tt, snap({ isMaxLevel = true }), settings(), fullStore(), opts, L, "BAR")
  local text = tt:text()
  truthy(text:find("Max level", 1, true))
  truthy(not text:find("Level total", 1, true))
  truthy(not text:find("Time to level", 1, true))
  truthy(text:find("Leveling history", 1, true))
end)

test("a missing history store is tolerated", function()
  local tt = fakeTooltip()
  Tooltip.fill(tt, snap(), settings(), nil, opts, L, "BAR")
  truthy(not tt:text():find("Leveling history", 1, true))
end)
