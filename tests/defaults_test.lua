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
  eq(db.version, 2)
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
  eq(s.height, 18)
  eq(s.style, "smooth")
  eq(s.palette, "arcane")
  eq(s.theme, nil)
  eq(s.barFont, "Friz Quadrata")
  eq(s.barFontSize, 11)
  eq(s.barFontOutline, "OUTLINE")
  eq(s.tooltipFont, "Friz Quadrata")
  eq(s.tooltipFontSize, 12)
  eq(s.tooltipFontOutline, "NONE")
  eq(s.textCenter, "current_max_percent")
  eq(s.maxLevelBehavior, "hide")
  eq(s.tooltip.history, true)
  eq(s.point, { "BOTTOM", "UIParent", "BOTTOM", 0, 120 })
  eq(D.root.version, 2)
end)

test("migrate converts v1 styles and themes for the account and every character", function()
  local db = {
    version = 1,
    account = { style = "glossy", theme = "minimal" },
    chars = {
      ["Realm-A"] = { settings = { style = "flat", theme = "class" } },
      ["Realm-B"] = { history = {} },
      ["Realm-C"] = "junk",
    },
  }
  D.migrate(db)
  eq(db.version, 2)
  eq(db.account.style, "smooth")
  eq(db.account.palette, "monochrome")
  eq(db.account.theme, nil)
  eq(db.chars["Realm-A"].settings.style, "smooth")
  eq(db.chars["Realm-A"].settings.palette, "class")
end)

test("migrate maps every v1 theme and keeps unknown v2 values", function()
  local map = { classic = "arcane", class = "class", faction = "faction", minimal = "monochrome" }
  for old, new in pairs(map) do
    local db = { version = 1, account = { theme = old, style = "gradient" }, chars = {} }
    D.migrate(db)
    eq(db.account.palette, new)
    eq(db.account.style, "smooth")
  end
  local db = { version = 1, account = { style = "neon" }, chars = {} }
  D.migrate(db)
  eq(db.account.style, "neon")
end)

test("migrate leaves a fresh or already migrated database alone", function()
  local fresh = {}
  D.migrate(fresh)
  eq(fresh, {})
  local v2 = { version = 2, account = { style = "flat" } }
  D.migrate(v2)
  eq(v2.account.style, "flat")
end)
