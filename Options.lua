local ADDON, ns = ...
local Defaults, History, Texts, Styles, Palettes, Fonts =
  ns.Defaults, ns.History, ns.Texts, ns.Styles, ns.Palettes, ns.Fonts
local L = ns.L

local Options = {}
ns.Options = Options

-- ------------------------------------------------------------------ model

Options.ROWS = 10 -- rows per column; two columns per tab

Options.TABS = {
  { key = "bar", label = "tab.bar" },
  { key = "colors", label = "tab.colors" },
  { key = "texts", label = "tab.texts" },
  { key = "tooltip", label = "tab.tooltip" },
}

local function named(prefix) return function(v) return L[prefix .. tostring(v)] end end
local function percent(v) return string.format("%d %%", math.floor(v * 100 + 0.5)) end
local OUTLINES = { "NONE", "OUTLINE", "THICKOUTLINE" }

-- kind "check": on/off; kind "menu": dropdown from `values` (shown through `display`) or from
-- a `source` (presets, palettes, fonts, textures); kind "color": swatch opening the colour wheel.
-- `account = true` writes to OdysseyDB instead of the active settings.
-- `preset = true`: picking a value applies a preset instead of storing it.
Options.CONTROLS = {
  -- Bar
  { tab = "bar", key = "preset", kind = "menu", label = "Preset", source = "presets", preset = true },
  { tab = "bar", key = "texture", kind = "menu", label = "Texture", source = "textures" },
  { tab = "bar", key = "corners", kind = "menu", label = "Corners", values = { "square", "rounded" }, display = named("corners.") },
  { tab = "bar", key = "border", kind = "menu", label = "Border", values = { "none", "thin", "thick" }, display = named("border.") },
  { tab = "bar", key = "bgOpacity", kind = "menu", label = "Background opacity", values = { 0, 0.25, 0.5, 0.75, 0.9, 1 }, display = percent },
  { tab = "bar", key = "ticks", kind = "menu", label = "Ticks", values = { 0, 10, 20 }, display = named("ticks.") },
  { tab = "bar", key = "gloss", kind = "check", label = "Gloss" },
  { tab = "bar", key = "shadow", kind = "check", label = "Shadow" },
  { tab = "bar", key = "glow", kind = "check", label = "Glow" },
  { tab = "bar", key = "spark", kind = "check", label = "Spark" },
  { tab = "bar", key = "width", kind = "menu", label = "Width", values = { 240, 320, 400, 480, 560, 640, 800, 1000 } },
  { tab = "bar", key = "height", kind = "menu", label = "Height", values = { 4, 6, 8, 10, 12, 14, 16, 18, 20, 24, 32 } },
  { tab = "bar", key = "scale", kind = "menu", label = "Scale", values = { 0.75, 0.9, 1, 1.1, 1.25, 1.5 }, display = percent },
  { tab = "bar", key = "visibility", kind = "menu", label = "Visibility", values = { "always", "mouseover" }, display = named("visibility.") },
  { tab = "bar", key = "fadedAlpha", kind = "menu", label = "Opacity when hidden", values = { 0, 0.15, 0.3, 0.5 }, display = percent },
  { tab = "bar", key = "maxLevelBehavior", kind = "menu", label = "At max level", values = { "hide", "show" }, display = named("max.") },
  { tab = "bar", key = "locked", kind = "check", label = "Lock bar" },
  { tab = "bar", key = "hideNativeBar", kind = "check", label = "Hide Blizzard XP bar" },
  { tab = "bar", key = "perCharacter", kind = "check", label = "Settings per character", account = true },
  -- Colours
  { tab = "colors", key = "palette", kind = "menu", label = "Palette", source = "palettes" },
  { tab = "colors", key = "borderColor", kind = "menu", label = "Border color", values = { "palette", "black", "gold" }, display = named("borderColor.") },
  { tab = "colors", key = "colors.fill", kind = "color", label = "color.fill", part = "fill" },
  { tab = "colors", key = "colors.rested", kind = "color", label = "color.rested", part = "rested" },
  { tab = "colors", key = "colors.quest", kind = "color", label = "color.quest", part = "quest" },
  { tab = "colors", key = "colors.bg", kind = "color", label = "color.bg", part = "bg" },
  { tab = "colors", key = "colors.border", kind = "color", label = "color.border", part = "border" },
  { tab = "colors", key = "colors.text", kind = "color", label = "color.text", part = "text" },
  -- Texts
  { tab = "texts", key = "textLeft", kind = "menu", label = "Left text", values = Texts.KEYS, display = named("text.") },
  { tab = "texts", key = "textCenter", kind = "menu", label = "Center text", values = Texts.KEYS, display = named("text.") },
  { tab = "texts", key = "textRight", kind = "menu", label = "Right text", values = Texts.KEYS, display = named("text.") },
  { tab = "texts", key = "textPosition", kind = "menu", label = "Text position", values = { "inside", "above", "below" }, display = named("textPosition.") },
  { tab = "texts", key = "barFont", kind = "menu", label = "Bar font", source = "fonts" },
  { tab = "texts", key = "barFontSize", kind = "menu", label = "Bar text size", values = { 8, 9, 10, 11, 12, 13, 14, 16, 18 } },
  { tab = "texts", key = "barFontOutline", kind = "menu", label = "Bar text outline", values = OUTLINES, display = named("outline.") },
  { tab = "texts", key = "abbreviate", kind = "check", label = "Abbreviate numbers" },
  -- Tooltip
  { tab = "tooltip", key = "tooltipFont", kind = "menu", label = "Tooltip font", source = "fonts" },
  { tab = "tooltip", key = "tooltipFontSize", kind = "menu", label = "Tooltip text size", values = { 10, 11, 12, 13, 14, 16 } },
  { tab = "tooltip", key = "tooltipFontOutline", kind = "menu", label = "Tooltip text outline", values = OUTLINES, display = named("outline.") },
  { tab = "tooltip", key = "tooltipBgOpacity", kind = "menu", label = "Tooltip background opacity", values = { 0.5, 0.7, 0.85, 0.93, 1 }, display = percent },
  { tab = "tooltip", key = "tooltipScale", kind = "menu", label = "Tooltip scale", values = { 0.8, 0.9, 1, 1.1, 1.2, 1.3 }, display = percent },
  { tab = "tooltip", key = "tooltipAnchor", kind = "menu", label = "Tooltip position", values = { "bar", "cursor" }, display = named("tooltipAnchor.") },
  { tab = "tooltip", key = "tooltip.level", kind = "check", label = "opt.tooltip.level" },
  { tab = "tooltip", key = "tooltip.rested", kind = "check", label = "opt.tooltip.rested" },
  { tab = "tooltip", key = "tooltip.quests", kind = "check", label = "opt.tooltip.quests" },
  { tab = "tooltip", key = "tooltip.kills", kind = "check", label = "opt.tooltip.kills" },
  { tab = "tooltip", key = "tooltip.session", kind = "check", label = "opt.tooltip.session" },
  { tab = "tooltip", key = "tooltip.played", kind = "check", label = "opt.tooltip.played" },
  { tab = "tooltip", key = "tooltip.history", kind = "check", label = "opt.tooltip.history" },
}

