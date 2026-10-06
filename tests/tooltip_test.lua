local ns = newNamespace()
loadAddonFile("Calc.lua", ns)
loadAddonFile("History.lua", ns)
loadAddonFile("TooltipContent.lua", ns)
loadAddonFile("Styles.lua", ns)
loadAddonFile("Fonts.lua", ns)
loadAddonFile("Tooltip.lua", ns)
local Tooltip = ns.Tooltip

test("Shift state is a boolean whatever the client returns", function()
  local previous = _G.IsShiftKeyDown
  for _, raw in ipairs({ 1, true }) do
    _G.IsShiftKeyDown = function() return raw end
    eq(Tooltip.shiftDown(), true)
  end
  for _, raw in ipairs({ false, 0 == 1 }) do
    _G.IsShiftKeyDown = function() return raw end
    eq(Tooltip.shiftDown(), false)
  end
  _G.IsShiftKeyDown = function() return nil end
  eq(Tooltip.shiftDown(), false)
  _G.IsShiftKeyDown = previous
end)

test("preview scale: the user's scale when it fits, smaller when it would overflow", function()
  eq(Tooltip.fitScale(1, 220, 200, 245, 380), 1)
  near(Tooltip.fitScale(1.5, 220, 200, 245, 380), 245 / 220)
  near(Tooltip.fitScale(2, 220, 300, 400, 380), 380 / 300)
  eq(Tooltip.fitScale(0.8, 220, 200, 245, 380), 0.8)
  eq(Tooltip.fitScale(1, 0, 0, 245, 380), 1)
end)
