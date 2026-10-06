local ADDON, ns = ...
local Calc, Texts, Styles, Palettes, Fonts, Visibility, TooltipContent =
  ns.Calc, ns.Texts, ns.Styles, ns.Palettes, ns.Fonts, ns.Visibility, ns.TooltipContent

local Bar = {}
Bar.__index = Bar
ns.Bar = Bar

local EASE_SPEED = 8
local LAYERS = { "fill", "quest", "rested" }
local TICKS = 19 -- enough lines for a tick every 5 %
local GLOW_OUTSET = 6

local function setWidth(tex, w)
  if w < 0.5 then
    tex:Hide()
  else
    tex:SetWidth(w)
    tex:Show()
  end
end

-- Horizontal gradient across the fill. Modern clients take ColorMixin objects, older ones
-- take raw numbers; without either the fill keeps the palette's end colour.
local function setGradient(tex, from, to)
  if tex.SetGradient and CreateColor then
    local ok = pcall(tex.SetGradient, tex, "HORIZONTAL",
      CreateColor(from[1], from[2], from[3], 1), CreateColor(to[1], to[2], to[3], 1))
    if ok then return end
  end
  if tex.SetGradient then
    local ok = pcall(tex.SetGradient, tex, "HORIZONTAL", from[1], from[2], from[3], to[1], to[2], to[3])
    if ok then return end
  end
  tex:SetVertexColor(to[1], to[2], to[3], 1)
end

local function setFont(fs, s, prefix)
  Fonts.apply(fs, Fonts.resolve(s[prefix .. "Font"], Fonts.lsm()), s[prefix .. "FontSize"],
    Fonts.flags(s[prefix .. "FontOutline"]))
end

