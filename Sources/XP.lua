local ADDON, ns = ...
local Calc = ns.Calc

local XPSource = {}
XPSource.__index = XPSource
ns.XPSource = XPSource

local PAIR_WINDOW = 1.0 -- seconds within which a kill message and an XP update belong together

function XPSource.new(api)
  local self = setmetatable({}, XPSource)
  self.api = api
  self.subscribers = {}
  self:rebase()
  self:resetSession()
  return self
end

function XPSource:Subscribe(fn)
  self.subscribers[#self.subscribers + 1] = fn
end

function XPSource:notify()
  for _, fn in ipairs(self.subscribers) do fn(self) end
end

-- Re-reads the game state without counting it as a gain (login, zoning).
function XPSource:rebase()
  local api = self.api
  self.level = api.unitLevel()
  self.xp = api.unitXP()
  self.xpMax = api.unitXPMax()
  self.rested = api.restedXP() or 0
  self:notify()
end

function XPSource:resetSession()
  self.sessionStart = self.api.now()
  self.sessionXP = 0
  self.lastGain = nil
  self.killMessageTime = nil
  self.unpairedDelta = nil
  self:notify()
end

function XPSource:onRestedUpdate()
  self.rested = self.api.restedXP() or 0
  self:notify()
end

function XPSource:pairGain(gain)
  local now = self.api.now()
  if self.killMessageTime and now - self.killMessageTime <= PAIR_WINDOW then
    self.lastGain = gain
    self.killMessageTime = nil
    self.unpairedDelta = nil
  else
    self.unpairedDelta = { amount = gain, time = now }
  end
end

-- PLAYER_LEVEL_UP carries the new level; UnitLevel can lag behind it on Classic clients.
-- Only the level is synced here: the XP crossing is counted by the XP update itself.
function XPSource:onLevelUp(newLevel)
  if newLevel and newLevel > self.level then
    self.level = newLevel
    self:notify()
  end
end

function XPSource:onXPUpdate()
  local api = self.api
  local level, xp, xpMax = api.unitLevel(), api.unitXP(), api.unitXPMax()
  local gain = Calc.xpDelta(self.xp, self.xpMax, xp, level > self.level)
  -- The level never goes down within a session; a stale UnitLevel must not undo onLevelUp.
  self.level, self.xp, self.xpMax = math.max(level, self.level), xp, xpMax
  if gain > 0 then
    self.sessionXP = self.sessionXP + gain
    self:pairGain(gain)
  end
  self:notify()
end

-- CHAT_MSG_COMBAT_XP_GAIN only fires for kills; its text is never parsed (language-independent).
function XPSource:onKillXPMessage()
  local now = self.api.now()
  local d = self.unpairedDelta
  if d and now - d.time <= PAIR_WINDOW then
    self.lastGain = d.amount
    self.unpairedDelta = nil
    self.killMessageTime = nil
    self:notify()
  else
    self.killMessageTime = now
  end
end

function XPSource:onPlayed(total, levelTime)
  self.played = { total = total, levelTime = levelTime, receivedAt = self.api.now() }
  self:notify()
end

-- list = { {title, xp}, ... } of completed quests, or nil when the quest API is unavailable.
function XPSource:setQuests(list)
  self.questList = list
  self:notify()
end

local function buildQuests(list, xpMax)
  if not list then return nil end
  local sorted, total = {}, 0
  for _, q in ipairs(list) do
    sorted[#sorted + 1] = { title = q.title, xp = q.xp, percent = Calc.percent(q.xp, xpMax) }
    total = total + q.xp
  end
  table.sort(sorted, function(a, b) return a.xp > b.xp end)
  return { total = total, percent = Calc.percent(total, xpMax), count = #sorted, list = sorted }
end

function XPSource:Get()
  local api = self.api
  local now = api.now()
  local seconds = now - self.sessionStart
  local remaining = Calc.remaining(self.xp, self.xpMax)
  local rate = Calc.xpPerHour(self.sessionXP, seconds)

  local played
  if self.played then
    local elapsed = now - self.played.receivedAt
    local average
    if self.level > 1 then
      average = (self.played.total - self.played.levelTime) / (self.level - 1)
    end
    played = {
      total = self.played.total + elapsed,
      levelTime = self.played.levelTime + elapsed,
      averagePerLevel = average,
    }
  end

  return {
    level = self.level,
    xp = self.xp,
    xpMax = self.xpMax,
    remaining = remaining,
    percent = Calc.percent(self.xp, self.xpMax),
    isMaxLevel = api.isMaxLevel(),
    rested = self.rested,
    restedPercent = Calc.percent(self.rested, self.xpMax),
    session = {
      xpGained = self.sessionXP,
      seconds = seconds,
      xpPerHour = rate,
      timeToLevel = Calc.timeToLevel(remaining, rate),
    },
    lastGain = self.lastGain,
    killsToLevel = Calc.killsToLevel(remaining, self.lastGain),
    played = played,
    quests = buildQuests(self.questList, self.xpMax),
  }
end
