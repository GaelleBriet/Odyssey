local ns = newNamespace()
loadAddonFile("Calc.lua", ns)
loadAddonFile("Sources/XP.lua", ns)

local function fakeApi(state)
  return {
    unitXP = function() return state.xp end,
    unitXPMax = function() return state.xpMax end,
    unitLevel = function() return state.level end,
    restedXP = function() return state.rested end,
    isMaxLevel = function() return state.maxLevel or false end,
    now = function() return state.time end,
  }
end

local function newSource(overrides)
  local state = { xp = 500, xpMax = 1000, level = 10, rested = 0, time = 0 }
  for k, v in pairs(overrides or {}) do state[k] = v end
  return ns.XPSource.new(fakeApi(state)), state
end

test("snapshot of a fresh source", function()
  local src = newSource()
  local snap = src:Get()
  eq(snap.level, 10)
  eq(snap.percent, 50)
  eq(snap.remaining, 500)
  eq(snap.session.xpGained, 0)
  eq(snap.quests, nil)
  eq(snap.played, nil)
  eq(snap.lastGain, nil)
end)

test("an XP gain updates the snapshot and the session", function()
  local src, state = newSource()
  state.xp = 600
  src:onXPUpdate()
  local snap = src:Get()
  eq(snap.xp, 600)
  eq(snap.session.xpGained, 100)
end)

test("a level-up counts the XP left in the old level plus the new XP", function()
  local src, state = newSource({ xp = 900 })
  state.level, state.xp, state.xpMax = 11, 50, 1200
  src:onXPUpdate()
  local snap = src:Get()
  eq(snap.session.xpGained, 150)
  eq(snap.xpMax, 1200)
  eq(snap.level, 11)
end)

test("a kill message followed by an XP update sets the last gain", function()
  local src, state = newSource()
  state.time = 10
  src:onKillXPMessage()
  state.xp = 580
  src:onXPUpdate()
  local snap = src:Get()
  eq(snap.lastGain, 80)
  eq(snap.killsToLevel, 6)
end)

test("an XP update followed by a kill message sets the last gain", function()
  local src, state = newSource()
  state.time = 10
  state.xp = 580
  src:onXPUpdate()
  state.time = 10.5
  src:onKillXPMessage()
  eq(src:Get().lastGain, 80)
end)

test("a level-up reported late by UnitLevel is not counted twice", function()
  local src, state = newSource({ xp = 900 })
  -- XP update arrives while UnitLevel and UnitXPMax still report the old level
  state.xp = 100
  src:onXPUpdate()
  src:onLevelUp(11)
  state.level, state.xpMax, state.xp = 11, 1200, 200
  src:onXPUpdate()
  eq(src:Get().session.xpGained, 300)
end)

test("a stale lower UnitLevel never moves the level backwards", function()
  local src, state = newSource()
  src:onLevelUp(11)
  state.level = 10
  src:onXPUpdate()
  eq(src:Get().level, 11)
end)

test("an XP update alone (a quest) does not set the last gain", function()
  local src, state = newSource()
  state.time = 10
  state.xp = 800
  src:onXPUpdate()
  eq(src:Get().lastGain, nil)
end)

test("a kill message and an XP update far apart are not paired", function()
  local src, state = newSource()
  state.time = 10
  src:onKillXPMessage()
  state.time = 12
  state.xp = 600
  src:onXPUpdate()
  eq(src:Get().lastGain, nil)
end)

test("session rate and time to level", function()
  local src, state = newSource({ xp = 500, xpMax = 100000 })
  state.time = 3600
  state.xp = 4100
  src:onXPUpdate()
  local snap = src:Get()
  near(snap.session.xpPerHour, 3600)
  near(snap.session.timeToLevel, 95900)
end)

test("played time advances locally between replies", function()
  local src, state = newSource()
  src:onPlayed(10000, 1000)
  state.time = 100
  local p = src:Get().played
  eq(p.total, 10100)
  eq(p.levelTime, 1100)
  eq(p.averagePerLevel, 1000)
end)

test("quests are summed, sorted and expressed as a percentage of the bar", function()
  local src = newSource()
  src:setQuests({ { title = "A", xp = 100 }, { title = "B", xp = 300 } })
  local q = src:Get().quests
  eq(q.total, 400)
  eq(q.percent, 40)
  eq(q.count, 2)
  eq(q.list[1].title, "B")
  eq(q.list[1].percent, 30)
  src:setQuests({})
  eq(src:Get().quests.total, 0)
  eq(src:Get().quests.count, 0)
  src:setQuests(nil)
  eq(src:Get().quests, nil)
end)

test("quest percentages follow the current level's XP max", function()
  local src, state = newSource()
  src:setQuests({ { title = "A", xp = 100 } })
  eq(src:Get().quests.percent, 10)
  state.level, state.xp, state.xpMax = 11, 0, 2000
  src:onXPUpdate()
  eq(src:Get().quests.percent, 5)
end)

test("subscribers are notified", function()
  local src, state = newSource()
  local calls = 0
  src:Subscribe(function() calls = calls + 1 end)
  state.xp = 600
  src:onXPUpdate()
  truthy(calls >= 1)
end)

test("XP max of zero (max level) never divides by zero", function()
  local src = newSource({ xp = 0, xpMax = 0, level = 60, maxLevel = true })
  local snap = src:Get()
  eq(snap.isMaxLevel, true)
  eq(snap.percent, 0)
  eq(snap.remaining, 0)
  eq(snap.killsToLevel, nil)
  eq(snap.session.timeToLevel, nil)
end)

test("resetSession clears the session figures", function()
  local src, state = newSource()
  state.time = 100
  state.xp = 600
  src:onXPUpdate()
  src:resetSession()
  local snap = src:Get()
  eq(snap.session.xpGained, 0)
  eq(snap.lastGain, nil)
end)

test("the snapshot says whether the player is resting", function()
  local state = { xp = 500, xpMax = 1000, level = 10, rested = 0, time = 0, resting = true }
  local api = fakeApi(state)
  api.isResting = function() return state.resting end
  local src = ns.XPSource.new(api)
  eq(src:Get().resting, true)
  state.resting = false
  eq(src:Get().resting, false)
  eq(newSource():Get().resting, false) -- an api without isResting
end)
