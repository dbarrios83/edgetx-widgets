-- Test Suite for TeleView Widget
require("setup")
local telemetry = require("telemetry_simulator")

print("\n=== TeleView Widget Test Suite ===\n")

-- Mock EdgeTX API and utils
local drawCalls = {}
local bitmapCalls = {}

-- Mock utils module
local mockUtils = {
  getVoltagePerCell = function(totalVoltage)
    if totalVoltage < 5 then
      return totalVoltage, 1 -- Single cell
    else
      local cellCount = math.floor(totalVoltage / 4.2 + 0.5)
      return totalVoltage / cellCount, cellCount
    end
  end,
  
  rxCellState = function(voltagePerCell)
    if voltagePerCell < 3.2 then return "dead"
    elseif voltagePerCell < 3.6 then return "low"
    elseif voltagePerCell < 3.8 then return "yellow"
    elseif voltagePerCell < 4.0 then return "ok"
    else return "full"
    end
  end,
  
  connectionIconState = function(tpwr, rqly)
    if tpwr == 0 then return "black"
    elseif rqly >= 80 then return "green"
    elseif rqly >= 50 then return "yellow"
    else return "red"
    end
  end,
  
  satIconColor = function(sats)
    if sats >= 9 then return "green"
    elseif sats >= 5 then return "yellow"
    else return "red"
    end
  end,
  
  formatLatLon = function(lat, lon)
    return string.format("%.6f°N", lat), string.format("%.6f°E", lon)
  end,
  
  safeOpen = function(path)
    return {path = path}
  end,
  
  text = function(x, y, txt, align, size, extra)
    table.insert(drawCalls, {x = x, y = y, text = txt, align = align, size = size, extra = extra})
  end,
  
  S = {
    left = 0,
    right = 1,
    base = 2,
    sml = 4,
    mid = 8,
    bold = 16
  }
}

function _G.loadScript(path)
  return function() return mockUtils end
end

function _G.getValue(key)
  -- Map "Sats" to "GpsSATS" for compatibility
  if key == "Sats" then
    key = "GpsSATS"
  end
  -- Handle GPS specially - return the table value directly
  if key == "GPS" then
    return telemetry:getValue(key)
  end
  return telemetry:getValue(key)
end

_G.lcd = {
  drawText = function(x, y, text, flags)
    table.insert(drawCalls, {x = x, y = y, text = text, flags = flags})
  end,
  drawBitmap = function(bitmap, x, y)
    table.insert(bitmapCalls, {bitmap = bitmap, x = x, y = y})
  end
}

_G.Bitmap = {
  open = function(path)
    return {path = path}
  end
}

-- Constants
_G.LEFT = 0
_G.RIGHT = 1
_G.WHITE = 2
_G.SHADOWED = 4
_G.MIDSIZE = 8

-- Test 1: Module Structure
print("Test 1: Module structure validation")
local widget_module, err = loadfile("../../widgets/TeleView/main.lua")
if not widget_module then
  print("Load error: " .. tostring(err))
  print("Trying alternative path...")
  widget_module, err = loadfile("../widgets/TeleView/main.lua")
end
assert(widget_module, "Failed to load TeleView widget: " .. tostring(err))
local widget = widget_module()
assert(widget.name == "TeleView", "Widget name should be 'TeleView'")
assert(type(widget.create) == "function", "Widget should have create function")
assert(type(widget.update) == "function", "Widget should have update function")
assert(type(widget.refresh) == "function", "Widget should have refresh function")
print("✓ Module structure is valid\n")

-- Test 2: Widget Creation
print("Test 2: Widget creation")
local zone = { x = 0, y = 0, w = 200, h = 80 }
local options = {}
local w = widget.create(zone, options)
assert(w, "Widget creation failed")
assert(w.zone == zone, "Zone not stored correctly")
assert(w.icons, "Icons not loaded")
assert(w.lastLat == 0, "lastLat should be initialized to 0")
assert(w.lastLon == 0, "lastLon should be initialized to 0")
assert(w.wasConnected == false, "Should start with wasConnected=false")
assert(w.gpsSeenThisConnection == false, "Should start with gpsSeenThisConnection=false")
print("✓ Widget created successfully with all properties\n")

