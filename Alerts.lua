local ADDON, ns = ...
local Calc = ns.Calc

-- Leveling alerts: "turning in your quests will level you up" and the level-up summary.
local Alerts = {}
ns.Alerts = Alerts

function Alerts.questsWouldLevel(snap)
  if snap.isMaxLevel or not snap.quests then return false end
  return snap.quests.total > 0 and snap.xp + snap.quests.total >= snap.xpMax
end

-- Remembers the level it last announced, so the alert fires once per level.
local Tracker = {}
Tracker.__index = Tracker

function Alerts.newTracker()
  return setmetatable({ announced = nil }, Tracker)
end

function Tracker:questsReady(snap)
  if not Alerts.questsWouldLevel(snap) or self.announced == snap.level then return false end
  self.announced = snap.level
  return true
end

-- "Level 21 reached in 1h 07m (pace +12 % vs your average)". `pace` is the percentage
-- difference with the player's own average, or nil without history.
function Alerts.levelUpSummary(record, pace, opts, L)
  local text = L["summary.levelup"]:format(record.level + 1, Calc.formatDuration(record.duration, opts.units))
  if pace then text = text .. " - " .. L["summary.pace"]:format(math.floor(pace + 0.5)) end
  return text
end
