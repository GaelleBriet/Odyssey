local function keysOf(t)
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end
  table.sort(keys)
  return keys
end

test("enUS falls back to the key for unknown strings", function()
  local ns = newNamespace()
  loadAddonFile("Locales/enUS.lua", ns)
  eq(ns.L["definitely not translated"], "definitely not translated")
end)

test("frFR defines exactly the keys of enUS", function()
  local en = newNamespace()
  loadAddonFile("Locales/enUS.lua", en)

  local fr = newNamespace()
  fr.L = {}
  local previous = _G.GetLocale
  _G.GetLocale = function() return "frFR" end
  loadAddonFile("Locales/frFR.lua", fr)
  _G.GetLocale = previous

  local enKeys = {}
  for k in pairs(en.L) do enKeys[k] = true end
  eq(keysOf(fr.L), keysOf(enKeys))
end)

test("frFR does nothing on other locales", function()
  local ns = newNamespace()
  loadAddonFile("Locales/enUS.lua", ns)
  local previous = _G.GetLocale
  _G.GetLocale = function() return "enUS" end
  loadAddonFile("Locales/frFR.lua", ns)
  _G.GetLocale = previous
  eq(ns.L["Level %d"], "Level %d")
end)
