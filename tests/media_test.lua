-- Reads the alpha of one pixel of an uncompressed 32-bit TGA (y = 0 is the top row).
local function alphaAt(path, x, y)
  local f = assert(io.open(path, "rb"))
  local data = f:read("*a")
  f:close()
  local width = data:byte(13) + data:byte(14) * 256
  local height = data:byte(15) + data:byte(16) * 256
  local row = height - 1 - y -- stored bottom to top
  return data:byte(18 + (row * width + x) * 4 + 4)
end

test("rounded border rings are hollow: opaque edge, transparent middle", function()
  for _, name in ipairs({ "round-ring-thin", "round-ring-thick" }) do
    local path = "Media/" .. name .. ".tga"
    eq(alphaAt(path, 256, 0), 255)
    eq(alphaAt(path, 256, 15), 255)
    eq(alphaAt(path, 256, 8), 0)
    eq(alphaAt(path, 0, 0), 0) -- rounded corner
  end
  eq(alphaAt("Media/round-ring-thick.tga", 256, 1), 255)
  eq(alphaAt("Media/round-ring-thin.tga", 256, 2), 0)
end)

test("the pill mask is filled", function()
  eq(alphaAt("Media/round-mask.tga", 256, 8), 255)
  eq(alphaAt("Media/round-mask.tga", 0, 0), 0)
end)
