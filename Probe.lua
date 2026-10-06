local ADDON, ns = ...

-- Every game API the addon may use. The probe records which ones exist on this client.
local PROBES = {
  "UnitXP", "UnitXPMax", "UnitLevel", "GetXPExhaustion", "RequestTimePlayed",
  "IsPlayerAtEffectiveMaxLevel", "GetMaxPlayerLevel", "MAX_PLAYER_LEVEL",
  "C_QuestLog.GetNumQuestLogEntries", "C_QuestLog.GetInfo", "C_QuestLog.IsComplete",
  "C_QuestLog.ReadyForTurnIn", "GetQuestLogRewardXP",
  "GetNumQuestLogEntries", "GetQuestLogTitle", "SelectQuestLogEntry",
  "C_Timer.After", "hooksecurefunc", "GetTime", "time",
  "Settings.RegisterCanvasLayoutCategory", "Settings.RegisterAddOnCategory", "Settings.OpenToCategory",
  "InterfaceOptions_AddCategory", "InterfaceOptionsFrame_OpenToCategory",
  "MainMenuExpBar", "StatusTrackingBarManager", "ReputationWatchBar",
  "UIParent", "GameTooltip", "RAID_CLASS_COLORS", "UnitFactionGroup", "NUM_CHAT_WINDOWS",
  "STANDARD_TEXT_FONT", "CreateColor", "LibStub", "IsShiftKeyDown", "UISpecialFrames",
  "UIParent.CreateMaskTexture", "ColorPickerFrame", "ColorPickerFrame.SetupColorPickerAndShow",
  "GetCursorPosition", "ShowUIPanel",
}

local function resolve(path)
  local obj = _G
  for part in path:gmatch("[^.]+") do
    if type(obj) ~= "table" then return nil end
    obj = obj[part]
    if obj == nil then return nil end
  end
  return obj
end

function ns.RunProbe()
  local version, build, _, toc = GetBuildInfo()
  local result = { build = tostring(version) .. " (" .. tostring(build) .. ")", toc = toc, locale = GetLocale(), apis = {} }
  print(("Odyssey probe: build %s, interface %s, locale %s"):format(result.build, tostring(toc), result.locale))
  for _, path in ipairs(PROBES) do
    local found = resolve(path) ~= nil
    result.apis[path] = found
    print(("  %-45s %s"):format(path, found and "yes" or "NO"))
  end
  -- Field names returned by the modern quest-log call, to adapt Compat if needed.
  if C_QuestLog and C_QuestLog.GetInfo and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetNumQuestLogEntries() > 0 then
    local info = C_QuestLog.GetInfo(1)
    if type(info) == "table" then
      local keys = {}
      for k in pairs(info) do keys[#keys + 1] = tostring(k) end
      table.sort(keys)
      result.questInfoFields = table.concat(keys, ",")
    end
  end
  OdysseyDB = OdysseyDB or {}
  OdysseyDB.probe = result
  print("Odyssey probe saved. Type /reload to write it to disk.")
end
