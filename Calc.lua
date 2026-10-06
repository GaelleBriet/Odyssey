local ADDON, ns = ...

local Calc = {}
ns.Calc = Calc

local MIN_RATE_SECONDS = 60
local DEFAULT_UNITS = { d = "d", h = "h", m = "m", s = "s" }

function Calc.percent(cur, max)
  if not max or max <= 0 then return 0 end
  local p = (cur or 0) / max * 100
  if p < 0 then return 0 end
  if p > 100 then return 100 end
  return p
end

function Calc.remaining(cur, max)
  if not max or max <= 0 then return 0 end
  local r = max - (cur or 0)
  return r > 0 and r or 0
end

function Calc.fraction(value, max)
  if not max or max <= 0 or not value or value <= 0 then return 0 end
  if value >= max then return 1 end
  return value / max
end

-- Where each layer of the bar ends, as fractions of the bar. A hidden segment collapses onto
-- the fill (zero width beyond it).
function Calc.barTargets(snap, settings)
  local questTotal = settings.showQuestSegment and snap.quests and snap.quests.total or 0
  local rested = settings.showRestedSegment and snap.rested or 0
  return {
    fill = Calc.fraction(snap.xp, snap.xpMax),
    quest = Calc.fraction(snap.xp + questTotal, snap.xpMax),
    rested = Calc.fraction(snap.xp + rested, snap.xpMax),
  }
end

-- The reputation bar only has a fill (no quest or rested band).
function Calc.repTargets(snap)
  local fill = snap.isMax and 1 or Calc.fraction(snap.current, snap.max)
  return { fill = fill, quest = 0, rested = 0 }
end

-- Rested and quest segments both start at the fill: the shorter one is drawn on top so
-- the two show as clean consecutive bands instead of a blended overlap.
function Calc.topSegment(targets)
  if targets.rested < targets.quest then return "rested" end
  return "quest"
end

-- XP gained between two readings. `leveledUp` means the level went up in between;
-- a drop in XP is also read as a level-up so that a missed level event cannot lose the gain.
function Calc.xpDelta(oldXP, oldMax, newXP, leveledUp)
  local d
  if leveledUp or newXP < oldXP then
    d = (oldMax - oldXP) + newXP
  else
    d = newXP - oldXP
  end
  return d > 0 and d or 0
end

function Calc.xpPerHour(xpGained, seconds)
  if not seconds or seconds < MIN_RATE_SECONDS or not xpGained or xpGained <= 0 then return nil end
  return xpGained * 3600 / seconds
end

function Calc.timeToLevel(remaining, ratePerHour)
  if not remaining or not ratePerHour or ratePerHour <= 0 then return nil end
  return remaining / ratePerHour * 3600
end

function Calc.killsToLevel(remaining, lastGain)
  if not remaining or not lastGain or lastGain <= 0 then return nil end
  return math.ceil(remaining / lastGain)
end

function Calc.average(list)
  if not list or #list == 0 then return nil end
  local sum = 0
  for _, v in ipairs(list) do sum = sum + v end
  return sum / #list
end

function Calc.paceDelta(current, average)
  if not current or not average or average <= 0 then return nil end
  return (current - average) / average * 100
end

-- Next (step = 1) or previous (step = -1) value in a list, wrapping around.
-- An unknown current value falls back to the first entry.
function Calc.cycle(values, current, step)
  for i, v in ipairs(values) do
    if v == current then
      local j = (i - 1 + step) % #values + 1
      return values[j]
    end
  end
  return values[1]
end

local function trimDecimal(s, decimal)
  s = s:gsub("%.0$", "")
  return (s:gsub("%.", decimal))
end

function Calc.formatNumber(n, opts)
  opts = opts or {}
  local thousands = opts.thousands or ","
  local decimal = opts.decimal or "."
  n = n or 0
  if opts.abbreviated then
    if n >= 1000000 then return trimDecimal(string.format("%.1f", n / 1000000), decimal) .. "m" end
    if n >= 1000 then return trimDecimal(string.format("%.1f", n / 1000), decimal) .. "k" end
  end
  local negative = n < 0
  local s = string.format("%d", math.floor(math.abs(n) + 0.5))
  local out, count = "", 0
  for i = #s, 1, -1 do
    if count > 0 and count % 3 == 0 then out = thousands .. out end
    out = s:sub(i, i) .. out
    count = count + 1
  end
  return negative and ("-" .. out) or out
end

function Calc.formatDuration(seconds, units)
  if not seconds then return nil end
  units = units or DEFAULT_UNITS
  seconds = math.floor(seconds + 0.5)
  if seconds < 0 then seconds = 0 end
  local d = math.floor(seconds / 86400)
  local h = math.floor((seconds % 86400) / 3600)
  local m = math.floor((seconds % 3600) / 60)
  local s = seconds % 60
  if d > 0 then return string.format("%d%s %d%s", d, units.d, h, units.h) end
  if h > 0 then return string.format("%d%s %02d%s", h, units.h, m, units.m) end
  if m > 0 then return string.format("%d%s %02d%s", m, units.m, s, units.s) end
  return string.format("%d%s", s, units.s)
end
