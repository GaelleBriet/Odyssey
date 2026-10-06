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
  barAlpha = 1, -- opacity of the whole bar
  showQuestSegment = true, -- gold segment: XP of the quests ready to turn in
  showRestedSegment = true, -- blue segment: rested XP
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

-- The reputation bar has a full set of its own settings, nested as settings.rep, starting
-- from the XP bar's defaults.
Defaults.repSettings = Defaults.copy(Defaults.settings)
do
  local rep = Defaults.repSettings
  rep.point = { "TOP", "OdysseyBar", "BOTTOM", 0, -8 }
  rep.textLeft = "faction"
  rep.textCenter = "rep_current_max_percent"
  rep.textRight = "standing"
  rep.tooltip = { progress = true, session = true }
  rep.enabled = true
  rep.linkStyle = true -- the look follows the XP bar
  rep.colorMode = "standing" -- "standing" (the game's standing colours) or "palette"
  rep.noFaction = "hide" -- "hide" or "text"
end
Defaults.settings.rep = Defaults.repSettings

-- Look settings the reputation bar takes from the XP bar while "same style" is on: shape,
-- effects and fonts. Colours (palette, border colour, custom colours) always stay its own,
-- since colour is what tells the two bars apart.
Defaults.LINKED_KEYS = {
  "texture", "corners", "border", "bgOpacity", "gloss", "shadow", "glow", "spark", "ticks",
  "barFont", "barFontSize", "barFontOutline",
  "tooltipFont", "tooltipFontSize", "tooltipFontOutline", "tooltipBgOpacity", "tooltipScale",
}
local LINKED = {}
for _, key in ipairs(Defaults.LINKED_KEYS) do LINKED[key] = true end

-- The reputation bar's settings as the bar and the settings window see them: its own values,
-- except the look keys, read from the XP bar while linkStyle is on. Writes go to settings.rep.
-- One view per settings table, reused: the bar asks for its settings every frame.
local views = setmetatable({}, { __mode = "k" })

function Defaults.repView(xp)
  local view = views[xp]
  if view then return view end
  view = setmetatable({}, {
    __index = function(_, key)
      local rep = xp.rep
      if rep.linkStyle and LINKED[key] then return xp[key] end
      return rep[key]
    end,
    __newindex = function(_, key, value) xp.rep[key] = value end,
  })
  views[xp] = view
  return view
end

-- Turning "same style" off starts the reputation bar from the XP bar's current look.
function Defaults.unlinkRep(xp)
  for _, key in ipairs(Defaults.LINKED_KEYS) do xp.rep[key] = Defaults.copy(xp[key]) end
  xp.rep.linkStyle = false
end

Defaults.root = {
  version = 4,
  profiles = {}, -- [name] = settings (Profiles.lua)
  profileKeys = {}, -- [character] = profile name
  window = { "CENTER", "CENTER", 0, 0 }, -- settings window position (point, relative point, x, y)
  chars = {}, -- per character data: leveling history
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

-- v4: settings live in named profiles. The account settings become the default profile;
-- characters that used their own settings ("per character" on) get a profile of their own.
local function migrateV3(db, defaultName)
  db.profiles = type(db.profiles) == "table" and db.profiles or {}
  db.profileKeys = type(db.profileKeys) == "table" and db.profileKeys or {}
  if type(db.account) == "table" then
    db.profiles[defaultName] = db.account
    db.defaultProfile = defaultName
  end
  if type(db.chars) == "table" then
    for key, data in pairs(db.chars) do
      if type(data) == "table" then
        if db.perCharacter and type(data.settings) == "table" then
          db.profiles[key] = data.settings
          db.profileKeys[key] = key
        end
        data.settings = nil
      end
    end
  end
  db.account, db.perCharacter = nil, nil
end

-- Upgrades a saved OdysseyDB in place. Run before `merge`, which fills the new keys.
-- `defaultName` names the profile made from the old account settings.
function Defaults.migrate(db, defaultName)
  if type(db.version) ~= "number" or db.version >= 4 then return db end
  if db.version < 2 then eachSettings(db, migrateV1) end
  if db.version < 3 then eachSettings(db, migrateV2) end
  migrateV3(db, defaultName or "Default")
  db.version = 4
  return db
end
