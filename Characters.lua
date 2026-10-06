local ADDON, ns = ...

-- The player's other characters, recorded at logout, with their rested XP estimated since.
-- store = OdysseyDB.alts: [key] = { name, class, level, rested, xpMax, resting, maxLevel, time }
local Characters = {}
ns.Characters = Characters

local RESTED_CAP = 1.5 -- rested XP stops at 150 % of a level
local INN_RATE = 0.05 / (8 * 3600) -- fraction of a level per second while resting

function Characters.record(store, key, info, now)
  store[key] = {
    name = info.name, class = info.class, level = info.level, rested = info.rested or 0,
    xpMax = info.xpMax, resting = info.resting, maxLevel = info.maxLevel, time = now,
  }
end

-- Characters still leveling, with their estimated rested XP now, most rested first.
function Characters.list(store, now, currentKey)
  local list = {}
  for key, c in pairs(store) do
    if key ~= currentKey and not c.maxLevel and c.xpMax and c.xpMax > 0 then
      local rate = INN_RATE * (c.resting and 1 or 0.25)
      local fraction = c.rested / c.xpMax + rate * math.max(0, now - (c.time or now))
      list[#list + 1] = {
        name = c.name, class = c.class, level = c.level,
        restedPercent = math.floor(math.min(RESTED_CAP, fraction) * 100 + 0.5),
      }
    end
  end
  table.sort(list, function(a, b)
    if a.restedPercent ~= b.restedPercent then return a.restedPercent > b.restedPercent end
    return a.name < b.name
  end)
  return list
end
