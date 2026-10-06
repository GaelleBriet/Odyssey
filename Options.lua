local ADDON, ns = ...
local Defaults, History, Texts, Styles, Palettes, Fonts, Profiles =
  ns.Defaults, ns.History, ns.Texts, ns.Styles, ns.Palettes, ns.Fonts, ns.Profiles
local L = ns.L

local Options = {}
ns.Options = Options

-- ======================================================================== model

local function named(prefix) return function(v) return L[prefix .. tostring(v)] end end
local function percent(v) return string.format("%d %%", math.floor(v * 100 + 0.5)) end
local OUTLINES = { "NONE", "OUTLINE", "THICKOUTLINE" }

-- Sidebar sections; `preview` = "bar" or "tooltip" shows a live preview at the top.
Options.SECTIONS = {
  { key = "bar", label = "section.bar", preview = "bar", cards = {
    { key = "appearance", label = "card.appearance" },
    { key = "effects", label = "card.effects" },
    { key = "size", label = "card.size" },
    { key = "visibility", label = "card.visibility" },
  } },
  { key = "colors", label = "section.colors", preview = "bar", cards = {
    { key = "palette", label = "card.palette" },
    { key = "custom", label = "card.custom" },
  } },
  { key = "texts", label = "section.texts", preview = "bar", cards = {
    { key = "content", label = "card.content" },
    { key = "font", label = "card.font" },
  } },
  { key = "tooltip", label = "section.tooltip", preview = "tooltip", cards = {
    { key = "font", label = "card.font" },
    { key = "window", label = "card.window" },
    { key = "blocks", label = "card.blocks" },
  } },
  { key = "general", label = "section.general", cards = {
    { key = "behaviour", label = "card.behaviour" },
    { key = "data", label = "card.data" },
    { key = "about", label = "card.about" },
  } },
  { key = "profiles", label = "section.profiles", cards = {
    { key = "active", label = "card.activeProfile" },
    { key = "manage", label = "card.manageProfiles" },
  } },
}

-- Settings-window state that is not saved (e.g. "start from defaults" for a new profile).
Options.uiState = {}

local function activeProfileName()
  return Profiles.activeName(OdysseyDB, ns.CharKey())
end

-- kind "menu": dropdown from `values` (shown through `display`) or a `source`
--   (presets, palettes, fonts, textures); `preset = true` applies a preset instead of storing;
-- kind "slider": continuous value between `min` and `max`, snapped to `step`;
-- kind "check": on/off; kind "color": swatch opening the colour wheel;
-- kind "action": a button running Options.ACTIONS[action]; kind "info": a read-only line.
-- `account = true` writes to OdysseyDB instead of the active settings.
-- `enabledWhen = { key, value }`: greyed out unless that setting has that value.
local function c(section, card, key, kind, label, extra)
  local control = { section = section, card = card, key = key, kind = kind, label = label }
  for k, v in pairs(extra or {}) do control[k] = v end
  return control
end

