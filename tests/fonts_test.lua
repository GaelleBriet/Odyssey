local ns = newNamespace()
loadAddonFile("Fonts.lua", ns)
local Fonts = ns.Fonts

local function fakeLSM(fonts)
  local lsm = { fonts = fonts or {}, registered = {} }
  function lsm:List(kind)
    local names = {}
    for name in pairs(self.fonts) do names[#names + 1] = name end
    table.sort(names)
    return names
  end
  function lsm:Fetch(kind, name, noDefault) return self.fonts[name] end
  function lsm:Register(kind, name, path)
    self.registered[#self.registered + 1] = name
    self.fonts[name] = path
    return true
  end
  return lsm
end

local function names(list)
  local out = {}
  for _, f in ipairs(list) do out[#out + 1] = f.name end
  return out
end

test("without LibSharedMedia the list is game fonts then bundled fonts", function()
  eq(names(Fonts.list(nil)), {
    "Friz Quadrata", "Arial Narrow", "Skurri", "Morpheus",
    "Nunito", "Barlow Condensed", "Cinzel", "Inter",
  })
  eq(Fonts.list(nil)[1].source, "game")
  eq(Fonts.list(nil)[5].source, "odyssey")
  truthy(Fonts.list(nil)[5].path:find("Media\\Fonts\\Nunito%-Bold%.ttf$"))
end)

test("LibSharedMedia fonts are appended without duplicates", function()
  local lsm = fakeLSM({ ["Expressway"] = "Interface\\AddOns\\X\\exp.ttf", ["Arial Narrow"] = "Fonts\\ARIALN.TTF" })
  local list = Fonts.list(lsm)
  eq(#list, 9)
  eq(list[9].name, "Expressway")
  eq(list[9].source, "shared")
end)

test("resolve finds game, bundled and shared fonts, and falls back to the default", function()
  local lsm = fakeLSM({ ["Expressway"] = "Interface\\AddOns\\X\\exp.ttf" })
  eq(Fonts.resolve("Skurri", nil), "Fonts\\SKURRI.TTF")
  truthy(Fonts.resolve("Cinzel", nil):find("Cinzel%-Bold%.ttf$"))
  eq(Fonts.resolve("Expressway", lsm), "Interface\\AddOns\\X\\exp.ttf")
  eq(Fonts.resolve("Expressway", nil), "Fonts\\FRIZQT__.TTF")
  eq(Fonts.resolve("Gone", lsm), "Fonts\\FRIZQT__.TTF")
  eq(Fonts.resolve(nil, nil), "Fonts\\FRIZQT__.TTF")
end)

test("outline flags", function()
  eq(Fonts.flags("NONE"), "")
  eq(Fonts.flags("OUTLINE"), "OUTLINE")
  eq(Fonts.flags("THICKOUTLINE"), "THICKOUTLINE")
  eq(Fonts.flags("bogus"), "")
end)

test("bundled fonts are registered in LibSharedMedia when it is present", function()
  local lsm = fakeLSM()
  Fonts.registerBundled(lsm)
  eq(lsm.registered, { "Nunito", "Barlow Condensed", "Cinzel", "Inter" })
  Fonts.registerBundled(nil)
end)

test("lsm() returns the library only when an addon loaded it", function()
  local previous = _G.LibStub
  _G.LibStub = nil
  eq(Fonts.lsm(), nil)
  local lib = fakeLSM()
  _G.LibStub = function(name, silent)
    if name == "LibSharedMedia-3.0" then return lib end
  end
  eq(Fonts.lsm(), lib)
  _G.LibStub = previous
end)
