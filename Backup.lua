local ADDON, ns = ...

-- A per-character copy of what cannot be rebuilt (the leveling history), kept in a separate
-- saved variable (OdysseyCharDB). If the main save comes back without this character's
-- history (the Forever beta once failed to load saved variables), the copy is put back.
local Backup = {}
ns.Backup = Backup

function Backup.save(charDB, data)
  charDB.history = data.history
  charDB.profile = data.profile
  charDB.saved = true
end

local function hasLevels(history)
  return type(history) == "table" and type(history.levels) == "table" and next(history.levels) ~= nil
end

-- Returns "restored" when the history was put back, otherwise "ok".
function Backup.restore(db, charDB, key)
  if type(charDB) ~= "table" or not hasLevels(charDB.history) then return "ok" end
  db.chars = type(db.chars) == "table" and db.chars or {}
  local data = db.chars[key]
  if type(data) == "table" and hasLevels(data.history) then return "ok" end
  db.chars[key] = type(data) == "table" and data or {}
  db.chars[key].history = charDB.history
  return "restored"
end
