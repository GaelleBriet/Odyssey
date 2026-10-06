local ns = newNamespace()
loadAddonFile("Calc.lua", ns)
loadAddonFile("History.lua", ns)
loadAddonFile("TooltipContent.lua", ns)
local TC = ns.TooltipContent

local L = setmetatable({}, { __index = function(_, k) return k end })
local opts = { number = { thousands = "," }, units = { d = "d", h = "h", m = "m", s = "s" } }

local function settings()
  return {
    questListMax = 2,
    tooltip = { level = true, rested = true, quests = true, kills = true, session = true, played = true, history = true },
  }
end

local function snap()
  return {
    level = 20, xp = 6495, xpMax = 23200, remaining = 16705, percent = 28, isMaxLevel = false,
    rested = 4740, restedPercent = 20,
    session = { xpGained = 3000, seconds = 1800, xpPerHour = 10700, timeToLevel = 5640 },
    lastGain = 130, killsToLevel = 129,
    played = { total = 104400, levelTime = 4020, averagePerLevel = 5280 },
    quests = {
      total = 1010, percent = 4, count = 3,
      list = {
        { title = "Ziz Fizziks", xp = 420, percent = 2 },
        { title = "Serres", xp = 320, percent = 1 },
        { title = "Ashenvale", xp = 160, percent = 1 },
      },
    },
  }
end

local function store()
  return { levels = {
    [18] = { level = 18, duration = 3600, xpMax = 36000, rate = 36000 },
    [19] = { level = 19, duration = 1800, xpMax = 36000, rate = 72000 },
  } }
end

