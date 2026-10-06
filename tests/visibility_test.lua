local ns = newNamespace()
loadAddonFile("Visibility.lua", ns)
local V = ns.Visibility

local function settings(visibility, faded, locked)
  return { visibility = visibility, fadedAlpha = faded, locked = locked ~= false }
end

test("always visible ignores the mouse", function()
  eq(V.alpha(settings("always", 0), {}), 1)
end)

test("mouseover: faded until hovered", function()
  eq(V.alpha(settings("mouseover", 0.3), {}), 0.3)
  eq(V.alpha(settings("mouseover", 0), { hover = true }), 1)
end)

test("mouseover: fully shown while moving, while its tooltip is open, or while unlocked", function()
  eq(V.alpha(settings("mouseover", 0), { moving = true }), 1)
  eq(V.alpha(settings("mouseover", 0), { tooltip = true }), 1)
  eq(V.alpha(settings("mouseover", 0, false), {}), 1)
end)

test("step moves toward the target without overshooting", function()
  near(V.step(0, 1, 0.1), 0.4)
  eq(V.step(0.9, 1, 0.5), 1)
  eq(V.step(1, 0, 1), 0)
  eq(V.step(0.5, 0.5, 0.1), 0.5)
end)

test("the bar opacity scales every visibility state", function()
  local s = settings("always", 0)
  s.barAlpha = 0.6
  near(V.alpha(s, {}), 0.6)
  s.visibility, s.fadedAlpha = "mouseover", 0.5
  near(V.alpha(s, {}), 0.3)
  near(V.alpha(s, { hover = true }), 0.6)
end)
