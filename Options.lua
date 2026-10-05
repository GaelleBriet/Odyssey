local ADDON, ns = ...
local Calc, Defaults, History, Texts, Styles, Themes = ns.Calc, ns.Defaults, ns.History, ns.Texts, ns.Styles, ns.Themes
local L = ns.L

local Options = {}
ns.Options = Options

local function textName(key) return L["text." .. key] end
local function styleName(key) return L["style." .. key] end
local function themeName(key) return L["theme." .. key] end
local function maxName(key) return L["max." .. key] end

-- kind "bool" toggles; kind "list" cycles through `values` (left click next, right click previous).
-- `account = true` writes to the account root (OdysseyDB) instead of the active settings.
local CONTROLS = {
  { key = "locked", kind = "bool", label = "Lock bar" },
  { key = "width", kind = "list", label = "Width", values = { 240, 320, 400, 480, 560, 640, 800 } },
  { key = "height", kind = "list", label = "Height", values = { 8, 10, 12, 14, 16, 20, 24, 32 } },
  { key = "scale", kind = "list", label = "Scale", values = { 0.75, 0.9, 1, 1.1, 1.25, 1.5 } },
  { key = "style", kind = "list", label = "Style", values = Styles.list, display = styleName },
  { key = "theme", kind = "list", label = "Theme", values = Themes.list, display = themeName },
  { key = "textLeft", kind = "list", label = "Left text", values = Texts.KEYS, display = textName },
  { key = "textCenter", kind = "list", label = "Center text", values = Texts.KEYS, display = textName },
  { key = "textRight", kind = "list", label = "Right text", values = Texts.KEYS, display = textName },
  { key = "maxLevelBehavior", kind = "list", label = "At max level", values = { "hide", "show" }, display = maxName },
  { key = "hideNativeBar", kind = "bool", label = "Hide Blizzard XP bar" },
  { key = "abbreviate", kind = "bool", label = "Abbreviate numbers" },
  { key = "perCharacter", kind = "bool", label = "Settings per character", account = true },
  { key = "tooltip.level", kind = "bool", label = "opt.tooltip.level" },
  { key = "tooltip.rested", kind = "bool", label = "opt.tooltip.rested" },
  { key = "tooltip.quests", kind = "bool", label = "opt.tooltip.quests" },
  { key = "tooltip.kills", kind = "bool", label = "opt.tooltip.kills" },
  { key = "tooltip.session", kind = "bool", label = "opt.tooltip.session" },
  { key = "tooltip.played", kind = "bool", label = "opt.tooltip.played" },
  { key = "tooltip.history", kind = "bool", label = "opt.tooltip.history" },
}

local COLUMN_SPLIT = 12
local COLUMN_WIDTH = 290
local LABEL_WIDTH = 150
local BUTTON_WIDTH = 120
local ROW_HEIGHT = 30

local function target(control)
  return control.account and OdysseyDB or ns.Settings()
end

local function display(control, value)
  if control.kind == "bool" then return value and L["On"] or L["Off"] end
  if control.display then return control.display(value) end
  return tostring(value)
end

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

  for i, control in ipairs(CONTROLS) do
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
    button:SetScript("OnClick", function(_, mouseButton)
      local t = target(control)
      local current = Defaults.get(t, control.key)
      local value
      if control.kind == "bool" then
        value = not current
      else
        value = Calc.cycle(control.values, current, mouseButton == "RightButton" and -1 or 1)
      end
      Defaults.set(t, control.key, value)
      if control.account then Defaults.merge(ns.Settings(), Defaults.settings) end
      ns.Refresh()
      refresh()
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

  -- Register with whichever settings system this client has; otherwise float as its own window.
  if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
    Options.categoryID = category.GetID and category:GetID() or category.ID
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
  else
    panel:SetParent(UIParent)
    panel:SetSize(620, 480)
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
