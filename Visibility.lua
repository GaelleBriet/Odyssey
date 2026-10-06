local ADDON, ns = ...

-- Bar opacity for the "show on mouseover" option. Pure: the bar passes its state in.
local Visibility = {}
ns.Visibility = Visibility

local FADE_SPEED = 4 -- full fade in a quarter of a second

-- state = { hover, moving, tooltip }
local FADED = 0.3 -- opacity of a bar faded by a condition (combat, instance)

-- A condition (combat, instance, death) that hides the bar entirely; such a bar also stops
-- catching the mouse. An unlocked bar ignores conditions so it can be placed.
function Visibility.blocked(settings, state)
  if not settings.locked then return false end
  if state.dead and settings.hideWhenDead then return true end
  if state.combat and settings.combatMode == "hide" then return true end
  if state.instance and settings.instanceMode == "hide" then return true end
  return false
end

-- The bar's own opacity (barAlpha) scales every state.
function Visibility.alpha(settings, state)
  local base = settings.barAlpha or 1
  if Visibility.blocked(settings, state) then return 0 end
  if settings.locked and ((state.combat and settings.combatMode == "fade")
      or (state.instance and settings.instanceMode == "fade")) then
    base = base * FADED
  end
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
