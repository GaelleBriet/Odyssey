local ns = newNamespace()
loadAddonFile("Styles.lua", ns)
local Styles, Palettes = ns.Styles, ns.Palettes

local function isColor(c) return type(c) == "table" and #c == 3 end

local PRESET_FIELDS = {
  texture = "string", corners = "string", border = "string", textPosition = "string",
  gloss = "boolean", shadow = "boolean", glow = "boolean", spark = "boolean",
  ticks = "number", height = "number",
}

test("the four presets set every bar field", function()
  eq(Styles.PRESET_LIST, { "smooth", "segmented", "neon", "thin" })
  for _, key in ipairs(Styles.PRESET_LIST) do
    local preset = Styles.PRESETS[key]
    truthy(preset, key)
    for field, kind in pairs(PRESET_FIELDS) do eq(type(preset[field]), kind) end
  end
end)

test("presets match the validated mockups", function()
  local P = Styles.PRESETS
  eq(P.smooth.corners, "rounded")
  eq(P.smooth.gloss, true)
  eq(P.smooth.shadow, true)
  eq(P.segmented.ticks, 10)
  eq(P.neon.glow, true)
  eq(P.thin.textPosition, "above")
  eq(P.thin.height, 4)
  eq(P.thin.border, "none")
end)

test("applyPreset writes the preset fields and nothing else", function()
  local s = { width = 640, palette = "gold", corners = "rounded", ticks = 20 }
  Styles.applyPreset(s, "segmented")
  eq(s.width, 640)
  eq(s.palette, "gold")
  eq(s.corners, "square")
  eq(s.ticks, 10)
  eq(s.height, 16)
  Styles.applyPreset(s, "bogus")
  eq(s.ticks, 10)
end)

local function fakeLSM(textures)
  local lsm = { textures = textures }
  function lsm:List(kind) local n = {} for k in pairs(self.textures) do n[#n + 1] = k end table.sort(n) return n end
  function lsm:Fetch(kind, name) return self.textures[name] end
  return lsm
end

test("texture list: Odyssey textures first, then LibSharedMedia without duplicates", function()
  local list = Styles.textureList(fakeLSM({ ["Minimalist"] = "Interface\\X\\min", ["flat"] = "dup" }))
  local names = {}
  for _, t in ipairs(list) do names[#names + 1] = t.value end
  eq(names, { "flat", "gradient", "glossy", "smooth", "Minimalist" })
  eq(list[1].source, "odyssey")
  eq(list[5].source, "shared")
  eq(#Styles.textureList(nil), 4)
end)

test("resolveTexture: own, shared, and unknown falls back to smooth", function()
  local lsm = fakeLSM({ ["Minimalist"] = "Interface\\X\\min" })
  truthy(Styles.resolveTexture("glossy", nil):find("glossy%.tga$"))
  eq(Styles.resolveTexture("Minimalist", lsm), "Interface\\X\\min")
  truthy(Styles.resolveTexture("Gone", lsm):find("fill%.tga$"))
  truthy(Styles.resolveTexture(nil, nil):find("fill%.tga$"))
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

test("effective colours: palette without overrides", function()
  local c = Palettes.effective("gold", {}, { borderColor = "palette", colors = {} })
  eq(c.fill.to, Palettes.defs.gold.fill.to)
  eq(c.border, Palettes.defs.gold.border)
end)

test("effective colours: per-element overrides", function()
  local c = Palettes.effective("arcane", {}, { borderColor = "palette", colors = {
    fill = { 0.2, 0.4, 0.8 }, rested = { 0, 0, 1 }, bg = { 0.1, 0.1, 0.1 }, text = { 1, 1, 0 },
  } })
  eq(c.fill.to, { 0.2, 0.4, 0.8 })
  near(c.fill.from[2], 0.3)
  eq(c.accent, { 0.2, 0.4, 0.8 })
  eq(c.rested, { 0, 0, 1 })
  eq(c.bg, { 0.1, 0.1, 0.1 })
  eq(c.text, { 1, 1, 0 })
  eq(c.quest, Palettes.defs.arcane.quest)
end)

test("effective colours: border colour choice, then border override", function()
  eq(Palettes.effective("arcane", {}, { borderColor = "black", colors = {} }).border, { 0, 0, 0 })
  eq(Palettes.effective("arcane", {}, { borderColor = "gold", colors = {} }).border, { 0.85, 0.68, 0.28 })
  eq(Palettes.effective("arcane", {}, { borderColor = "gold", colors = { border = { 1, 0, 0 } } }).border, { 1, 0, 0 })
end)

test("effective colours ignore malformed overrides", function()
  local c = Palettes.effective("arcane", {}, { colors = { fill = "red", quest = { 1 } } })
  eq(c.fill.to, Palettes.defs.arcane.fill.to)
  eq(c.quest, Palettes.defs.arcane.quest)
end)

test("rounded masks: the one whose proportions match the bar is chosen", function()
  truthy(Styles.maskFor(480, 18).mask:find("round%-mask%-32%.tga$"))
  truthy(Styles.maskFor(480, 32).mask:find("round%-mask%-16%.tga$"))
  truthy(Styles.maskFor(1000, 16).mask:find("round%-mask%-64%.tga$"))
  truthy(Styles.maskFor(200, 24).mask:find("round%-mask%-8%.tga$"))
  truthy(Styles.maskFor(480, 18).ring.thin:find("round%-ring%-thin%-32%.tga$"))
  truthy(Styles.maskFor(480, 18).ring.thick:find("round%-ring%-thick%-32%.tga$"))
  truthy(Styles.maskFor(480, 0).mask) -- never divides by zero
end)
