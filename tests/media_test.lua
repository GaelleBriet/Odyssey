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

local RATIOS = { 8, 16, 32, 64 }

test("rounded border rings are hollow in every proportion", function()
  for _, ratio in ipairs(RATIOS) do
    local mid = ratio * 8
    for _, weight in ipairs({ "thin", "thick" }) do
      local path = "Media/round-ring-" .. weight .. "-" .. ratio .. ".tga"
      eq(alphaAt(path, mid, 0), 255)
      eq(alphaAt(path, mid, 15), 255)
      eq(alphaAt(path, mid, 8), 0)
      eq(alphaAt(path, 0, 0), 0) -- rounded corner
    end
    eq(alphaAt("Media/round-ring-thick-" .. ratio .. ".tga", mid, 1), 255)
    eq(alphaAt("Media/round-ring-thin-" .. ratio .. ".tga", mid, 2), 0)
  end
end)

test("the pill masks are filled in every proportion", function()
  for _, ratio in ipairs(RATIOS) do
    local path = "Media/round-mask-" .. ratio .. ".tga"
    eq(alphaAt(path, ratio * 8, 8), 255)
    eq(alphaAt(path, 0, 0), 0)
  end
end)
