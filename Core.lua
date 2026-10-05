local ADDON, ns = ...

SLASH_ODYSSEY1 = "/odyssey"
SlashCmdList["ODYSSEY"] = function(msg)
  local cmd = (msg or ""):lower():match("^%s*(%S*)")
  if cmd == "probe" then
    ns.RunProbe()
  else
    print("Odyssey: /odyssey probe")
  end
end
