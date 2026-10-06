local ADDON, ns = ...
local Calc, Defaults, History, Texts, Styles, Palettes, Fonts =
  ns.Calc, ns.Defaults, ns.History, ns.Texts, ns.Styles, ns.Palettes, ns.Fonts
local L = ns.L

local Options = {}
ns.Options = Options

local function named(prefix) return function(key) return L[prefix .. key] end end
local OUTLINES = { "NONE", "OUTLINE", "THICKOUTLINE" }

-- kind "bool" toggles; kind "list" cycles through `values` (left click next, right click previous);
-- kind "menu" opens a scrolling list built by Options.choices.
-- `account = true` writes to the account root (OdysseyDB) instead of the active settings.
Options.CONTROLS = {
  { key = "locked", kind = "bool", label = "Lock bar" },
  { key = "style", kind = "menu", label = "Style", source = "styles" },
  { key = "palette", kind = "menu", label = "Palette", source = "palettes" },
  { key = "width", kind = "list", label = "Width", values = { 240, 320, 400, 480, 560, 640, 800, 1000 } },
  { key = "height", kind = "list", label = "Height", values = { 4, 8, 10, 12, 14, 16, 18, 20, 24, 32 } },
  { key = "scale", kind = "list", label = "Scale", values = { 0.75, 0.9, 1, 1.1, 1.25, 1.5 } },
  { key = "textLeft", kind = "list", label = "Left text", values = Texts.KEYS, display = named("text.") },
  { key = "textCenter", kind = "list", label = "Center text", values = Texts.KEYS, display = named("text.") },
  { key = "textRight", kind = "list", label = "Right text", values = Texts.KEYS, display = named("text.") },
  { key = "barFont", kind = "menu", label = "Bar font", source = "fonts" },
  { key = "barFontSize", kind = "list", label = "Bar text size", values = { 8, 9, 10, 11, 12, 13, 14, 16 } },
  { key = "barFontOutline", kind = "list", label = "Bar text outline", values = OUTLINES, display = named("outline.") },
  { key = "maxLevelBehavior", kind = "list", label = "At max level", values = { "hide", "show" }, display = named("max.") },
  { key = "tooltipFont", kind = "menu", label = "Tooltip font", source = "fonts" },
  { key = "tooltipFontSize", kind = "list", label = "Tooltip text size", values = { 10, 11, 12, 13, 14, 16 } },
  { key = "tooltipFontOutline", kind = "list", label = "Tooltip text outline", values = OUTLINES, display = named("outline.") },
  { key = "tooltip.level", kind = "bool", label = "opt.tooltip.level" },
  { key = "tooltip.rested", kind = "bool", label = "opt.tooltip.rested" },
  { key = "tooltip.quests", kind = "bool", label = "opt.tooltip.quests" },
  { key = "tooltip.kills", kind = "bool", label = "opt.tooltip.kills" },
  { key = "tooltip.session", kind = "bool", label = "opt.tooltip.session" },
  { key = "tooltip.played", kind = "bool", label = "opt.tooltip.played" },
  { key = "tooltip.history", kind = "bool", label = "opt.tooltip.history" },
  { key = "hideNativeBar", kind = "bool", label = "Hide Blizzard XP bar" },
  { key = "abbreviate", kind = "bool", label = "Abbreviate numbers" },
  { key = "perCharacter", kind = "bool", label = "Settings per character", account = true },
}

