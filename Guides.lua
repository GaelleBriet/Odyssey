local ADDON, ns = ...

-- Positioning guides: a vertical line at the screen's horizontal centre and a horizontal one
-- at its vertical centre, shown while a bar is unlocked or being dragged. A line lights up
-- while the dragged bar is snapped to it.
local Guides = {}
ns.Guides = Guides

local frame, vertical, horizontal
local users = {} -- bars currently asking for the guides

local IDLE = { 1, 1, 1, 0.25 }
local SNAPPED = { 0.73, 0.55, 1, 0.95 }

local function create()
  frame = CreateFrame("Frame", nil, UIParent)
  frame:SetAllPoints(UIParent)
  frame:SetFrameStrata("BACKGROUND")
  frame:EnableMouse(false)
  vertical = frame:CreateTexture(nil, "OVERLAY")
  vertical:SetWidth(2)
  vertical:SetPoint("TOP", frame, "TOP")
  vertical:SetPoint("BOTTOM", frame, "BOTTOM")
  horizontal = frame:CreateTexture(nil, "OVERLAY")
  horizontal:SetHeight(2)
  horizontal:SetPoint("LEFT", frame, "LEFT")
  horizontal:SetPoint("RIGHT", frame, "RIGHT")
  frame:Hide()
end

local function paint(tex, color) tex:SetColorTexture(color[1], color[2], color[3], color[4]) end

function Guides.Highlight(snappedX, snappedY)
  if not frame then return end
  paint(vertical, snappedX and SNAPPED or IDLE)
  paint(horizontal, snappedY and SNAPPED or IDLE)
end

-- `who` (a bar) wants the guides shown (true) or no longer needs them (false).
function Guides.Request(who, wanted)
  if not frame then create() end
  users[who] = wanted or nil
  if next(users) then
    Guides.Highlight(false, false)
    frame:Show()
  else
    frame:Hide()
  end
end
