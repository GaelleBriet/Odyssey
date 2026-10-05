local ns = newNamespace()
loadAddonFile("Styles.lua", ns)
local Styles, Themes = ns.Styles, ns.Themes

test("every listed style has a definition", function()
  for _, key in ipairs(Styles.list) do
    local def = Styles.defs[key]
    truthy(def, key)
    truthy(def.texture:find("%.tga$"))
    truthy(def.border >= 1)
  end
end)

test("every listed theme has a complete definition", function()
  for _, key in ipairs(Themes.list) do
    local def = Themes.defs[key]
    truthy(def, key)
    for _, part in ipairs({ "fill", "rested", "quest", "bg", "border" }) do
      eq(#def[part], 3)
    end
  end
end)

test("class theme uses the class colour when known", function()
  eq(Themes.colors("class", { classColor = { 1, 0.5, 0 } }).fill, { 1, 0.5, 0 })
  eq(Themes.colors("class", {}).fill, Themes.defs.class.fill)
end)

test("faction theme depends on the faction", function()
  local horde = Themes.colors("faction", { faction = "Horde" }).fill
  local alliance = Themes.colors("faction", { faction = "Alliance" }).fill
  truthy(horde[1] > horde[3])
  truthy(alliance[3] > alliance[1])
end)

test("an unknown theme falls back to classic and does not alias the definition", function()
  local c = Themes.colors("bogus", {})
  eq(c.fill, Themes.defs.classic.fill)
  c.fill[1] = 0
  truthy(Themes.defs.classic.fill[1] ~= 0)
end)