-- opts.kind = "xp" (default) or "rep"; opts.settings() returns the settings table to use
-- (the XP settings, or the reputation view); opts.name names the frame.
-- opts.parent + opts.width make a preview bar (inside the settings window): same drawing,
-- no dragging, no tooltip, no visibility fading, no effect on the Blizzard bar.
function Bar.create(source, opts)
  opts = opts or {}
  local self = setmetatable({}, Bar)
  self.source = source
  self.kind = opts.kind or "xp"
  self.settings = opts.settings or ns.Settings
  self.preview = opts.parent ~= nil
  self.previewWidth = opts.width

  local f = CreateFrame("Frame", (not self.preview) and (opts.name or "OdysseyBar") or nil, opts.parent or UIParent)
  self.frame = f
  if not self.preview then
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
  end

  -- Soft drop shadow under the bar (smooth style), drawn from the glow texture in black.
  self.shadow = f:CreateTexture(nil, "BACKGROUND", nil, -3)
  self.shadow:SetTexture(Styles.GLOW)
  self.shadow:SetVertexColor(0, 0, 0, 0.7)
  self.shadow:SetPoint("TOPLEFT", f, "TOPLEFT", -5, 2)
  self.shadow:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 5, -6)
  -- The border is a hollow outline so a see-through background stays see-through:
  -- four edge strips for square corners, or a ring-masked texture for rounded ones.
  self.borderTex = f:CreateTexture(nil, "BACKGROUND", nil, -2)
  self.edges = {}
  for i = 1, 4 do self.edges[i] = f:CreateTexture(nil, "BACKGROUND", nil, -2) end
  self.bg = f:CreateTexture(nil, "BACKGROUND", nil, 0)
  self.glow = f:CreateTexture(nil, "BACKGROUND", nil, 1)
  self.glow:SetTexture(Styles.GLOW)
  self.glow:SetBlendMode("ADD")
  self.rested = f:CreateTexture(nil, "BORDER")
  self.quest = f:CreateTexture(nil, "ARTWORK", nil, 0)
  self.fill = f:CreateTexture(nil, "ARTWORK", nil, 1)
  self.gloss = f:CreateTexture(nil, "ARTWORK", nil, 2)
  self.gloss:SetTexture(Styles.GLOSS)
  self.spark = f:CreateTexture(nil, "OVERLAY", nil, 1)
  self.spark:SetTexture(Styles.SPARK)
  self.spark:SetBlendMode("ADD")
  self.ticks = {}
  for i = 1, TICKS do self.ticks[i] = f:CreateTexture(nil, "OVERLAY", nil, 0) end

  -- Rounded corners need mask textures, which older clients lack: the bar is then square.
  if f.CreateMaskTexture then
    self.innerMask = f:CreateMaskTexture()
    self.innerMask:SetTexture(Styles.MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    self.outerMask = f:CreateMaskTexture()
    self.outerMask:SetAllPoints(f)
  end
  self.masked = false

  -- Texts live on a child frame so they always draw above every texture of the bar.
  local overlay = CreateFrame("Frame", nil, f)
  overlay:SetAllPoints(f)
  overlay:SetFrameLevel(f:GetFrameLevel() + 2)
  local function fontString(justify)
    local fs = overlay:CreateFontString(nil, "OVERLAY")
    fs:SetFont(Fonts.resolve(Fonts.DEFAULT, nil), 11, "OUTLINE")
    fs:SetJustifyH(justify)
    return fs
  end
  self.textLeft = fontString("LEFT")
  self.textCenter = fontString("CENTER")
  self.textRight = fontString("RIGHT")

  self.current = { fill = 0, quest = 0, rested = 0 }
  self.target = { fill = 0, quest = 0, rested = 0 }
  self.tooltipTimer = 0

  self.state = { hover = false, moving = false, tooltip = false }
  self.alpha = 1

  if not self.preview then
  -- Dragging is done by hand (not StartMoving) so the bar can snap to the screen centre.
  f:SetScript("OnDragStart", function()
    if self.settings().locked then return end
    local eff = f:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    local fx, fy = f:GetCenter()
    self.drag = { fx - cx / eff, fy - cy / eff }
    self.state.moving = true
    if ns.Guides then ns.Guides.Request(self, true) end
  end)
  f:SetScript("OnDragStop", function()
    if not self.drag then return end
    self.drag = nil
    self.state.moving = false
    self:SavePosition()
    if ns.Guides then ns.Guides.Request(self, not self.settings().locked) end
  end)
  f:SetScript("OnEnter", function()
    self.state.hover = true
    if ns.Tooltip then ns.Tooltip.Show(f, self) end
  end)
  f:SetScript("OnLeave", function()
    self.state.hover = false
    if ns.Tooltip then ns.Tooltip.Hide() end
  end)
  f:SetScript("OnMouseUp", function(_, button)
    if button == "RightButton" and ns.OpenOptions then ns.OpenOptions() end
  end)
  end
  f:SetScript("OnUpdate", function(_, elapsed) self:OnUpdate(elapsed) end)

  source:Subscribe(function() self:Update() end)
  self:ApplySettings()
  self:Update()
  return self
end

local SNAP_DISTANCE = 8

-- Screen centre in this frame's own coordinates.
function Bar:ScreenCenter()
  local ratio = UIParent:GetEffectiveScale() / self.frame:GetEffectiveScale()
  return UIParent:GetWidth() * ratio / 2, UIParent:GetHeight() * ratio / 2
end

-- One step of a drag: follow the cursor, stick to the centre lines unless Shift is held.
function Bar:DragStep()
  local f = self.frame
  local eff = f:GetEffectiveScale()
  local cx, cy = GetCursorPosition()
  local x, y = cx / eff + self.drag[1], cy / eff + self.drag[2]
  local snappedX, snappedY = false, false
  if not IsShiftKeyDown() then
    local midX, midY = self:ScreenCenter()
    x, snappedX = Calc.snapToCenter(x, midX, SNAP_DISTANCE)
    y, snappedY = Calc.snapToCenter(y, midY, SNAP_DISTANCE)
  end
  f:ClearAllPoints()
  f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
  if ns.Guides then ns.Guides.Highlight(snappedX, snappedY) end
end

function Bar:CenterHorizontally()
  local f = self.frame
  local _, y = f:GetCenter()
  local midX = self:ScreenCenter()
  f:ClearAllPoints()
  f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", midX, y)
  self:SavePosition()
end

function Bar:SavePosition()
  local point, relativeTo, relativePoint, x, y = self.frame:GetPoint()
  local relativeName = (relativeTo and relativeTo.GetName and relativeTo:GetName()) or "UIParent"
  self.settings().point = { point, relativeName, relativePoint, x, y }
end

function Bar:SetMasked(masked)
  if not self.innerMask or masked == self.masked then return end
  for _, tex in ipairs({ self.bg, self.rested, self.quest, self.fill, self.gloss }) do
    if masked then tex:AddMaskTexture(self.innerMask) else tex:RemoveMaskTexture(self.innerMask) end
  end
  if masked then self.borderTex:AddMaskTexture(self.outerMask) else self.borderTex:RemoveMaskTexture(self.outerMask) end
  self.masked = masked
end

function Bar:ApplySettings()
  local s = self.settings()
  local f = self.frame
  local width = self.preview and self.previewWidth or s.width
  f:SetSize(width, s.height)
  if not self.preview and ns.Guides then ns.Guides.Request(self, not s.locked) end
  if not self.preview then
    f:SetScale(s.scale)
    local p = s.point
    f:ClearAllPoints()
    f:SetPoint(p[1], _G[p[2]] or UIParent, p[3], p[4], p[5])
  end

  self.look = { glow = s.glow, spark = s.spark }
  local b = Styles.BORDER_SIZE[s.border] or 1
  self.innerWidth = width - 2 * b

  local _, class = UnitClass("player")
  local rc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  local colors = Palettes.effective(s.palette, {
    classColor = rc and { rc.r, rc.g, rc.b } or nil,
    faction = UnitFactionGroup("player"),
  }, s)
  self.colors = colors

  local rounded = s.corners == "rounded" and self.outerMask ~= nil
  local bc = colors.border
  self.borderTex:ClearAllPoints()
  self.borderTex:SetAllPoints(f)
  self.borderTex:SetColorTexture(bc[1], bc[2], bc[3], 1)
  if rounded and b > 0 then
    self.outerMask:SetTexture(Styles.RING[s.border] or Styles.RING.thin, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    self.borderTex:Show()
  else
    self.borderTex:Hide()
  end
  local e = self.edges
  for i = 1, 4 do
    e[i]:ClearAllPoints()
    e[i]:SetColorTexture(bc[1], bc[2], bc[3], 1)
    if not rounded and b > 0 then e[i]:Show() else e[i]:Hide() end
  end
  e[1]:SetPoint("TOPLEFT"); e[1]:SetPoint("TOPRIGHT"); e[1]:SetHeight(math.max(b, 1))
  e[2]:SetPoint("BOTTOMLEFT"); e[2]:SetPoint("BOTTOMRIGHT"); e[2]:SetHeight(math.max(b, 1))
  e[3]:SetPoint("TOPLEFT", 0, -b); e[3]:SetPoint("BOTTOMLEFT", 0, b); e[3]:SetWidth(math.max(b, 1))
  e[4]:SetPoint("TOPRIGHT", 0, -b); e[4]:SetPoint("BOTTOMRIGHT", 0, b); e[4]:SetWidth(math.max(b, 1))

  for _, tex in ipairs({ self.bg, self.rested, self.quest, self.fill }) do
    tex:ClearAllPoints()
    tex:SetPoint("TOPLEFT", f, "TOPLEFT", b, -b)
    tex:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", b, b)
  end
  self.bg:SetWidth(self.innerWidth)
  if self.preview then f:SetAlpha(s.barAlpha or 1) end
  self.bg:SetColorTexture(colors.bg[1], colors.bg[2], colors.bg[3], s.bgOpacity)
  if self.innerMask then
    self.innerMask:ClearAllPoints()
    self.innerMask:SetPoint("TOPLEFT", f, "TOPLEFT", b, -b)
    self.innerMask:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -b, b)
  end

  local texture = Styles.resolveTexture(s.texture, Fonts.lsm())
  for _, tex in ipairs({ self.rested, self.quest, self.fill }) do tex:SetTexture(texture) end
  setGradient(self.fill, colors.fill.from, colors.fill.to)
  -- Opaque, slightly toned down: the segments never blend into each other (see Layout).
  self.rested:SetVertexColor(colors.rested[1] * 0.85, colors.rested[2] * 0.85, colors.rested[3] * 0.85, 1)
  self.quest:SetVertexColor(colors.quest[1] * 0.85, colors.quest[2] * 0.85, colors.quest[3] * 0.85, 1)

  self.gloss:ClearAllPoints()
  self.gloss:SetPoint("TOPLEFT", f, "TOPLEFT", b, -b)
  self.gloss:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -b, b)
  if s.gloss then self.gloss:Show() else self.gloss:Hide() end
  if s.shadow then self.shadow:Show() else self.shadow:Hide() end

  local a = colors.accent
  self.glow:SetVertexColor(a[1], a[2], a[3], 0.85)
  self.spark:SetSize(14, s.height * 2)

  -- s.ticks = number of segments (10 or 20): one line between each pair of segments.
  local segments = s.ticks or 0
  for i, tick in ipairs(self.ticks) do
    tick:ClearAllPoints()
    if segments > 1 and i < segments then
      local x = b + self.innerWidth * i / segments
      tick:SetColorTexture(0, 0, 0, 0.75)
      tick:SetWidth(1)
      tick:SetPoint("TOP", f, "TOPLEFT", x, -b)
      tick:SetPoint("BOTTOM", f, "BOTTOMLEFT", x, b)
      tick:Show()
    else
      tick:Hide()
    end
  end

  self:SetMasked(s.corners == "rounded")

  for _, fs in ipairs({ self.textLeft, self.textCenter, self.textRight }) do
    fs:ClearAllPoints()
    setFont(fs, s, "bar")
    fs:SetTextColor(colors.text[1], colors.text[2], colors.text[3], 1)
  end
  local textRoom = s.barFontSize + 6
  if s.textPosition == "above" then
    self.textLeft:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 3)
    self.textCenter:SetPoint("BOTTOM", f, "TOP", 0, 3)
    self.textRight:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 0, 3)
    -- Let the mouse reach the bar through its text too.
    f:SetHitRectInsets(0, 0, -textRoom, 0)
  elseif s.textPosition == "below" then
    self.textLeft:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, -3)
    self.textCenter:SetPoint("TOP", f, "BOTTOM", 0, -3)
    self.textRight:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 0, -3)
    f:SetHitRectInsets(0, 0, 0, -textRoom)
  else
    self.textLeft:SetPoint("LEFT", f, "LEFT", 6, 0)
    self.textCenter:SetPoint("CENTER", f, "CENTER", 0, 0)
    self.textRight:SetPoint("RIGHT", f, "RIGHT", -6, 0)
    f:SetHitRectInsets(0, 0, 0, 0)
  end

  self:Layout()
