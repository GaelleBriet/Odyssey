local ns = newNamespace()
ns.L = setmetatable({}, { __index = function(_, k) return k end })
loadAddonFile("Calc.lua", ns)
loadAddonFile("Defaults.lua", ns)
loadAddonFile("History.lua", ns)
loadAddonFile("Texts.lua", ns)
loadAddonFile("Styles.lua", ns)
loadAddonFile("Fonts.lua", ns)
loadAddonFile("Options.lua", ns)
local Options, Defaults = ns.Options, ns.Defaults

local function control(key)
  for _, c in ipairs(Options.CONTROLS) do if c.key == key then return c end end
end

local function tabKeys()
  local keys = {}
  for _, t in ipairs(Options.TABS) do keys[t.key] = true end
  return keys
end

test("four tabs", function()
  local keys = {}
  for _, t in ipairs(Options.TABS) do keys[#keys + 1] = t.key end
  eq(keys, { "bar", "colors", "texts", "tooltip" })
end)

test("every control belongs to a tab and is a checkbox, a menu or a colour swatch", function()
  local tabs = tabKeys()
  for _, c in ipairs(Options.CONTROLS) do
    truthy(tabs[c.tab], c.key .. " tab")
    truthy(c.kind == "check" or c.kind == "menu" or c.kind == "color" or c.kind == "slider" or c.kind == "header", c.key .. " kind")
    eq(type(c.label), "string")
    if c.kind == "menu" then truthy(c.values or c.source, c.key .. " choices") end
  end
end)

test("every tab fits in two columns", function()
  local count = {}
  for _, c in ipairs(Options.CONTROLS) do count[c.tab] = (count[c.tab] or 0) + 1 end
  for _, t in ipairs(Options.TABS) do
    truthy((count[t.key] or 0) > 0, t.key)
    truthy(count[t.key] <= 2 * Options.ROWS, t.key .. " too long")
  end
end)

test("every customization of the spec has a control", function()
  for _, key in ipairs({
    "preset", "texture", "corners", "border", "borderColor", "bgOpacity", "gloss", "shadow", "glow",
    "spark", "ticks", "textPosition", "visibility", "fadedAlpha", "palette", "barFont", "barFontSize",
    "barFontOutline", "tooltipFont", "tooltipBgOpacity", "tooltipScale", "tooltipAnchor",
    "colors.fill", "colors.rested", "colors.quest", "colors.bg", "colors.border", "colors.text",
  }) do
    truthy(control(key), key)
  end
end)

test("menus list presets, palettes, fonts and textures", function()
  eq(#Options.choices(control("preset")), 4)
  eq(Options.choices(control("preset"))[1], { value = "smooth", text = "style.smooth" })
  eq(#Options.choices(control("palette")), 11)
  local font = Options.choices(control("barFont"))[1]
  eq(font.value, "Friz Quadrata")
  eq(font.font, "Fonts\\FRIZQT__.TTF")
  local texture = Options.choices(control("texture"))[2]
  eq(texture.value, "gradient")
  eq(texture.text, "texture.gradient")
  truthy(texture.texture:find("gradient%.tga$"))
end)

test("value menus show readable names", function()
  eq(Options.choices(control("ticks"))[3], { value = 20, text = "ticks.20" })
  eq(Options.choices(control("corners"))[1], { value = "square", text = "corners.square" })
  eq(Options.choices(control("barFontSize"))[1].text, "8")
end)

test("continuous values are sliders with a range and a step", function()
  for _, key in ipairs({ "bgOpacity", "barAlpha", "tooltipBgOpacity", "width", "height", "scale", "tooltipScale" }) do
    local c = control(key)
    eq(c.kind, "slider")
    truthy(c.min < c.max and c.step > 0, key)
  end
end)

test("slider values snap to the step and stay in range", function()
  local c = control("bgOpacity")
  eq(Options.sliderValue(c, 0.333), 0.35)
  eq(Options.sliderValue(c, -1), 0)
  eq(Options.sliderValue(c, 7), 1)
  eq(Options.sliderValue(control("width"), 487), 490)
  eq(Options.sliderValue(control("height"), 2.4), 2)
end)

test("slider values are displayed in their unit", function()
  eq(Options.displayValue(control("bgOpacity"), 0.35), "35 %")
  eq(Options.displayValue(control("width"), 490), "490")
end)

test("picking a preset writes its fields; other menus write their own key", function()
  local s = Defaults.copy(Defaults.settings)
  Options.applyValue(s, control("preset"), "segmented")
  eq(s.ticks, 10)
  eq(s.corners, "square")
  Options.applyValue(s, control("corners"), "rounded")
  eq(s.corners, "rounded")
  Options.applyValue(s, control("colors.fill"), { 1, 0, 0 })
  eq(s.colors.fill, { 1, 0, 0 })
end)

test("reset colours clears every override", function()
  local s = { colors = { fill = { 1, 0, 0 }, bg = { 0, 0, 0 } } }
  Options.resetColors(s)
  eq(s.colors, {})
end)

test("current value of a menu is displayed by name", function()
  local s = Defaults.copy(Defaults.settings)
  eq(Options.displayValue(control("texture"), s.texture), "texture.smooth")
  eq(Options.displayValue(control("preset"), nil), "Choose…")
end)

test("colour session: opening the wheel at the current colour writes nothing", function()
  local s = { colors = {} }
  local session = Options.colorSession(s, "fill", { 0.73, 0.55, 1 })
  session.change(0.73, 0.55, 1)
  eq(s.colors.fill, nil)
end)

test("colour session: a real change writes the override", function()
  local s = { colors = {} }
  local session = Options.colorSession(s, "rested", { 0.2, 0.4, 0.8 })
  session.change(1, 0, 0)
  eq(s.colors.rested, { 1, 0, 0 })
end)

test("colour session: cancel restores exactly what was there, nil included", function()
  local s = { colors = {} }
  local session = Options.colorSession(s, "fill", { 0.73, 0.55, 1 })
  session.change(1, 0, 0)
  session.cancel()
  eq(s.colors.fill, nil)

  s.colors.bg = { 0.1, 0.1, 0.1 }
  session = Options.colorSession(s, "bg", { 0.1, 0.1, 0.1 })
  session.change(0.5, 0.5, 0.5)
  session.cancel()
  eq(s.colors.bg, { 0.1, 0.1, 0.1 })
end)

test("colour session works when the settings have no colours table yet", function()
  local s = {}
  local session = Options.colorSession(s, "text", { 1, 1, 1 })
  session.change(0, 0, 0)
  eq(s.colors.text, { 0, 0, 0 })
end)

test("visibility is a sub-section: a header, the mode, then the hidden opacity", function()
  local keys = {}
  for _, c in ipairs(Options.CONTROLS) do keys[#keys + 1] = c.key end
  local joined = table.concat(keys, ",")
  truthy(joined:find("header.visibility,visibility,fadedAlpha", 1, true))
  eq(control("header.visibility").kind, "header")
  eq(Options.choices(control("visibility"))[2], { value = "mouseover", text = "visibility.mouseover" })
  eq(control("fadedAlpha").kind, "slider")
end)

test("the hidden opacity is only active in mouseover mode", function()
  local c = control("fadedAlpha")
  eq(Options.isEnabled({ visibility = "always" }, c), false)
  eq(Options.isEnabled({ visibility = "mouseover" }, c), true)
  eq(Options.isEnabled({ visibility = "always" }, control("width")), true)
end)

test("continuous values are sliders with a range and a step", function()
  for _, key in ipairs({ "bgOpacity", "barAlpha", "tooltipBgOpacity", "width", "height", "scale", "tooltipScale" }) do
    local c = control(key)
    eq(c.kind, "slider")
    truthy(c.min < c.max and c.step > 0, key)
  end
end)

test("slider values snap to the step and stay in range", function()
  local c = control("bgOpacity")
  eq(Options.sliderValue(c, 0.333), 0.35)
  eq(Options.sliderValue(c, -1), 0)
  eq(Options.sliderValue(c, 7), 1)
  eq(Options.sliderValue(control("width"), 487), 490)
  eq(Options.sliderValue(control("height"), 2.4), 2)
end)

test("slider values are displayed in their unit", function()
  eq(Options.displayValue(control("bgOpacity"), 0.35), "35 %")
  eq(Options.displayValue(control("width"), 490), "490")
end)

test("picking a preset writes its fields; other menus write their own key", function()
  local s = Defaults.copy(Defaults.settings)
  Options.applyValue(s, control("preset"), "segmented")
  eq(s.ticks, 10)
  eq(s.corners, "square")
  Options.applyValue(s, control("corners"), "rounded")
  eq(s.corners, "rounded")
  Options.applyValue(s, control("colors.fill"), { 1, 0, 0 })
  eq(s.colors.fill, { 1, 0, 0 })
end)

test("reset colours clears every override", function()
  local s = { colors = { fill = { 1, 0, 0 }, bg = { 0, 0, 0 } } }
  Options.resetColors(s)
  eq(s.colors, {})
end)

test("current value of a menu is displayed by name", function()
  local s = Defaults.copy(Defaults.settings)
  eq(Options.displayValue(control("texture"), s.texture), "texture.smooth")
  eq(Options.displayValue(control("preset"), nil), "Choose…")
end)

test("colour session: opening the wheel at the current colour writes nothing", function()
  local s = { colors = {} }
  local session = Options.colorSession(s, "fill", { 0.73, 0.55, 1 })
  session.change(0.73, 0.55, 1)
  eq(s.colors.fill, nil)
end)

test("colour session: a real change writes the override", function()
  local s = { colors = {} }
  local session = Options.colorSession(s, "rested", { 0.2, 0.4, 0.8 })
  session.change(1, 0, 0)
  eq(s.colors.rested, { 1, 0, 0 })
end)

test("colour session: cancel restores exactly what was there, nil included", function()
  local s = { colors = {} }
  local session = Options.colorSession(s, "fill", { 0.73, 0.55, 1 })
  session.change(1, 0, 0)
  session.cancel()
  eq(s.colors.fill, nil)

  s.colors.bg = { 0.1, 0.1, 0.1 }
  session = Options.colorSession(s, "bg", { 0.1, 0.1, 0.1 })
  session.change(0.5, 0.5, 0.5)
  session.cancel()
  eq(s.colors.bg, { 0.1, 0.1, 0.1 })
end)

test("colour session works when the settings have no colours table yet", function()
  local s = {}
  local session = Options.colorSession(s, "text", { 1, 1, 1 })
  session.change(0, 0, 0)
  eq(s.colors.text, { 0, 0, 0 })
end)
