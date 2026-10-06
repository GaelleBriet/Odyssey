-- Run from the repo root: luajit tests/run.lua [name-filter]
local filter = arg and arg[1]

local tests = {}
function test(name, fn) tests[#tests + 1] = { name = name, fn = fn } end

local function deepEqual(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not deepEqual(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

local function show(v)
  if type(v) ~= "table" then return tostring(v) end
  local parts = {}
  for k, x in pairs(v) do parts[#parts + 1] = tostring(k) .. "=" .. show(x) end
  table.sort(parts)
  return "{" .. table.concat(parts, ", ") .. "}"
end

function eq(actual, expected)
  if not deepEqual(actual, expected) then
    error("expected " .. show(expected) .. ", got " .. show(actual), 2)
  end
end

function near(actual, expected, eps)
  eps = eps or 1e-6
  if type(actual) ~= "number" or math.abs(actual - expected) > eps then
    error("expected ~" .. tostring(expected) .. ", got " .. tostring(actual), 2)
  end
end

function truthy(v, msg)
  if not v then error(msg or "expected a truthy value", 2) end
end

-- Loads an addon file the way WoW does: the chunk receives (addonName, namespace).
function loadAddonFile(path, ns)
  local chunk = assert(loadfile(path))
  return chunk("Odyssey", ns)
end

function newNamespace() return {} end

local listing = io.popen("ls tests/*_test.lua")
for file in listing:lines() do dofile(file) end
listing:close()

local passed, failed = 0, 0
for _, t in ipairs(tests) do
  if not filter or t.name:find(filter, 1, true) then
    local ok, err = pcall(t.fn)
    if ok then
      passed = passed + 1
    else
      failed = failed + 1
      print("FAIL  " .. t.name .. "\n      " .. tostring(err))
    end
  end
end
print(("%d passed, %d failed"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
