local ADDON, ns = ...
local Calc, Texts, Styles, Themes = ns.Calc, ns.Texts, ns.Styles, ns.Themes

local Bar = {}
Bar.__index = Bar
ns.Bar = Bar

local EASE_SPEED = 8
local LAYERS = { "fill", "quest", "rested" }

local function setWidth(tex, w)
  if w < 0.5 then
    tex:Hide()
  else
    tex:SetWidth(w)
    tex:Show()
  end
end

function Bar.create(source)
  local self = setmetatable({}, Bar)
  self.source = source

  local f = CreateFrame("Frame", "OdysseyBar", UIParent)
  self.frame = f
  f:SetFrameStrata("MEDIUM")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")

  self.bg = f:CreateTexture(nil, "BACKGROUND")
  self.rested = f:CreateTexture(nil, "BORDER")
  self.quest = f:CreateTexture(nil, "ARTWORK", nil, 0)
  self.fill = f:CreateTexture(nil, "ARTWORK", nil, 1)
  self.spark = f:CreateTexture(nil, "OVERLAY")
  self.spark:SetBlendMode("ADD")
  self.border = {}
  for i = 1, 4 do self.border[i] = f:CreateTexture(nil, "OVERLAY") end

  local function fontString(justify)
    local fs = f:CreateFontString(nil, "OVERLAY")
    fs:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    fs:SetJustifyH(justify)
    return fs
  end
  self.textLeft = fontString("LEFT")
  self.textCenter = fontString("CENTER")
  self.textRight = fontString("RIGHT")
  self.textLeft:SetPoint("LEFT", f, "LEFT", 6, 0)
  self.textCenter:SetPoint("CENTER", f, "CENTER", 0, 0)
  self.textRight:SetPoint("RIGHT", f, "RIGHT", -6, 0)

  self.current = { fill = 0, quest = 0, rested = 0 }
  self.target = { fill = 0, quest = 0, rested = 0 }
  self.tooltipTimer = 0

  f:SetScript("OnDragStart", function()
    if not ns.Settings().locked then f:StartMoving() end
  end)
  f:SetScript("OnDragStop", function()
    f:StopMovingOrSizing()
    if not ns.Settings().locked then self:SavePosition() end
  end)
  f:SetScript("OnEnter", function()
    if ns.Tooltip then ns.Tooltip.Show(f) end
  end)
  f:SetScript("OnLeave", function() GameTooltip:Hide() end)
  f:SetScript("OnMouseUp", function(_, button)
    if button == "RightButton" and ns.OpenOptions then ns.OpenOptions() end
  end)
  f:SetScript("OnUpdate", function(_, elapsed) self:OnUpdate(elapsed) end)

  source:Subscribe(function() self:Update() end)
  self:ApplySettings()
  self:Update()
  return self
end

function Bar:SavePosition()
  local point, relativeTo, relativePoint, x, y = self.frame:GetPoint()
  local relativeName = (relativeTo and relativeTo.GetName and relativeTo:GetName()) or "UIParent"
  ns.Settings().point = { point, relativeName, relativePoint, x, y }
end

