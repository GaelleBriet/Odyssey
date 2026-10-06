local ADDON, ns = ...

local Fonts = {}
ns.Fonts = Fonts

local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\Fonts\\"

Fonts.DEFAULT = "Friz Quadrata"

local GAME = {
  { name = "Friz Quadrata", path = "Fonts\\FRIZQT__.TTF" },
  { name = "Arial Narrow", path = "Fonts\\ARIALN.TTF" },
  { name = "Skurri", path = "Fonts\\SKURRI.TTF" },
  { name = "Morpheus", path = "Fonts\\MORPHEUS.TTF" },
}

-- SIL Open Font License fonts shipped in Media/Fonts (licence files next to them).
local BUNDLED = {
  { name = "Nunito", path = MEDIA .. "Nunito-Bold.ttf" },
  { name = "Barlow Condensed", path = MEDIA .. "BarlowCondensed-SemiBold.ttf" },
  { name = "Cinzel", path = MEDIA .. "Cinzel-Bold.ttf" },
  { name = "Inter", path = MEDIA .. "Inter-SemiBold.ttf" },
}

local OUTLINES = { NONE = "", OUTLINE = "OUTLINE", THICKOUTLINE = "THICKOUTLINE" }

local function own(name)
  for _, f in ipairs(GAME) do if f.name == name then return f.path end end
  for _, f in ipairs(BUNDLED) do if f.name == name then return f.path end end
  return nil
end

-- LibSharedMedia only when another addon already loaded it; Odyssey never depends on it.
function Fonts.lsm()
  if not LibStub then return nil end
  return LibStub("LibSharedMedia-3.0", true)
end

-- Every font that can be picked: game fonts, Odyssey's fonts, then LibSharedMedia's.
function Fonts.list(lsm)
  local list, seen = {}, {}
  for _, f in ipairs(GAME) do
    list[#list + 1] = { name = f.name, path = f.path, source = "game" }
    seen[f.name] = true
  end
  for _, f in ipairs(BUNDLED) do
    list[#list + 1] = { name = f.name, path = f.path, source = "odyssey" }
    seen[f.name] = true
  end
  if lsm then
    for _, name in ipairs(lsm:List("font")) do
      if not seen[name] then
        list[#list + 1] = { name = name, path = lsm:Fetch("font", name, true), source = "shared" }
        seen[name] = true
      end
    end
  end
  return list
end

-- File path for a font name; an unknown name (addon uninstalled) falls back to the default.
function Fonts.resolve(name, lsm)
  if name then
    local path = own(name)
    if path then return path end
    if lsm then
      path = lsm:Fetch("font", name, true)
      if path then return path end
    end
  end
  return own(Fonts.DEFAULT)
end

local function normalize(path)
  if type(path) ~= "string" then return nil end
  return (path:lower():gsub("/", "\\"))
end

-- Sets a font and checks the result with GetFont rather than SetFont's return value,
-- which differs between clients; a font that did not load falls back to the default.
function Fonts.apply(fs, path, size, flags)
  fs:SetFont(path, size, flags)
  if normalize((fs:GetFont())) ~= normalize(path) then
    fs:SetFont(own(Fonts.DEFAULT), size, flags)
  end
end

function Fonts.flags(outline)
  return OUTLINES[outline] or ""
end

function Fonts.registerBundled(lsm)
  if not lsm then return end
  for _, f in ipairs(BUNDLED) do lsm:Register("font", f.name, f.path) end
end