-- Items of a "menu" control: { value, text, font? }. Pure apart from the font catalogue.
function Options.choices(control)
  local items = {}
  if control.source == "styles" then
    for _, key in ipairs(Styles.list) do items[#items + 1] = { value = key, text = L["style." .. key] } end
  elseif control.source == "palettes" then
    for _, key in ipairs(Palettes.list) do items[#items + 1] = { value = key, text = L["palette." .. key] } end
  elseif control.source == "fonts" then
    for _, f in ipairs(Fonts.list(Fonts.lsm())) do items[#items + 1] = { value = f.name, text = f.name, font = f.path } end
  end
  return items
end

local function target(control)
  return control.account and OdysseyDB or ns.Settings()
end

local function display(control, value)
  if control.kind == "bool" then return value and L["On"] or L["Off"] end
  if control.kind == "menu" then
    for _, item in ipairs(Options.choices(control)) do
      if item.value == value then return item.text end
    end
    return tostring(value)
  end
  if control.display then return control.display(value) end
  return tostring(value)
end

-- ---------------------------------------------------------------- the menu

local MENU_WIDTH, ITEM_HEIGHT, MENU_ROWS = 200, 20, 12
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
  local bg = menu:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.05, 0.05, 0.07, 0.97)
  local edge = menu:CreateTexture(nil, "BORDER")
  edge:SetPoint("TOPLEFT", -1, 1)
  edge:SetPoint("BOTTOMRIGHT", 1, -1)
  edge:SetColorTexture(0.35, 0.3, 0.45, 1)
  edge:SetDrawLayer("BACKGROUND", -1)
  menu.rows = {}
  for i = 1, MENU_ROWS do
    local row = CreateFrame("Button", nil, menu)
    row:SetSize(MENU_WIDTH - 8, ITEM_HEIGHT)
    row:SetPoint("TOPLEFT", 4, -4 - (i - 1) * ITEM_HEIGHT)
    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.1)
    row.check = row:CreateTexture(nil, "ARTWORK")
    row.check:SetSize(3, ITEM_HEIGHT - 6)
    row.check:SetPoint("LEFT", 0, 0)
    row.check:SetColorTexture(0.73, 0.55, 1, 1)
    row.text = row:CreateFontString(nil, "OVERLAY")
    row.text:SetPoint("LEFT", 8, 0)
    row.text:SetPoint("RIGHT", -4, 0)
    row.text:SetJustifyH("LEFT")
    menu.rows[i] = row
  end
  menu:SetScript("OnMouseWheel", function(_, delta)
    menu.offset = math.max(0, math.min(#menu.items - MENU_ROWS, menu.offset - delta * 3))
    menu.render()
  end)
  -- Escape closes the menu like any Blizzard popup.
  if UISpecialFrames then table.insert(UISpecialFrames, "OdysseyMenu") end
end

local function openMenu(button, control, onPick)
  if not menu then createMenu() end
  if menu:IsShown() and menu.owner == button then menu:Hide() return end
  menu.owner = button
  menu.items = Options.choices(control)
  local current = Defaults.get(target(control), control.key)
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

local COLUMN_SPLIT = 13
local COLUMN_WIDTH = 290
local LABEL_WIDTH = 150
local BUTTON_WIDTH = 125
local ROW_HEIGHT = 28

local function makeButton(parent, width, text)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width, 22)
  b:SetText(text)
  return b
end

function Options.create()
  local panel = CreateFrame("Frame", "OdysseyOptionsPanel", UIParent)
  panel.name = "Odyssey"
  Options.panel = panel

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("Odyssey")

  local widgets = {}

  local function refresh()
    for _, w in ipairs(widgets) do
      local value = Defaults.get(target(w.control), w.control.key)
      w.button:SetText(display(w.control, value))
    end
  end

  local function apply(control, value)
    local t = target(control)
    Defaults.set(t, control.key, value)
    if control.key == "style" and Styles.defs[value] then
      ns.Settings().height = Styles.defs[value].height -- each style has its own natural height
    end
    if control.account then Defaults.merge(ns.Settings(), Defaults.settings) end
    ns.Refresh()
    refresh()
  end

  for i, control in ipairs(Options.CONTROLS) do
    local column = i <= COLUMN_SPLIT and 0 or 1
    local index = i <= COLUMN_SPLIT and (i - 1) or (i - COLUMN_SPLIT - 1)
    local x = 16 + column * COLUMN_WIDTH
    local y = -56 - index * ROW_HEIGHT

    local label = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("TOPLEFT", x, y)
    label:SetWidth(LABEL_WIDTH)
    label:SetJustifyH("LEFT")
    label:SetText(L[control.label])

    local button = makeButton(panel, BUTTON_WIDTH, "")
    button:SetPoint("TOPLEFT", x + LABEL_WIDTH, y + 4)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function(self, mouseButton)
      local current = Defaults.get(target(control), control.key)
      if control.kind == "bool" then
        apply(control, not current)
      elseif control.kind == "list" then
        apply(control, Calc.cycle(control.values, current, mouseButton == "RightButton" and -1 or 1))
      else
        openMenu(self, control, function(value) apply(control, value) end)
      end
    end)
    widgets[#widgets + 1] = { control = control, button = button }
  end

  local actionsY = -56 - COLUMN_SPLIT * ROW_HEIGHT - 10
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

  -- Register with whichever settings system this client has; otherwise float as its own window.
  if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
    Options.categoryID = category.GetID and category:GetID() or category.ID
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
  else
    panel:SetParent(UIParent)
    panel:SetSize(620, 520)
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
