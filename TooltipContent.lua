local ADDON, ns = ...
local Calc, History = ns.Calc, ns.History

local TooltipContent = {}
ns.TooltipContent = TooltipContent

local HISTORY_ROWS = 6

-- Builds the "Minimal" tooltip as data: a title, a subtitle, groups of rows and a hint.
-- A row is { label, value, color } where color is nil, "rested", "quest" or "muted",
-- or { kind = "history", label, value, ratio } for one level of the history chart.
-- `detailed` is the Shift view. Pure: everything it needs is passed in.
function TooltipContent.build(snap, settings, store, opts, L, detailed)
  local show = settings.tooltip
  local function num(n) return Calc.formatNumber(n, opts.number) end
  local function dur(s) return Calc.formatDuration(s, opts.units) end
  local function pct(p) return string.format("%d%%", math.floor(p + 0.5)) end

  local groups = {}
  local function group()
    local g = {}
    local function add(label, value, color) g[#g + 1] = { label = label, value = value, color = color } end
    return g, add
  end
  local function keep(g) if #g > 0 then groups[#groups + 1] = g end end

  local content = { title = L["Level %d"]:format(snap.level) }
  content.subtitle = snap.isMaxLevel and L["Max level"]
    or (num(snap.xp) .. " / " .. num(snap.xpMax))

  if not snap.isMaxLevel then
    local g, add = group()
    if show.level then
      add(L["Progress"], pct(snap.percent))
      add(L["Remaining"], num(snap.remaining))
    end
    if show.rested and snap.rested > 0 then add(L["Rested"], num(snap.rested), "rested") end
    if show.quests and snap.quests and snap.quests.total > 0 then
      add(L["Quests ready to turn in"], "+" .. num(snap.quests.total), "quest")
      if detailed then
        local limit = settings.questListMax or 5
        for i, q in ipairs(snap.quests.list) do
          if i > limit then break end
          add(q.title, num(q.xp), "quest")
        end
        local extra = snap.quests.count - limit
        if extra > 0 then add(L["… and %d more"]:format(extra), nil, "muted") end
      end
    end
    keep(g)

    if detailed and show.kills and snap.killsToLevel then
      local k, addK = group()
      addK(L["Kills to level"], "~" .. snap.killsToLevel)
      if snap.lastGain then addK(L["Last gain"], num(snap.lastGain)) end
      keep(k)
    end
  end

  if show.session then
    local g, add = group()
    if snap.session.xpPerHour then add(L["XP per hour"], num(snap.session.xpPerHour)) end
    if snap.session.timeToLevel and not snap.isMaxLevel then
      add(L["Time to level"], dur(snap.session.timeToLevel))
    end
    if detailed then
      add(L["XP gained"], num(snap.session.xpGained))
      add(L["Duration"], dur(snap.session.seconds))
    end
    keep(g)
  end

  if show.played and snap.played then
    local g, add = group()
    add(L["Time played"], dur(snap.played.total))
    if detailed then
      add(L["This level"], dur(snap.played.levelTime))
      if snap.played.averagePerLevel then add(L["Average per level"], dur(snap.played.averagePerLevel)) end
    end
    keep(g)
  end

  if detailed and show.history and store and #History.entries(store) > 0 then
    local g, add = group()
    local delta = Calc.paceDelta(snap.session.xpPerHour, History.averageRate(store))
    if delta then add(L["Pace"], L["%+d%% vs your average"]:format(math.floor(delta + 0.5))) end
    for _, p in ipairs(History.sparkline(store, HISTORY_ROWS)) do
      g[#g + 1] = { kind = "history", label = L["Level %d"]:format(p.level), value = dur(p.duration), ratio = p.ratio }
    end
    keep(g)
  end

  content.groups = groups
  if not detailed then content.hint = L["Hold Shift for details"] end
  return content
end

-- The reputation bar's tooltip, same shape as the XP one.
-- settings.tooltip = { progress, session }.
function TooltipContent.buildRep(snap, settings, opts, L, detailed)
  local show = settings.tooltip
  local function num(n) return Calc.formatNumber(n, opts.number) end
  local function dur(s) return Calc.formatDuration(s, opts.units) end
  local function pct(p) return string.format("%d%%", math.floor(p + 0.5)) end
  local function signed(n) return (n > 0 and "+" or "") .. num(n) end

  if snap.none then
    return { title = L["No watched faction"], groups = {}, hint = nil }
  end

  local groups = {}
  local function group()
    local g = {}
    return g, function(label, value, color) g[#g + 1] = { label = label, value = value, color = color } end
  end
  local function keep(g) if #g > 0 then groups[#groups + 1] = g end end

  if show.progress then
    local g, add = group()
    add(L["Progress"], pct(snap.percent))
    add(L["Standing"], num(snap.current) .. " / " .. num(snap.max))
    if not snap.isMax then add(L["Remaining"], num(snap.remaining)) end
    if detailed and snap.toExalted > 0 then add(L["To Exalted"], num(snap.toExalted)) end
    keep(g)
  end

  if show.session then
    local g, add = group()
    if snap.session.perHour then add(L["Rep per hour"], num(snap.session.perHour)) end
    if snap.session.timeToNext then add(L["Time to next standing"], dur(snap.session.timeToNext)) end
    if detailed then
      add(L["Reputation gained"], signed(snap.session.gained))
      add(L["Duration"], dur(snap.session.seconds))
      if snap.lastGain then add(L["Last gain"], signed(snap.lastGain)) end
    end
    keep(g)
  end

  return {
    title = snap.name,
    subtitle = snap.standingLabel,
    groups = groups,
    hint = (not detailed) and L["Hold Shift for details"] or nil,
  }
end