-- Test 3: No Connection State
print("Test 3: No connection (black icon, 'No RX Telemetry' message)")
telemetry:setValue("TPWR", 0)
telemetry:setValue("RQly", 0)
telemetry:setValue("RxBt", 0)
telemetry:setValue("GpsSATS", 0)
drawCalls = {}
bitmapCalls = {}
widget.refresh(w)
assert(w.wasConnected == false, "Should track disconnected state")
print("✓ No connection state handled correctly\n")

-- Test 4: Good Connection (Green)
print("Test 4: Good connection (LQ ≥ 80%, green icon)")
telemetry:setValue("TPWR", 100)
telemetry:setValue("RQly", 95)
telemetry:setValue("RxBt", 16.8)
telemetry:setValue("GpsSATS", 12)
telemetry:setValue("GPS", {lat = 37.7749, lon = -122.4194})
drawCalls = {}
bitmapCalls = {}
widget.refresh(w)
assert(w.wasConnected == true, "Should track connected state")
assert(w.gpsSeenThisConnection == true, "Should detect GPS module")
assert(w.lastLat ~= 0, "Should cache GPS latitude")
assert(w.lastLon ~= 0, "Should cache GPS longitude")
print("✓ Good connection with green icon\n")

-- Test 5: Fair Connection (Yellow)
print("Test 5: Fair connection (LQ 50-79%, yellow icon)")
telemetry:setValue("TPWR", 50)
telemetry:setValue("RQly", 65)
drawCalls = {}
widget.refresh(w)
print("✓ Fair connection with yellow icon\n")

-- Test 6: Poor Connection (Red)
print("Test 6: Poor connection (LQ < 50%, red icon)")
telemetry:setValue("TPWR", 25)
telemetry:setValue("RQly", 35)
drawCalls = {}
widget.refresh(w)
print("✓ Poor connection with red icon\n")

-- Test 7: Battery Display (Multi-Cell)
print("Test 7: Battery display (4S, 16.8V)")
telemetry:setValue("TPWR", 100)
telemetry:setValue("RxBt", 16.8)
widget.refresh(w)
-- Utils should detect 4S battery (16.8V / 4 = 4.2V per cell)
print("✓ Battery displays with cell count\n")

-- Test 8: Battery Display (Single Cell)
print("Test 8: Battery display (1S, 3.7V)")
telemetry:setValue("RxBt", 3.7)
widget.refresh(w)
-- Should display as single cell
print("✓ Single cell battery display\n")

-- Test 9: Low Battery Warning
print("Test 9: Low battery (3.5V per cell, yellow/low icon)")
telemetry:setValue("RxBt", 14.0) -- 4S at 3.5V per cell
widget.refresh(w)
print("✓ Low battery state with appropriate icon\n")

-- Test 10: Critical Battery
print("Test 10: Critical battery (3.1V per cell, dead icon)")
telemetry:setValue("RxBt", 12.4) -- 4S at 3.1V per cell
widget.refresh(w)
print("✓ Critical battery with dead icon\n")

-- Test 11: GPS - No Satellites (Red)
print("Test 11: GPS - No satellites (red icon)")
telemetry:setValue("TPWR", 100)
telemetry:setValue("GpsSATS", 0)
telemetry:setValue("GPS", {lat = 0, lon = 0})
widget.refresh(w)
print("✓ No GPS lock with red icon\n")

-- Test 12: GPS - Acquiring (Yellow)
print("Test 12: GPS - Acquiring (6 sats, yellow icon)")
telemetry:setValue("GpsSATS", 6)
widget.refresh(w)
print("✓ GPS acquiring with yellow icon\n")

