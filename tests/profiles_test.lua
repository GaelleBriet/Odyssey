local ns = newNamespace()
loadAddonFile("Defaults.lua", ns)
loadAddonFile("Profiles.lua", ns)
local P, D = ns.Profiles, ns.Defaults

local function newDb()
  return { version = 4, profiles = { ["Défaut"] = { width = 480 } }, profileKeys = {}, defaultProfile = "Défaut" }
end

test("a character without a choice uses the default profile", function()
  local db = newDb()
  eq(P.activeName(db, "Realm-A"), "Défaut")
  eq(P.active(db, "Realm-A").width, 480)
end)

test("an empty database gets a default profile with default settings", function()
  local db = { profiles = {}, profileKeys = {} }
  eq(P.active(db, "Realm-A", "Défaut").width, D.settings.width)
  eq(db.defaultProfile, "Défaut")
  eq(P.list(db), { "Défaut" })
end)

test("use switches the character's profile; unknown names are refused", function()
  local db = newDb()
  db.profiles.Raid = { width = 800 }
  eq(P.use(db, "Realm-A", "Raid"), true)
  eq(P.active(db, "Realm-A").width, 800)
  eq(P.activeName(db, "Realm-B"), "Défaut")
  eq(P.use(db, "Realm-A", "Nope"), false)
  eq(P.activeName(db, "Realm-A"), "Raid")
end)

test("a character pointing at a vanished profile falls back to the default", function()
  local db = newDb()
  db.profileKeys["Realm-A"] = "Gone"
  eq(P.activeName(db, "Realm-A"), "Défaut")
end)

test("create copies the given settings, or the defaults", function()
  local db = newDb()
  eq(P.create(db, "Copie", db.profiles["Défaut"]), true)
  eq(db.profiles.Copie.width, 480)
  db.profiles.Copie.width = 1
  eq(db.profiles["Défaut"].width, 480)
  eq(P.create(db, "Neuf"), true)
  eq(db.profiles.Neuf.width, D.settings.width)
end)

test("create refuses empty and duplicate names, and trims spaces", function()
  local db = newDb()
  eq({ P.create(db, "   ") }, { false, "empty" })
  eq({ P.create(db, "Défaut") }, { false, "exists" })
  eq(P.create(db, "  Raid  "), true)
  truthy(db.profiles.Raid)
end)

test("copyFrom replaces the target's settings with a copy", function()
  local db = newDb()
  db.profiles.Raid = { width = 800, tooltip = { level = false } }
  eq(P.copyFrom(db, "Défaut", "Raid"), true)
  eq(db.profiles["Défaut"].width, 800)
  db.profiles["Défaut"].tooltip.level = true
  eq(db.profiles.Raid.tooltip.level, false)
  eq(P.copyFrom(db, "Défaut", "Nope"), false)
end)

test("rename keeps characters and the default pointing at the profile", function()
  local db = newDb()
  db.profileKeys["Realm-A"] = "Défaut"
  eq(P.rename(db, "Défaut", "Principal"), true)
  eq(db.profiles["Défaut"], nil)
  eq(db.profiles.Principal.width, 480)
  eq(db.profileKeys["Realm-A"], "Principal")
  eq(db.defaultProfile, "Principal")
  eq({ P.rename(db, "Principal", "") }, { false, "empty" })
  db.profiles.Raid = {}
  eq({ P.rename(db, "Principal", "Raid") }, { false, "exists" })
end)

test("delete refuses the active profile and the last one", function()
  local db = newDb()
  eq({ P.delete(db, "Défaut", "Realm-A") }, { false, "active" })
  db.profiles.Raid = {}
  db.profileKeys["Realm-A"] = "Raid"
  eq({ P.delete(db, "Raid", "Realm-A") }, { false, "active" })
end)

test("delete moves other characters back to the default profile", function()
  local db = newDb()
  db.profiles.Raid = {}
  db.profileKeys["Realm-B"] = "Raid"
  eq(P.delete(db, "Raid", "Realm-A"), true)
  eq(db.profiles.Raid, nil)
  eq(P.activeName(db, "Realm-B"), "Défaut")
end)

test("deleting the default profile hands the role to another one", function()
  local db = newDb()
  db.profiles.Raid = {}
  db.profileKeys["Realm-A"] = "Raid"
  eq(P.delete(db, "Défaut", "Realm-A"), true)
  eq(db.defaultProfile, "Raid")
end)

test("reset restores the default settings", function()
  local db = newDb()
  P.reset(db, "Défaut")
  eq(db.profiles["Défaut"].width, D.settings.width)
  eq(db.profiles["Défaut"].rep.enabled, true)
end)

test("list is sorted", function()
  local db = newDb()
  db.profiles.Zeta, db.profiles.Alpha = {}, {}
  eq(P.list(db), { "Alpha", "Défaut", "Zeta" })
end)
