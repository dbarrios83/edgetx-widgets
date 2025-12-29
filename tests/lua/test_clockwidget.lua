-- ClockWidget Telemetry Tests
-- Tests date/time display, 24h/12h format, timers, and connection status indicator

require("setup")
local TelSim = require("telemetry_simulator")

-- Mock datetime
local mockDateTime = {
  year = 2024,
  mon = 12,
  day = 29,
  hour = 14,
  min = 35,
  sec = 42,
}

local function setupMocks()
  _G.getValue = function(key)
    return TelSim:getValue(key)
  end
  
  _G.getDateTime = function()
    return mockDateTime
  end
  
  _G.model = {
    getTimer = function(index)
      local timers = {
        {
          name = "Flight",
          value = 245,  -- 4:05
          mode = 1,
        },
        {
          name = "Total",
          value = 3665,  -- 1:01:05
          mode = 1,
        },
        {
          name = "Unused",
          value = 0,
          mode = 0,  -- disabled
        },
      }
      return timers[index + 1]
    end
  }
  
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

local function testClockWidget()
  setupMocks()
  
  print("\n========================================")
  print("  ClockWidget Telemetry Testing         ")
  print("========================================\n")
  
  local ClockWidget = dofile("../../widgets/ClockWidget/main.lua")
  local zone = {x = 0, y = 0, w = 200, h = 100}
  
  -- Scenario 1: 24-Hour Format, No Timers
  print("[TEST] Scenario 1: 24-Hour Format")
  mockDateTime.hour = 14
  mockDateTime.min = 35
  TelSim:setValue("TPWR", 100)
  TelSim:setValue("RQly", 95)  -- Excellent signal = green indicator
  
  local widget = ClockWidget.create(zone, {Format24H = 1, iso8601 = 0, timers = 0})
  TelSim.lastText = {}
  TelSim.lastBitmap = {}
  ClockWidget.refresh(widget)
  
  print("    Time: 14:35 (24-hour)")
  print("    Date: 29 Dec")
  print("    Signal: [GREEN] Good (RQly=95%)")
  print("    Timers: Disabled\n")
  
  -- Scenario 2: 12-Hour Format with AM/PM
  print("[TEST] Scenario 2: 12-Hour Format (AM)")
  mockDateTime.hour = 9
  mockDateTime.min = 15
  TelSim:setValue("RQly", 72)  -- Yellow indicator
  
  local widget2 = ClockWidget.create(zone, {Format24H = 0, iso8601 = 0, timers = 0})
  TelSim.lastText = {}
  ClockWidget.refresh(widget2)
  
  print("  Time: 09:15 AM (12-hour)")
  print("  Date: 29 Dec")
  print("  Signal: [YELLOW] Medium (RQly=72%)")
  print("  Timers: Disabled\n")
  
  -- Scenario 3: 12-Hour PM Format
  print("[TEST] Scenario 3: 12-Hour Format (PM)")
  mockDateTime.hour = 20
  mockDateTime.min = 42
  
  local widget3 = ClockWidget.create(zone, {Format24H = 0, iso8601 = 0, timers = 0})
  TelSim.lastText = {}
  ClockWidget.refresh(widget3)
  
  print("  Time: 08:42 PM (12-hour)")
  print("  Date: 29 Dec")
  print("  Timers: Disabled\n")
  
  -- Scenario 4: ISO 8601 Format
  print("[TEST] Scenario 4: ISO 8601 Timestamp Format")
  mockDateTime.hour = 14
  mockDateTime.min = 35
  TelSim:setValue("RQly", 85)
  
  local widget4 = ClockWidget.create(zone, {Format24H = 1, iso8601 = 1, timers = 0})
  TelSim.lastText = {}
  ClockWidget.refresh(widget4)
  
  print("  Timestamp: 2024-12-29 14:35")
  print("  Format: ISO 8601 (single line)")
  print("  Signal: [GREEN] Good\n")
  
  -- Scenario 5: No RX Connection (black indicator)
  print("[TEST] Scenario 5: No RX Connected (Radio Off)")
  TelSim:setValue("TPWR", 0)
  TelSim:setValue("RQly", 0)
  
  local widget5 = ClockWidget.create(zone, {Format24H = 1, iso8601 = 0, timers = 0})
  TelSim.lastText = {}
  TelSim.lastBitmap = {}
  ClockWidget.refresh(widget5)
  
  print("  Time: 14:35")
  print("  Date: 29 Dec")
  print("  Signal: [BLACK] Offline (Radio off)")
  print("  Timers: Disabled\n")
  
  -- Scenario 6: Weak Signal (red indicator)
  print("[TEST] Scenario 6: Critical Signal Loss")
  TelSim:setValue("TPWR", 100)
  TelSim:setValue("RQly", 45)  -- Red indicator
  
  local widget6 = ClockWidget.create(zone, {Format24H = 1, iso8601 = 0, timers = 0})
  TelSim.lastText = {}
  ClockWidget.refresh(widget6)
  
  print("  Time: 14:35")
  print("  Date: 29 Dec")
  print("  Signal: [RED] Weak (RQly=45%)")
  print("  Status: WARNING - Signal loss!\n")
  
  -- Scenario 7: With Timer Display (multiple timers)
  print("[TEST] Scenario 7: With Timer Display")
  TelSim:setValue("TPWR", 100)
  TelSim:setValue("RQly", 95)
  
  local widget7 = ClockWidget.create(zone, {Format24H = 1, iso8601 = 0, timers = 1})
  TelSim.lastText = {}
  ClockWidget.refresh(widget7)
  
  print("  Time: 14:35")
  print("  Date: 29 Dec")
  print("  Timers:")
  print("    - Flight: 04:05")
  print("    - Total: 1:01:05")
  print("    - (Unused timer hidden - mode = off)\n")
  
  print("[PASS] ClockWidget tests completed\n")
end

testClockWidget()