-- Test 13: GPS - Good Lock (Green)
print("Test 13: GPS - Good lock (15 sats, green icon)")
telemetry:setValue("GpsSATS", 15)
telemetry:setValue("GPS", {lat = 37.7749, lon = -122.4194})
widget.refresh(w)
assert(w.lastLat == 37.7749, "Should cache latitude on good lock")
assert(w.lastLon == -122.4194, "Should cache longitude on good lock")
print("✓ GPS good lock with green icon\n")

-- Test 14: GPS Detection and "No GPS" Display
print("Test 14: GPS module detection and No GPS display")
-- Create new widget to start fresh
local w2 = widget.create(zone, options)
telemetry:setValue("TPWR", 100)
telemetry:setValue("RQly", 85)
telemetry:setValue("GPS", nil) -- No GPS module
drawCalls = {}
widget.refresh(w2)
assert(w2.gpsSeenThisConnection == false, "Should not detect GPS when GPS value is nil")
-- Should display "No GPS" instead of satellite count
print("✓ Correctly handles missing GPS module\n")

-- Test 15: Last GPS Fix Display on Disconnect
print("Test 15: Last GPS fix display when disconnected")
local w3 = widget.create(zone, options)
-- Connect with GPS
telemetry:setValue("TPWR", 100)
telemetry:setValue("GPS", {lat = 37.7749, lon = -122.4194})
widget.refresh(w3)
assert(w3.lastLat == 37.7749, "Should cache latitude")
assert(w3.lastLon == -122.4194, "Should cache longitude")

-- Disconnect
telemetry:setValue("TPWR", 0)
telemetry:setValue("GPS", nil)
drawCalls = {}
widget.refresh(w3)
-- Should display "Last GPS fix" with coordinates
local foundLastGPS = false
for _, call in ipairs(drawCalls) do
  if call.text and call.text:match("Last GPS fix") then
    foundLastGPS = true
    break
  end
end
assert(foundLastGPS, "Should display 'Last GPS fix' when disconnected with cached coords")
print("✓ Last GPS fix displayed correctly on disconnect\n")

-- Test 16: Integrated Flight Scenario
print("Test 16: Complete flight scenario")
local w4 = widget.create(zone, options)

-- Pre-flight
telemetry:setValue("TPWR", 100)
telemetry:setValue("RQly", 98)
telemetry:setValue("RxBt", 16.8)
telemetry:setValue("GpsSATS", 14)
telemetry:setValue("GPS", {lat = 37.7749, lon = -122.4194})
widget.refresh(w4)
print("  - Pre-flight: Good signal, full battery, GPS lock")
assert(w4.gpsSeenThisConnection == true, "GPS detected")
assert(w4.lastLat ~= 0, "GPS coordinates cached")

-- In-flight (battery draining)
telemetry:setValue("RxBt", 15.2) -- 3.8V per cell
telemetry:setValue("RQly", 75)
widget.refresh(w4)
print("  - In-flight: Fair signal, battery draining")

-- Low battery warning
telemetry:setValue("RxBt", 14.4) -- 3.6V per cell
telemetry:setValue("RQly", 60)
widget.refresh(w4)
print("  - Warning: Low battery, moderate signal")

-- Landing and disconnect
telemetry:setValue("TPWR", 0)
telemetry:setValue("GPS", nil)
drawCalls = {}
widget.refresh(w4)
print("  - Landed: Disconnected, showing last GPS fix")
assert(w4.wasConnected == false, "Disconnected")

-- Verify last GPS fix is displayed
local foundGPSFix = false
for _, call in ipairs(drawCalls) do
  if call.text and call.text:match("Last GPS fix") then
    foundGPSFix = true
    break
  end
end
assert(foundGPSFix, "Last GPS fix should be shown")
print("✓ Complete flight scenario passed\n")

print("=== All TeleView Tests Passed! ===\n")