Options.CONTROLS = {
  c("bar", "appearance", "linkStyle", "check", "Same style as the XP bar", { bars = { "rep" } }),
  c("bar", "appearance", "preset", "menu", "Preset", { source = "presets", preset = true, look = true }),
  c("bar", "appearance", "texture", "menu", "Texture", { source = "textures", look = true }),
  c("bar", "appearance", "corners", "menu", "Corners", { values = { "square", "rounded" }, display = named("corners."), look = true }),
  c("bar", "appearance", "border", "menu", "Border", { values = { "none", "thin", "thick" }, display = named("border."), look = true }),
  c("bar", "appearance", "ticks", "menu", "Ticks", { values = { 0, 10, 20 }, display = named("ticks."), look = true }),

  c("bar", "effects", "gloss", "check", "Gloss", { look = true }),
  c("bar", "effects", "shadow", "check", "Shadow", { look = true }),
  c("bar", "effects", "glow", "check", "Glow", { look = true }),
  c("bar", "effects", "spark", "check", "Spark", { look = true }),
  c("bar", "effects", "showQuestSegment", "check", "Show quest XP", { bars = { "xp" } }),
  c("bar", "effects", "showRestedSegment", "check", "Show rested XP", { bars = { "xp" } }),

  c("bar", "size", "width", "slider", "Width", { min = 200, max = 1200, step = 10 }),
  c("bar", "size", "height", "slider", "Height", { min = 2, max = 40, step = 1 }),
  c("bar", "size", "scale", "slider", "Scale", { min = 0.5, max = 2, step = 0.05, display = percent }),
  c("bar", "size", "bgOpacity", "slider", "Background opacity", { min = 0, max = 1, step = 0.05, display = percent, look = true }),
  c("bar", "size", "barAlpha", "slider", "Bar opacity", { min = 0.1, max = 1, step = 0.05, display = percent }),
  c("bar", "size", "action.centerX", "action", "Center horizontally", { action = "centerX" }),

  c("bar", "visibility", "noFaction", "menu", "No watched faction", { bars = { "rep" },
    values = { "hide", "text" }, display = named("noFaction.") }),
  c("bar", "visibility", "visibility", "menu", "Mode", { values = { "always", "mouseover" }, display = named("visibility.") }),
  c("bar", "visibility", "fadedAlpha", "slider", "Opacity when hidden", { min = 0, max = 1, step = 0.05, display = percent,
    enabledWhen = { key = "visibility", value = "mouseover" } }),

  c("colors", "palette", "palette", "menu", "Palette", { source = "palettes" }),
  c("colors", "palette", "colorMode", "menu", "Fill color", { bars = { "rep" },
    values = { "standing", "palette" }, display = named("colorMode.") }),
  c("colors", "palette", "borderColor", "menu", "Border color", { values = { "palette", "black", "gold" }, display = named("borderColor.") }),
  c("colors", "custom", "colors.fill", "color", "color.fill", { part = "fill" }),
  c("colors", "custom", "colors.rested", "color", "color.rested", { part = "rested", bars = { "xp" } }),
  c("colors", "custom", "colors.quest", "color", "color.quest", { part = "quest", bars = { "xp" } }),
  c("colors", "custom", "colors.bg", "color", "color.bg", { part = "bg" }),
  c("colors", "custom", "colors.border", "color", "color.border", { part = "border" }),
  c("colors", "custom", "colors.text", "color", "color.text", { part = "text" }),
  c("colors", "custom", "action.resetColors", "action", "Reset to palette colors", { action = "resetColors" }),

  c("texts", "content", "textLeft", "menu", "Left text", { valuesFor = { xp = Texts.KEYS, rep = Texts.REP_KEYS }, display = named("text.") }),
  c("texts", "content", "textCenter", "menu", "Center text", { valuesFor = { xp = Texts.KEYS, rep = Texts.REP_KEYS }, display = named("text.") }),
  c("texts", "content", "textRight", "menu", "Right text", { valuesFor = { xp = Texts.KEYS, rep = Texts.REP_KEYS }, display = named("text.") }),
  c("texts", "content", "textPosition", "menu", "Text position", { values = { "inside", "above", "below" }, display = named("textPosition.") }),
  c("texts", "font", "barFont", "menu", "Font", { source = "fonts", look = true }),
  c("texts", "font", "barFontSize", "menu", "Size", { values = { 8, 9, 10, 11, 12, 13, 14, 16, 18 }, look = true }),
  c("texts", "font", "barFontOutline", "menu", "Outline", { values = OUTLINES, display = named("outline."), look = true }),
  c("texts", "font", "abbreviate", "check", "Abbreviate numbers"),

  c("tooltip", "font", "tooltipFont", "menu", "Font", { source = "fonts", look = true }),
  c("tooltip", "font", "tooltipFontSize", "menu", "Size", { values = { 10, 11, 12, 13, 14, 16 }, look = true }),
  c("tooltip", "font", "tooltipFontOutline", "menu", "Outline", { values = OUTLINES, display = named("outline."), look = true }),
  c("tooltip", "window", "tooltipBgOpacity", "slider", "Background opacity", { min = 0, max = 1, step = 0.05, display = percent, look = true }),
  c("tooltip", "window", "tooltipScale", "slider", "Scale", { min = 0.5, max = 2, step = 0.05, display = percent, look = true }),
  c("tooltip", "window", "tooltipAnchor", "menu", "Position", { values = { "bar", "cursor" }, display = named("tooltipAnchor.") }),
  c("tooltip", "blocks", "tooltip.progress", "check", "opt.tooltip.progress", { bars = { "rep" } }),
  c("tooltip", "blocks", "tooltip.repSession", "check", "opt.tooltip.session", { bars = { "rep" }, settingKey = "tooltip.session" }),
  c("tooltip", "blocks", "tooltip.level", "check", "opt.tooltip.level", { bars = { "xp" } }),
  c("tooltip", "blocks", "tooltip.rested", "check", "opt.tooltip.rested", { bars = { "xp" } }),
  c("tooltip", "blocks", "tooltip.quests", "check", "opt.tooltip.quests", { bars = { "xp" } }),
  c("tooltip", "blocks", "tooltip.kills", "check", "opt.tooltip.kills", { bars = { "xp" } }),
  c("tooltip", "blocks", "tooltip.session", "check", "opt.tooltip.session", { bars = { "xp" } }),
  c("tooltip", "blocks", "tooltip.played", "check", "opt.tooltip.played", { bars = { "xp" } }),
  c("tooltip", "blocks", "tooltip.history", "check", "opt.tooltip.history", { bars = { "xp" } }),

  c("general", "behaviour", "enabled", "check", "Show the reputation bar", { bars = { "rep" } }),
  c("general", "behaviour", "locked", "check", "Lock bar"),
  c("general", "behaviour", "hideNativeBar", "check", "Hide Blizzard XP bar", { bars = { "xp" } }),
  c("general", "behaviour", "maxLevelBehavior", "menu", "At max level", { values = { "hide", "show" }, display = named("max."), bars = { "xp" } }),

  c("general", "data", "action.resetSession", "action", "Reset session", { action = "resetSession" }),
  c("general", "data", "action.clearHistory", "action", "Clear history", { action = "clearHistory" }),
  c("general", "about", "info.version", "info", "Version", { info = "version" }),

  -- `profile` names the Options.profileAction run by the control; `pick` menus have no
  -- current value; `confirm` asks for a second click; `ui` values live in Options.uiState.
  c("profiles", "active", "profile.active", "menu", "Profile", { source = "profiles", profile = "use", get = activeProfileName }),
  c("profiles", "manage", "profile.new", "input", "New profile", { profile = "create" }),
  c("profiles", "manage", "profile.fromDefaults", "check", "Start from defaults", { ui = true }),
  c("profiles", "manage", "profile.copyFrom", "menu", "Copy from", { source = "otherProfiles", profile = "copyFrom", pick = true, confirm = true }),
  c("profiles", "manage", "profile.rename", "input", "Rename", { profile = "rename" }),
  c("profiles", "manage", "action.resetProfile", "action", "Reset profile", { profile = "reset", confirm = true }),
  c("profiles", "manage", "profile.delete", "menu", "Delete profile", { source = "otherProfiles", profile = "delete", pick = true, confirm = true }),
}

