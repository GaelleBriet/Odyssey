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
