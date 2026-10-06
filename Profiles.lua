local ADDON, ns = ...
local Defaults = ns.Defaults

-- Named profiles. db = OdysseyDB: profiles[name] = full settings (XP + reputation),
-- profileKeys[character] = name, defaultProfile = name used by characters without a choice.
-- Pure: every function works on the db table it is given.
local Profiles = {}
ns.Profiles = Profiles

local function trim(name)
  if type(name) ~= "string" then return "" end
  return (name:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function validNewName(db, name)
  name = trim(name)
  if name == "" then return nil, "empty" end
  if db.profiles[name] then return nil, "exists" end
  return name
end

function Profiles.list(db)
  local names = {}
  for name in pairs(db.profiles) do names[#names + 1] = name end
  table.sort(names)
  return names
end

-- The profile a character uses: its choice if that profile still exists, otherwise the default.
function Profiles.activeName(db, charKey, defaultName)
  local chosen = db.profileKeys[charKey]
  if chosen and db.profiles[chosen] then return chosen end
  if db.defaultProfile and db.profiles[db.defaultProfile] then return db.defaultProfile end
  local first = Profiles.list(db)[1]
  if first then
    db.defaultProfile = first
    return first
  end
  -- No profile at all: create the default one.
  local name = defaultName or "Default"
  db.profiles[name] = Defaults.copy(Defaults.settings)
  db.defaultProfile = name
  return name
end

function Profiles.active(db, charKey, defaultName)
  return db.profiles[Profiles.activeName(db, charKey, defaultName)]
end

function Profiles.use(db, charKey, name)
  if not db.profiles[name] then return false, "missing" end
  db.profileKeys[charKey] = name
  return true
end

-- New profile from `source` settings (copied) or from the defaults.
function Profiles.create(db, name, source)
  local valid, err = validNewName(db, name)
  if not valid then return false, err end
  db.profiles[valid] = Defaults.copy(source or Defaults.settings)
  return true, valid
end

function Profiles.copyFrom(db, target, from)
  if target == from then return false, "same" end
  if not db.profiles[target] or not db.profiles[from] then return false, "missing" end
  db.profiles[target] = Defaults.copy(db.profiles[from])
  return true
end

function Profiles.rename(db, old, new)
  if not db.profiles[old] then return false, "missing" end
  local valid, err = validNewName(db, new)
  if not valid then return false, err end
  db.profiles[valid], db.profiles[old] = db.profiles[old], nil
  for charKey, name in pairs(db.profileKeys) do
    if name == old then db.profileKeys[charKey] = valid end
  end
  if db.defaultProfile == old then db.defaultProfile = valid end
  return true, valid
end

-- Deletes a profile that is neither the current character's nor the last one.
function Profiles.delete(db, name, charKey)
  if not db.profiles[name] then return false, "missing" end
  if Profiles.activeName(db, charKey) == name then return false, "active" end
  if #Profiles.list(db) <= 1 then return false, "last" end
  db.profiles[name] = nil
  for key, chosen in pairs(db.profileKeys) do
    if chosen == name then db.profileKeys[key] = nil end
  end
  if db.defaultProfile == name then
    db.defaultProfile = Profiles.activeName(db, charKey)
  end
  return true
end

function Profiles.reset(db, name)
  if not db.profiles[name] then return false, "missing" end
  db.profiles[name] = Defaults.copy(Defaults.settings)
  return true
end