-- The controls that apply to one bar ("xp" or "rep").
function Options.controlsFor(bar)
  local list = {}
  for _, control in ipairs(Options.CONTROLS) do
    local applies = control.bars == nil
    for _, b in ipairs(control.bars or {}) do if b == bar then applies = true end end
    if applies then list[#list + 1] = control end
  end
  return list
end

-- The settings key a control reads and writes (usually its own key).
local function settingKey(control) return control.settingKey or control.key end

-- Items of a menu: { value, text } plus `font` or `texture` for a preview.
function Options.choices(control, bar)
  local items = {}
  if control.source == "presets" then
    for _, key in ipairs(Styles.PRESET_LIST) do items[#items + 1] = { value = key, text = L["style." .. key] } end
  elseif control.source == "palettes" then
    for _, key in ipairs(Palettes.list) do items[#items + 1] = { value = key, text = L["palette." .. key] } end
  elseif control.source == "fonts" then
    for _, f in ipairs(Fonts.list(Fonts.lsm())) do items[#items + 1] = { value = f.name, text = f.name, font = f.path } end
  elseif control.source == "profiles" or control.source == "otherProfiles" then
    local active = activeProfileName()
    for _, name in ipairs(Profiles.list(OdysseyDB)) do
      if control.source == "profiles" or name ~= active then items[#items + 1] = { value = name, text = name } end
    end
  elseif control.source == "textures" then
    for _, t in ipairs(Styles.textureList(Fonts.lsm())) do
      local text = t.source == "odyssey" and L["texture." .. t.value] or t.value
      items[#items + 1] = { value = t.value, text = text, texture = t.path }
    end
  else
    local values = control.valuesFor and control.valuesFor[bar or "xp"] or control.values
    for _, v in ipairs(values) do
      items[#items + 1] = { value = v, text = control.display and control.display(v) or tostring(v) }
    end
  end
  return items
end

-- Snaps a raw slider position to the control's step and range.
function Options.sliderValue(control, raw)
  local v = math.max(control.min, math.min(control.max, raw))
  v = control.min + math.floor((v - control.min) / control.step + 0.5) * control.step
  v = math.floor(v * 10000 + 0.5) / 10000 -- drop float noise (0.35000000000000003)
  return math.min(control.max, v)
end

function Options.displayValue(control, value, bar)
  if control.preset or control.pick then return L["Choose…"] end
  if control.kind == "slider" then
    return control.display and control.display(value) or tostring(value)
  end
  for _, item in ipairs(Options.choices(control, bar)) do
    if item.value == value then return item.text end
  end
  return tostring(value)
end

function Options.currentValue(t, control)
  if control.get then return control.get() end
  if control.ui then return Options.uiState[control.key] end
  return Defaults.get(t, settingKey(control))
end

-- Runs a profile operation for the current character. Returns true, or false and a reason
-- ("empty", "exists", "active", "last", "missing").
function Options.profileAction(action, value, opts)
  local db, key = OdysseyDB, ns.CharKey()
  local active = Profiles.activeName(db, key)
  if action == "use" then return Profiles.use(db, key, value) end
  if action == "create" then
    return Profiles.create(db, value, not (opts and opts.fromDefaults) and db.profiles[active] or nil)
  end
  if action == "copyFrom" then return Profiles.copyFrom(db, active, value) end
  if action == "rename" then return Profiles.rename(db, active, value) end
  if action == "reset" then return Profiles.reset(db, active) end
  if action == "delete" then return Profiles.delete(db, value, key) end
  return false, "missing"
end

-- Greyed out: an `enabledWhen` rule not met, or a look setting of the reputation bar while
-- it follows the XP bar's style.
function Options.isEnabled(t, control, bar)
  if bar == "rep" and control.look and t.linkStyle then return false end
  local rule = control.enabledWhen
  return rule == nil or Defaults.get(t, rule.key) == rule.value
end

-- Ticks a checkbox. Unticking "same style" copies the XP bar's look first.
function Options.setCheck(t, control, value, xp)
  if control.ui then
    Options.uiState[control.key] = value
  elseif control.key == "linkStyle" and not value then
    Defaults.unlinkRep(xp)
  else
    Defaults.set(t, settingKey(control), value)
  end
end

-- Writes a picked value; a preset fills every bar field instead.
function Options.applyValue(t, control, value)
  if control.preset then
    Styles.applyPreset(t, value)
  else
    Defaults.set(t, settingKey(control), value)
  end
end

-- One use of the colour wheel on one element. The wheel reports its starting colour as soon
-- as it opens, so a "change" equal to the start writes nothing; cancel puts back exactly the
-- override that existed before (nil included).
function Options.colorSession(settings, part, start)
  if type(settings.colors) ~= "table" then settings.colors = {} end
  local previous = settings.colors[part]
  previous = previous and { previous[1], previous[2], previous[3] } or nil
  local function same(r, g, b)
    return math.abs(r - start[1]) < 0.002 and math.abs(g - start[2]) < 0.002 and math.abs(b - start[3]) < 0.002
  end
  local session = {}
  function session.change(r, g, b)
    if same(r, g, b) and settings.colors[part] == previous then return end
    settings.colors[part] = { r, g, b }
  end
  function session.cancel()
    settings.colors[part] = previous and { previous[1], previous[2], previous[3] } or nil
  end
  return session
end

function Options.resetColors(settings)
  settings.colors = {}
end

Options.ACTIONS = {
  resetColors = function(bar) Options.resetColors(bar == "rep" and ns.Settings().rep or ns.Settings()) end,
  resetSession = function(bar)
    if bar == "rep" then ns.repSource:resetSession() else ns.source:resetSession() end
    print("|cff9966ffOdyssey|r: " .. L["Session reset."])
  end,
  centerX = function(bar) (bar == "rep" and ns.repBar or ns.bar):CenterHorizontally() end,
  clearHistory = function(_)
    History.reset(ns.CharData().history)
    print("|cff9966ffOdyssey|r: " .. L["History cleared."])
  end,
}

local function addonVersion()
  local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  local version = get and get(ADDON, "Version")
  if not version or version:find("@") then return L["development version"] end
  return version
end

-- The settings a control edits: the account root, the XP settings, or the reputation view.
local function target(control, bar)
  if control.account then return OdysseyDB end
  if bar == "rep" then return Defaults.repView(ns.Settings()) end
  return ns.Settings()
end

-- The live bar object of a kind (its colours feed the swatches and the tooltip preview).
local function barObject(bar)
  return bar == "rep" and ns.repBar or ns.bar
end

-- ======================================================================= style

local C = {
  window = { 0.06, 0.05, 0.08, 0.97 },
  sidebar = { 0.045, 0.04, 0.06, 1 },
  card = { 0.105, 0.09, 0.15, 1 },
  cardEdge = { 0.165, 0.14, 0.22, 1 },
  widget = { 0.14, 0.12, 0.2, 1 },
  widgetEdge = { 0.26, 0.22, 0.34, 1 },
  text = { 0.91, 0.89, 0.94 },
  muted = { 0.6, 0.57, 0.68 },
}

local function solid(parent, layer, color, sublevel)
  local tex = parent:CreateTexture(nil, layer, nil, sublevel)
  tex:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
  return tex
end

local function fontString(parent, size, color, template)
  local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
  local path = fs:GetFont()
  if path then fs:SetFont(path, size, "") end
  fs:SetTextColor(color[1], color[2], color[3], 1)
  fs:SetJustifyH("LEFT")
  return fs
end

local function accentColor()
  local s = ns.Settings()
  local colors = (ns.bar and ns.bar.colors) or Palettes.effective(s.palette, {}, s)
  return colors.accent, colors
end

-- Flat button in the window's style; `kind = "menu"` adds a small marker on the right.
local function flatButton(parent, width, height, text, kind)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(width, height)
  local edge = solid(b, "BACKGROUND", C.widgetEdge)
  edge:SetAllPoints()
  local bg = solid(b, "BORDER", C.widget)
  bg:SetPoint("TOPLEFT", 1, -1)
  bg:SetPoint("BOTTOMRIGHT", -1, 1)
  local hl = b:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(1, 1, 1, 0.08)
  b.label = fontString(b, 11, C.text)
  local pad = width < 40 and 0 or 8
  b.label:SetPoint("LEFT", pad, 0)
  b.label:SetPoint("RIGHT", kind == "menu" and -16 or -pad, 0)
  b.label:SetWordWrap(false)
  if kind ~= "menu" then b.label:SetJustifyH("CENTER") end
  if kind == "menu" then
    b.marker = b:CreateTexture(nil, "ARTWORK")
    b.marker:SetSize(5, 5)
    b.marker:SetPoint("RIGHT", -7, 0)
    b.marker:SetColorTexture(0.73, 0.55, 1, 1)
  end
  function b:SetText(t) self.label:SetText(t) end
  b:SetText(text or "")
  return b
end

-- ======================================================================= menu

local MENU_WIDTH, ITEM_HEIGHT, MENU_ROWS = 220, 20, 12
local menu
local menuButtons = {} -- every dropdown button of the window, for one-click switching

local function createMenu()
  local catcher = CreateFrame("Button", nil, UIParent)
  catcher:SetAllPoints(UIParent)
  catcher:SetFrameStrata("FULLSCREEN_DIALOG")
  catcher:RegisterForClicks("AnyUp")
  catcher:Hide()
  menu = CreateFrame("Frame", "OdysseyMenu", UIParent)
  menu.catcher = catcher
  menu:SetFrameStrata("FULLSCREEN_DIALOG")
  menu:SetClampedToScreen(true)
  menu:EnableMouse(true)
  menu:EnableMouseWheel(true)
  menu:Hide()
  menu:SetFrameLevel(catcher:GetFrameLevel() + 10)
  -- A click anywhere outside the menu lands on the catcher and closes it; when the click
  -- lands on another menu button of the window, that menu opens right away.
  catcher:SetScript("OnClick", function()
    menu:Hide()
    for _, button in ipairs(menuButtons) do
      if button:IsVisible() and button:IsMouseOver() then button:Click() break end
    end
  end)
  menu:SetScript("OnShow", function() catcher:Show() end)
  menu:SetScript("OnHide", function() catcher:Hide() end)
  local edge = solid(menu, "BACKGROUND", C.widgetEdge, -1)
  edge:SetPoint("TOPLEFT", -1, 1)
  edge:SetPoint("BOTTOMRIGHT", 1, -1)
  local bg = solid(menu, "BACKGROUND", { 0.05, 0.05, 0.07, 0.98 })
  bg:SetAllPoints()
  menu.rows = {}
  for i = 1, MENU_ROWS do
    local row = CreateFrame("Button", nil, menu)
    row:SetSize(MENU_WIDTH - 8, ITEM_HEIGHT)
    row:SetPoint("TOPLEFT", 4, -4 - (i - 1) * ITEM_HEIGHT)
    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.1)
    row.preview = row:CreateTexture(nil, "BACKGROUND")
    row.preview:SetPoint("TOPLEFT", 4, -2)
    row.preview:SetPoint("BOTTOMRIGHT", -4, 2)
    row.check = row:CreateTexture(nil, "ARTWORK")
    row.check:SetSize(3, ITEM_HEIGHT - 6)
    row.check:SetPoint("LEFT", 0, 0)
    row.check:SetColorTexture(0.73, 0.55, 1, 1)
    row.text = row:CreateFontString(nil, "OVERLAY")
    row.text:SetPoint("LEFT", 8, 0)
    row.text:SetPoint("RIGHT", -4, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetShadowOffset(1, -1)
    menu.rows[i] = row
  end
  menu:SetScript("OnMouseWheel", function(_, delta)
    menu.offset = math.max(0, math.min(#menu.items - MENU_ROWS, menu.offset - delta * 3))
    menu.render()
  end)
  -- Escape closes only the menu (the window stays open for the next Escape).
  menu:EnableKeyboard(true)
  menu:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
      if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(false) end
      self:Hide()
    elseif self.SetPropagateKeyboardInput then
      self:SetPropagateKeyboardInput(true)
    end
  end)
end

local function openMenu(button, control, current, onPick, bar)
  if not menu then createMenu() end
  if menu:IsShown() and menu.owner == button then menu:Hide() return end
  menu.owner = button
  menu.items = Options.choices(control, bar)
  menu.offset = 0
  for i, item in ipairs(menu.items) do
    if item.value == current then menu.offset = math.max(0, math.min(#menu.items - MENU_ROWS, i - 3)) end
  end
  local defaultFont = Fonts.resolve(Fonts.DEFAULT, nil)
  function menu.render()
    for i, row in ipairs(menu.rows) do
      local item = menu.items[i + menu.offset]
      if item then
        Fonts.apply(row.text, item.font or defaultFont, item.font and 13 or 12, "")
        row.text:SetText(item.text)
        if item.texture then
          row.preview:SetTexture(item.texture)
          row.preview:SetVertexColor(0.45, 0.35, 0.7, 1)
          row.preview:Show()
        else
          row.preview:Hide()
        end
        row.check:SetShown(item.value == current)
        row:SetScript("OnClick", function()
          menu:Hide()
          onPick(item.value)
        end)
        row:Show()
      else
        row:Hide()
      end
    end
  end
  menu:SetSize(MENU_WIDTH, math.min(#menu.items, MENU_ROWS) * ITEM_HEIGHT + 8)
  menu:ClearAllPoints()
  menu:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2)
  menu.render()
  menu:Show()
end

-- ================================================================ colour wheel

-- Opens the game's colour picker; modern clients use SetupColorPickerAndShow, older ones
-- the func/cancelFunc fields. `session` (Options.colorSession) records the choice;
-- `onUpdate` redraws after every change or cancel.
local function openColorPicker(color, session, onUpdate)
  local picker = ColorPickerFrame
  if not picker then return end
  local r, g, b = color[1], color[2], color[3]
  local function changed()
    session.change(picker:GetColorRGB())
    onUpdate()
  end
  local function cancelled()
    session.cancel()
    onUpdate()
  end
  if picker.SetupColorPickerAndShow then
    picker:SetupColorPickerAndShow({
      r = r, g = g, b = b, hasOpacity = false,
      swatchFunc = changed, cancelFunc = cancelled,
    })
  else
    picker.hasOpacity = false
    picker.opacityFunc = nil
    picker.extraInfo = nil
    picker.previousValues = { r = r, g = g, b = b }
    picker.func = changed
    picker.cancelFunc = cancelled
    picker:SetColorRGB(r, g, b)
    if ShowUIPanel then ShowUIPanel(picker) else picker:Show() end
  end
end

-- ===================================================================== widgets

local WIDGET_WIDTH = 130

local function makeCheck(parent)
  local box = CreateFrame("Button", nil, parent)
  box:SetSize(18, 18)
  local edge = solid(box, "BACKGROUND", C.widgetEdge)
  edge:SetAllPoints()
  local inner = solid(box, "BORDER", { 0.07, 0.07, 0.1, 1 })
  inner:SetPoint("TOPLEFT", 1, -1)
  inner:SetPoint("BOTTOMRIGHT", -1, 1)
  box.mark = solid(box, "ARTWORK", { 0.73, 0.55, 1, 1 })
  box.mark:SetPoint("TOPLEFT", 4, -4)
  box.mark:SetPoint("BOTTOMRIGHT", -4, 4)
  local hl = box:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(1, 1, 1, 0.12)
  return box
end

-- Drag, click on the track or use the mouse wheel; `onPick(raw)` gets the raw value.
local function makeSlider(parent, control, onPick)
  local slider = CreateFrame("Frame", nil, parent)
  slider:SetSize(WIDGET_WIDTH - 44, 18)
  slider:EnableMouse(true)
  slider:EnableMouseWheel(true)
  local track = solid(slider, "BACKGROUND", { 0.25, 0.23, 0.32, 1 })
  track:SetPoint("LEFT")
  track:SetPoint("RIGHT")
  track:SetHeight(4)
  slider.fill = solid(slider, "BORDER", { 0.73, 0.55, 1, 1 })
  slider.fill:SetPoint("LEFT")
  slider.fill:SetHeight(4)
  slider.thumb = solid(slider, "ARTWORK", { 0.92, 0.9, 0.98, 1 })
  slider.thumb:SetSize(8, 14)
  slider.text = fontString(slider, 11, C.text)
  slider.text:SetPoint("LEFT", slider, "RIGHT", 8, 0)

  function slider:SetValue(value)
    local fraction = (value - control.min) / (control.max - control.min)
    fraction = math.max(0, math.min(1, fraction))
    local width = self:GetWidth()
    self.fill:SetWidth(math.max(1, fraction * width))
    self.thumb:ClearAllPoints()
    self.thumb:SetPoint("CENTER", self, "LEFT", fraction * width, 0)
    self.text:SetText(Options.displayValue(control, value))
    self.value = value
  end

  local function fromCursor()
    local x = GetCursorPosition() / slider:GetEffectiveScale()
    local left, width = slider:GetLeft(), slider:GetWidth()
    if not left or width <= 0 then return end
    onPick(control.min + (x - left) / width * (control.max - control.min))
  end
  slider:SetScript("OnMouseDown", function(self)
    if not self.enabled then return end
    self.dragging = true
    fromCursor()
  end)
  slider:SetScript("OnMouseUp", function(self) self.dragging = false end)
  slider:SetScript("OnHide", function(self) self.dragging = false end)
  slider:SetScript("OnUpdate", function(self)
    if self.dragging then fromCursor() end
  end)
  slider:SetScript("OnMouseWheel", function(self, delta)
    if self.enabled and self.value then onPick(self.value + delta * control.step) end
  end)
  slider.enabled = true
  return slider
end

local function makeSwatch(parent)
  local swatch = CreateFrame("Button", nil, parent)
  swatch:SetSize(40, 18)
  local edge = solid(swatch, "BACKGROUND", C.widgetEdge)
  edge:SetAllPoints()
  swatch.color = swatch:CreateTexture(nil, "ARTWORK")
  swatch.color:SetPoint("TOPLEFT", 1, -1)
  swatch.color:SetPoint("BOTTOMRIGHT", -1, 1)
  local hl = swatch:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(1, 1, 1, 0.15)
  swatch.reset = flatButton(parent, 20, 18, "x")
  swatch.reset:SetPoint("LEFT", swatch, "RIGHT", 6, 0)
  return swatch
end

-- ===================================================================== window

local WINDOW_W, WINDOW_H = 800, 540
local TITLE_H, SIDEBAR_W = 32, 150
local CONTENT_W = WINDOW_W - SIDEBAR_W - 20 -- inside the scroll frame
local CARD_GAP = 12
local CARD_W = (CONTENT_W - CARD_GAP) / 2
local ROW_H = 26
local CARD_HEADER = 28
local PREVIEW_BAR_H = 88
local TOOLTIP_PREVIEW_H = 420

local window, widgets, refresh

local function setGradient(tex, from, to)
  if tex.SetGradient and CreateColor then
    local ok = pcall(tex.SetGradient, tex, "HORIZONTAL",
      CreateColor(from[1], from[2], from[3], 1), CreateColor(to[1], to[2], to[3], 1))
    if ok then return end
  end
  tex:SetVertexColor(to[1], to[2], to[3], 1)
end

local function changed(control)
  if control and control.account then Defaults.merge(ns.Settings(), Defaults.settings) end
  ns.Refresh() -- redraws the bars, then calls Options.Refresh for the window and previews
end

local function say(text) print("|cff9966ffOdyssey|r: " .. text) end

local PROFILE_MESSAGES = {
  use = "Now using profile \"%s\".", create = "Profile \"%s\" created.", copyFrom = "Copied from \"%s\".",
  rename = "Profile renamed to \"%s\".", delete = "Profile \"%s\" deleted.",
}

-- Runs a profile operation, tells the player how it went, and redraws everything.
local function runProfile(action, value)
  local ok, result = Options.profileAction(action, value, { fromDefaults = Options.uiState["profile.fromDefaults"] })
  if ok then
    local name = type(result) == "string" and result or value
    if action == "reset" then say(L["Profile reset."]) else say(L[PROFILE_MESSAGES[action]]:format(name or "")) end
  else
    say(L["profile.err." .. tostring(result)])
  end
  changed({})
  return ok
end

-- Two-click confirmation: the first click arms the button for a few seconds.
local CONFIRM_SECONDS = 4
local function arm(button, text)
  button.armed = true
  button.armedText = button.label:GetText()
  button:SetText(text)
  local token = {}
  button.armToken = token
  local after = C_Timer and C_Timer.After
  if after then
    after(CONFIRM_SECONDS, function()
      if button.armToken == token then
        button.armed, button.pendingValue = false, nil
        button:SetText(button.armedText)
      end
    end)
  end
end
local function disarm(button)
  button.armed, button.pendingValue, button.armToken = false, nil, nil
end

-- Flat text field with an OK button; Enter or OK submits.
local function makeInput(parent, onSubmit)
  local box = CreateFrame("EditBox", nil, parent)
  box:SetSize(WIDGET_WIDTH - 34, 20)
  box:SetAutoFocus(false)
  box:SetMaxLetters(40)
  local edge = solid(box, "BACKGROUND", C.widgetEdge)
  edge:SetAllPoints()
  local bg = solid(box, "BORDER", { 0.07, 0.07, 0.1, 1 })
  bg:SetPoint("TOPLEFT", 1, -1)
  bg:SetPoint("BOTTOMRIGHT", -1, 1)
  local font = fontString(box, 11, C.text)
  box:SetFontObject(font:GetFontObject() or GameFontHighlightSmall)
  font:Hide()
  local path = font:GetFont()
  if path then box:SetFont(path, 11, "") end
  box:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
  box:SetTextInsets(6, 6, 0, 0)
  local ok = flatButton(parent, 30, 20, "OK")
  ok:SetPoint("LEFT", box, "RIGHT", 4, 0)
  local function submit()
    local text = box:GetText()
    box:ClearFocus()
    if onSubmit(text) then box:SetText("") end
  end
  box:SetScript("OnEnterPressed", submit)
  box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  ok:SetScript("OnClick", submit)
  box.ok = ok
  return box
end

-- One row of a card: label on the left, widget on the right.
local function buildRow(card, control, y, bar)
  local label = fontString(card, 12, C.text)
  label:SetPoint("TOPLEFT", 12, y - 4)
  local widgetSpace = (control.kind == "check" and 30) or (control.kind == "color" and 80)
    or (control.kind == "info" and 120) or (WIDGET_WIDTH + 14)
  label:SetWidth(CARD_W - 24 - widgetSpace)
  label:SetWordWrap(false)
  label:SetText(L[control.label])
  local right = CARD_W - 12
  local widget

  if control.kind == "check" then
    widget = makeCheck(card)
    widget:SetPoint("TOPRIGHT", card, "TOPLEFT", right, y - 2)
    widget:SetScript("OnClick", function(self)
      if self.enabled == false then return end
      local t = target(control, bar)
      Options.setCheck(t, control, not Options.currentValue(t, control), ns.Settings())
      changed(control)
    end)
  elseif control.kind == "menu" then
    widget = flatButton(card, WIDGET_WIDTH, 20, "", "menu")
    menuButtons[#menuButtons + 1] = widget
    widget:SetPoint("TOPRIGHT", card, "TOPLEFT", right, y - 1)
    widget:SetScript("OnClick", function(self)
      if self.enabled == false then return end
      if self.armed then
        local value = self.pendingValue
        disarm(self)
        runProfile(control.profile, value)
        return
      end
      openMenu(self, control, Options.currentValue(target(control, bar), control), function(value)
        if control.profile and control.confirm then
          self.pendingValue = value
          arm(self, L["Confirm?"] .. " " .. value)
        elseif control.profile then
          runProfile(control.profile, value)
        else
          Options.applyValue(target(control, bar), control, value)
          changed(control)
        end
      end, bar)
    end)
  elseif control.kind == "slider" then
    widget = makeSlider(card, control, function(raw)
      local t = target(control, bar)
      local value = Options.sliderValue(control, raw)
      if value ~= Defaults.get(t, control.key) then
        Options.applyValue(t, control, value)
        changed(control)
      end
    end)
    widget:SetPoint("TOPLEFT", card, "TOPLEFT", right - WIDGET_WIDTH, y - 2)
  elseif control.kind == "color" then
    widget = makeSwatch(card)
    widget:SetPoint("TOPRIGHT", card, "TOPLEFT", right - 26, y - 2)
    widget:SetScript("OnClick", function(self)
      if self.enabled == false then return end
      local s = bar == "rep" and ns.Settings().rep or ns.Settings()
      local colors = barObject(bar).colors
      local start = control.part == "fill" and colors.fill.to or colors[control.part]
      openColorPicker(start, Options.colorSession(s, control.part, start), function() changed(control) end)
    end)
    widget.reset:SetScript("OnClick", function()
      if widget.enabled == false then return end
      Defaults.set(bar == "rep" and ns.Settings().rep or ns.Settings(), control.key, nil)
      changed(control)
    end)
  elseif control.kind == "action" then
    label:Hide()
    widget = flatButton(card, CARD_W - 24, 22, L[control.label])
    widget:SetPoint("TOPLEFT", 12, y - 1)
    widget:SetScript("OnClick", function(self)
      if self.enabled == false then return end
      if control.confirm and not self.armed then
        arm(self, L["Confirm?"])
        return
      end
      disarm(self)
      self:SetText(L[control.label])
      if control.profile then
        runProfile(control.profile)
      else
        Options.ACTIONS[control.action](bar)
        changed(control)
      end
    end)
  elseif control.kind == "input" then
    widget = makeInput(card, function(text) return runProfile(control.profile, text) end)
    widget:SetPoint("TOPLEFT", card, "TOPLEFT", right - WIDGET_WIDTH, y - 1)
  elseif control.kind == "info" then
    widget = fontString(card, 12, C.muted)
    widget:SetPoint("TOPRIGHT", card, "TOPLEFT", right, y - 4)
    widget:SetText(addonVersion())
  end
  widgets[#widgets + 1] = { control = control, widget = widget, label = label, bar = bar }
end

local function buildCard(parent, section, card, bar)
  local rows = {}
  for _, control in ipairs(Options.controlsFor(bar)) do
    if control.section == section.key and control.card == card.key then rows[#rows + 1] = control end
  end
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetSize(CARD_W, CARD_HEADER + #rows * ROW_H + 8)
  local edge = solid(frame, "BACKGROUND", C.cardEdge, -1)
  edge:SetAllPoints()
  local bg = solid(frame, "BACKGROUND", C.card)
  bg:SetPoint("TOPLEFT", 1, -1)
  bg:SetPoint("BOTTOMRIGHT", -1, 1)
  local title = fontString(frame, 11, { 0.79, 0.64, 1 })
  title:SetPoint("TOPLEFT", 12, -9)
  title:SetText(string.upper(L[card.label]))
  for i, control in ipairs(rows) do buildRow(frame, control, -CARD_HEADER - (i - 1) * ROW_H, bar) end
  return frame
end

-- Lays the section's cards in two columns, each card going to the shorter column.
local function buildPage(scrollChild, section, bar)
  local page = CreateFrame("Frame", nil, scrollChild)
  page:SetPoint("TOPLEFT")
  page:SetWidth(CONTENT_W)
  local top = 0
  if section.preview then
    local card = CreateFrame("Frame", nil, page)
    local height = section.preview == "tooltip" and TOOLTIP_PREVIEW_H or PREVIEW_BAR_H
    local width = section.preview == "tooltip" and CARD_W or CONTENT_W
    card:SetSize(width, height)
    local edge = solid(card, "BACKGROUND", C.cardEdge, -1)
    edge:SetAllPoints()
    local bg = solid(card, "BACKGROUND", { 0.08, 0.07, 0.11, 1 })
    bg:SetPoint("TOPLEFT", 1, -1)
    bg:SetPoint("BOTTOMRIGHT", -1, 1)
    local title = fontString(card, 11, { 0.79, 0.64, 1 })
    title:SetPoint("TOPLEFT", 12, -9)
    title:SetText(string.upper(L["Preview"]))
    page.previewCard = card
    if section.preview == "bar" then
      card:SetPoint("TOPLEFT", 0, 0)
      top = height + CARD_GAP
    else
      card:SetPoint("TOPLEFT", CARD_W + CARD_GAP, 0) -- tooltip preview: right column
    end
  end

  local columns = { top, top }
  local tooltipLayout = section.preview == "tooltip"
  for _, cardDef in ipairs(section.cards) do
    local card = buildCard(page, section, cardDef, bar)
    -- The tooltip preview owns the whole right column (the detailed view is tall).
    local col = (tooltipLayout or columns[1] <= columns[2]) and 1 or 2
    card:SetPoint("TOPLEFT", (col - 1) * (CARD_W + CARD_GAP), -columns[col])
    columns[col] = columns[col] + card:GetHeight() + CARD_GAP
  end
  if tooltipLayout then
    page.previewCard:SetHeight(math.max(TOOLTIP_PREVIEW_H, columns[1] - CARD_GAP))
    columns[2] = page.previewCard:GetHeight()
  end
  page:SetHeight(math.max(columns[1], columns[2]))
  page:Hide()
  return page
end

local function createWindow()
  widgets = {}
  window = CreateFrame("Frame", "OdysseyWindow", UIParent)
  window:SetSize(WINDOW_W, WINDOW_H)
  window:SetFrameStrata("DIALOG")
  window:SetClampedToScreen(true)
  window:SetMovable(true)
  window:EnableMouse(true)
  window:Hide()
  if UISpecialFrames then table.insert(UISpecialFrames, "OdysseyWindow") end

  local edge = solid(window, "BACKGROUND", { 0.23, 0.19, 0.31, 1 }, -1)
  edge:SetPoint("TOPLEFT", -1, 1)
  edge:SetPoint("BOTTOMRIGHT", 1, -1)
  local bg = solid(window, "BACKGROUND", C.window)
  bg:SetAllPoints()

  -- Title bar: drag handle, palette-tinted gradient, close button.
  local titleBar = CreateFrame("Frame", nil, window)
  titleBar:SetPoint("TOPLEFT")
  titleBar:SetPoint("TOPRIGHT")
  titleBar:SetHeight(TITLE_H)
  titleBar:EnableMouse(true)
  titleBar:RegisterForDrag("LeftButton")
  titleBar:SetScript("OnDragStart", function() window:StartMoving() end)
  titleBar:SetScript("OnDragStop", function()
    window:StopMovingOrSizing()
    local point, _, relativePoint, x, y = window:GetPoint()
    OdysseyDB.window = { point, relativePoint, x, y }
  end)
  window.titleTex = titleBar:CreateTexture(nil, "BACKGROUND")
  window.titleTex:SetAllPoints()
  window.titleTex:SetTexture(Styles.resolveTexture("flat", nil))
  local title = fontString(titleBar, 14, { 1, 1, 1 })
  title:SetPoint("LEFT", 14, 0)
  title:SetText("Odyssey")
  local close = flatButton(titleBar, 22, 20, "X")
  close:SetPoint("RIGHT", -8, 0)
  close:SetScript("OnClick", function() window:Hide() end)

  -- Sidebar.
  local sidebar = CreateFrame("Frame", nil, window)
  sidebar:SetPoint("TOPLEFT", 0, -TITLE_H)
  sidebar:SetPoint("BOTTOMLEFT")
  sidebar:SetWidth(SIDEBAR_W)
  local sideBg = solid(sidebar, "BACKGROUND", C.sidebar)
  sideBg:SetAllPoints()

  -- Scrolling content.
  local scroll = CreateFrame("ScrollFrame", nil, window)
  scroll:SetPoint("TOPLEFT", SIDEBAR_W + 10, -TITLE_H - 10)
  scroll:SetPoint("BOTTOMRIGHT", -10, 10)
  scroll:EnableMouseWheel(true)
  local child = CreateFrame("Frame", nil, scroll)
  child:SetSize(CONTENT_W, 10)
  scroll:SetScrollChild(child)
  scroll:SetScript("OnMouseWheel", function(self, delta)
    local max = math.max(0, child:GetHeight() - self:GetHeight())
    self:SetVerticalScroll(math.max(0, math.min(max, self:GetVerticalScroll() - delta * 40)))
  end)

  -- Bar selector: which bar the sections edit.
  window.barButtons = {}
  for i, bar in ipairs({ "xp", "rep" }) do
    local b = flatButton(sidebar, SIDEBAR_W - 16, 22, L[bar == "xp" and "XP bar" or "Reputation bar"])
    b:SetPoint("TOPLEFT", 8, -10 - (i - 1) * 26)
    b:SetScript("OnClick", function() Options.SelectBar(bar) end)
    window.barButtons[bar] = b
  end
  local SECTIONS_TOP = -10 - 2 * 26 - 10

  window.pages, window.tabs = { xp = {}, rep = {} }, {}
  for i, section in ipairs(Options.SECTIONS) do
    for _, bar in ipairs({ "xp", "rep" }) do
      window.pages[bar][section.key] = buildPage(child, section, bar)
    end
    local tab = CreateFrame("Button", nil, sidebar)
    tab:SetSize(SIDEBAR_W, 32)
    tab:SetPoint("TOPLEFT", 0, SECTIONS_TOP - (i - 1) * 34)
    tab.bg = solid(tab, "BACKGROUND", { 0.13, 0.11, 0.2, 1 })
    tab.bg:SetAllPoints()
    tab.strip = tab:CreateTexture(nil, "ARTWORK")
    tab.strip:SetPoint("TOPLEFT")
    tab.strip:SetPoint("BOTTOMLEFT")
    tab.strip:SetWidth(3)
    local hl = tab:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.05)
    tab.label = fontString(tab, 13, C.text)
    tab.label:SetPoint("LEFT", 16, 0)
    tab.label:SetText(L[section.label])
    tab:SetScript("OnClick", function() Options.Select(section.key) end)
    window.tabs[section.key] = tab
  end

  -- "Detailed preview" toggle in each tooltip preview card (not saved).
  window.detailChecks = {}
  for _, bar in ipairs({ "xp", "rep" }) do
    local card = window.pages[bar].tooltip.previewCard
    local detail = makeCheck(card)
    detail:SetPoint("TOPRIGHT", -10, -6)
    detail.mark:Hide()
    local detailLabel = fontString(card, 11, C.muted)
    detailLabel:SetPoint("RIGHT", detail, "LEFT", -6, 0)
    detailLabel:SetText(L["Detailed preview"])
    detail:SetScript("OnClick", function()
      window.previewDetailed = not window.previewDetailed
      for _, check in ipairs(window.detailChecks) do check.mark:SetShown(window.previewDetailed) end
      Options.UpdatePreview()
    end)
    window.detailChecks[#window.detailChecks + 1] = detail
  end
  window.bar = "xp"

  window.scroll, window.child = scroll, child
  window:SetScript("OnHide", function()
    if menu then menu:Hide() end
    if ns.Tooltip then ns.Tooltip.HidePreview() end
  end)
  window:SetScript("OnShow", function()
    refresh()
    Options.UpdatePreview()
  end)

  local p = OdysseyDB.window or { "CENTER", "CENTER", 0, 0 }
  window:SetPoint(p[1], UIParent, p[2], p[3], p[4])
end

function refresh()
  if not window then return end
  local accent, colors = accentColor()
  window.titleTex:SetVertexColor(1, 1, 1, 1)
  setGradient(window.titleTex, { accent[1] * 0.45, accent[2] * 0.45, accent[3] * 0.45 }, { 0.09, 0.07, 0.12 })
  for key, tab in pairs(window.tabs) do
    local selected = key == window.current
    tab.bg:SetShown(selected)
    tab.strip:SetColorTexture(accent[1], accent[2], accent[3], selected and 1 or 0)
  end
  for bar, button in pairs(window.barButtons) do
    local selected = bar == window.bar
    button.label:SetTextColor(selected and 1 or C.muted[1], selected and 1 or C.muted[2], selected and 1 or C.muted[3], 1)
    if button.marker then button.marker:SetShown(selected) end
    button:SetAlpha(selected and 1 or 0.7)
  end
  for _, w in ipairs(widgets) do
    local c = w.control
    local t = target(c, w.bar)
    local value = Options.currentValue(t, c)
    if w.widget then
      local enabled = Options.isEnabled(t, c, w.bar)
      w.widget.enabled = enabled
      w.widget:SetAlpha(enabled and 1 or 0.35)
      w.label:SetAlpha(enabled and 1 or 0.35)
      if w.widget.reset then w.widget.reset.enabled = enabled end
    end
    if c.kind == "color" then colors = barObject(w.bar).colors or colors end
    if w.widget and w.widget.armed then
      disarm(w.widget)
      if c.kind == "action" then w.widget:SetText(L[c.label]) end
    end
    if c.kind == "slider" then
      w.widget:SetValue(value)
    elseif c.kind == "check" then
      w.widget.mark:SetShown(value and true or false)
    elseif c.kind == "menu" then
      w.widget:SetText(Options.displayValue(c, value, w.bar))
    elseif c.kind == "color" then
      local color = c.part == "fill" and colors.fill.to or colors[c.part]
      w.widget.color:SetColorTexture(color[1], color[2], color[3], 1)
      w.widget.reset:SetShown(value ~= nil)
    end
  end
end

-- Shows the live preview of the current section: the mini bar, or the tooltip.
function Options.UpdatePreview()
  if not window or not window:IsShown() then return end
  local section
  for _, sec in ipairs(Options.SECTIONS) do if sec.key == window.current then section = sec end end
  local page = window.pages[window.bar][window.current]
  ns.previewBars = ns.previewBars or {}
  for bar, preview in pairs(ns.previewBars) do
    if bar ~= window.bar or not (section and section.preview == "bar") then preview.frame:Hide() end
  end
  if section and section.preview == "bar" then
    local bar = window.bar
    if not ns.previewBars[bar] then
      ns.previewBars[bar] = ns.Bar.create(bar == "rep" and ns.repSource or ns.source, {
        parent = page.previewCard, width = CONTENT_W - 40, kind = bar,
        settings = bar == "rep" and ns.RepSettings or ns.Settings,
      })
    end
    local preview = ns.previewBars[bar]
    preview.frame:SetParent(page.previewCard)
    preview.frame:ClearAllPoints()
    preview.frame:SetPoint("LEFT", page.previewCard, "LEFT", 20, -6)
    preview.frame:Show()
    preview:ApplySettings()
    preview:Update()
  end
  if ns.Tooltip then
    if section and section.preview == "tooltip" then
      ns.Tooltip.ShowPreview(page.previewCard, window.previewDetailed, true, barObject(window.bar))
    else
      ns.Tooltip.HidePreview()
    end
  end
end

function Options.Select(key)
  if menu then menu:Hide() end
  window.current = key
  for bar, pages in pairs(window.pages) do
    for k, page in pairs(pages) do page:SetShown(bar == window.bar and k == key) end
  end
  window.child:SetHeight(window.pages[window.bar][key]:GetHeight())
  window.scroll:SetVerticalScroll(0)
  refresh()
  Options.UpdatePreview()
end

function Options.SelectBar(bar)
  window.bar = bar
  Options.Select(window.current or "bar")
end

-- Keeps widgets and previews in sync after any change (Core's ns.Refresh calls it, so
-- slash commands are covered too).
function Options.Refresh()
  if window and window:IsShown() then
    refresh()
    Options.UpdatePreview()
  end
end

-- =========================================================== Blizzard settings

-- The game's options keep one small page with a button that opens the Odyssey window.
local function registerSettingsStub()
  local panel = CreateFrame("Frame", "OdysseyOptionsPanel", UIParent)
  panel.name = "Odyssey"
  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("Odyssey")
  local text = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  text:SetPoint("TOPLEFT", 16, -48)
  text:SetText(L["Odyssey has its own settings window."])
  local open = flatButton(panel, 200, 26, L["Open Odyssey"])
  open:SetPoint("TOPLEFT", 16, -76)
  open:SetScript("OnClick", function()
    if SettingsPanel and SettingsPanel:IsShown() and HideUIPanel then HideUIPanel(SettingsPanel) end
    Options.Show()
  end)
  if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
  end
end

function Options.create()
  createWindow()
  registerSettingsStub()
end

function Options.Show()
  if not window then return end
  window:Show()
  Options.Select(window.current or "bar")
end

-- /odyssey and right-click on the bar toggle the window.
function ns.OpenOptions()
  if not window then return end
  if window:IsShown() then window:Hide() else Options.Show() end
end
