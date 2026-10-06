local ADDON, ns = ...
local TooltipContent, Styles, Palettes, Fonts = ns.TooltipContent, ns.Styles, ns.Palettes, ns.Fonts

-- The "Minimal" tooltip: Odyssey's own frame, drawn from TooltipContent.build().
local Tooltip = {}
ns.Tooltip = Tooltip

local PAD_X, PAD_LEFT, PAD_Y = 12, 16, 10
local STRIP = 3
local GAP = 18           -- between label and value
local HISTORY_BAR = 70   -- max width of a history bar
local SEPARATOR_SPACE = 9
local MIN_WIDTH = 220
local MUTED = { 0.62, 0.60, 0.68 }
local SEPARATOR = { 1, 1, 1, 0.12 }

local frame, owner, shiftShown
local strings, textures = {}, {}
local usedStrings, usedTextures = 0, 0

-- IsShiftKeyDown returns 1/nil on some clients and true/false on others.
function Tooltip.shiftDown()
  return IsShiftKeyDown() and true or false
end

local function createFrame()
  frame = CreateFrame("Frame", "OdysseyTooltip", UIParent)
  frame:SetFrameStrata("TOOLTIP")
  frame:SetClampedToScreen(true)
  frame:Hide()
  frame.bg = frame:CreateTexture(nil, "BACKGROUND")
  frame.bg:SetAllPoints()
  frame.strip = frame:CreateTexture(nil, "BORDER")
  frame.strip:SetPoint("TOPLEFT")
  frame.strip:SetPoint("BOTTOMLEFT")
  frame.strip:SetWidth(STRIP)
  -- Rebuild when Shift is pressed or released.
  frame:SetScript("OnUpdate", function()
    if not owner then return end
    if Tooltip.shiftDown() ~= shiftShown then Tooltip.Show(owner) return end
    if ns.Settings().tooltipAnchor == "cursor" then followCursor() end
  end)
end

local function nextString()
  usedStrings = usedStrings + 1
  local fs = strings[usedStrings]
  if not fs then
    fs = frame:CreateFontString(nil, "OVERLAY")
    strings[usedStrings] = fs
  end
  fs:ClearAllPoints()
  fs:Show()
  return fs
end

local function nextTexture()
  usedTextures = usedTextures + 1
  local tex = textures[usedTextures]
  if not tex then
    tex = frame:CreateTexture(nil, "ARTWORK")
    textures[usedTextures] = tex
  end
  tex:ClearAllPoints()
  tex:SetVertexColor(1, 1, 1, 1)
  tex:Show()
  return tex
end

local function reset()
  for i = 1, #strings do strings[i]:Hide() end
  for i = 1, #textures do textures[i]:Hide() end
  usedStrings, usedTextures = 0, 0
end

local function colorFor(role, colors)
  if role == "rested" then return colors.rested end
  if role == "quest" then return colors.quest end
  if role == "muted" then return MUTED end
  return colors.text
end

local CURSOR_OFFSET = 18

-- Near the mouse ("cursor" anchor), kept on screen by SetClampedToScreen.
local function followCursor()
  local x, y = GetCursorPosition()
  local scale = frame:GetEffectiveScale()
  frame:ClearAllPoints()
  frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / scale + CURSOR_OFFSET, y / scale + CURSOR_OFFSET)
end

local function place(anchor)
  local s = ns.Settings()
  if s.tooltipAnchor == "cursor" then
    followCursor()
    return
  end
  frame:ClearAllPoints()
  -- Keep clear of the bar's texts when they sit above or below it.
  local textRoom = s.barFontSize + 4
  local above = 8 + (s.textPosition == "above" and textRoom or 0)
  local below = 8 + (s.textPosition == "below" and textRoom or 0)
  local _, y = anchor:GetCenter()
  local screenMiddle = UIParent:GetHeight() * UIParent:GetEffectiveScale() / 2
  if y and y * anchor:GetEffectiveScale() < screenMiddle then
    frame:SetPoint("BOTTOM", anchor, "TOP", 0, above)
  else
    frame:SetPoint("TOP", anchor, "BOTTOM", 0, -below)
  end
end