function Bar:ApplySettings()
  local s = ns.Settings()
  local f = self.frame
  f:SetSize(s.width, s.height)
  f:SetScale(s.scale)
  local p = s.point
  f:ClearAllPoints()
  f:SetPoint(p[1], _G[p[2]] or UIParent, p[3], p[4], p[5])

  self.style = Styles.defs[s.style] or Styles.defs.glossy
  local b = self.style.border
  self.innerWidth = s.width - 2 * b

  local _, class = UnitClass("player")
  local rc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  local colors = Themes.colors(s.theme, {
    classColor = rc and { rc.r, rc.g, rc.b } or nil,
    faction = UnitFactionGroup("player"),
  })
  self.colors = colors

  self.bg:ClearAllPoints()
  self.bg:SetAllPoints(f)
  self.bg:SetColorTexture(colors.bg[1], colors.bg[2], colors.bg[3], 0.9)

  local e = self.border
  for i = 1, 4 do
    e[i]:ClearAllPoints()
    e[i]:SetColorTexture(colors.border[1], colors.border[2], colors.border[3], 1)
  end
  e[1]:SetPoint("TOPLEFT"); e[1]:SetPoint("TOPRIGHT"); e[1]:SetHeight(b)
  e[2]:SetPoint("BOTTOMLEFT"); e[2]:SetPoint("BOTTOMRIGHT"); e[2]:SetHeight(b)
  e[3]:SetPoint("TOPLEFT"); e[3]:SetPoint("BOTTOMLEFT"); e[3]:SetWidth(b)
  e[4]:SetPoint("TOPRIGHT"); e[4]:SetPoint("BOTTOMRIGHT"); e[4]:SetWidth(b)

  for _, tex in ipairs({ self.rested, self.quest, self.fill }) do
    tex:ClearAllPoints()
    tex:SetPoint("TOPLEFT", f, "TOPLEFT", b, -b)
    tex:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", b, b)
    tex:SetTexture(self.style.texture)
  end
  self.fill:SetVertexColor(colors.fill[1], colors.fill[2], colors.fill[3], 1)
  self.rested:SetVertexColor(colors.rested[1], colors.rested[2], colors.rested[3], 0.9)
  self.quest:SetVertexColor(colors.quest[1], colors.quest[2], colors.quest[3], 0.55)

  self.spark:SetTexture(Styles.SPARK)
  self.spark:SetSize(14, s.height * 2)

  local size = math.max(8, math.min(14, s.height - 4))
  for _, fs in ipairs({ self.textLeft, self.textCenter, self.textRight }) do
    fs:SetFont(STANDARD_TEXT_FONT, size, "OUTLINE")
  end

  self:Layout()
end

function Bar:Layout()
  local inner = self.innerWidth
  setWidth(self.rested, self.current.rested * inner)
  setWidth(self.quest, self.current.quest * inner)
  setWidth(self.fill, self.current.fill * inner)

  local showSpark = self.style.spark and self.current.fill > 0.002 and self.current.fill < 0.998
  if showSpark then
    self.spark:ClearAllPoints()
    self.spark:SetPoint("CENTER", self.fill, "RIGHT", 0, 0)
    self.spark:Show()
  else
    self.spark:Hide()
  end
end

function Bar:Update()
  local s = ns.Settings()
  local snap = self.source:Get()
  self.snap = snap

  local hidden = snap.isMaxLevel and s.maxLevelBehavior == "hide"
  if hidden then self.frame:Hide() else self.frame:Show() end
  ns.Compat.setNativeXPBarHidden(s.hideNativeBar and not hidden)

  local questTotal = snap.quests and snap.quests.total or 0
  self.target.fill = Calc.fraction(snap.xp, snap.xpMax)
  self.target.quest = Calc.fraction(snap.xp + questTotal, snap.xpMax)
  self.target.rested = Calc.fraction(snap.xp + snap.rested, snap.xpMax)
  -- Snap back after a level-up instead of sliding backwards.
  if self.target.fill < self.current.fill then self.current.fill = self.target.fill end

  local L, opts = ns.L, ns.FormatOptions()
  if snap.isMaxLevel then
    self.textLeft:SetText(Texts.render("level", snap, opts, L))
    self.textCenter:SetText(L["Max level"])
    self.textRight:SetText("")
  else
    self.textLeft:SetText(Texts.render(s.textLeft, snap, opts, L))
    self.textCenter:SetText(Texts.render(s.textCenter, snap, opts, L))
    self.textRight:SetText(Texts.render(s.textRight, snap, opts, L))
  end
  self:Layout()
end

function Bar:OnUpdate(elapsed)
  local k = math.min(1, elapsed * EASE_SPEED)
  local moved = false
  for _, key in ipairs(LAYERS) do
    local c, t = self.current[key], self.target[key]
    if c ~= t then
      c = c + (t - c) * k
      if math.abs(t - c) < 0.0005 then c = t end
      self.current[key] = c
      moved = true
    end
  end
  if moved then self:Layout() end

  -- Keep the tooltip live while the mouse rests on the bar.
  self.tooltipTimer = self.tooltipTimer + elapsed
  if self.tooltipTimer >= 1 then
    self.tooltipTimer = 0
    if ns.Tooltip and GameTooltip:IsShown() and GameTooltip:GetOwner() == self.frame then
      ns.Tooltip.Show(self.frame)
    end
  end
end
