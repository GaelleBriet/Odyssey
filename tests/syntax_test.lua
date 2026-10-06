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
