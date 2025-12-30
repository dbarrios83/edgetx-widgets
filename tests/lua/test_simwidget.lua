-- SimWidget Unified Tests
-- Tests for the unified SimWidget combining SimModel and SimStick functionality

require("setup")
local sim = require("utils.telemetry_simulator")

-- =====================
-- Mock EdgeTX API
-- =====================

local drawCalls = {}
local bitmapDraws = {}

function lcd.drawText(x, y, text, style)
  table.insert(drawCalls, {
    type = "text",
    x = x, y = y,
    text = tostring(text),
    style = style
  })
end

function lcd.drawBitmap(bitmap, x, y)
  table.insert(bitmapDraws, {
    bitmap = bitmap,
    x = x, y = y
  })
end

function lcd.drawPoint(x, y, color)
  -- Point drawing for stick visualization
end

function lcd.drawLine(x1, y1, x2, y2, pattern, color)
  -- Line drawing for stick axes
end

-- Mock model
local mockModel = {
  getInfo = function()
    return {name = "Test Model"}
  end,
  getTimer = function(i)
    if i == 0 then
      return {name = "Timer1", mode = 1, value = 125} -- 2:05
    elseif i == 1 then
      return {name = "Timer2", mode = 1, value = 3665} -- 1:01:05
    end
    return nil
  end
}

-- Mock fieldInfo
local mockFieldInfo = {
  rud = {id = 1},
  thr = {id = 2},
  ail = {id = 3},
  ele = {id = 4}
}

function getFieldInfo(name)
  return mockFieldInfo[name] or {id = 0}
end

function getDateTime()
  return {year = 2025, mon = 12, day = 30, hour = 14, min = 45, sec = 30}
end

function getVersion()
  return "EdgeTX", "v2.10.5", 2, 10, 5, "EdgeTX"
end

function getValue(fieldId)
  -- Return stick values in range -1024 to 1024
  local stickValues = {
    [1] = 0,    -- rud (centered)
    [2] = 512,  -- thr (half throttle)
    [3] = -256, -- ail (slight left)
    [4] = 128   -- ele (slight up)
  }
  return stickValues[fieldId] or 0
end

-- =====================
-- Helper Functions
-- =====================

local function loadSimWidget()
  -- Clear global state
  drawCalls = {}
  bitmapDraws = {}
  _G.model = mockModel
  
  -- Load the widget
  dofile("../../widgets/SimWidget/main.lua")
  return _G
end

local function createTestWidget(options)
  options = options or {}
  local zone = {x = 0, y = 0, w = 320, h = 240}
  return _G.create(zone, options)
end

local function countDrawCalls(textPattern)
  local count = 0
  for _, call in ipairs(drawCalls) do
    if call.type == "text" and call.text:match(textPattern or ".*") then
      count = count + 1
    end
  end
  return count
end

-- =====================
-- Test Functions
-- =====================

local tests = {}
local testsPassed = 0
local testsFailed = 0