-- Flattens the groups to "label=value" strings for readable assertions.
local function flat(content)
  local out = {}
  for _, group in ipairs(content.groups) do
    local rows = {}
    for _, row in ipairs(group) do rows[#rows + 1] = row.label .. "=" .. (row.value or "") end
    out[#out + 1] = rows
  end
  return out
end

test("default view has three short groups and a Shift hint", function()
  local c = TC.build(snap(), settings(), store(), opts, L, false)
  eq(c.title, "Level 20")
  eq(c.subtitle, "6,495 / 23,200")
  eq(flat(c), {
    { "Progress=28%", "Remaining=16,705", "Rested=4,740", "Quests ready to turn in=+1,010" },
    { "XP per hour=10,700", "Time to level=1h 34m" },
    { "Time played=1d 5h" },
  })
  eq(c.hint, "Hold Shift for details")
end)

test("values carry the colour role of their line", function()
  local c = TC.build(snap(), settings(), store(), opts, L, false)
  eq(c.groups[1][3].color, "rested")
  eq(c.groups[1][4].color, "quest")
  eq(c.groups[1][1].color, nil)
end)

test("detailed view adds quests, kills, session, level times and history", function()
  local c = TC.build(snap(), settings(), store(), opts, L, true)
  local f = flat(c)
  eq(f[1], {
    "Progress=28%", "Remaining=16,705", "Quests ready to turn in=+1,010",
    "Ziz Fizziks=420", "Serres=320", "… and 1 more=",
  }) -- rested XP moves to the rested planner group in the detailed view
  eq(f[2], { "Kills to level=~129", "Last gain=130" })
  eq(f[3], { "XP per hour=10,700", "Time to level=1h 34m", "XP gained=3,000", "Duration=30m 00s" })
  eq(f[4], { "Time played=1d 5h", "This level=1h 07m", "Average per level=1h 28m" })
  eq(f[5][1], "Pace=-78% vs your average")
  eq(c.groups[5][2].kind, "history")
  eq(c.groups[5][2].label, "Level 18")
  eq(c.groups[5][2].ratio, 1)
  eq(c.hint, "hint.clicks")
end)

test("lines and groups without data are dropped", function()
  local s = snap()
  s.rested, s.quests, s.played, s.killsToLevel, s.lastGain = 0, nil, nil, nil, nil
  s.session = { xpGained = 0, seconds = 5, xpPerHour = nil, timeToLevel = nil }
  local c = TC.build(s, settings(), { levels = {} }, opts, L, true)
  eq(flat(c), {
    { "Progress=28%", "Remaining=16,705" },
    { "XP gained=0", "Duration=5s" },
    -- the rested planner stays: time to full is useful even at 0 rested XP
    { "Rested=0 (0%)", "Resting=No", "Rested maximum=34,800", "Full in=40d 0h" },
  })
end)

test("tooltip toggles hide their lines in both views", function()
  local st = settings()
  st.tooltip = { level = false, rested = false, quests = false, kills = false, session = false, played = false, history = false }
  eq(TC.build(snap(), st, store(), opts, L, false).groups, {})
  eq(TC.build(snap(), st, store(), opts, L, true).groups, {})
end)

test("max level replaces progress with a level-cap subtitle", function()
  local s = snap()
  s.isMaxLevel = true
  local c = TC.build(s, settings(), store(), opts, L, false)
  eq(c.subtitle, "Max level")
  eq(flat(c), { { "XP per hour=10,700" }, { "Time played=1d 5h" } })
end)

local function repSnap()
  return {
    none = false, name = "Orgrimmar", standing = 5, standingLabel = "Friendly",
    current = 1500, max = 6000, percent = 25, remaining = 4500, toExalted = 37500, isMax = false,
    session = { gained = 300, seconds = 1800, perHour = 600, timeToNext = 27000 }, lastGain = 25,
  }
end
local repSettings = { tooltip = { progress = true, session = true } }

test("reputation tooltip: default view", function()
  local c = TC.buildRep(repSnap(), repSettings, opts, L, false)
  eq(c.title, "Orgrimmar")
  eq(c.subtitle, "Friendly")
  eq(flat(c), {
    { "Progress=25%", "Standing=1,500 / 6,000", "Remaining=4,500" },
  })
  eq(c.hint, "Hold Shift for details")
end)

test("reputation tooltip: detailed view", function()
  local c = TC.buildRep(repSnap(), repSettings, opts, L, true)
  eq(flat(c), {
    { "Progress=25%", "Standing=1,500 / 6,000", "Remaining=4,500", "To Exalted=37,500" },
    { "Rep per hour=600", "Time to next standing=7h 30m", "Reputation gained=+300", "Duration=30m 00s", "Last gain=+25" },
  })
end)

test("reputation tooltip: no watched faction, and blocks switched off", function()
  local c = TC.buildRep({ none = true, session = { gained = 0, seconds = 0 } }, repSettings, opts, L, false)
  eq(c.title, "No watched faction")
  eq(c.groups, {})
  local off = TC.buildRep(repSnap(), { tooltip = { progress = false, session = false } }, opts, L, true)
  eq(off.groups, {})
end)

test("reputation tooltip: exalted has no remaining lines", function()
  local s = repSnap()
  s.isMax, s.remaining, s.toExalted, s.standingLabel = true, 0, 0, "Exalted"
  s.session.timeToNext = nil
  local c = TC.buildRep(s, repSettings, opts, L, true)
  eq(flat(c)[1], { "Progress=25%", "Standing=1,500 / 6,000" })
end)

-- ---------------------------------------------------- leveling tools

test("default view hints at Shift; the detailed view hints at the clicks", function()
  eq(TC.build(snap(), settings(), store(), opts, L, false).hint, "Hold Shift for details")
  eq(TC.build(snap(), settings(), store(), opts, L, true).hint, "hint.clicks")
  eq(TC.buildRep(repSnap(), repSettings, opts, L, true).hint, "hint.repClicks")
end)

test("detailed view: rested planner with resting state, maximum and time to full", function()
  local s = snap()
  s.resting = true
  local c = TC.build(s, settings(), store(), opts, L, true)
  local found
  for _, g in ipairs(c.groups) do
    if g[1].label == "Rested" then found = g end
  end
  truthy(found, "rested group")
  eq(found[1].value, "4,740 (20%)")
  eq(found[2].label, "Resting")
  eq(found[3].label, "Rested maximum")
  eq(found[3].value, "34,800")
  eq(found[4].label, "Full in")
end)

test("detailed view: other characters with their estimated rested XP", function()
  local alts = { { name = "Bob", level = 18, restedPercent = 45 }, { name = "Eve", level = 30, restedPercent = 150 } }
  local c = TC.build(snap(), settings(), store(), opts, L, true, { alts = alts })
  local last = c.groups[#c.groups]
  eq(last[1].label, "Bob (18)")
  eq(last[1].value, "45%")
  eq(last[2].value, "150%")
  eq(TC.build(snap(), settings(), store(), opts, L, false, { alts = alts }).groups[#c.groups], nil)
end)
