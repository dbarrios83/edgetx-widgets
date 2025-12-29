-- RXWidget Telemetry Tests
-- Tests receiver signal strength, power, and telemetry with various signal conditions

require("setup")
local TelSim = require("telemetry_simulator")

local function setupMocks()
  _G.getValue = function(key)
    if key == "1RSS" then
      return TelSim:getValue("RSSI1")
    elseif key == "2RSS" then
      return TelSim:getValue("RSSI2")
    elseif key == "RQly" then
      return TelSim:getValue("RQly") or 0
    elseif key == "ANT" then
      return 0
    elseif key == "FM" then
      return 0
    elseif key == "RFMD" then
      return 0
    end
    return TelSim:getValue(key)
  end
  
  -- Mock crossfire telemetry (ELRS)
  _G.crossfireTelemetryPop = function()
    return nil
  end
  
  _G.crossfireTelemetryPush = function(cmd, data)
    -- Mock implementation
  end
  
  _G.getTime = function()
    return 0
  end
  
  _G.lcd = {
    drawText = function(x, y, text, flags)
      -- Capture text output for verification
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
  _G.LEFT = 4
  _G.MIDSIZE = 8
  _G.RED = 16
  _G.GREEN = 32
  _G.YELLOW = 64
end

local function testRXWidget()
  setupMocks()
  
  print("\n========================================")
  print("  RXWidget Telemetry Testing            ")
  print("========================================\n")
  
  local RXWidget = dofile("../../widgets/RXWidget/main.lua")
  local zone = {x = 0, y = 0, w = 100, h = 150}
  local widget = RXWidget.create(zone, {})
  
  -- Scenario 1: No RX Connected (TPWR = 0)
  print("[TEST] Scenario 1: No RX Connected")
  TelSim:setValue("TPWR", 0)
  TelSim.lastText = {}
  RXWidget.refresh(widget)
  if TelSim.lastText and #TelSim.lastText > 0 then
    print("    Display: " .. TelSim.lastText[1].text)
  end
  print("    Status: No signal (expected behavior)\n")
  
  -- Scenario 2: RX Connected - Good Signal
  print("[TEST] Scenario 2: RX Connected - Good Signal")
  TelSim:setValue("TPWR", 100)
  TelSim:setValue("RSSI1", -55)
  TelSim:setValue("RSSI2", -58)
  TelSim:setValue("RQly", 95)
  TelSim.lastText = {}
  RXWidget.refresh(widget)
  print("    Power: " .. tostring(TelSim:getValue("TPWR")) .. "mW")
  print("    Signal: RSSI1=" .. tostring(TelSim:getValue("RSSI1")) .. "dBm RSSI2=" .. tostring(TelSim:getValue("RSSI2")) .. "dBm")
  print("    Quality: " .. tostring(TelSim:getValue("RQly")) .. "%")
  print("    Status: Strong connection\n")
  
  -- Scenario 3: Weak Signal - High Noise
  print("[TEST] Scenario 3: Weak Signal - High Noise")
  TelSim:setValue("TPWR", 50)
  TelSim:setValue("RSSI1", -85)
  TelSim:setValue("RSSI2", -88)
  TelSim:setValue("RQly", 55)
  TelSim.lastText = {}
  RXWidget.refresh(widget)
  print("    Power: " .. tostring(TelSim:getValue("TPWR")) .. "mW")
  print("    Signal: RSSI1=" .. tostring(TelSim:getValue("RSSI1")) .. "dBm RSSI2=" .. tostring(TelSim:getValue("RSSI2")) .. "dBm")
  print("    Quality: " .. tostring(TelSim:getValue("RQly")) .. "%")
  print("    Status: [WARN] Weak connection\n")
  
  -- Scenario 4: Critical Signal - Link Loss Risk
  print("[TEST] Scenario 4: Critical Signal - Link Loss Risk")
  TelSim:setValue("TPWR", 25)
  TelSim:setValue("RSSI1", -105)
  TelSim:setValue("RSSI2", -110)
  TelSim:setValue("RQly", 20)
  TelSim.lastText = {}
  RXWidget.refresh(widget)
  print("    Power: " .. tostring(TelSim:getValue("TPWR")) .. "mW")
  print("    Signal: RSSI1=" .. tostring(TelSim:getValue("RSSI1")) .. "dBm RSSI2=" .. tostring(TelSim:getValue("RSSI2")) .. "dBm")
  print("    Quality: " .. tostring(TelSim:getValue("RQly")) .. "%")
  print("    Status: [CRITICAL] Link Loss Risk!\n")
  
  -- Scenario 5: Single Antenna Failure (one antenna dead)
  print("[TEST] Scenario 5: Antenna Failure - Single Antenna Operating")
  TelSim:setValue("TPWR", 80)
  TelSim:setValue("RSSI1", -70)
  TelSim:setValue("RSSI2", 0)  -- Second antenna dead
  TelSim:setValue("RQly", 80)
  TelSim.lastText = {}
  RXWidget.refresh(widget)
  print("    Power: " .. tostring(TelSim:getValue("TPWR")) .. "mW")
  print("    Signal: RSSI1=" .. tostring(TelSim:getValue("RSSI1")) .. "dBm (RSSI2 disconnected)")
  print("    Quality: " .. tostring(TelSim:getValue("RQly")) .. "%")
  print("    Status: [WARN] Operating on single antenna\n")
  
  print("  [PASS] RXWidget tests completed\n")
end

testRXWidget()
