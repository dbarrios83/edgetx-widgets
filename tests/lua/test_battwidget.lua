-- Battery Widget Comprehensive Tests
-- Tests BattWidget functionality including module structure, lifecycle, and telemetry scenarios

require("setup")
local TelSim = require("telemetry_simulator")

-- Mock EdgeTX API
local drawCalls = {}
local bitmapCalls = {}

local function setupMocks()
  _G.getValue = function(key)
    return TelSim:getValue(key)
  end
  
  _G.lcd = {
    drawText = function(x, y, text, flags)
      table.insert(drawCalls, {x = x, y = y, text = text, flags = flags})
      TelSim.lastDrawnText = {x = x, y = y, text = text, flags = flags}
    end,
    drawBitmap = function(bitmap, x, y)
      table.insert(bitmapCalls, {bitmap = bitmap, x = x, y = y})
      TelSim.lastBitmap = {bitmap = bitmap, x = x, y = y}
    end
  }
  
  _G.Bitmap = {}
  function _G.Bitmap.open(path)
    return {
      path = path,
      delete = function(self) end
    }
  end
  
  -- Add global constants
  _G.RIGHT = 0
  _G.WHITE = 1
  _G.SHADOWED = 2
  _G.MIDSIZE = 4
end

local function assert(condition, message)
  if not condition then
    error("ASSERTION FAILED: " .. (message or "unknown"))
  end
end

local function testBattWidget()
  setupMocks()
  
  print("\n========================================")
  print("  BattWidget Comprehensive Testing      ")
  print("========================================\n")
  
  local BattWidget = dofile("../../widgets/BattWidget/main.lua")
  
  -- Test 1: Module Structure
  print("[TEST] Test 1: Module Structure")
  assert(BattWidget.name == "BattWidget", "Widget name should be 'BattWidget'")
  assert(type(BattWidget.create) == "function", "create() should be a function")
  assert(type(BattWidget.update) == "function", "update() should be a function")
  assert(type(BattWidget.refresh) == "function", "refresh() should be a function")
  assert(type(BattWidget.destroy) == "function", "destroy() should be a function")
  print("  [PASS] All required functions exported")
  print("  [PASS] Widget name: " .. BattWidget.name .. "\n")
  
  -- Test 2: Widget Creation with Zone
  print("[TEST] Test 2: Widget Creation")
  local zone = {x = 10, y = 20, w = 100, h = 50}
  local widget = BattWidget.create(zone, {})
  assert(widget ~= nil, "Widget should be created")
  assert(widget.zone.x == 10, "Zone x coordinate should match")
  assert(widget.zone.y == 20, "Zone y coordinate should match")
  assert(widget.zone.w == 100, "Zone width should match")
  assert(widget.zone.h == 50, "Zone height should match")
  print("  [PASS] Widget created with correct zone")
  print("  [PASS] Zone: {x=" .. widget.zone.x .. ", y=" .. widget.zone.y .. 
        ", w=" .. widget.zone.w .. ", h=" .. widget.zone.h .. "}\n")
  
  -- Test 3: Icon Preloading
  print("[TEST] Test 3: Battery Icon Preloading")
  assert(widget.icons ~= nil, "Icons should be preloaded")
  assert(widget.icons.dead ~= nil, "Dead battery icon should exist")
  assert(widget.icons.low ~= nil, "Low battery icon should exist")
  assert(widget.icons.yellow ~= nil, "Yellow battery icon should exist")
  assert(widget.icons.ok ~= nil, "OK battery icon should exist")
  assert(widget.icons.full ~= nil, "Full battery icon should exist")
  print("  [PASS] All 5 battery icons preloaded")
  print("  [PASS] Icons: dead, low, yellow, ok, full\n")
  
  -- Test 4: Update Function
  print("[TEST] Test 4: Widget Update")
  local newOptions = {testOption = "testValue"}
  BattWidget.update(widget, newOptions)
  assert(widget.cfg.testOption == "testValue", "Options should be updated")
  print("  [PASS] Widget options updated successfully\n")
  
  -- Test 5: Healthy Battery (Cruising)
  print("[TEST] Test 5: Healthy Battery (Cruising)")
  drawCalls = {}
  TelSim:applyProfile("cruising")
  BattWidget.refresh(widget)
  assert(#drawCalls > 0, "Should draw text for healthy battery")
  TelSim:printSummary()
  
  -- Test 6: Low Battery Warning
  print("[TEST] Test 6: Low Battery Warning")
  drawCalls = {}
  TelSim:applyProfile("lowbattery")
  BattWidget.refresh(widget)
  assert(#drawCalls > 0, "Should draw text for low battery")
  TelSim:printSummary()
  
  -- Test 7: Ground Station (Idle)
  print("[TEST] Test 7: Ground Station (Idle)")
  drawCalls = {}
  TelSim:applyProfile("idle")
  BattWidget.refresh(widget)
  assert(#drawCalls > 0, "Should draw text for idle state")
  TelSim:printSummary()
  
  -- Test 8: High Current (Takeoff)
  print("[TEST] Test 8: High Current (Takeoff)")
  drawCalls = {}
  TelSim:applyProfile("takeoff")
  BattWidget.refresh(widget)
  assert(#drawCalls > 0, "Should draw text for high current")
  TelSim:printSummary()
  
  -- Test 9: No Power (TPWR = 0)
  print("[TEST] Test 9: No Power (Radio Off)")
  drawCalls = {}
  TelSim:setValue("TPWR", 0)
  BattWidget.refresh(widget)
  assert(#drawCalls > 0, "Should display message when power is off")
  print("  [PASS] No power message displayed")
  print("  TPWR: 0 mW (Radio Off)\n")
  
  -- Test 10: Single Cell Battery (3.7V)
  print("[TEST] Test 10: Single Cell Battery")
  drawCalls = {}
  TelSim:setValue("RxBt", 3.7)
  TelSim:setValue("TPWR", 100)
  TelSim:setValue("Curr", 0.5)
  BattWidget.refresh(widget)
  assert(#drawCalls > 0, "Should handle single cell voltage")
  print("  [PASS] Single cell (3.7V) handled correctly")
  print("  RxBt: 3.7V, Curr: 0.5A\n")
  
  -- Test 11: High Capacity Discharge
  print("[TEST] Test 11: High Capacity Discharge")
  drawCalls = {}
  TelSim:setValue("RxBt", 11.2)
  TelSim:setValue("Curr", 8.5)
  TelSim:setValue("Capa", 1500)
  TelSim:setValue("TPWR", 250)
  BattWidget.refresh(widget)
  assert(#drawCalls > 0, "Should display high capacity discharge")
  print("  [PASS] High capacity discharge displayed")
  print("  RxBt: 11.2V, Curr: 8.5A, Capa: 1500mAh\n")
  
  -- Test 12: Widget Destroy
  print("[TEST] Test 12: Widget Cleanup")
  assert(widget.icons ~= nil, "Icons should exist before destroy")
  BattWidget.destroy(widget)
  assert(widget.icons == nil, "Icons should be cleaned up")
  print("  [PASS] Widget destroyed successfully")
  print("  [PASS] Icons cleaned up\n")
  
  print("===========================================")
  print("  [PASS] All 12 BattWidget tests passed!")
  print("===========================================\n")
end

testBattWidget()
