local ns = newNamespace()
ns.L = setmetatable({}, { __index = function(_, k) return k end })
loadAddonFile("Calc.lua", ns)
loadAddonFile("Defaults.lua", ns)
loadAddonFile("History.lua", ns)
loadAddonFile("Texts.lua", ns)
loadAddonFile("Styles.lua", ns)
loadAddonFile("Fonts.lua", ns)
loadAddonFile("Options.lua", ns)
local Options = ns.Options

local function control(key)
  for _, c in ipairs(Options.CONTROLS) do if c.key == key then return c end end
end

test("every control has a known kind and a label", function()
  for _, c in ipairs(Options.CONTROLS) do
    truthy(c.kind == "bool" or c.kind == "list" or c.kind == "menu", c.key)
    eq(type(c.label), "string")
  end
end)

test("style, palette and fonts use the scrolling menu", function()
  for _, key in ipairs({ "style", "palette", "barFont", "tooltipFont" }) do
    eq(control(key).kind, "menu")
  end
end)

test("style menu lists the four styles with their names", function()
  local items = Options.choices(control("style"))
  eq(#items, 4)
  eq(items[1], { value = "smooth", text = "style.smooth" })
end)

test("palette menu lists the eleven palettes", function()
  local items = Options.choices(control("palette"))
  eq(#items, 11)
  eq(items[11].value, "faction")
  eq(items[11].text, "palette.faction")
end)

test("font menu items carry their font file so each is drawn in its own face", function()
  local items = Options.choices(control("barFont"))
  eq(items[1].value, "Friz Quadrata")
  eq(items[1].font, "Fonts\\FRIZQT__.TTF")
  eq(#items, 8)
end)

test("outline choices are named", function()
  local c = control("barFontOutline")
  eq(c.values, { "NONE", "OUTLINE", "THICKOUTLINE" })
  eq(c.display("THICKOUTLINE"), "outline.THICKOUTLINE")
end)

test("the old theme control is gone", function()
  eq(control("theme"), nil)
end)
