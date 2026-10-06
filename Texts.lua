local ADDON, ns = ...
local Calc = ns.Calc

local Texts = {}
ns.Texts = Texts

Texts.KEYS = {
  "none", "level", "percent", "current_max", "current_max_percent",
  "remaining", "rested", "xp_per_hour", "time_to_level", "kills", "quests",
}

local function pct(p) return string.format("%d%%", math.floor(p + 0.5)) end

local renderers = {}

function renderers.none() return "" end

function renderers.level(s, o, L)
  return L["Level %d"]:format(s.level)
end

function renderers.percent(s)
  return string.format("%.1f%%", s.percent)
end

function renderers.current_max(s, o)
  return Calc.formatNumber(s.xp, o.number) .. " / " .. Calc.formatNumber(s.xpMax, o.number)
end

function renderers.current_max_percent(s, o)
  return renderers.current_max(s, o) .. " (" .. pct(s.percent) .. ")"
end

function renderers.remaining(s, o, L)
  return L["%s remaining"]:format(Calc.formatNumber(s.remaining, o.number))
end

function renderers.rested(s, o, L)
  if s.rested <= 0 then return "" end
  return L["Rested %s"]:format(Calc.formatNumber(s.rested, o.number) .. " (" .. pct(s.restedPercent) .. ")")
end

function renderers.xp_per_hour(s, o, L)
  if not s.session.xpPerHour then return "" end
  return L["%s XP/h"]:format(Calc.formatNumber(s.session.xpPerHour, o.number))
end

function renderers.time_to_level(s, o, L)
  local t = Calc.formatDuration(s.session.timeToLevel, o.units)
  if not t then return "" end
  return L["%s to level"]:format(t)
end

function renderers.kills(s, o, L)
  if not s.killsToLevel then return "" end
  return L["~%d kills"]:format(s.killsToLevel)
end

function renderers.quests(s, o, L)
  if not s.quests or s.quests.total <= 0 then return "" end
  return L["+%s from quests"]:format(Calc.formatNumber(s.quests.total, o.number))
end

-- Reputation bar texts (the snapshot comes from Sources/Reputation.lua).
Texts.REP_KEYS = {
  "none", "faction", "standing", "rep_current_max", "rep_current_max_percent",
  "rep_percent", "rep_remaining", "to_exalted", "rep_per_hour",
}

local rep = {}
function rep.faction(s) return s.name end
function rep.standing(s) return s.standingLabel end
function rep.rep_current_max(s, o)
  return Calc.formatNumber(s.current, o.number) .. " / " .. Calc.formatNumber(s.max, o.number)
end
function rep.rep_current_max_percent(s, o) return rep.rep_current_max(s, o) .. " (" .. pct(s.percent) .. ")" end
function rep.rep_percent(s) return string.format("%.1f%%", s.percent) end
function rep.rep_remaining(s, o, L)
  if s.isMax then return "" end
  return L["%s remaining"]:format(Calc.formatNumber(s.remaining, o.number))
end
function rep.to_exalted(s, o, L)
  if s.toExalted <= 0 then return "" end
  return L["%s to Exalted"]:format(Calc.formatNumber(s.toExalted, o.number))
end
function rep.rep_per_hour(s, o, L)
  if not s.session.perHour then return "" end
  return L["%s rep/h"]:format(Calc.formatNumber(s.session.perHour, o.number))
end
for key, fn in pairs(rep) do
  renderers[key] = function(s, o, L)
    if s.none then return "" end
    return fn(s, o, L) or ""
  end
end

-- One line describing the progress, inserted into the chat box on Shift+click.
function Texts.chatLine(kind, snap, opts, L)
  local function num(n) return Calc.formatNumber(n, opts.number) end
  if kind == "rep" then
    if snap.none then return nil end
    return L["chat.rep"]:format(snap.name, snap.standingLabel, num(snap.current), num(snap.max), pct(snap.percent))
  end
  if snap.isMaxLevel then return L["chat.max"]:format(snap.level) end
  local line = L["chat.xp"]:format(snap.level, pct(snap.percent), num(snap.xp), num(snap.xpMax), num(snap.remaining))
  if snap.rested > 0 then line = line .. " | " .. L["chat.rested"]:format(num(snap.rested)) end
  return line
end

function Texts.render(key, snap, opts, L)
  local fn = renderers[key]
  if not fn then return "" end
  return fn(snap, opts, L)
end
