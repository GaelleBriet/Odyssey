local ADDON, ns = ...

local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"

local Styles = { list = { "flat", "gradient", "glossy" } }
ns.Styles = Styles

Styles.defs = {
  flat     = { texture = MEDIA .. "flat.tga",     border = 1, spark = false },
  gradient = { texture = MEDIA .. "gradient.tga", border = 1, spark = true },
  glossy   = { texture = MEDIA .. "glossy.tga",   border = 2, spark = true },
}
Styles.SPARK = MEDIA .. "spark.tga"
Styles.TIPBAR = MEDIA .. "tipbar.tga"

local Themes = { list = { "classic", "class", "faction", "minimal" } }
ns.Themes = Themes

Themes.defs = {
  classic = {
    fill = { 0.58, 0.30, 0.85 }, rested = { 0.20, 0.45, 0.90 }, quest = { 1.00, 0.82, 0.20 },
    bg = { 0.05, 0.05, 0.07 }, border = { 0, 0, 0 },
  },
  class = {
    fill = { 0.58, 0.30, 0.85 }, rested = { 0.20, 0.45, 0.90 }, quest = { 1.00, 0.82, 0.20 },
    bg = { 0.05, 0.05, 0.07 }, border = { 0, 0, 0 },
  },
  faction = {
    fill = { 0.58, 0.30, 0.85 }, rested = { 0.20, 0.45, 0.90 }, quest = { 1.00, 0.82, 0.20 },
    bg = { 0.05, 0.05, 0.07 }, border = { 0, 0, 0 },
  },
  minimal = {
    fill = { 0.85, 0.85, 0.88 }, rested = { 0.45, 0.60, 0.80 }, quest = { 0.80, 0.70, 0.40 },
    bg = { 0.10, 0.10, 0.10 }, border = { 0.20, 0.20, 0.20 },
  },
}

local FACTION_FILL = {
  Horde = { 0.75, 0.15, 0.15 },
  Alliance = { 0.15, 0.35, 0.80 },
}

local function copyColors(def)
  local out = {}
  for part, c in pairs(def) do out[part] = { c[1], c[2], c[3] } end
  return out
end

function Themes.colors(key, ctx)
  ctx = ctx or {}
  local colors = copyColors(Themes.defs[key] or Themes.defs.classic)
  if key == "class" and ctx.classColor then
    colors.fill = { ctx.classColor[1], ctx.classColor[2], ctx.classColor[3] }
  elseif key == "faction" and FACTION_FILL[ctx.faction] then
    local f = FACTION_FILL[ctx.faction]
    colors.fill = { f[1], f[2], f[3] }
  end
  return colors
end
