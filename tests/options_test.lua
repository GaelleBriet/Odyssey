local ns = newNamespace()
ns.L = setmetatable({}, { __index = function(_, k) return k end })
loadAddonFile("Calc.lua", ns)
loadAddonFile("Defaults.lua", ns)
loadAddonFile("History.lua", ns)
loadAddonFile("Texts.lua", ns)
loadAddonFile("Styles.lua", ns)
loadAddonFile("Fonts.lua", ns)
loadAddonFile("Profiles.lua", ns)
loadAddonFile("Options.lua", ns)
local Options, Defaults = ns.Options, ns.Defaults

local function control(key)
  for _, c in ipairs(Options.CONTROLS) do if c.key == key then return c end end
end

local function section(key)
  for _, s in ipairs(Options.SECTIONS) do if s.key == key then return s end end
end

local KINDS = { check = true, menu = true, color = true, slider = true, action = true, info = true, input = true }

-- ------------------------------------------------------------- layout model

test("six sections in the sidebar", function()
  local keys = {}
  for _, s in ipairs(Options.SECTIONS) do keys[#keys + 1] = s.key end
  eq(keys, { "bar", "colors", "texts", "tooltip", "general", "profiles" })
end)

test("bar, colours and texts show the bar preview; tooltip shows the tooltip preview", function()
  eq(section("bar").preview, "bar")
  eq(section("colors").preview, "bar")
  eq(section("texts").preview, "bar")
  eq(section("tooltip").preview, "tooltip")
  eq(section("general").preview, nil)
end)

test("every control sits in an existing card of an existing section", function()
  for _, c in ipairs(Options.CONTROLS) do
    truthy(KINDS[c.kind], c.key .. " kind")
    local s = section(c.section)
    truthy(s, c.key .. " section")
    local found = false
    for _, card in ipairs(s.cards) do if card.key == c.card then found = true end end
    truthy(found, c.key .. " card")
    eq(type(c.label), "string")
    if c.kind == "menu" then truthy(c.values or c.valuesFor or c.source, c.key .. " choices") end
  end
end)

test("every card has at least one control and keys are unique", function()
  local seen, count = {}, {}
  for _, c in ipairs(Options.CONTROLS) do
    truthy(not seen[c.key], "duplicate " .. c.key)
    seen[c.key] = true
    local id = c.section .. "/" .. c.card
    count[id] = (count[id] or 0) + 1
  end
  for _, s in ipairs(Options.SECTIONS) do
    for _, card in ipairs(s.cards) do truthy(count[s.key .. "/" .. card.key], s.key .. "/" .. card.key) end
  end
end)

test("cards follow the validated layout", function()
  local function cardOf(key) return control(key).section .. "/" .. control(key).card end
  eq(cardOf("preset"), "bar/appearance")
  eq(cardOf("showQuestSegment"), "bar/effects")
  eq(cardOf("barAlpha"), "bar/size")
  eq(cardOf("fadedAlpha"), "bar/visibility")
  eq(cardOf("colors.fill"), "colors/custom")
  eq(cardOf("textPosition"), "texts/content")
  eq(cardOf("tooltipAnchor"), "tooltip/window")
  eq(cardOf("tooltip.history"), "tooltip/blocks")
  eq(cardOf("profile.active"), "profiles/active")
  eq(cardOf("profile.delete"), "profiles/manage")
  eq(cardOf("action.clearHistory"), "general/data")
end)

test("every customization has exactly one control", function()
  for _, key in ipairs({
    "preset", "texture", "corners", "border", "ticks", "gloss", "shadow", "glow", "spark",
    "showQuestSegment", "showRestedSegment", "width", "height", "scale", "bgOpacity", "barAlpha",
    "visibility", "fadedAlpha", "palette", "borderColor",
    "colors.fill", "colors.rested", "colors.quest", "colors.bg", "colors.border", "colors.text",
    "textLeft", "textCenter", "textRight", "textPosition", "barFont", "barFontSize", "barFontOutline", "abbreviate",
    "tooltipFont", "tooltipFontSize", "tooltipFontOutline", "tooltipBgOpacity", "tooltipScale", "tooltipAnchor",
    "tooltip.level", "tooltip.rested", "tooltip.quests", "tooltip.kills", "tooltip.session", "tooltip.played", "tooltip.history",
    "locked", "hideNativeBar", "maxLevelBehavior",
    "profile.active", "profile.new", "profile.fromDefaults", "profile.copyFrom", "profile.rename",
    "action.resetProfile", "profile.delete",
    "action.resetColors", "action.resetSession", "action.clearHistory", "info.version",
  }) do
    truthy(control(key), key)
  end
end)

test("action controls name their action", function()
  eq(control("action.resetColors").action, "resetColors")
  eq(control("action.resetSession").action, "resetSession")
  eq(control("action.clearHistory").action, "clearHistory")
end)

-- ---------------------------------------------------------------- menus

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
  eq(Options.choices(control("visibility"))[2], { value = "mouseover", text = "visibility.mouseover" })
end)

