local ns = newNamespace()
loadAddonFile("Defaults.lua", ns)
loadAddonFile("Styles.lua", ns)
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
  eq(db.version, 3)
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
  eq(s.style, nil)
  eq(s.texture, "smooth")
  eq(s.corners, "rounded")
  eq(s.border, "thin")
  eq(s.borderColor, "palette")
  eq(s.bgOpacity, 0.9)
  eq(s.barAlpha, 1)
  eq(s.showQuestSegment, true)
  eq(s.showRestedSegment, true)
  eq(s.gloss, true)
  eq(s.shadow, true)
  eq(s.glow, false)
  eq(s.spark, true)
  eq(s.ticks, 0)
  eq(s.textPosition, "inside")
  eq(s.visibility, "always")
  eq(s.fadedAlpha, 0)
  eq(s.colors, {})
  eq(s.palette, "arcane")
  eq(s.barFont, "Friz Quadrata")
  eq(s.tooltipBgOpacity, 0.93)
  eq(s.tooltipScale, 1)
  eq(s.tooltipAnchor, "bar")
  eq(s.textCenter, "current_max_percent")
  eq(s.tooltip.history, true)
  eq(s.point, { "BOTTOM", "UIParent", "BOTTOM", 0, 120 })
  eq(D.root.version, 3)
end)

test("migrate v1: style and theme become preset fields and a palette, for every character", function()
  local db = {
    version = 1,
    account = { style = "glossy", theme = "minimal", height = 16 },
    chars = {
      ["Realm-A"] = { settings = { style = "flat", theme = "class" } },
      ["Realm-B"] = { history = {} },
      ["Realm-C"] = "junk",
    },
  }
  D.migrate(db)
  eq(db.version, 3)
  eq(db.account.style, nil)
  eq(db.account.theme, nil)
  eq(db.account.palette, "monochrome")
  eq(db.account.texture, "smooth")
  eq(db.account.corners, "rounded")
  eq(db.account.height, 16)
  eq(db.chars["Realm-A"].settings.palette, "class")
  eq(db.chars["Realm-A"].settings.gloss, true)
end)

test("migrate v1 maps every theme", function()
  local map = { classic = "arcane", class = "class", faction = "faction", minimal = "monochrome" }
  for old, new in pairs(map) do
    local db = { version = 1, account = { theme = old, style = "gradient" }, chars = {} }
    D.migrate(db)
    eq(db.account.palette, new)
  end
end)

test("migrate v2: the chosen style becomes its preset, the height is kept", function()
  local db = { version = 2, account = { style = "segmented", height = 20 }, chars = {} }
  D.migrate(db)
  eq(db.version, 3)
  eq(db.account.style, nil)
  eq(db.account.ticks, 10)
  eq(db.account.texture, "gradient")
  eq(db.account.corners, "square")
  eq(db.account.height, 20)
end)

test("migrate v2 with an unknown style uses the smooth preset", function()
  local db = { version = 2, account = { style = "weird" }, chars = {} }
  D.migrate(db)
  eq(db.account.texture, "smooth")
  eq(db.account.style, nil)
end)

test("migrate leaves a fresh or already migrated database alone", function()
  local fresh = {}
  D.migrate(fresh)
  eq(fresh, {})
  local v3 = { version = 3, account = { texture = "flat" } }
  D.migrate(v3)
  eq(v3.account.texture, "flat")
end)
