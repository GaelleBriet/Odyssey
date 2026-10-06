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
  -- bar look (the presets in Styles.PRESETS fill these fields at once)
  texture = "smooth",
  corners = "rounded", -- "square" or "rounded"
  border = "thin", -- "none", "thin" or "thick"
  borderColor = "palette", -- "palette", "black" or "gold"
  bgOpacity = 0.9,
  gloss = true,
  shadow = true,
  glow = false,
  spark = true,
  ticks = 0, -- 0, 10 (every 10 %) or 20 (every 5 %)
  textPosition = "inside", -- "inside", "above" or "below"
  visibility = "always", -- "always" or "mouseover"
  fadedAlpha = 0, -- bar opacity while not hovered, in "mouseover" mode
  palette = "arcane",
  colors = {}, -- per-element overrides: fill, rested, quest, bg, border, text = {r, g, b}
  barFont = "Friz Quadrata",
  barFontSize = 11,
  barFontOutline = "OUTLINE", -- "NONE", "OUTLINE" or "THICKOUTLINE"
  tooltipFont = "Friz Quadrata",
  tooltipFontSize = 12,
  tooltipFontOutline = "NONE",
  tooltipBgOpacity = 0.93,
  tooltipScale = 1,
  tooltipAnchor = "bar", -- "bar" or "cursor"
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
  version = 3,
  perCharacter = false,
  account = Defaults.settings,
  chars = {},
}

-- ------------------------------------------------------------- migrations

local V1_STYLES = { flat = "smooth", gradient = "smooth", glossy = "smooth" }
local V1_THEMES = { classic = "arcane", class = "class", faction = "faction", minimal = "monochrome" }

local function migrateV1(s)
  if V1_STYLES[s.style] then s.style = V1_STYLES[s.style] end
  if s.theme ~= nil then
    s.palette = V1_THEMES[s.theme] or s.palette
    s.theme = nil
  end
end

-- v3 splits the v2 "style" into independent fields: the matching preset fills them,
-- the user's height is kept.
local function migrateV2(s)
  local height = s.height
  local Styles = ns.Styles
  if Styles then
    Styles.applyPreset(s, Styles.PRESETS[s.style] and s.style or "smooth")
  end
  if height ~= nil then s.height = height end
  s.style = nil
end

local function eachSettings(db, fn)
  if type(db.account) == "table" then fn(db.account) end
  if type(db.chars) == "table" then
    for _, data in pairs(db.chars) do
      if type(data) == "table" and type(data.settings) == "table" then fn(data.settings) end
    end
  end
end

-- Upgrades a saved OdysseyDB in place. Run before `merge`, which fills the new keys.
function Defaults.migrate(db)
  if type(db.version) ~= "number" or db.version >= 3 then return db end
  if db.version < 2 then eachSettings(db, migrateV1) end
  eachSettings(db, migrateV2)
  db.version = 3
  return db
end