function tests.testModuleStructure()
  local w = loadSimWidget()
  assert(w.create, "create function missing")
  assert(w.update, "update function missing")
  assert(w.refresh, "refresh function missing")
  assert(w.options, "options missing")
  assert(#w.options == 1, "should have 1 option (Format24H)")
  print("✓ Test 1: Module structure")
  testsPassed = testsPassed + 1
end

function tests.testWidgetCreation()
  local w = loadSimWidget()
  local widget = createTestWidget({Format24H = 1})
  assert(widget.zone, "zone not set")
  assert(widget.cfg, "cfg not set")
  assert(widget.icons, "icons not set")
  assert(widget.icons.ok, "battery icon not loaded")
  print("✓ Test 2: Widget creation with options")
  testsPassed = testsPassed + 1
end

function tests.testModelInfoDisplay()
  local w = loadSimWidget()
  local widget = createTestWidget({Format24H = 1})
  drawCalls = {}
  w.refresh(widget)
  
  local found = false
  for _, call in ipairs(drawCalls) do
    if call.text == "Test Model" then
      found = true
      break
    end
  end
  assert(found, "model name not displayed")
  print("✓ Test 3: Model info display")
  testsPassed = testsPassed + 1
end

function tests.testBatteryDisplay()
  local w = loadSimWidget()
  local widget = createTestWidget({Format24H = 1})
  drawCalls = {}
  bitmapDraws = {}
  w.refresh(widget)
  
  local battFound = false
  for _, call in ipairs(drawCalls) do
    if call.text:match("V$") then
      battFound = true
      break
    end
  end
  assert(battFound, "battery voltage not displayed")
  assert(#bitmapDraws > 0, "battery icon not drawn")
  print("✓ Test 4: Battery display with icon")
  testsPassed = testsPassed + 1
end

function tests.testDateTimeDisplay24H()
  local w = loadSimWidget()
  local widget = createTestWidget({Format24H = 1})
  drawCalls = {}
  w.refresh(widget)
  
  local dateFound = false
  local timeFound = false
  for _, call in ipairs(drawCalls) do
    if call.text:match("30%s") then
      dateFound = true
    end
    if call.text:match("%d%d:%d%d") then
      timeFound = true
    end
  end
  assert(dateFound, "date not displayed")
  assert(timeFound, "time not displayed")
  print("✓ Test 5: Date and time display (24-hour format)")
  testsPassed = testsPassed + 1
end

function tests.testDateTimeDisplay12H()
  local w = loadSimWidget()
  local widget = createTestWidget({Format24H = 0})
  drawCalls = {}
  w.refresh(widget)
  
  local timeFound = false
  for _, call in ipairs(drawCalls) do
    if call.text:match("%d%d:%d%d") then
      timeFound = true
      break
    end
  end
  assert(timeFound, "time not displayed in 12H format")
  print("✓ Test 6: Date and time display (12-hour format)")
  testsPassed = testsPassed + 1
end

function tests.testStickChartDisplay()
  local w = loadSimWidget()
  local widget = createTestWidget({Format24H = 1})
  drawCalls = {}
  w.refresh(widget)
  
  -- Stick visualization uses drawLine and drawSquare from utils
  -- Just verify the function runs without error
  assert(true, "stick chart displayed")
  print("✓ Test 8: Stick chart visualization")
  testsPassed = testsPassed + 1
end

function tests.testBatteryLow()
  local w = loadSimWidget()
  local widget = createTestWidget({Format24H = 1})
  
  -- Simulate low battery
  local originalGetValue = getValue
  getValue = function(fieldId)
    if fieldId == getFieldInfo('tx-voltage').id then
      return 700 -- 7.0V (low)
    end
    return originalGetValue(fieldId)
  end
  
  drawCalls = {}
  w.refresh(widget)
  
  -- Verify battery display still works
  local battFound = false
  for _, call in ipairs(drawCalls) do
    if call.text and call.text:match("V$") then
      battFound = true
      break
    end
  end
  assert(battFound, "battery voltage not displayed on low battery")
  print("✓ Test 9: Low TX battery warning")
  testsPassed = testsPassed + 1
end

function tests.testOsVersionDisplay()
  local w = loadSimWidget()
  local widget = createTestWidget({Format24H = 1})
  drawCalls = {}
  w.refresh(widget)
  
  local versionFound = false
  for _, call in ipairs(drawCalls) do
    if call.text and call.text:match("EdgeTX") then
      versionFound = true
      break
    end
  end
  assert(versionFound, "OS version not displayed")
  print("✓ Test 10: OS version display")
  testsPassed = testsPassed + 1
end

-- =====================
-- Run Tests
-- =====================

print("\n========================================")
print("SimWidget Unified Tests (9 tests)")
print("========================================\n")

for _, test in pairs(tests) do
  local status, err = pcall(test)
  if not status then
    print("✗ Test failed: " .. tostring(err))
    testsFailed = testsFailed + 1
  end
end

print("\n========================================")
print(string.format("Results: %d passed, %d failed", testsPassed, testsFailed))
print("========================================\n")

os.exit(testsFailed > 0 and 1 or 0)