end

function Bar:Layout()
  local inner = self.innerWidth
  -- The shorter segment goes on top so both stay visible as clean bands.
  if Calc.topSegment(self.current) == "rested" then
    self.quest:SetDrawLayer("BORDER", 0)
    self.rested:SetDrawLayer("ARTWORK", 0)
  else
    self.rested:SetDrawLayer("BORDER", 0)
    self.quest:SetDrawLayer("ARTWORK", 0)
  end
  setWidth(self.rested, self.current.rested * inner)
  setWidth(self.quest, self.current.quest * inner)
  setWidth(self.fill, self.current.fill * inner)

  local fillShown = self.current.fill * inner >= 0.5
  if self.look.glow and fillShown then
    self.glow:ClearAllPoints()
    self.glow:SetPoint("TOPLEFT", self.fill, "TOPLEFT", -GLOW_OUTSET, GLOW_OUTSET)
    self.glow:SetPoint("BOTTOMRIGHT", self.fill, "BOTTOMRIGHT", GLOW_OUTSET, -GLOW_OUTSET)
    self.glow:Show()
  else
    self.glow:Hide()
  end

  if self.look.spark and fillShown and self.current.fill < 0.998 then
    self.spark:ClearAllPoints()
    self.spark:SetPoint("CENTER", self.fill, "RIGHT", 0, 0)
    self.spark:Show()
  else
    self.spark:Hide()
  end
