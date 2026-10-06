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
  height = 18,
  scale = 1,
  style = "smooth",
  palette = "arcane",
  barFont = "Friz Quadrata",
  barFontSize = 11,
  barFontOutline = "OUTLINE", -- "NONE", "OUTLINE" or "THICKOUTLINE"
  tooltipFont = "Friz Quadrata",
  tooltipFontSize = 12,
  tooltipFontOutline = "NONE",
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
  version = 2,
  perCharacter = false,
  account = Defaults.settings,
  chars = {},
}

-- ------------------------------------------------------------- migrations

local V1_STYLES = { flat = "smooth", gradient = "smooth", glossy = "smooth" }
local V1_THEMES = { classic = "arcane", class = "class", faction = "faction", minimal = "monochrome" }

local function migrateSettings(s)
  if type(s) ~= "table" then return end
  if V1_STYLES[s.style] then s.style = V1_STYLES[s.style] end
  if s.theme ~= nil then
    s.palette = V1_THEMES[s.theme] or s.palette
    s.theme = nil
  end
end

-- Upgrades a saved OdysseyDB in place. Run before `merge`, which fills the new keys.
function Defaults.migrate(db)
  if type(db.version) ~= "number" or db.version >= 2 then return db end
  migrateSettings(db.account)
  if type(db.chars) == "table" then
    for _, data in pairs(db.chars) do
      if type(data) == "table" then migrateSettings(data.settings) end
    end
  end
  db.version = 2
  return db
end
