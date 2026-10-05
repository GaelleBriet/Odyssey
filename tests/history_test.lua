local ns = newNamespace()
loadAddonFile("Calc.lua", ns)
loadAddonFile("History.lua", ns)
local H = ns.History

test("first reply only sets the baseline", function()
  local s = H.newStore()
  eq(H.onPlayed(s, 10, 10000, 1000, 5000, 111), nil)
  eq(s.current, { level = 10, start = 9000, xpMax = 5000 })
  eq(s.levels, {})
end)

test("a repeated reply for the same level records nothing", function()
  local s = H.newStore()
  H.onPlayed(s, 10, 10000, 1000, 5000, 111)
  eq(H.onPlayed(s, 10, 10600, 1600, 5000, 112), nil)
  eq(s.current.start, 9000)
  eq(s.levels, {})
end)

test("a level-up records the finished level", function()
  local s = H.newStore()
  H.onPlayed(s, 10, 10000, 1000, 5000, 111)
  local rec = H.onPlayed(s, 11, 13700, 100, 5600, 200)
  eq(rec.level, 10)
  eq(rec.duration, 4600)
  eq(rec.xpMax, 5000)
  near(rec.rate, 5000 * 3600 / 4600)
  eq(rec.date, 200)
  eq(s.levels[10], rec)
  eq(s.current, { level = 11, start = 13600, xpMax = 5600 })
end)

test("a duplicate reply after a level-up does not record twice", function()
  local s = H.newStore()
  H.onPlayed(s, 10, 10000, 1000, 5000, 111)
  H.onPlayed(s, 11, 13700, 100, 5600, 200)
  eq(H.onPlayed(s, 11, 13800, 200, 5600, 201), nil)
  eq(#H.entries(s), 1)
end)

test("a gap of several levels records nothing and resets the baseline", function()
  local s = H.newStore()
  H.onPlayed(s, 10, 10000, 1000, 5000, 111)
  eq(H.onPlayed(s, 13, 50000, 50, 9000, 300), nil)
  eq(s.levels, {})
  eq(s.current.level, 13)
end)

test("a non-positive duration is ignored", function()
  local s = H.newStore()
  H.onPlayed(s, 10, 10000, 1000, 5000, 111)
  eq(H.onPlayed(s, 11, 9000, 0, 5600, 200), nil)
  eq(s.levels, {})
end)

test("averageRate is weighted by time", function()
  local s = { levels = {
    [10] = { level = 10, duration = 3600, xpMax = 3600, rate = 3600 },
    [11] = { level = 11, duration = 1800, xpMax = 3600, rate = 7200 },
  } }
  near(H.averageRate(s), 4800)
  eq(H.averageRate(H.newStore()), nil)
end)

test("compare uses the weighted average", function()
  local s = { levels = { [10] = { level = 10, duration = 3600, xpMax = 3600, rate = 3600 } } }
  near(H.compare(s, 4320), 20)
  eq(H.compare(H.newStore(), 4320), nil)
  eq(H.compare(s, nil), nil)
end)

test("entries are sorted by level", function()
  local s = { levels = { [12] = { level = 12 }, [10] = { level = 10 }, [11] = { level = 11 } } }
  local levels = {}
  for _, e in ipairs(H.entries(s)) do levels[#levels + 1] = e.level end
  eq(levels, { 10, 11, 12 })
end)

test("sparkline returns the last n levels scaled to the longest", function()
  local s = { levels = {
    [10] = { level = 10, duration = 3600 },
    [11] = { level = 11, duration = 1800 },
    [12] = { level = 12, duration = 900 },
  } }
  local all = H.sparkline(s, 6)
  eq(#all, 3)
  eq(all[1].ratio, 1)
  eq(all[2].ratio, 0.5)
  local last = H.sparkline(s, 2)
  eq(#last, 2)
  eq(last[1].level, 11)
  eq(last[1].ratio, 1)
  eq(H.sparkline(H.newStore(), 6), {})
end)

test("reset empties the store", function()
  local s = H.newStore()
  H.onPlayed(s, 10, 10000, 1000, 5000, 111)
  H.reset(s)
  eq(s.levels, {})
  eq(s.current, nil)
end)
