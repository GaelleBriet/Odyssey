local ns = newNamespace()
loadAddonFile("Calc.lua", ns)
loadAddonFile("Sources/Reputation.lua", ns)

local function fakeApi(state)
  return {
    watched = function() return state.faction end,
    label = function(standing) return "standing" .. standing end,
    now = function() return state.time end,
  }
end

local function friendly(value)
  return { name = "Orgrimmar", factionID = 76, standing = 5, min = 3000, max = 9000, value = value }
end

local function newSource(faction)
  local state = { faction = faction, time = 0 }
  return ns.RepSource.new(fakeApi(state)), state
end

test("no watched faction", function()
  local src = newSource(nil)
  local snap = src:Get()
  eq(snap.none, true)
  eq(snap.percent, 0)
end)

test("snapshot of a watched faction", function()
  local snap = newSource(friendly(4500)):Get()
  eq(snap.none, false)
  eq(snap.name, "Orgrimmar")
  eq(snap.standing, 5)
  eq(snap.standingLabel, "standing5")
  eq(snap.current, 1500)
  eq(snap.max, 6000)
  eq(snap.percent, 25)
  eq(snap.remaining, 4500)
  eq(snap.toExalted, 37500)
  eq(snap.isMax, false)
end)

test("a reputation gain is counted in the session", function()
  local src, state = newSource(friendly(4500))
  state.faction = friendly(4600)
  src:onUpdate()
  local snap = src:Get()
  eq(snap.session.gained, 100)
  eq(snap.lastGain, 100)
  eq(snap.current, 1600)
end)

test("a gain that crosses into the next standing is counted once", function()
  local src, state = newSource(friendly(8900))
  state.faction = { name = "Orgrimmar", factionID = 76, standing = 6, min = 9000, max = 21000, value = 9100 }
  src:onUpdate()
  eq(src:Get().session.gained, 200)
  eq(src:Get().standing, 6)
end)

test("switching the watched faction is not a gain", function()
  local src, state = newSource(friendly(4500))
  state.faction = { name = "Thunder Bluff", factionID = 81, standing = 4, min = 0, max = 3000, value = 2000 }
  src:onUpdate()
  eq(src:Get().session.gained, 0)
  eq(src:Get().lastGain, nil)
  eq(src:Get().name, "Thunder Bluff")
end)

test("a loss lowers the session total but is not a last gain", function()
  local src, state = newSource(friendly(4500))
  state.faction = friendly(4400)
  src:onUpdate()
  eq(src:Get().session.gained, -100)
  eq(src:Get().lastGain, nil)
end)

test("rate and time to the next standing", function()
  local src, state = newSource(friendly(4500))
  state.time = 3600
  state.faction = friendly(5400)
  src:onUpdate()
  local snap = src:Get()
  near(snap.session.perHour, 900)
  near(snap.session.timeToNext, 3600 * 3600 / 900)
end)

test("exalted is the top", function()
  local snap = newSource({ name = "Orgrimmar", factionID = 76, standing = 8, min = 42000, max = 42999, value = 42999 }):Get()
  eq(snap.isMax, true)
  eq(snap.toExalted, 0)
  eq(snap.remaining, 0)
end)

test("resetSession clears the session", function()
  local src, state = newSource(friendly(4500))
  state.faction = friendly(4700)
  src:onUpdate()
  src:resetSession()
  eq(src:Get().session.gained, 0)
  eq(src:Get().lastGain, nil)
end)

test("subscribers are notified", function()
  local src, state = newSource(friendly(4500))
  local calls = 0
  src:Subscribe(function() calls = calls + 1 end)
  state.faction = friendly(4600)
  src:onUpdate()
  truthy(calls >= 1)
end)

test("without faction IDs, a different faction name is a switch, not a gain", function()
  local src, state = newSource({ name = "Orgrimmar", standing = 5, min = 3000, max = 9000, value = 4500 })
  state.faction = { name = "Thunder Bluff", standing = 5, min = 3000, max = 9000, value = 8000 }
  src:onUpdate()
  eq(src:Get().session.gained, 0)
end)
