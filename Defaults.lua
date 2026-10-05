local ADDON, ns = ...

local Defaults = {}
ns.Defaults = Defaults

function Defaults.copy(v)
  if type(v) ~= "table" then return v end
  local out = {}
  for k, x in pairs(v) do out[k] = Defaults.copy(x) end
  return out
end

-- Fills `target` with the keys it lacks and replaces values whose type differs from the
-- default; never overwrites a value of the right type.
function Defaults.merge(target, defaults)
  for k, v in pairs(defaults) do
    if type(target[k]) ~= type(v) then
      target[k] = Defaults.copy(v)
    elseif type(v) == "table" then
      Defaults.merge(target[k], v)
    end
  end
  return target
end

function Defaults.get(t, path)
  local cur = t
  for part in path:gmatch("[^.]+") do
    if type(cur) ~= "table" then return nil end
    cur = cur[part]
  end
  return cur
end

function Defaults.set(t, path, value)
  local parts = {}
  for part in path:gmatch("[^.]+") do parts[#parts + 1] = part end
  local cur = t
  for i = 1, #parts - 1 do
    if type(cur[parts[i]]) ~= "table" then cur[parts[i]] = {} end
    cur = cur[parts[i]]
  end
  cur[parts[#parts]] = value
end

Defaults.settings = {
  locked = true,
  point = { "BOTTOM", "UIParent", "BOTTOM", 0, 120 },
  width = 480,
  height = 16,
  scale = 1,
  style = "glossy",
  theme = "classic",
  textLeft = "level",
  textCenter = "current_max_percent",
  textRight = "rested",
  maxLevelBehavior = "hide", -- "hide" or "show"
  hideNativeBar = true,
  abbreviate = false,
  questListMax = 5,
  tooltip = {
    level = true,
    rested = true,
    quests = true,
    kills = true,
    session = true,
    played = true,
    history = true,
  },
}

Defaults.root = {
  version = 1,
  perCharacter = false,
  account = Defaults.settings,
  chars = {},
}
