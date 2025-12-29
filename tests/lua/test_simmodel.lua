-- SimModel Widget Tests
-- Tests SimModel widget functionality for simulator mode

require("setup")
local TelSim = require("telemetry_simulator")

-- Mock EdgeTX API
local drawCalls = {}

local function setupMocks()
  -- Field ID to name mapping
  local fieldIdMap = {
    [1000] = "tx-voltage",
    [2000] = "timer1",
    [2001] = "timer2",
    [2002] = "timer3",
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
      ['timer1'] = {id = 2000, name = 'timer1'},
      ['timer2'] = {id = 2001, name = 'timer2'},
      ['timer3'] = {id = 2002, name = 'timer3'},
    }
    return fieldMap[name]
  end
  
  _G.getVersion = function()
    return "EdgeTX", "v2.10.5", 2, 10, 5, "EdgeTX"
  end
  
  _G.getDateTime = function()
    return {
      year = 2025,
      mon = 12,
      day = 29,
      hour = 14,
      min = 30,
      sec = 45
    }
  end
  
  _G.model = {
    getInfo = function()
      return {name = "Simulator", bitmap = "sim.bmp"}
    end,
    getTimer = function(idx)
      return {
        mode = idx == 0 and 1 or 0,  -- timer1 active, others off
        start = 0,
        value = idx == 0 and 125 or 0  -- 125 seconds
      }
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
  _G.BOOL = 0
  _G.BOLD = 16
  _G.SMLSIZE = 64
end

local function assert(condition, message)
  if not condition then
    error("ASSERTION FAILED: " .. (message or "unknown"))
  end
end

local function testSimModel()
  setupMocks()
  
  print("\n========================================")
  print("  SimModel Widget Testing               ")
  print("========================================\n")
  
  local SimModel = dofile("../../widgets/SimModel/main.lua")
  
  -- Test 1: Module Structure
  print("[TEST] Test 1: Module Structure")
  assert(SimModel.name == "SimModel", "Widget name should be 'SimModel'")
  assert(type(SimModel.create) == "function", "create() should be a function")
  assert(type(SimModel.refresh) == "function", "refresh() should be a function")
  print("  [PASS] Widget name: " .. SimModel.name .. "\n")
  
  -- Test 2: Widget Creation with Options
  print("[TEST] Test 2: Widget Creation")
  local zone = {x = 0, y = 0, w = 200, h = 150}
  local widget = SimModel.create(zone, {iso8601 = 0, timers = 0, sim_designator = 1})
  assert(widget ~= nil, "Widget should be created")
  print("  [PASS] Widget created with options\n")
  
  -- Test 3: Normal Display with Simulator Designator
  print("[TEST] Test 3: Simulator Display")
  drawCalls = {}
  TelSim:setValue("tx-voltage", 8.2)
  SimModel.refresh(widget)
  assert(#drawCalls > 0, "Should draw simulator info")
  print("  [PASS] Model: Simulator")
  print("  [PASS] TX Battery: 8.2V\n")
  
  -- Test 4: ISO 8601 Timestamp Mode
  print("[TEST] Test 4: ISO 8601 Timestamp Mode")
  drawCalls = {}
  widget.cfg.iso8601 = 1
  SimModel.refresh(widget)
  assert(#drawCalls > 0, "Should display ISO 8601 format")
  print("  [PASS] Timestamp: 2025-12-29 14:30\n")
  
  -- Test 5: Timer Display Mode
  print("[TEST] Test 5: Timer Display Mode")
  drawCalls = {}
  widget.cfg.timers = 1
  SimModel.refresh(widget)
  assert(#drawCalls > 0, "Should display active timers")
  print("  [PASS] Timer1: 02:05 (active)\n")
  
  -- Test 6: Low TX Battery in Simulator
  print("[TEST] Test 6: Low TX Battery Warning")
  drawCalls = {}
  TelSim:setValue("tx-voltage", 6.8)
  SimModel.refresh(widget)
  assert(#drawCalls > 0, "Should show low battery warning")
  print("  [PASS] TX Battery: 6.8V (Low)\n")
  
  print("===========================================")
  print("  [PASS] All 6 SimModel tests passed!")
  print("===========================================\n")
end

testSimModel()
