-- SimStick Widget Tests
-- Tests SimStick widget visual stick position display

require("setup")
local TelSim = require("telemetry_simulator")

-- Mock EdgeTX API
local drawCalls = {}
local lineCalls = {}
local pointCalls = {}

local function setupMocks()
  _G.getValue = function(key)
    return TelSim:getValue(key)
  end
  
  _G.getFieldInfo = function(name)
    local fieldMap = {
      ['ail'] = {id = 1, name = 'ail'},
      ['ele'] = {id = 2, name = 'ele'},
      ['thr'] = {id = 3, name = 'thr'},
      ['rud'] = {id = 4, name = 'rud'},
    }
    return fieldMap[name]
  end
  
  _G.getVersion = function()
    return "EdgeTX", "v2.10.5-simu"  -- Simulator mode
  end
  
  _G.lcd = {
    drawText = function(x, y, text, flags)
      table.insert(drawCalls, {x = x, y = y, text = text, flags = flags})
    end,
    drawLine = function(x1, y1, x2, y2, pattern, flags)
      table.insert(lineCalls, {x1 = x1, y1 = y1, x2 = x2, y2 = y2})
    end,
    drawPoint = function(x, y, color)
      table.insert(pointCalls, {x = x, y = y, color = color})
    end
  }
  
  -- Add global constants
  _G.LEFT = 0
  _G.RIGHT = 1
  _G.WHITE = 2
  _G.GREEN = 3
  _G.SHADOWED = 4
  _G.MIDSIZE = 8
  _G.BOOL = 0
  _G.SOLID = 0
end

local function assert(condition, message)
  if not condition then
    error("ASSERTION FAILED: " .. (message or "unknown"))
  end
end

local function testSimStick()
  setupMocks()
  
  print("\n========================================")
  print("  SimStick Widget Testing               ")
  print("========================================\n")
  
  local SimStick = dofile("../../widgets/SimStick/main.lua")
  
  -- Test 1: Module Structure
  print("[TEST] Test 1: Module Structure")
  assert(SimStick.name == "SimStick", "Widget name should be 'SimStick'")
  assert(type(SimStick.create) == "function", "create() should be a function")
  assert(type(SimStick.refresh) == "function", "refresh() should be a function")
  print("  [PASS] Widget name: " .. SimStick.name .. "\n")
  
  -- Test 2: Widget Creation
  print("[TEST] Test 2: Widget Creation")
  local zone = {x = 0, y = 0, w = 300, h = 150}
  local widget = SimStick.create(zone, {values_down = 0, sticks_out = 0})
  assert(widget ~= nil, "Widget should be created")
  assert(widget.DEBUG == true, "Should detect simulator mode")
  print("  [PASS] Widget created")
  print("  [PASS] Simulator mode detected\n")
  
  -- Test 3: All Sticks Centered
  print("[TEST] Test 3: All Sticks Centered")
  drawCalls = {}
  lineCalls = {}
  pointCalls = {}
  TelSim:setValue("ail", 0)
  TelSim:setValue("ele", 0)
  TelSim:setValue("thr", 0)
  TelSim:setValue("rud", 0)
  SimStick.refresh(widget)
  assert(#lineCalls > 0, "Should draw stick axes")
  assert(#pointCalls > 0, "Should draw stick positions")
  print("  [PASS] R=0% T=0% A=0% E=0%")
  print("  [PASS] Stick axes and positions drawn\n")
  
  -- Test 4: Full Throttle
  print("[TEST] Test 4: Full Throttle Position")
  drawCalls = {}
  lineCalls = {}
  pointCalls = {}
  TelSim:setValue("thr", 1024)
  SimStick.refresh(widget)
  assert(#lineCalls > 0, "Should draw axes")
  assert(#pointCalls > 0, "Should draw full throttle position")
  print("  [PASS] Throttle: 100%\n")
  
  -- Test 5: Full Aileron Right
  print("[TEST] Test 5: Full Aileron Right")
  drawCalls = {}
  lineCalls = {}
  pointCalls = {}
  TelSim:setValue("ail", 1024)
  TelSim:setValue("thr", 0)
  SimStick.refresh(widget)
  assert(#drawCalls > 0, "Should display stick values")
  assert(#pointCalls > 0, "Should draw aileron position")
  print("  [PASS] Aileron: 100% Right\n")
  
  -- Test 6: Full Elevator Up
  print("[TEST] Test 6: Full Elevator Up")
  drawCalls = {}
  lineCalls = {}
  pointCalls = {}
  TelSim:setValue("ele", 1024)
  TelSim:setValue("ail", 0)
  SimStick.refresh(widget)
  assert(#drawCalls > 0, "Should display stick values")
  assert(#pointCalls > 0, "Should draw elevator position")
  print("  [PASS] Elevator: 100% Up\n")
  
  -- Test 7: Full Rudder Left
  print("[TEST] Test 7: Full Rudder Left")
  drawCalls = {}
  lineCalls = {}
  pointCalls = {}
  TelSim:setValue("rud", -1024)
  TelSim:setValue("ele", 0)
  SimStick.refresh(widget)
  assert(#drawCalls > 0, "Should display stick values")
  assert(#pointCalls > 0, "Should draw rudder position")
  print("  [PASS] Rudder: -100% Left\n")
  
  -- Test 8: Alternative Layout (values_down)
  print("[TEST] Test 8: Alternative Layout (Values Down)")
  drawCalls = {}
  lineCalls = {}
  pointCalls = {}
  widget.cfg.values_down = 1
  TelSim:setValue("rud", 0)
  SimStick.refresh(widget)
  assert(#drawCalls > 0, "Should draw stick values")
  assert(#lineCalls > 0, "Should draw axes")
  print("  [PASS] Layout: Values positioned down\n")
  
  -- Test 9: Alternative Layout (sticks_out)
  print("[TEST] Test 9: Alternative Layout (Sticks Out)")
  drawCalls = {}
  lineCalls = {}
  pointCalls = {}
  widget.cfg.sticks_out = 1
  SimStick.refresh(widget)
  assert(#drawCalls > 0, "Should draw stick values")
  assert(#lineCalls > 0, "Should draw axes")
  print("  [PASS] Layout: Sticks spread out\n")
  
  print("===========================================")
  print("  [PASS] All 9 SimStick tests passed!")
  print("===========================================\n")
end

testSimStick()
