local ADDON, ns = ...

local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"

-- ------------------------------------------------------------------- styles

local Styles = { list = { "smooth", "segmented", "neon", "thin" } }
ns.Styles = Styles

-- height: the height applied when the style is picked in the settings.
-- textPosition: "inside" the bar, or "above" it for the thin line.
Styles.defs = {
  smooth = {
    texture = MEDIA .. "fill.tga", border = 1, height = 18, textPosition = "inside",
    gloss = true, ticks = false, glow = false, spark = true, rounded = true, shadow = true,
  },
  segmented = {
    texture = MEDIA .. "fill.tga", border = 1, height = 16, textPosition = "inside",
    gloss = false, ticks = true, glow = false, spark = false, rounded = false, shadow = false,
  },
  neon = {
    texture = MEDIA .. "fill.tga", border = 1, height = 12, textPosition = "inside",
    gloss = false, ticks = false, glow = true, spark = true, rounded = true, shadow = false,
  },
  thin = {
    texture = MEDIA .. "fill.tga", border = 0, height = 4, textPosition = "above",
    gloss = false, ticks = false, glow = false, spark = false, rounded = false, shadow = false,
  },
}

Styles.GLOSS = MEDIA .. "gloss.tga"
Styles.GLOW = MEDIA .. "glow.tga"
Styles.MASK = MEDIA .. "round-mask.tga"
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
