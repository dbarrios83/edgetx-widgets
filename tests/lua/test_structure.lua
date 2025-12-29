-- Test the new directory structure
-- Run from: tests/lua/ folder
-- Usage: lua ../../tests/lua/test_structure.lua

print("\n========================================")
print("  Project Structure Verification        ")
print("========================================\n")

-- Check paths
local paths = {
  "../../widgets/BattWidget/main.lua",
  "../../widgets/RXWidget/main.lua",
  "../../widgets/GPSWidget/main.lua",
  "../../widgets/ClockWidget/main.lua",
  "../utils/telemetry_simulator.lua",
}

print("Checking required paths:\n")
for _, path in ipairs(paths) do
  local f = io.open(path)
  if f then
    f:close()
    print("    [PASS] " .. path)
  else
    print("    [FAIL] " .. path .. " (MISSING!)")
  end
end

print("\n========================================")
print("  Structure Verification Complete      ")
print("========================================\n")