end

-- Whether the bar is shown at all (outside the settings preview).
function Bar:ShouldShow(snap, s)
  if self.kind == "rep" then
    if not s.enabled then return false end
    return not (snap.none and s.noFaction == "hide")
  end
  return not (snap.isMaxLevel and s.maxLevelBehavior == "hide")
end

function Bar:Update()
  local s = self.settings()
  local snap = self.source:Get()
  self.snap = snap

  if not self.preview then
    local shown = self:ShouldShow(snap, s)
    if shown then self.frame:Show() else self.frame:Hide() end
    if self.kind == "xp" then ns.Compat.setNativeXPBarHidden(s.hideNativeBar and shown) end
  end

  if self.kind == "rep" then
    self.target = Calc.repTargets(snap)
    self.current.quest, self.current.rested = 0, 0
    -- Standing colour: the game's colour for the current standing, as a gradient.
    if s.colorMode == "standing" and not snap.none then
      local c = ns.Compat.standingColor(snap.standing)
      setGradient(self.fill, { c[1] * 0.7, c[2] * 0.7, c[3] * 0.7 }, c)
    end
  else
    self.target = Calc.barTargets(snap, s)
  end
  -- Snap back after a level-up (or a new standing) instead of sliding backwards.
  if self.target.fill < self.current.fill then self.current.fill = self.target.fill end

  local L, opts = ns.L, ns.FormatOptions(s)
  if self.kind == "rep" and snap.none then
    self.textLeft:SetText("")
    self.textCenter:SetText(L["No watched faction"])
    self.textRight:SetText("")
  elseif self.kind == "xp" and snap.isMaxLevel then
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

-- Tooltip content for this bar (used by Tooltip.Show).
function Bar:TooltipContent(detailed)
  local s = self.settings()
  if self.kind == "rep" then
    return TooltipContent.buildRep(self.source:Get(), s, ns.FormatOptions(s), ns.L, detailed)
  end
  return TooltipContent.build(self.source:Get(), s, ns.CharData().history, ns.FormatOptions(s), ns.L, detailed)
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

  if self.preview then return end
  if self.drag then self:DragStep() end

  -- Mouseover visibility: fade toward the target opacity.
  self.state.tooltip = ns.Tooltip and ns.Tooltip.IsShownFor(self.frame) or false
  local target = Visibility.alpha(self.settings(), self.state)
  if self.alpha ~= target then
    self.alpha = Visibility.step(self.alpha, target, elapsed)
    self.frame:SetAlpha(self.alpha)
  end

  -- Keep the tooltip live while the mouse rests on the bar.
  self.tooltipTimer = self.tooltipTimer + elapsed
  if self.tooltipTimer >= 1 then
    self.tooltipTimer = 0
    if ns.Tooltip and ns.Tooltip.IsShownFor(self.frame) then ns.Tooltip.Show(self.frame, self) end
  end
end
