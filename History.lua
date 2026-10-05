local ADDON, ns = ...
local Calc = ns.Calc

local History = {}
ns.History = History

-- store = {
--   current = { level, start, xpMax },   -- the level in progress; `start` = total played when it began
--   levels  = { [level] = { level, duration, xpMax, rate, date } },
-- }
function History.newStore()
  return { levels = {} }
end

local function validEntry(e)
  return type(e) == "table" and type(e.level) == "number" and type(e.duration) == "number"
    and type(e.xpMax) == "number" and e.duration > 0
end

-- Repairs a store read from saved variables: drops malformed entries and baseline.
function History.sanitize(store)
  if type(store) ~= "table" then return History.newStore() end
  if type(store.levels) ~= "table" then store.levels = {} end
  for key, e in pairs(store.levels) do
    if validEntry(e) then
      e.rate = e.xpMax * 3600 / e.duration
    else
      store.levels[key] = nil
    end
  end
  local cur = store.current
  if type(cur) ~= "table" or type(cur.level) ~= "number" or type(cur.start) ~= "number" then
    store.current = nil
  end
  return store
end

-- Feed every /played reply. `total` and `levelTime` are the two values of TIME_PLAYED_MSG.
-- Returns the record of a level that was just completed, otherwise nil.
function History.onPlayed(store, level, total, levelTime, xpMax, now)
  store.levels = store.levels or {}
  local start = total - levelTime
  local cur = store.current

  if cur and cur.level == level then
    cur.start = start
    cur.xpMax = xpMax
    return nil
  end

  local recorded
  if cur and level == cur.level + 1 then
    local duration = start - cur.start
    if duration > 0 and cur.xpMax and cur.xpMax > 0 then
      recorded = {
        level = cur.level,
        duration = duration,
        xpMax = cur.xpMax,
        rate = cur.xpMax * 3600 / duration,
        date = now,
      }
      store.levels[cur.level] = recorded
    end
  end

  store.current = { level = level, start = start, xpMax = xpMax }
  return recorded
end

function History.entries(store)
  local list = {}
  for _, e in pairs(store.levels or {}) do list[#list + 1] = e end
  table.sort(list, function(a, b) return a.level < b.level end)
  return list
end

-- XP per hour over every recorded level, weighted by time spent.
function History.averageRate(store)
  local xp, seconds = 0, 0
  for _, e in ipairs(History.entries(store)) do
    xp = xp + e.xpMax
    seconds = seconds + e.duration
  end
  if seconds <= 0 then return nil end
  return xp * 3600 / seconds
end

function History.compare(store, currentRate)
  return Calc.paceDelta(currentRate, History.averageRate(store))
end

function History.sparkline(store, n)
  local entries = History.entries(store)
  local first = math.max(1, #entries - n + 1)
  local out, longest = {}, 0
  for i = first, #entries do
    local e = entries[i]
    out[#out + 1] = { level = e.level, duration = e.duration }
    if e.duration > longest then longest = e.duration end
  end
  for _, p in ipairs(out) do
    p.ratio = longest > 0 and p.duration / longest or 0
  end
  return out
end

function History.reset(store)
  store.levels = {}
  store.current = nil
end
