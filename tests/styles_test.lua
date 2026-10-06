local ns = newNamespace()
loadAddonFile("Styles.lua", ns)
local Styles, Palettes = ns.Styles, ns.Palettes

local function isColor(c) return type(c) == "table" and #c == 3 end

test("the four styles are defined", function()
  eq(Styles.list, { "smooth", "segmented", "neon", "thin" })
  for _, key in ipairs(Styles.list) do
    local def = Styles.defs[key]
    truthy(def, key)
    truthy(def.texture:find("%.tga$"), key)
    eq(type(def.border), "number")
    eq(type(def.height), "number")
    truthy(def.textPosition == "inside" or def.textPosition == "above", key)
    for _, flag in ipairs({ "gloss", "ticks", "glow", "spark", "rounded", "shadow" }) do
      eq(type(def[flag]), "boolean")
    end
  end
end)

test("style traits match the validated mockups", function()
  eq(Styles.defs.segmented.ticks, true)
  eq(Styles.defs.neon.glow, true)
  eq(Styles.defs.smooth.rounded, true)
  eq(Styles.defs.smooth.gloss, true)
  eq(Styles.defs.smooth.shadow, true)
  eq(Styles.defs.thin.textPosition, "above")
  eq(Styles.defs.thin.height, 4)
  eq(Styles.defs.thin.spark, false)
end)

test("the eleven palettes are complete", function()
  eq(#Palettes.list, 11)
  for _, key in ipairs(Palettes.list) do
    local def = Palettes.defs[key]
    truthy(def, key)
    truthy(isColor(def.fill.from) and isColor(def.fill.to), key .. " fill")
    for _, part in ipairs({ "rested", "quest", "bg", "border", "accent", "text" }) do
      truthy(isColor(def[part]), key .. " " .. part)
    end
  end
end)

test("class palette follows the class colour", function()
  local c = Palettes.colors("class", { classColor = { 1, 0.5, 0 } })
  eq(c.fill.to, { 1, 0.5, 0 })
  eq(c.fill.from, { 0.75, 0.375, 0 })
  eq(c.accent, { 1, 0.5, 0 })
  eq(Palettes.colors("class", {}).fill.to, Palettes.defs.class.fill.to)
end)

test("faction palette depends on the faction", function()
  local horde = Palettes.colors("faction", { faction = "Horde" }).fill.to
  local alliance = Palettes.colors("faction", { faction = "Alliance" }).fill.to
  truthy(horde[1] > horde[3])
  truthy(alliance[3] > alliance[1])
end)

test("an unknown palette falls back to arcane without aliasing", function()
  local c = Palettes.colors("bogus", {})
  eq(c.fill.to, Palettes.defs.arcane.fill.to)
  c.fill.to[1] = 0
  c.accent[1] = 0
  truthy(Palettes.defs.arcane.fill.to[1] ~= 0)
  truthy(Palettes.defs.arcane.accent[1] ~= 0)
end)