function Tooltip.Show(anchor)
  if not frame then createFrame() end
  owner = anchor
  shiftShown = Tooltip.shiftDown()

  local s = ns.Settings()
  local colors = (ns.bar and ns.bar.colors) or Palettes.colors(s.palette, {})
  local content = TooltipContent.build(ns.source:Get(), s, ns.CharData().history,
    ns.FormatOptions(), ns.L, shiftShown)

  local fontPath = Fonts.resolve(s.tooltipFont, Fonts.lsm())
  local size = s.tooltipFontSize
  local flags = Fonts.flags(s.tooltipFontOutline)
  local function style(fs, fontSize, color)
    Fonts.apply(fs, fontPath, fontSize, flags)
    fs:SetTextColor(color[1], color[2], color[3], 1)
  end

  reset()
  frame:SetScale(s.tooltipScale)
  frame.bg:SetColorTexture(0.05, 0.05, 0.07, s.tooltipBgOpacity)
  frame.strip:SetColorTexture(colors.accent[1], colors.accent[2], colors.accent[3], 1)

  local rowHeight = size + 5
  local y = -PAD_Y
  local width = MIN_WIDTH - PAD_LEFT - PAD_X

  -- Title line: level on the left, XP on the right.
  local title = nextString()
  style(title, size + 3, colors.text)
  title:SetText(content.title)
  title:SetPoint("TOPLEFT", PAD_LEFT, y)
  local subtitle = nextString()
  style(subtitle, size, MUTED)
  subtitle:SetText(content.subtitle)
  subtitle:SetPoint("TOPRIGHT", -PAD_X, y - 2)
  width = math.max(width, title:GetStringWidth() + GAP + subtitle:GetStringWidth())
  y = y - (size + 3) - 6

  local separators = {}
  for _, group in ipairs(content.groups) do
    -- A thin line opens every group, the first one included (it sits under the title).
    local sep = nextTexture()
    sep:SetColorTexture(SEPARATOR[1], SEPARATOR[2], SEPARATOR[3], SEPARATOR[4])
    sep:SetHeight(1)
    separators[#separators + 1] = { tex = sep, y = y - 3 }
    y = y - SEPARATOR_SPACE
    for _, row in ipairs(group) do
      local label = nextString()
      style(label, size, row.kind == "history" and colors.text or MUTED)
      label:SetText(row.label)
      label:SetPoint("TOPLEFT", PAD_LEFT, y)
      local rowWidth = label:GetStringWidth()

      if row.value then
        local value = nextString()
        style(value, size, colorFor(row.color, colors))
        value:SetText(row.value)
        value:SetPoint("TOPRIGHT", -PAD_X, y)
        rowWidth = rowWidth + GAP + value:GetStringWidth()

        if row.kind == "history" then
          local bar = nextTexture()
          bar:SetTexture(Styles.TIPBAR)
          bar:SetVertexColor(colors.accent[1], colors.accent[2], colors.accent[3], 0.9)
          bar:SetSize(math.max(2, row.ratio * HISTORY_BAR), size - 3)
          bar:SetPoint("RIGHT", value, "LEFT", -8, 0)
          rowWidth = rowWidth + HISTORY_BAR + 8
        end
      end
      width = math.max(width, rowWidth)
      y = y - rowHeight
    end
  end

  if content.hint then
    y = y - 4
    local hint = nextString()
    style(hint, math.max(8, size - 2), MUTED)
    hint:SetText(content.hint)
    hint:SetPoint("TOPLEFT", PAD_LEFT, y)
    width = math.max(width, hint:GetStringWidth())
    y = y - size
  end

  local totalWidth = PAD_LEFT + width + PAD_X
  for _, sep in ipairs(separators) do
    sep.tex:SetPoint("TOPLEFT", PAD_LEFT, sep.y)
    sep.tex:SetWidth(width)
  end
  frame:SetSize(totalWidth, -y + PAD_Y)
  place(anchor)
  frame:Show()
end

function Tooltip.Hide()
  owner = nil
  if frame then frame:Hide() end
end

function Tooltip.IsShownFor(anchor)
  return frame ~= nil and frame:IsShown() and owner == anchor
end
