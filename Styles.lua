local ADDON, ns = ...

local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"

-- ------------------------------------------------------------------- styles

local Styles = {}
ns.Styles = Styles

-- Odyssey's own fill textures; LibSharedMedia "statusbar" textures come after them.
local TEXTURES = {
  { value = "flat", path = MEDIA .. "flat.tga" },
  { value = "gradient", path = MEDIA .. "gradient.tga" },
  { value = "glossy", path = MEDIA .. "glossy.tga" },
  { value = "smooth", path = MEDIA .. "fill.tga" },
}
Styles.DEFAULT_TEXTURE = "smooth"

function Styles.textureList(lsm)
  local list, seen = {}, {}
  for _, t in ipairs(TEXTURES) do
    list[#list + 1] = { value = t.value, path = t.path, source = "odyssey" }
    seen[t.value] = true
  end
  if lsm then
    for _, name in ipairs(lsm:List("statusbar")) do
      if not seen[name] then
        list[#list + 1] = { value = name, path = lsm:Fetch("statusbar", name, true), source = "shared" }
        seen[name] = true
      end
    end
  end
  return list
end

local function ownTexture(name)
  for _, t in ipairs(TEXTURES) do if t.value == name then return t.path end end
end

-- File path of a texture name; an unknown one (addon uninstalled) falls back to smooth.
function Styles.resolveTexture(name, lsm)
  local path = name and ownTexture(name)
  if path then return path end
  if name and lsm then
    path = lsm:Fetch("statusbar", name, true)
    if path then return path end
  end
  return ownTexture(Styles.DEFAULT_TEXTURE)
end

-- Presets (the former styles) fill every bar field at once; the user adjusts afterwards.
Styles.PRESET_LIST = { "smooth", "segmented", "neon", "thin" }
Styles.PRESETS = {
  smooth = {
    texture = "smooth", corners = "rounded", border = "thin", textPosition = "inside", height = 18,
    gloss = true, shadow = true, glow = false, spark = true, ticks = 0,
  },
  segmented = {
    texture = "gradient", corners = "square", border = "thin", textPosition = "inside", height = 16,
    gloss = false, shadow = false, glow = false, spark = false, ticks = 10,
  },
  neon = {
    texture = "flat", corners = "rounded", border = "thin", textPosition = "inside", height = 12,
    gloss = false, shadow = false, glow = true, spark = true, ticks = 0,
  },
  thin = {
    texture = "flat", corners = "square", border = "none", textPosition = "above", height = 4,
    gloss = false, shadow = false, glow = false, spark = false, ticks = 0,
  },
}

function Styles.applyPreset(settings, key)
  local preset = Styles.PRESETS[key]
  if not preset then return end
  for field, value in pairs(preset) do settings[field] = value end
end

Styles.BORDER_SIZE = { none = 0, thin = 1, thick = 2 }

Styles.GLOSS = MEDIA .. "gloss.tga"
Styles.GLOW = MEDIA .. "glow.tga"
-- Rounded masks exist in several proportions (width / height = 8, 16, 32, 64); the one
-- closest to the bar's proportions keeps the corners round instead of elliptical.
local MASK_RATIOS = { 8, 16, 32, 64 }
function Styles.maskFor(width, height)
  local aspect = width / math.max(height, 1)
  local best, bestDistance = MASK_RATIOS[1], math.huge
  for _, ratio in ipairs(MASK_RATIOS) do
    local distance = math.abs(math.log(aspect) - math.log(ratio))
    if distance < bestDistance then best, bestDistance = ratio, distance end
  end
  return {
    mask = MEDIA .. "round-mask-" .. best .. ".tga",
    ring = {
      thin = MEDIA .. "round-ring-thin-" .. best .. ".tga",
      thick = MEDIA .. "round-ring-thick-" .. best .. ".tga",
    },
  }
end
Styles.SPARK = MEDIA .. "spark.tga"
Styles.TIPBAR = MEDIA .. "tipbar.tga"

-- ----------------------------------------------------------------- palettes

local Palettes = {
  list = { "arcane", "gold", "emerald", "frost", "ember", "rose", "night", "fel", "monochrome", "class", "faction" },
}
ns.Palettes = Palettes

local TEXT = { 0.96, 0.95, 0.98 }
local BLACK = { 0, 0, 0 }

local function palette(from, to, rested, quest, bg, accent, border)
  return {
    fill = { from = from, to = to },
    rested = rested, quest = quest, bg = bg,
    border = border or BLACK, accent = accent or to, text = TEXT,
  }
end

Palettes.defs = {
  arcane = palette({ 0.42, 0.21, 0.77 }, { 0.73, 0.55, 1.00 }, { 0.24, 0.44, 0.82 }, { 0.85, 0.66, 0.23 }, { 0.08, 0.07, 0.11 }, { 0.61, 0.36, 0.94 }),
  gold = palette({ 0.72, 0.53, 0.17 }, { 0.94, 0.78, 0.37 }, { 0.35, 0.63, 0.88 }, { 1.00, 0.95, 0.69 }, { 0.10, 0.08, 0.04 }),
  emerald = palette({ 0.12, 0.56, 0.35 }, { 0.25, 0.82, 0.54 }, { 0.31, 0.70, 0.85 }, { 0.90, 0.78, 0.35 }, { 0.05, 0.09, 0.07 }),
  frost = palette({ 0.25, 0.56, 0.85 }, { 0.56, 0.83, 1.00 }, { 0.65, 0.78, 1.00 }, { 0.95, 0.90, 0.69 }, { 0.05, 0.08, 0.13 }),
  ember = palette({ 0.72, 0.20, 0.12 }, { 1.00, 0.48, 0.24 }, { 0.30, 0.50, 0.84 }, { 1.00, 0.83, 0.42 }, { 0.10, 0.05, 0.04 }),
  rose = palette({ 0.76, 0.25, 0.49 }, { 1.00, 0.54, 0.75 }, { 0.48, 0.64, 1.00 }, { 1.00, 0.85, 0.54 }, { 0.10, 0.06, 0.09 }),
  night = palette({ 0.17, 0.23, 0.56 }, { 0.35, 0.44, 0.88 }, { 0.37, 0.49, 1.00 }, { 0.91, 0.82, 0.48 }, { 0.03, 0.04, 0.09 }),
  fel = palette({ 0.31, 0.60, 0.07 }, { 0.65, 1.00, 0.24 }, { 0.54, 0.42, 1.00 }, { 0.90, 0.83, 0.35 }, { 0.04, 0.08, 0.02 }),
  monochrome = palette({ 0.75, 0.76, 0.79 }, { 1.00, 1.00, 1.00 }, { 0.60, 0.64, 0.70 }, { 0.85, 0.81, 0.65 }, { 0.07, 0.07, 0.07 }, { 0.85, 0.85, 0.88 }, { 0.25, 0.25, 0.25 }),
  class = palette({ 0.45, 0.45, 0.45 }, { 0.60, 0.60, 0.60 }, { 0.30, 0.50, 0.84 }, { 0.90, 0.76, 0.35 }, { 0.08, 0.08, 0.08 }),
  faction = palette({ 0.42, 0.21, 0.77 }, { 0.73, 0.55, 1.00 }, { 0.30, 0.50, 0.84 }, { 0.90, 0.76, 0.35 }, { 0.08, 0.06, 0.06 }),
}

local FACTION_FILL = {
  Horde = { from = { 0.56, 0.11, 0.11 }, to = { 0.82, 0.23, 0.23 } },
  Alliance = { from = { 0.10, 0.25, 0.60 }, to = { 0.25, 0.50, 0.95 } },
}

local function copy(c) return { c[1], c[2], c[3] } end

local function copyPalette(def)
  return {
    fill = { from = copy(def.fill.from), to = copy(def.fill.to) },
    rested = copy(def.rested), quest = copy(def.quest), bg = copy(def.bg),
    border = copy(def.border), accent = copy(def.accent), text = copy(def.text),
  }
end

-- ctx = { classColor = {r,g,b}|nil, faction = "Horde"|"Alliance"|nil }
function Palettes.colors(key, ctx)
  ctx = ctx or {}
  local colors = copyPalette(Palettes.defs[key] or Palettes.defs.arcane)
  if key == "class" and ctx.classColor then
    local c = ctx.classColor
    colors.fill = { from = { c[1] * 0.75, c[2] * 0.75, c[3] * 0.75 }, to = copy(c) }
    colors.accent = copy(c)
  elseif key == "faction" and FACTION_FILL[ctx.faction] then
    local f = FACTION_FILL[ctx.faction]
    colors.fill = { from = copy(f.from), to = copy(f.to) }
    colors.accent = copy(f.to)
  end
  return colors
end

local BORDER_COLORS = { black = { 0, 0, 0 }, gold = { 0.85, 0.68, 0.28 } }
local OVERRIDABLE = { "rested", "quest", "bg", "border", "text" }

local function isColor(c)
  return type(c) == "table" and type(c[1]) == "number" and type(c[2]) == "number" and type(c[3]) == "number"
end

-- The colours actually drawn: the palette, then the border colour choice, then the user's
-- per-element overrides (settings.colors). A fill override becomes a 75 % -> 100 % gradient.
function Palettes.effective(key, ctx, settings)
  local colors = Palettes.colors(key, ctx)
  local border = BORDER_COLORS[settings.borderColor]
  if border then colors.border = copy(border) end
  local overrides = type(settings.colors) == "table" and settings.colors or {}
  local fill = overrides.fill
  if isColor(fill) then
    colors.fill = { from = { fill[1] * 0.75, fill[2] * 0.75, fill[3] * 0.75 }, to = copy(fill) }
    colors.accent = copy(fill)
  end
  for _, part in ipairs(OVERRIDABLE) do
    if isColor(overrides[part]) then colors[part] = copy(overrides[part]) end
  end
  return colors
end
