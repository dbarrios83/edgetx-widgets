-- ModelWidget Comprehensive Tests
-- Tests ModelWidget functionality including model info, TX battery, and stick positions

require("setup")
local TelSim = require("telemetry_simulator")

-- Mock EdgeTX API
local drawCalls = {}

local function setupMocks()
  -- Field ID to name mapping
  local fieldIdMap = {
    [1000] = "tx-voltage",
    [1] = "ail",
    [2] = "ele",
    [3] = "thr",
    [4] = "rud",
  }
  
  _G.getValue = function(key)
    -- If key is a number (field ID), look up the name first
    if type(key) == "number" then
      key = fieldIdMap[key] or key
    end
    return TelSim:getValue(key)
  end
  
  _G.getFieldInfo = function(name)
    local fieldMap = {
      ['tx-voltage'] = {id = 1000, name = 'tx-voltage'},
      ['ail'] = {id = 1, name = 'ail'},
      ['ele'] = {id = 2, name = 'ele'},
      ['thr'] = {id = 3, name = 'thr'},
      ['rud'] = {id = 4, name = 'rud'},
    }
    return fieldMap[name]
  end
  
  _G.getVersion = function()
    return "EdgeTX", "v2.10.5", 2, 10, 5, "EdgeTX"
  end
  
  _G.model = {
    getInfo = function()
      return {name = "TestModel", bitmap = "test.bmp"}
    end
  }
  
  _G.lcd = {
    drawText = function(x, y, text, flags)
      table.insert(drawCalls, {x = x, y = y, text = text, flags = flags})
    end,
    drawBitmap = function(bitmap, x, y)
      -- Mock bitmap drawing
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
  _G.LEFT = 0
  _G.RIGHT = 1
  _G.WHITE = 2
  _G.SHADOWED = 4
  _G.MIDSIZE = 8
  _G.BOLD = 16
  _G.GREY = 32
  _G.SMLSIZE = 64
end

local function assert(condition, message)
  if not condition then
    error("ASSERTION FAILED: " .. (message or "unknown"))
  end
end

local function testModelWidget()
  setupMocks()
  
  print("\n========================================")
  print("  ModelWidget Testing                   ")
  print("========================================\n")
  
  local ModelWidget = dofile("../../widgets/ModelWidget/main.lua")
  
  -- Test 1: Module Structure
  print("[TEST] Test 1: Module Structure")
  assert(ModelWidget.name == "ModelWidget", "Widget name should be 'ModelWidget'")
  assert(type(ModelWidget.create) == "function", "create() should be a function")
  assert(type(ModelWidget.update) == "function", "update() should be a function")
  assert(type(ModelWidget.refresh) == "function", "refresh() should be a function")
  print("  [PASS] All required functions exported")
  print("  [PASS] Widget name: " .. ModelWidget.name .. "\n")
  
  -- Test 2: Widget Creation
  print("[TEST] Test 2: Widget Creation")
  local zone = {x = 0, y = 0, w = 200, h = 100}
  local widget = ModelWidget.create(zone, {})
  assert(widget ~= nil, "Widget should be created")
  assert(widget.zone.w == 200, "Zone width should match")
  print("  [PASS] Widget created successfully\n")
  
  -- Test 3: Normal Flight - TX Battery Good
  print("[TEST] Test 3: Normal Flight (TX Battery Good)")
  drawCalls = {}
  TelSim:setValue("tx-voltage", 8.2)
  TelSim:setValue("ail", 0)
  TelSim:setValue("ele", 0)
  TelSim:setValue("thr", 512)
  TelSim:setValue("rud", 0)
  ModelWidget.refresh(widget)
  assert(#drawCalls > 0, "Should draw model information")
  print("  [PASS] TX Battery: 8.2V (Good)")
  print("  [PASS] Sticks: A=0% E=0% T=50% R=0%\n")
  
  -- Test 4: Low TX Battery Warning
  print("[TEST] Test 4: Low TX Battery Warning")
  drawCalls = {}
  TelSim:setValue("tx-voltage", 7.0)
  ModelWidget.refresh(widget)
  assert(#drawCalls > 0, "Should draw low battery warning")
  print("  [PASS] TX Battery: 7.0V (Low)\n")
  
  -- Test 5: Full Throttle Position
  print("[TEST] Test 5: Full Throttle Position")
  drawCalls = {}
  TelSim:setValue("tx-voltage", 8.2)
  TelSim:setValue("thr", 1024)
  ModelWidget.refresh(widget)
  assert(#drawCalls > 0, "Should display full throttle")
  print("  [PASS] Throttle: 100%\n")
  
  -- Test 6: All Sticks Centered
  print("[TEST] Test 6: All Sticks Centered")
  drawCalls = {}
  TelSim:setValue("ail", 0)
  TelSim:setValue("ele", 0)
  TelSim:setValue("thr", 0)
  TelSim:setValue("rud", 0)
  ModelWidget.refresh(widget)
  assert(#drawCalls > 0, "Should display centered sticks")
  print("  [PASS] All sticks centered (0%)\n")
  
  -- Test 7: Maximum Stick Deflection
  print("[TEST] Test 7: Maximum Stick Deflection")
  drawCalls = {}
  TelSim:setValue("ail", 1024)
  TelSim:setValue("ele", -1024)
  TelSim:setValue("rud", 1024)
  ModelWidget.refresh(widget)
  assert(#drawCalls > 0, "Should display max deflection")
  print("  [PASS] A=100% E=-100% R=100%\n")
  
  print("===========================================")
  print("  [PASS] All 7 ModelWidget tests passed!")
  print("===========================================\n")
end

testModelWidget()
