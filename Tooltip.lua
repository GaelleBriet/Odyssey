local ADDON, ns = ...
local Calc, History = ns.Calc, ns.History

local Tooltip = {}
ns.Tooltip = Tooltip

local HISTORY_ROWS = 6
local BAR_MAX_WIDTH = 70

local function row(tt, label, value)
  tt:AddDoubleLine(label, value, 1, 0.82, 0, 1, 1, 1)
end

local function head(tt, text)
  tt:AddLine(" ")
  tt:AddLine(text, 0.55, 0.75, 1)
end

-- Writes the tooltip lines. Pure: everything it needs is passed in.
function Tooltip.fill(tt, snap, settings, store, opts, L, barTexture)
  local show = settings.tooltip
  local function num(n) return Calc.formatNumber(n, opts.number) end
  local function dur(s) return Calc.formatDuration(s, opts.units) end
  local function pct(p) return string.format("%d%%", math.floor(p + 0.5)) end

  tt:AddLine(L["Experience"] .. " - " .. L["Level %d"]:format(snap.level), 1, 1, 1)

  if snap.isMaxLevel then
    tt:AddLine(L["Max level"], 0.6, 1, 0.6)
  else
    if show.level then
      row(tt, L["Level total"], num(snap.xpMax))
      row(tt, L["Done"], num(snap.xp) .. " (" .. pct(snap.percent) .. ")")
      row(tt, L["Remaining"], num(snap.remaining))
    end
    if show.rested and snap.rested > 0 then
      row(tt, L["Rested"], num(snap.rested) .. " (" .. pct(snap.restedPercent) .. ")")
    end
    if show.quests and snap.quests and snap.quests.total > 0 then
      head(tt, L["Quests ready to turn in"] .. ": +" .. num(snap.quests.total) .. " (" .. pct(snap.quests.percent) .. ")")
      local limit = settings.questListMax or 5
      for i, q in ipairs(snap.quests.list) do
        if i > limit then break end
        row(tt, "  " .. q.title, num(q.xp) .. " (" .. pct(q.percent) .. ")")
      end
      local extra = snap.quests.count - limit
      if extra > 0 then tt:AddLine(L["… and %d more"]:format(extra), 0.6, 0.6, 0.6) end
    end
    if show.kills and snap.killsToLevel then
      head(tt, L["Kills to level"])
      row(tt, L["Kills to level"], "~" .. snap.killsToLevel)
      if snap.lastGain then row(tt, L["Last gain"], num(snap.lastGain)) end
    end
  end

  if show.session then
    head(tt, L["Session"])
    row(tt, L["XP gained"], num(snap.session.xpGained))
    row(tt, L["Duration"], dur(snap.session.seconds))
    if snap.session.xpPerHour then row(tt, L["XP per hour"], num(snap.session.xpPerHour)) end
    if snap.session.timeToLevel and not snap.isMaxLevel then
      row(tt, L["Time to level"], dur(snap.session.timeToLevel))
    end
  end

  if show.played and snap.played then
    head(tt, L["Time played"])
    row(tt, L["Total played"], dur(snap.played.total))
    row(tt, L["This level"], dur(snap.played.levelTime))
    if snap.played.averagePerLevel then row(tt, L["Average per level"], dur(snap.played.averagePerLevel)) end
  end

  if show.history and store and #History.entries(store) > 0 then
    head(tt, L["Leveling history"])
    local delta = Calc.paceDelta(snap.session.xpPerHour, History.averageRate(store))
    if delta then
      row(tt, L["Pace"], L["%+d%% vs your average"]:format(math.floor(delta + 0.5)))
    end
    for _, p in ipairs(History.sparkline(store, HISTORY_ROWS)) do
      local width = math.max(2, math.floor(p.ratio * BAR_MAX_WIDTH + 0.5))
      row(tt, L["Level %d"]:format(p.level), "|T" .. barTexture .. ":8:" .. width .. "|t " .. dur(p.duration))
    end
  end
end

function Tooltip.Show(anchor)
  GameTooltip:SetOwner(anchor, "ANCHOR_TOP")
  Tooltip.fill(GameTooltip, ns.source:Get(), ns.Settings(), ns.CharData().history,
    ns.FormatOptions(), ns.L, ns.Styles.TIPBAR)
  GameTooltip:Show()
end
