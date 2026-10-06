local ADDON, ns = ...
local Calc = ns.Calc

-- Reputation of the faction watched in the game ("Show as experience bar").
-- api = { watched() -> { name, factionID, standing, min, max, value } | nil, label(standing), now() }
-- min/max/value are the game's absolute reputation values for the current standing.
local RepSource = {}
RepSource.__index = RepSource
ns.RepSource = RepSource

local EXALTED = 8
local EXALTED_START = 42000 -- absolute reputation at which Exalted begins

function RepSource.new(api)
  local self = setmetatable({}, RepSource)
  self.api = api
  self.subscribers = {}
  self:rebase()
  self:resetSession()
  return self
end

function RepSource:Subscribe(fn)
  self.subscribers[#self.subscribers + 1] = fn
end

function RepSource:notify()
  for _, fn in ipairs(self.subscribers) do fn(self) end
end

-- Re-reads the watched faction without counting anything as a gain.
function RepSource:rebase()
  self.faction = self.api.watched()
  self:notify()
end

function RepSource:resetSession()
  self.sessionStart = self.api.now()
  self.sessionGain = 0
  self.lastGain = nil
  self:notify()
end

-- UPDATE_FACTION: a change of value of the same faction is a gain (or a loss);
-- a different faction just becomes the new baseline.
-- Same faction: by ID when both have one, otherwise by name.
local function sameFaction(a, b)
  if not a or not b then return false end
  if a.factionID and b.factionID then return a.factionID == b.factionID end
  return a.name == b.name
end

function RepSource:onUpdate()
  local old, new = self.faction, self.api.watched()
  if sameFaction(old, new) then
    local delta = new.value - old.value
    if delta ~= 0 then
      self.sessionGain = self.sessionGain + delta
      self.lastGain = delta > 0 and delta or self.lastGain
    end
  else
    -- Another faction: its session starts now (no rate mixed across factions).
    self.sessionStart = self.api.now()
    self.sessionGain = 0
    self.lastGain = nil
  end
  self.faction = new
  self:notify()
end

function RepSource:Get()
  local f = self.faction
  local seconds = self.api.now() - self.sessionStart
  local rate = Calc.xpPerHour(self.sessionGain, seconds)
  if not f then
    return {
      none = true, current = 0, max = 0, percent = 0, remaining = 0, toExalted = 0, isMax = false,
      session = { gained = self.sessionGain, seconds = seconds, perHour = rate },
      lastGain = self.lastGain,
    }
  end
  local current, max = f.value - f.min, f.max - f.min
  local isMax = f.standing >= EXALTED
  local remaining = isMax and 0 or Calc.remaining(current, max)
  return {
    none = false,
    name = f.name,
    factionID = f.factionID,
    standing = f.standing,
    standingLabel = self.api.label(f.standing),
    current = current,
    max = max,
    percent = Calc.percent(current, max),
    remaining = remaining,
    toExalted = isMax and 0 or math.max(0, EXALTED_START - f.value),
    isMax = isMax,
    session = {
      gained = self.sessionGain,
      seconds = seconds,
      perHour = rate,
      timeToNext = (not isMax) and Calc.timeToLevel(remaining, rate) or nil,
    },
    lastGain = self.lastGain,
  }
end
