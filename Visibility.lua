local ADDON, ns = ...

-- Bar opacity for the "show on mouseover" option. Pure: the bar passes its state in.
local Visibility = {}
ns.Visibility = Visibility

local FADE_SPEED = 4 -- full fade in a quarter of a second

-- state = { hover, moving, tooltip }
-- The bar's own opacity (barAlpha) scales every state.
function Visibility.alpha(settings, state)
  local base = settings.barAlpha or 1
  if settings.visibility ~= "mouseover" then return base end
  if state.hover or state.moving or state.tooltip or not settings.locked then return base end
  return base * (settings.fadedAlpha or 0)
end

function Visibility.step(current, target, elapsed)
  local delta = FADE_SPEED * elapsed
  if current < target then return math.min(target, current + delta) end
  if current > target then return math.max(target, current - delta) end
  return current
end
