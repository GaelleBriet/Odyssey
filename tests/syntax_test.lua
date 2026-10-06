test("every addon Lua file parses", function()
  local listing = io.popen("find . -name '*.lua' -not -path './tests/*' -not -path './.git/*'")
  local bad = {}
  for file in listing:lines() do
    local chunk, err = loadfile(file)
    if not chunk then bad[#bad + 1] = err end
  end
  listing:close()
  eq(bad, {})
end)

-- A misspelt or undeclared local becomes a global write; the addon may only write these.
local ALLOWED_GLOBAL_WRITES = { OdysseyDB = true, SLASH_ODYSSEY1 = true }

test("addon files write no unexpected globals", function()
  local listing = io.popen("find . -name '*.lua' -not -path './tests/*' -not -path './.git/*' -not -path './.superpowers/*'")
  local bad = {}
  for file in listing:lines() do
    local dump = io.popen("luajit -bl " .. file)
    for line in dump:lines() do
      local name = line:match('GSET.*"([%w_]+)"')
      if name and not ALLOWED_GLOBAL_WRITES[name] then bad[#bad + 1] = file .. ": " .. name end
    end
    dump:close()
  end
  listing:close()
  eq(bad, {})
end)

-- Every global an addon file reads must be a known game or Lua name: a misspelt or
-- not-yet-declared local otherwise reads as a nil global and fails only in game.
local KNOWN_GLOBALS = { C_AddOns = true, ColorPickerFrame = true, COMBATLOG_XP_GAIN_FIRST_PERSON_UNNAMED = true, C_QuestLog = true, CreateColor = true, CreateFrame = true, C_Reputation = true, C_Timer = true, FACTION_BAR_COLORS = true, _G = true, GameFontHighlightSmall = true, GetAddOnMetadata = true, GetBuildInfo = true, GetCursorPosition = true, GetLocale = true, GetMaxPlayerLevel = true, GetNumQuestLogEntries = true, GetQuestLogRewardXP = true, GetQuestLogSelection = true, GetQuestLogTitle = true, GetRealmName = true, GetTime = true, GetWatchedFactionInfo = true, GetXPExhaustion = true, HideUIPanel = true, InterfaceOptions_AddCategory = true, ipairs = true, IsPlayerAtEffectiveMaxLevel = true, IsShiftKeyDown = true, LibStub = true, MainMenuExpBar = true, math = true, MAX_PLAYER_LEVEL = true, next = true, NUM_CHAT_WINDOWS = true, OdysseyDB = true, pairs = true, pcall = true, print = true, RAID_CLASS_COLORS = true, RequestTimePlayed = true, SelectQuestLogEntry = true, setmetatable = true, Settings = true, SettingsPanel = true, ShowUIPanel = true, SlashCmdList = true, StatusTrackingBarManager = true, string = true, table = true, time = true, tostring = true, type = true, UIParent = true, UISpecialFrames = true, UnitClass = true, UnitFactionGroup = true, UnitLevel = true, UnitName = true, UnitXP = true, UnitXPMax = true }

test("addon files read only known globals", function()
  local listing = io.popen("find . -name '*.lua' -not -path './tests/*' -not -path './.git/*' -not -path './.superpowers/*'")
  local unknown = {}
  for file in listing:lines() do
    local dump = io.popen("luajit -bl " .. file)
    for line in dump:lines() do
      local name = line:match('GGET.*"([%w_]+)"')
      if name and not KNOWN_GLOBALS[name] then unknown[#unknown + 1] = file .. ": " .. name end
    end
    dump:close()
  end
  listing:close()
  eq(unknown, {})
end)

-- Every `Module.field` the addon reads from a pure module must exist once the module is
-- loaded (a renamed or removed field otherwise only fails in game).
test("module fields used by the addon exist", function()
  local ns = newNamespace()
  ns.L = setmetatable({}, { __index = function(_, k) return k end })
  for _, file in ipairs({ "Defaults.lua", "Calc.lua", "History.lua", "Compat.lua", "Sources/XP.lua",
    "Sources/Reputation.lua", "Texts.lua", "Styles.lua", "Visibility.lua", "Profiles.lua", "Fonts.lua",
    "TooltipContent.lua" }) do
    loadAddonFile(file, ns)
  end
  local modules = { "Calc", "Defaults", "History", "Compat", "Texts", "Styles", "Palettes", "Visibility",
    "Profiles", "Fonts", "TooltipContent", "XPSource", "RepSource" }
  local missing, seen = {}, {}
  local listing = io.popen("find . -name '*.lua' -not -path './tests/*' -not -path './.git/*' -not -path './.superpowers/*'")
  for file in listing:lines() do
    local f = io.open(file)
    local code = f:read("*a")
    f:close()
    for _, module in ipairs(modules) do
      for field in code:gmatch("%f[%w_]" .. module .. "%.([%a_][%w_]*)") do
        local id = module .. "." .. field
        if field ~= "lua" and not seen[id] and ns[module][field] == nil then missing[#missing + 1] = file .. ": " .. id end
        seen[id] = true
      end
    end
  end
  listing:close()
  eq(missing, {})
end)
