local ns = newNamespace()
loadAddonFile("Defaults.lua", ns)
local D = ns.Defaults

test("copy is deep", function()
  local a = { x = { y = 1 } }
  local b = D.copy(a)
  b.x.y = 2
  eq(a.x.y, 1)
end)

test("merge fills missing keys and keeps user values", function()
  local db = { width = 300, tooltip = { level = false } }
  D.merge(db, { width = 480, height = 16, tooltip = { level = true, rested = true } })
  eq(db.width, 300)
  eq(db.height, 16)
  eq(db.tooltip.level, false)
  eq(db.tooltip.rested, true)
end)

test("merge repairs a value of the wrong type", function()
  local db = { tooltip = "oops", point = 5 }
  D.merge(db, { tooltip = { level = true }, point = { "BOTTOM", "UIParent", "BOTTOM", 0, 120 } })
  eq(db.tooltip, { level = true })
  eq(db.point[1], "BOTTOM")
end)

test("merge replaces scalars of the wrong type", function()
  local db = { width = "wide", questListMax = "5", locked = 1 }
  D.merge(db, { width = 480, questListMax = 5, locked = true })
  eq(db.width, 480)
  eq(db.questListMax, 5)
  eq(db.locked, true)
end)

test("merge does not alias the defaults", function()
  local defaults = { tooltip = { level = true } }
  local db = D.merge({}, defaults)
  db.tooltip.level = false
  eq(defaults.tooltip.level, true)
end)

test("merge repairs an old, nearly empty OdysseyDB", function()
  local db = D.merge({ probe = { build = "x" } }, D.root)
  eq(db.version, 1)
  eq(db.perCharacter, false)
  eq(db.chars, {})
  eq(db.account.style, D.settings.style)
  eq(db.probe.build, "x")
end)

test("get and set with dotted paths", function()
  local t = { tooltip = { level = true } }
  eq(D.get(t, "tooltip.level"), true)
  eq(D.get(t, "tooltip.nope.deeper"), nil)
  D.set(t, "tooltip.level", false)
  eq(t.tooltip.level, false)
  D.set(t, "width", 123)
  eq(t.width, 123)
end)

test("default settings are complete", function()
  local s = D.settings
  eq(s.locked, true)
  eq(s.width, 480)
  eq(s.style, "glossy")
  eq(s.theme, "classic")
  eq(s.textCenter, "current_max_percent")
  eq(s.maxLevelBehavior, "hide")
  eq(s.tooltip.history, true)
  eq(s.point, { "BOTTOM", "UIParent", "BOTTOM", 0, 120 })
end)
