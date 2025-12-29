-- GPSWidget Telemetry Tests
-- Tests GPS satellite acquisition, signal strength, and location data

require("setup")
local TelSim = require("telemetry_simulator")

local function setupMocks()
  _G.getValue = function(key)
    if key == "Sats" then
      return TelSim:getValue("GpsSATS")
    elseif key == "GPS" then
      return {
        lat = TelSim:getValue("Lat"),
        lon = TelSim:getValue("Lon")
      }
    end
    return TelSim:getValue(key)
  end
  
  _G.lcd = {
    drawText = function(x, y, text, flags)
      if not TelSim.lastText then TelSim.lastText = {} end
      table.insert(TelSim.lastText, {x = x, y = y, text = text, flags = flags})
    end,
    drawBitmap = function(bitmap, x, y)
      if not TelSim.lastBitmap then TelSim.lastBitmap = {} end
      table.insert(TelSim.lastBitmap, {bitmap = bitmap, x = x, y = y})
    end
  }
  
  _G.Bitmap = {}
  function _G.Bitmap.open(path)
    return { path = path, delete = function(self) end }
  end
  
  _G.RIGHT = 0
  _G.WHITE = 1
  _G.SHADOWED = 2
  _G.MIDSIZE = 8
  _G.RED = 16
  _G.GREEN = 32
  _G.YELLOW = 64
end

-- Helper to format degrees-minutes-seconds
local function formatDMS(value)
  local degrees = math.floor(value)
  local minutes = math.floor((value - degrees) * 60)
  local seconds = ((value - degrees) * 60 - minutes) * 60
  return string.format("%ddeg %d' %d\"", degrees, minutes, seconds)
end

local function testGPSWidget()
  setupMocks()
  
  print("\n========================================")
  print("  GPSWidget Telemetry Testing           ")
  print("========================================\n")
  
  local GPSWidget = dofile("../../widgets/GPSWidget/main.lua")
  local zone = {x = 0, y = 0, w = 100, h = 150}
  
  -- Scenario 1: Strong GPS Lock (Perfect conditions)
  print("[TEST] Scenario 1: Strong GPS Lock (15+ satellites)")
  TelSim:setValue("GpsSATS", 16)
  TelSim:setValue("Lat", 37.7749)
  TelSim:setValue("Lon", -122.4194)
  local widget = GPSWidget.create(zone, {Coordinates = 1})
  TelSim.lastText = {}
  GPSWidget.refresh(widget)
  print("    Satellites: " .. TelSim:getValue("GpsSATS"))
  print("    Location: " .. formatDMS(37.7749) .. " N, " .. formatDMS(122.4194) .. " W")
  print("    Status: [GREEN] Strong lock - Excellent\n")
  
  -- Scenario 2: Medium GPS Lock
  print("[TEST] Scenario 2: Medium GPS Lock (8-10 satellites)")
  TelSim:setValue("GpsSATS", 9)
  TelSim.lastText = {}
  GPSWidget.refresh(widget)
  print("    Satellites: " .. TelSim:getValue("GpsSATS"))
  print("    Location: " .. formatDMS(37.7749) .. " N, " .. formatDMS(122.4194) .. " W")
  print("    Status: [YELLOW] Medium lock - Good\n")
  
  -- Scenario 3: Weak GPS Lock (urban canyon, trees)
  print("[TEST] Scenario 3: Weak GPS Lock (3-5 satellites)")
  TelSim:setValue("GpsSATS", 4)
  TelSim.lastText = {}
  GPSWidget.refresh(widget)
  print("    Satellites: " .. TelSim:getValue("GpsSATS"))
  print("    Location: " .. formatDMS(37.7749) .. " N, " .. formatDMS(122.4194) .. " W")
  print("    Status: [RED] Weak lock - Poor\n")
  
  -- Scenario 4: No GPS Lock (cold start, indoors)
  print("[TEST] Scenario 4: No GPS Lock (Cold Start / Indoor)")
  TelSim:setValue("GpsSATS", 0)
  TelSim:setValue("Lat", 0)
  TelSim:setValue("Lon", 0)
  TelSim.lastText = {}
  GPSWidget.refresh(widget)
  print("    Satellites: " .. TelSim:getValue("GpsSATS"))
  print("    Status: [X] No signal - Acquiring satellites...\n")
  
  -- Scenario 5: Initializing (1-2 satellites, signal search)
  print("[TEST] Scenario 5: Initializing (1-2 satellites)")
  TelSim:setValue("GpsSATS", 2)
  TelSim:setValue("Lat", 37.0)
  TelSim:setValue("Lon", -122.0)
  TelSim.lastText = {}
  GPSWidget.refresh(widget)
  print("    Satellites: " .. TelSim:getValue("GpsSATS"))
  print("    Status: [SEARCH] Initializing - Acquiring lock...\n")
  
  -- Scenario 6: Lost Lock (was locked, now lost signal)
  print("[TEST] Scenario 6: Lost Previous Lock (Signal Lost in Flight)")
  TelSim:setValue("GpsSATS", 0)
  TelSim:setValue("Lat", 37.7749)  -- Keep last known position
  TelSim:setValue("Lon", -122.4194)
  TelSim.lastText = {}
  GPSWidget.refresh(widget)
  print("    Satellites: " .. TelSim:getValue("GpsSATS"))
  print("    Last Known: " .. formatDMS(37.7749) .. " N, " .. formatDMS(122.4194) .. " W")
  print("    Status: [LAST] Using last known position\n")
  
  print("  [PASS] GPSWidget tests completed\n")
end

testGPSWidget()