-- Items of a menu: { value, text } plus `font` or `texture` for a preview.
function Options.choices(control)
  local items = {}
  if control.source == "presets" then
    for _, key in ipairs(Styles.PRESET_LIST) do items[#items + 1] = { value = key, text = L["style." .. key] } end
  elseif control.source == "palettes" then
    for _, key in ipairs(Palettes.list) do items[#items + 1] = { value = key, text = L["palette." .. key] } end
  elseif control.source == "fonts" then
    for _, f in ipairs(Fonts.list(Fonts.lsm())) do items[#items + 1] = { value = f.name, text = f.name, font = f.path } end
  elseif control.source == "textures" then
    for _, t in ipairs(Styles.textureList(Fonts.lsm())) do
      local text = t.source == "odyssey" and L["texture." .. t.value] or t.value
      items[#items + 1] = { value = t.value, text = text, texture = t.path }
    end
  else
    for _, v in ipairs(control.values) do
      items[#items + 1] = { value = v, text = control.display and control.display(v) or tostring(v) }
    end
  end
  return items
end

function Options.displayValue(control, value)
  if control.preset then return L["Choose…"] end
  for _, item in ipairs(Options.choices(control)) do
    if item.value == value then return item.text end
  end
  return tostring(value)
end

-- Writes a picked value; a preset fills every bar field instead.
function Options.applyValue(t, control, value)
  if control.preset then
    Styles.applyPreset(t, value)
  else
    Defaults.set(t, control.key, value)
  end
end

function Options.resetColors(settings)
  settings.colors = {}
end

local function target(control)
  return control.account and OdysseyDB or ns.Settings()
end

-- ------------------------------------------------------------ colour wheel

-- Opens the game's colour picker; modern clients use SetupColorPickerAndShow, older ones
-- the func/cancelFunc fields. `onChange(r, g, b)` runs live and on cancel (previous colour).
local function openColorPicker(color, onChange)
  local picker = ColorPickerFrame
  if not picker then return end
  local r, g, b = color[1], color[2], color[3]
  local function changed()
    local nr, ng, nb = picker:GetColorRGB()
    onChange(nr, ng, nb)
  end
  local function cancelled(previous)
    if type(previous) == "table" and previous.r then onChange(previous.r, previous.g, previous.b) else onChange(r, g, b) end
  end
  if picker.SetupColorPickerAndShow then
    picker:SetupColorPickerAndShow({
      r = r, g = g, b = b, hasOpacity = false,
      swatchFunc = changed, cancelFunc = cancelled,
    })
  else
    picker.hasOpacity = false
    picker.previousValues = { r = r, g = g, b = b }
    picker.func = changed
    picker.cancelFunc = cancelled
    picker:SetColorRGB(r, g, b)
    if ShowUIPanel then ShowUIPanel(picker) else picker:Show() end
  end
end

-- ---------------------------------------------------------------- the menu

local MENU_WIDTH, ITEM_HEIGHT, MENU_ROWS = 220, 20, 12
local menu

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
  -- A click anywhere outside the menu lands on the catcher and closes it.
  catcher:SetScript("OnClick", function() menu:Hide() end)
  menu:SetScript("OnShow", function() catcher:Show() end)
  menu:SetScript("OnHide", function() catcher:Hide() end)
  local edge = menu:CreateTexture(nil, "BACKGROUND", nil, -1)
  edge:SetPoint("TOPLEFT", -1, 1)
  edge:SetPoint("BOTTOMRIGHT", 1, -1)
  edge:SetColorTexture(0.35, 0.3, 0.45, 1)
  local bg = menu:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.05, 0.05, 0.07, 0.97)
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
  -- Escape closes the menu like any Blizzard popup.
  if UISpecialFrames then table.insert(UISpecialFrames, "OdysseyMenu") end
end

local function openMenu(button, control, current, onPick)
  if not menu then createMenu() end
  if menu:IsShown() and menu.owner == button then menu:Hide() return end
  menu.owner = button
  menu.items = Options.choices(control)
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

-- ---------------------------------------------------------------- the panel

local COLUMN_WIDTH = 300
local LABEL_WIDTH = 150
local WIDGET_WIDTH = 135
local ROW_HEIGHT = 28
local TOP = -84 -- below the title and the tab buttons

local function makeButton(parent, width, text)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width, 22)
  b:SetText(text)
  return b
end

-- A flat checkbox drawn by Odyssey (no template whose name varies between clients).
local function makeCheck(parent)
  local box = CreateFrame("Button", nil, parent)
  box:SetSize(18, 18)
  local edge = box:CreateTexture(nil, "BACKGROUND")
  edge:SetAllPoints()
  edge:SetColorTexture(0.45, 0.42, 0.55, 1)
  local inner = box:CreateTexture(nil, "BORDER")
  inner:SetPoint("TOPLEFT", 1, -1)
  inner:SetPoint("BOTTOMRIGHT", -1, 1)
  inner:SetColorTexture(0.07, 0.07, 0.1, 1)
  box.mark = box:CreateTexture(nil, "ARTWORK")
  box.mark:SetPoint("TOPLEFT", 4, -4)
  box.mark:SetPoint("BOTTOMRIGHT", -4, 4)
  box.mark:SetColorTexture(0.73, 0.55, 1, 1)
  local hl = box:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(1, 1, 1, 0.12)
  return box
end

local function makeSwatch(parent)
  local swatch = CreateFrame("Button", nil, parent)
  swatch:SetSize(40, 18)
  local edge = swatch:CreateTexture(nil, "BACKGROUND")
  edge:SetAllPoints()
  edge:SetColorTexture(0.45, 0.42, 0.55, 1)
  swatch.color = swatch:CreateTexture(nil, "ARTWORK")
  swatch.color:SetPoint("TOPLEFT", 1, -1)
  swatch.color:SetPoint("BOTTOMRIGHT", -1, 1)
  local hl = swatch:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(1, 1, 1, 0.15)
  swatch.reset = makeButton(parent, 22, "×")
  swatch.reset:SetPoint("LEFT", swatch, "RIGHT", 6, 0)
  return swatch
end

function Options.create()
  local panel = CreateFrame("Frame", "OdysseyOptionsPanel", UIParent)
  panel.name = "Odyssey"
  Options.panel = panel

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("Odyssey")

  local pages, tabButtons, widgets = {}, {}, {}

  local function refresh()
    local s = ns.Settings()
    local colors = (ns.bar and ns.bar.colors) or Palettes.effective(s.palette, {}, s)
    for _, w in ipairs(widgets) do
      local c = w.control
      local value = Defaults.get(target(c), c.key)
      if c.kind == "check" then
        w.widget.mark:SetShown(value and true or false)
      elseif c.kind == "menu" then
        w.widget:SetText(Options.displayValue(c, value))
      else
        local color = colors[c.part]
        if c.part == "fill" then color = colors.fill.to end
        w.widget.color:SetColorTexture(color[1], color[2], color[3], 1)
        w.widget.reset:SetShown(value ~= nil)
      end
    end
  end

  local function changed(control)
    if control.account then Defaults.merge(ns.Settings(), Defaults.settings) end
    ns.Refresh()
    refresh()
  end

  local function selectTab(key)
    for k, page in pairs(pages) do page:SetShown(k == key) end
    for k, button in pairs(tabButtons) do
      if k == key then button:LockHighlight() else button:UnlockHighlight() end
    end
    if menu then menu:Hide() end
  end

  for i, tab in ipairs(Options.TABS) do
    local button = makeButton(panel, 110, L[tab.label])
    button:SetPoint("TOPLEFT", 16 + (i - 1) * 116, -44)
    button:SetScript("OnClick", function() selectTab(tab.key) end)
    tabButtons[tab.key] = button
    local page = CreateFrame("Frame", nil, panel)
    page:SetPoint("TOPLEFT", 0, 0)
    page:SetPoint("BOTTOMRIGHT", 0, 0)
    pages[tab.key] = page
  end

  local indexInTab = {}
  for _, control in ipairs(Options.CONTROLS) do
    local page = pages[control.tab]
    local i = (indexInTab[control.tab] or 0) + 1
    indexInTab[control.tab] = i
    local column = i <= Options.ROWS and 0 or 1
    local index = (i - 1) % Options.ROWS
    local x = 16 + column * COLUMN_WIDTH
    local y = TOP - index * ROW_HEIGHT

    local label = page:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("TOPLEFT", x, y)
    label:SetWidth(LABEL_WIDTH)
    label:SetJustifyH("LEFT")
    label:SetText(L[control.label])

    local widget
    if control.kind == "check" then
      widget = makeCheck(page)
      widget:SetPoint("TOPLEFT", x + LABEL_WIDTH, y + 2)
      widget:SetScript("OnClick", function()
        local t = target(control)
        Defaults.set(t, control.key, not Defaults.get(t, control.key))
        changed(control)
      end)
    elseif control.kind == "menu" then
      widget = makeButton(page, WIDGET_WIDTH, "")
      widget:SetPoint("TOPLEFT", x + LABEL_WIDTH, y + 4)
      widget:SetScript("OnClick", function(self)
        openMenu(self, control, Defaults.get(target(control), control.key), function(value)
          Options.applyValue(target(control), control, value)
          changed(control)
        end)
      end)
    else
      widget = makeSwatch(page)
      widget:SetPoint("TOPLEFT", x + LABEL_WIDTH, y + 2)
      widget:SetScript("OnClick", function()
        local s = ns.Settings()
        local colors = (ns.bar and ns.bar.colors) or Palettes.effective(s.palette, {}, s)
        local start = control.part == "fill" and colors.fill.to or colors[control.part]
        openColorPicker(start, function(r, g, b)
          Options.applyValue(s, control, { r, g, b })
          changed(control)
        end)
      end)
      widget.reset:SetScript("OnClick", function()
        Defaults.set(ns.Settings(), control.key, nil)
        changed(control)
      end)
    end
    widgets[#widgets + 1] = { control = control, widget = widget }
  end

  local resetColors = makeButton(pages.colors, 260, L["Reset to palette colors"])
  resetColors:SetPoint("TOPLEFT", 16, TOP - Options.ROWS * ROW_HEIGHT - 10)
  resetColors:SetScript("OnClick", function()
    Options.resetColors(ns.Settings())
    changed({})
  end)

  local actionsY = TOP - Options.ROWS * ROW_HEIGHT - 50
  local resetSession = makeButton(panel, 190, L["Reset session"])
  resetSession:SetPoint("TOPLEFT", 16, actionsY)
  resetSession:SetScript("OnClick", function()
    ns.source:resetSession()
    print("|cff9966ffOdyssey|r: " .. L["Session reset."])
  end)
  local clearHistory = makeButton(panel, 190, L["Clear history"])
  clearHistory:SetPoint("TOPLEFT", 16 + COLUMN_WIDTH, actionsY)
  clearHistory:SetScript("OnClick", function()
    History.reset(ns.CharData().history)
    print("|cff9966ffOdyssey|r: " .. L["History cleared."])
  end)

  panel:SetScript("OnShow", refresh)
  panel:SetScript("OnHide", function() if menu then menu:Hide() end end)
  selectTab("bar")

  -- Register with whichever settings system this client has; otherwise float as its own window.
  if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
    Options.categoryID = category.GetID and category:GetID() or category.ID
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
  else
    panel:SetParent(UIParent)
    panel:SetSize(640, 520)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.85)
    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    panel:Hide()
    Options.standalone = true
  end
end

function ns.OpenOptions()
  if not Options.panel then return end
  if Options.categoryID and Settings and Settings.OpenToCategory then
    Settings.OpenToCategory(Options.categoryID)
  elseif InterfaceOptionsFrame_OpenToCategory and not Options.standalone then
    InterfaceOptionsFrame_OpenToCategory(Options.panel)
    InterfaceOptionsFrame_OpenToCategory(Options.panel) -- first call can open the wrong page (known client quirk)
  else
    Options.panel:SetShown(not Options.panel:IsShown())
  end
end
