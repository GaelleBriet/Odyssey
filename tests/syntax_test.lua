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
