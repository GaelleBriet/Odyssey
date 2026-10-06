local ADDON, ns = ...
local Defaults, History, Texts, Styles, Palettes, Fonts =
  ns.Defaults, ns.History, ns.Texts, ns.Styles, ns.Palettes, ns.Fonts
local L = ns.L

local Options = {}
ns.Options = Options

-- ------------------------------------------------------------------ model

Options.ROWS = 11 -- rows per column; two columns per tab

Options.TABS = {
  { key = "bar", label = "tab.bar" },
  { key = "colors", label = "tab.colors" },
  { key = "texts", label = "tab.texts" },
  { key = "tooltip", label = "tab.tooltip" },
}

local function named(prefix) return function(v) return L[prefix .. tostring(v)] end end
local function percent(v) return string.format("%d %%", math.floor(v * 100 + 0.5)) end
local OUTLINES = { "NONE", "OUTLINE", "THICKOUTLINE" }

-- kind "header": a sub-section title;
-- kind "slider": continuous value between `min` and `max`, snapped to `step`;
-- kind "check": on/off; kind "menu": dropdown from `values` (shown through `display`) or from
-- a `source` (presets, palettes, fonts, textures); kind "color": swatch opening the colour wheel.
-- `account = true` writes to OdysseyDB instead of the active settings.
-- `preset = true`: picking a value applies a preset instead of storing it.
-- `enabledWhen = { key, value }`: the control is greyed out unless that setting has that value.
Options.CONTROLS = {
  -- Bar, first column: the look
  { tab = "bar", key = "preset", kind = "menu", label = "Preset", source = "presets", preset = true },
  { tab = "bar", key = "texture", kind = "menu", label = "Texture", source = "textures" },
  { tab = "bar", key = "corners", kind = "menu", label = "Corners", values = { "square", "rounded" }, display = named("corners.") },
  { tab = "bar", key = "border", kind = "menu", label = "Border", values = { "none", "thin", "thick" }, display = named("border.") },
  { tab = "bar", key = "ticks", kind = "menu", label = "Ticks", values = { 0, 10, 20 }, display = named("ticks.") },
  { tab = "bar", key = "gloss", kind = "check", label = "Gloss" },
  { tab = "bar", key = "shadow", kind = "check", label = "Shadow" },
  { tab = "bar", key = "glow", kind = "check", label = "Glow" },
  { tab = "bar", key = "spark", kind = "check", label = "Spark" },
  { tab = "bar", key = "bgOpacity", kind = "slider", label = "Background opacity", min = 0, max = 1, step = 0.05, display = percent },
  { tab = "bar", key = "barAlpha", kind = "slider", label = "Bar opacity", min = 0.1, max = 1, step = 0.05, display = percent },
  -- Bar, second column: size, visibility, behaviour
  { tab = "bar", key = "width", kind = "slider", label = "Width", min = 200, max = 1200, step = 10 },
  { tab = "bar", key = "height", kind = "slider", label = "Height", min = 2, max = 40, step = 1 },
  { tab = "bar", key = "scale", kind = "slider", label = "Scale", min = 0.5, max = 2, step = 0.05, display = percent },
  { tab = "bar", key = "header.visibility", kind = "header", label = "Visibility" },
  { tab = "bar", key = "visibility", kind = "menu", label = "Mode", values = { "always", "mouseover" }, display = named("visibility.") },
  { tab = "bar", key = "fadedAlpha", kind = "slider", label = "Opacity when hidden", min = 0, max = 1, step = 0.05, display = percent,
    enabledWhen = { key = "visibility", value = "mouseover" } },
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
  { tab = "tooltip", key = "tooltipBgOpacity", kind = "slider", label = "Tooltip background opacity", min = 0, max = 1, step = 0.05, display = percent },
  { tab = "tooltip", key = "tooltipScale", kind = "slider", label = "Tooltip scale", min = 0.5, max = 2, step = 0.05, display = percent },
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

-- Snaps a raw slider position to the control's step and range.
function Options.sliderValue(control, raw)
  local v = math.max(control.min, math.min(control.max, raw))
  v = control.min + math.floor((v - control.min) / control.step + 0.5) * control.step
  v = math.floor(v * 10000 + 0.5) / 10000 -- drop float noise (0.35000000000000003)
  return math.min(control.max, v)
end

function Options.displayValue(control, value)
  if control.preset then return L["Choose…"] end
  if control.kind == "slider" then
    return control.display and control.display(value) or tostring(value)
  end
  for _, item in ipairs(Options.choices(control)) do
    if item.value == value then return item.text end
  end
  return tostring(value)
end

-- The value a control currently shows (the visibility menu reads two fields).
function Options.currentValue(t, control)
  return Defaults.get(t, control.key)
end

function Options.isEnabled(t, control)
  local rule = control.enabledWhen
  return rule == nil or Defaults.get(t, rule.key) == rule.value
end

-- Writes a picked value; a preset fills every bar field instead.
function Options.applyValue(t, control, value)
  if control.preset then
    Styles.applyPreset(t, value)
  else
    Defaults.set(t, control.key, value)
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

local function target(control)
  return control.account and OdysseyDB or ns.Settings()
end

-- ------------------------------------------------------------ colour wheel

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

-- A slider drawn by Odyssey: drag, click on the track or use the mouse wheel.
-- `onPick(raw)` receives the raw value under the cursor; the caller snaps it.
local function makeSlider(parent, control, onPick)
  local slider = CreateFrame("Frame", nil, parent)
  slider:SetSize(WIDGET_WIDTH - 44, 18)
  slider:EnableMouse(true)
  slider:EnableMouseWheel(true)
  local track = slider:CreateTexture(nil, "BACKGROUND")
  track:SetPoint("LEFT")
  track:SetPoint("RIGHT")
  track:SetHeight(4)
  track:SetColorTexture(0.25, 0.23, 0.32, 1)
  slider.fill = slider:CreateTexture(nil, "BORDER")
  slider.fill:SetPoint("LEFT")
  slider.fill:SetHeight(4)
  slider.fill:SetColorTexture(0.73, 0.55, 1, 1)
  slider.thumb = slider:CreateTexture(nil, "ARTWORK")
  slider.thumb:SetSize(8, 14)
  slider.thumb:SetColorTexture(0.92, 0.9, 0.98, 1)
  slider.text = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
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
  local currentTab, previewDetailed = "bar", false

  -- The settings window itself when the client has one, else our panel.
  local function previewAnchor()
    return (SettingsPanel and SettingsPanel:IsShown() and SettingsPanel) or panel
  end
  local function updatePreview()
    if not ns.Tooltip then return end
    if currentTab == "tooltip" and panel:IsVisible() then
      ns.Tooltip.ShowPreview(previewAnchor(), previewDetailed)
    else
      ns.Tooltip.HidePreview()
    end
  end

  local function refresh()
    local s = ns.Settings()
    local colors = (ns.bar and ns.bar.colors) or Palettes.effective(s.palette, {}, s)
    for _, w in ipairs(widgets) do
      local c = w.control
      local value = Options.currentValue(target(c), c)
      if w.widget and c.enabledWhen then
        local enabled = Options.isEnabled(target(c), c)
        w.widget.enabled = enabled
        w.widget:SetAlpha(enabled and 1 or 0.35)
        w.label:SetAlpha(enabled and 1 or 0.35)
      end
      if c.kind == "header" then
        -- nothing to refresh
      elseif c.kind == "slider" then
        w.widget:SetValue(value)
      elseif c.kind == "check" then
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
    updatePreview()
  end

  local function selectTab(key)
    currentTab = key
    for k, page in pairs(pages) do page:SetShown(k == key) end
    for k, button in pairs(tabButtons) do
      if k == key then button:LockHighlight() else button:UnlockHighlight() end
    end
    if menu then menu:Hide() end
    updatePreview()
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

    local label = page:CreateFontString(nil, "ARTWORK", control.kind == "header" and "GameFontNormal" or "GameFontHighlight")
    label:SetPoint("TOPLEFT", x, y)
    label:SetWidth(control.kind == "header" and (LABEL_WIDTH + WIDGET_WIDTH) or LABEL_WIDTH)
    label:SetJustifyH("LEFT")
    label:SetText(L[control.label])

    local widget
    if control.kind == "header" then
      -- Sub-section title with a thin line under it; the following rows belong to it.
      local line = page:CreateTexture(nil, "ARTWORK")
      line:SetColorTexture(1, 0.82, 0, 0.35)
      line:SetHeight(1)
      line:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -3)
      line:SetWidth(LABEL_WIDTH + WIDGET_WIDTH)
    elseif control.kind == "slider" then
      widget = makeSlider(page, control, function(raw)
        local t = target(control)
        local value = Options.sliderValue(control, raw)
        if value ~= Defaults.get(t, control.key) then
          Options.applyValue(t, control, value)
          changed(control)
        end
      end)
      widget:SetPoint("TOPLEFT", x + LABEL_WIDTH, y + 2)
    elseif control.kind == "check" then
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
        openMenu(self, control, Options.currentValue(target(control), control), function(value)
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
        openColorPicker(start, Options.colorSession(s, control.part, start), function() changed(control) end)
      end)
      widget.reset:SetScript("OnClick", function()
        Defaults.set(ns.Settings(), control.key, nil)
        changed(control)
      end)
    end
    widgets[#widgets + 1] = { control = control, widget = widget, label = label }
  end

  -- "Detailed preview": show the Shift view in the preview without holding Shift (not saved).
  local detailLabel = pages.tooltip:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  detailLabel:SetPoint("TOPLEFT", 16, TOP - Options.ROWS * ROW_HEIGHT - 10)
  detailLabel:SetText(L["Detailed preview"])
  local detailCheck = makeCheck(pages.tooltip)
  detailCheck:SetPoint("LEFT", detailLabel, "RIGHT", 10, 0)
  detailCheck.mark:Hide()
  detailCheck:SetScript("OnClick", function()
    previewDetailed = not previewDetailed
    detailCheck.mark:SetShown(previewDetailed)
    updatePreview()
  end)

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

  panel:SetScript("OnShow", function()
    refresh()
    updatePreview()
  end)
  panel:SetScript("OnHide", function()
    if menu then menu:Hide() end
    if ns.Tooltip then ns.Tooltip.HidePreview() end
  end)
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