test("current value of a menu is displayed by name", function()
  local s = Defaults.copy(Defaults.settings)
  eq(Options.displayValue(control("texture"), s.texture), "texture.smooth")
  eq(Options.displayValue(control("preset"), nil), "Choose…")
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

-- -------------------------------------------------------------- sliders

test("continuous values are sliders with a range and a step", function()
  for _, key in ipairs({ "bgOpacity", "barAlpha", "tooltipBgOpacity", "width", "height", "scale", "tooltipScale", "fadedAlpha" }) do
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

test("the hidden opacity is only active in mouseover mode", function()
  local c = control("fadedAlpha")
  eq(Options.isEnabled({ visibility = "always" }, c), false)
  eq(Options.isEnabled({ visibility = "mouseover" }, c), true)
  eq(Options.isEnabled({ visibility = "always" }, control("width")), true)
end)

-- --------------------------------------------------------------- colours

test("reset colours clears every override", function()
  local s = { colors = { fill = { 1, 0, 0 }, bg = { 0, 0, 0 } } }
  Options.resetColors(s)
  eq(s.colors, {})
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

-- ------------------------------------------------------------ reputation

local function keysFor(bar)
  local keys = {}
  for _, c in ipairs(Options.controlsFor(bar)) do keys[c.key] = true end
  return keys
end

test("XP-only and reputation-only controls", function()
  local xp, rep = keysFor("xp"), keysFor("rep")
  for _, key in ipairs({ "showQuestSegment", "showRestedSegment", "hideNativeBar", "maxLevelBehavior", "tooltip.level", "tooltip.history" }) do
    truthy(xp[key], "xp " .. key)
    truthy(not rep[key], "rep " .. key)
  end
  for _, key in ipairs({ "enabled", "linkStyle", "colorMode", "noFaction", "tooltip.progress", "tooltip.repSession" }) do
    truthy(rep[key], "rep " .. key)
    truthy(not xp[key], "xp " .. key)
  end
  for _, key in ipairs({ "texture", "palette", "width", "visibility", "textLeft", "barFont", "locked" }) do
    truthy(xp[key] and rep[key], "both " .. key)
  end
end)

test("every card has controls for each bar", function()
  for _, bar in ipairs({ "xp", "rep" }) do
    local count = {}
    for _, c in ipairs(Options.controlsFor(bar)) do count[c.section .. "/" .. c.card] = true end
    for _, s in ipairs(Options.SECTIONS) do
      for _, card in ipairs(s.cards) do truthy(count[s.key .. "/" .. card.key], bar .. " " .. s.key .. "/" .. card.key) end
    end
  end
end)

test("text menus offer the keys of the bar being edited", function()
  local c = control("textLeft")
  eq(Options.choices(c, "xp")[2].value, "level")
  eq(Options.choices(c, "rep")[2].value, "faction")
  eq(#Options.choices(c, "rep"), 9)
end)

test("the reputation look is greyed while it follows the XP bar", function()
  eq(Options.isEnabled({ linkStyle = true }, control("texture"), "rep"), false)
  eq(Options.isEnabled({ linkStyle = false }, control("texture"), "rep"), true)
  eq(Options.isEnabled({ linkStyle = true }, control("texture"), "xp"), true)
  eq(Options.isEnabled({ linkStyle = true }, control("width"), "rep"), true)
  eq(Options.isEnabled({ linkStyle = true }, control("linkStyle"), "rep"), true)
end)

test("unticking 'same style' copies the XP look first", function()
  local xp = Defaults.copy(Defaults.settings)
  xp.texture = "flat"
  local view = Defaults.repView(xp)
  Options.setCheck(view, control("linkStyle"), false, xp)
  eq(xp.rep.linkStyle, false)
  eq(xp.rep.texture, "flat")
  Options.setCheck(view, control("linkStyle"), true, xp)
  eq(xp.rep.linkStyle, true)
  Options.setCheck(view, control("enabled"), false, xp)
  eq(xp.rep.enabled, false)
end)

test("the reputation colours stay editable while its style follows the XP bar", function()
  for _, key in ipairs({ "palette", "borderColor", "colorMode", "colors.fill", "action.resetColors" }) do
    eq(Options.isEnabled({ linkStyle = true }, control(key), "rep"), true)
  end
end)

-- -------------------------------------------------------------- profiles

local function withProfiles(fn)
  local savedDb, savedKey = _G.OdysseyDB, ns.CharKey
  _G.OdysseyDB = { profiles = { ["Défaut"] = Defaults.copy(Defaults.settings), Raid = Defaults.copy(Defaults.settings) },
    profileKeys = {}, defaultProfile = "Défaut" }
  ns.CharKey = function() return "Realm-A" end
  local ok, err = pcall(fn, _G.OdysseyDB)
  _G.OdysseyDB, ns.CharKey = savedDb, savedKey
  if not ok then error(err, 0) end
end

test("the per-character checkbox is gone", function()
  eq(control("perCharacter"), nil)
end)

test("profile menus list every profile, or the others", function()
  withProfiles(function()
    eq(Options.choices(control("profile.active")), { { value = "Défaut", text = "Défaut" }, { value = "Raid", text = "Raid" } })
    eq(Options.choices(control("profile.delete")), { { value = "Raid", text = "Raid" } })
    eq(Options.choices(control("profile.copyFrom")), { { value = "Raid", text = "Raid" } })
  end)
end)

test("the active profile menu shows the profile in use; pick menus show Choose", function()
  withProfiles(function()
    eq(Options.displayValue(control("profile.active"), Options.currentValue(nil, control("profile.active"))), "Défaut")
    eq(Options.displayValue(control("profile.delete"), nil), "Choose…")
  end)
end)

test("profile actions: use, create, copy, rename, reset, delete", function()
  withProfiles(function(db)
    eq(Options.profileAction("use", "Raid"), true)
    eq(db.profileKeys["Realm-A"], "Raid")
    eq(Options.profileAction("create", "Neuf", { fromDefaults = true }), true)
    eq(db.profiles.Neuf.width, Defaults.settings.width)
    db.profiles.Raid.width = 777
    eq(Options.profileAction("create", "Clone"), true)
    eq(db.profiles.Clone.width, 777) -- from the active profile
    eq(Options.profileAction("copyFrom", "Neuf"), true)
    eq(db.profiles.Raid.width, Defaults.settings.width)
    eq(Options.profileAction("rename", "Raid 2"), true)
    eq(db.profileKeys["Realm-A"], "Raid 2")
    db.profiles["Raid 2"].width = 5
    eq(Options.profileAction("reset"), true)
    eq(db.profiles["Raid 2"].width, Defaults.settings.width)
    eq(Options.profileAction("delete", "Clone"), true)
    eq(db.profiles.Clone, nil)
    eq({ Options.profileAction("delete", "Raid 2") }, { false, "active" })
    eq({ Options.profileAction("create", "Neuf") }, { false, "exists" })
  end)
end)

test("showing a font or texture value does not rebuild the whole list", function()
  local fontList, textureList = ns.Fonts.list, ns.Styles.textureList
  ns.Fonts.list = function() error("font list rebuilt") end
  ns.Styles.textureList = function() error("texture list rebuilt") end
  local ok, err = pcall(function()
    eq(Options.displayValue(control("barFont"), "Cinzel"), "Cinzel")
    eq(Options.displayValue(control("texture"), "gradient"), "texture.gradient")
    eq(Options.displayValue(control("texture"), "Minimalist"), "Minimalist")
  end)
  ns.Fonts.list, ns.Styles.textureList = fontList, textureList
  if not ok then error(err, 0) end
end)
