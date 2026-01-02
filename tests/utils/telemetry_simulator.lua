-- EdgeTX Telemetry Simulator
-- Simulates realistic telemetry data for widget testing in EdgeTX Companion Simulator
-- This script can be run in the simulator to inject telemetry values

local telemetrySimulator = {}

-- Telemetry data storage
telemetrySimulator.data = {
  -- Battery telemetry
  RxBt = 12.6,    -- RX Battery voltage (volts)
  Curr = 5.5,     -- Current draw (amps)
  Capa = 2200,    -- Battery capacity used (mAh)
  TPWR = 100,     -- Transmitter power (%)
  
  -- GPS telemetry
  Lat = 37.7749,  -- Latitude
  Lon = -122.4194, -- Longitude
  Gps = 10,       -- GPS status/satellite count
  GpsSATS = 10,   -- Satellite count
  
  -- Signal strength
  RSSI1 = -65,    -- Signal strength antenna 1 (dBm)
  RSSI2 = -70,    -- Signal strength antenna 2 (dBm)
  RQly = 95,      -- Link quality (%)
  
  -- Flight data
  Alt = 125.5,    -- Altitude (meters)
  Speed = 15.3,   -- Speed (m/s)
  Hdg = 270,      -- Heading (degrees)
  
  -- Attitude
  Pitch = 5.2,    -- Pitch angle (degrees)
  Roll = -3.1,    -- Roll angle (degrees)
  Yaw = 270.5,    -- Yaw angle (degrees)
  
  -- Transmitter
  ["tx-voltage"] = 8.2,  -- TX battery voltage (volts)
  
  -- Stick positions (raw values: -1024 to 1024)
  ail = 0,        -- Aileron
  ele = 0,        -- Elevator  
  thr = 0,        -- Throttle
  rud = 0,        -- Rudder
  
  -- Timers
  timer1 = 0,     -- Timer 1 (seconds)
  timer2 = 0,     -- Timer 2 (seconds)
  timer3 = 0,     -- Timer 3 (seconds)
  
  -- Other
  Fuel = 85,      -- Fuel remaining (%)
  Temp1 = 45.2,   -- Temperature 1 (deg C)
  Temp2 = 42.1,   -- Temperature 2 (deg C)
}

-- Simulation states
telemetrySimulator.state = {
  running = false,
  time = 0,
  flightTime = 0,
}

-- Telemetry variation profiles for realistic behavior
telemetrySimulator.profiles = {
  idle = {
    description = "Ground station - radio on, drone not flying",
    RxBt = 12.8,
    Curr = 0.5,
    Capa = 0,
    TPWR = 50,
    GpsSATS = 12,
    RSSI1 = -45,
    RSSI2 = -50,
    Alt = 0,
    Speed = 0,
  },
  
  takeoff = {
    description = "Drone taking off",
    RxBt = 12.5,
    Curr = 15.0,
    Capa = 50,
    TPWR = 100,
    GpsSATS = 15,
    RSSI1 = -65,
    RSSI2 = -68,
    Alt = 5,
    Speed = 2,
  },
  
  cruising = {
    description = "Drone cruising at steady altitude",
    RxBt = 12.0,
    Curr = 8.5,
    Capa = 500,
    TPWR = 80,
    GpsSATS = 15,
    RSSI1 = -75,
    RSSI2 = -78,
    Alt = 100,
    Speed = 10,
  },
  
  landing = {
    description = "Drone descending and landing",
    RxBt = 11.5,
    Curr = 10.0,
    Capa = 1200,
    TPWR = 100,
    GpsSATS = 14,
    RSSI1 = -55,
    RSSI2 = -60,
    Alt = 5,
    Speed = 1,
  },
  
  lowbattery = {
    description = "Low battery warning scenario",
    RxBt = 10.2,    -- Critical voltage
    Curr = 12.0,
    Capa = 1800,
    TPWR = 50,
    GpsSATS = 10,
    RSSI1 = -80,
    RSSI2 = -85,
    Alt = 50,
    Speed = 8,
  },
}

-- Apply a profile (scenario) to telemetry
function telemetrySimulator:applyProfile(profileName)
  local profile = self.profiles[profileName]
  if not profile then
    return false, "Profile not found: " .. profileName
  end
  
  for key, value in pairs(profile) do
    if key ~= "description" then
      self.data[key] = value
    end
  end
  
  return true, "Applied profile: " .. profileName .. " - " .. profile.description
end

-- Add variation to simulate real-world telemetry changes
function telemetrySimulator:updateWithVariation(deltaTime)
  -- Simulate altitude change
  if self.state.running then
    self.state.time = self.state.time + deltaTime
    self.state.flightTime = self.state.flightTime + deltaTime
    
    -- Gradual battery drain during flight
    if self.state.flightTime > 0 then
      local drainRate = 0.05 * deltaTime  -- ~5% drain per minute
      self.data.RxBt = math.max(self.data.RxBt - drainRate, 9.0)
      self.data.Capa = self.data.Capa + (self.data.Curr * deltaTime / 3600) * 1000  -- Convert to mAh
    end
    
    -- Simulate signal variation
    local signalVariation = math.sin(self.state.time / 5) * 5  -- ±5 dBm variation
    self.data.RSSI1 = -65 + signalVariation
    self.data.RSSI2 = -70 + signalVariation
    
    -- Simulate GPS satellite tracking
    if self.data.GpsSATS < 15 then
      if math.random() > 0.9 then
        self.data.GpsSATS = self.data.GpsSATS + 1
      end
    end
  end
end

-- Start simulation
function telemetrySimulator:start()
  self.state.running = true
  self.state.time = 0
  self.state.flightTime = 0
  return "Telemetry simulation started"
end

-- Stop simulation
function telemetrySimulator:stop()
  self.state.running = false
  return "Telemetry simulation stopped"
end

-- Reset all telemetry to defaults
function telemetrySimulator:reset()
  self.state.flightTime = 0
  self.data = {
    RxBt = 12.6,
    Curr = 5.5,
    Capa = 2200,
    TPWR = 100,
    Lat = 37.7749,
    Lon = -122.4194,
    Gps = 10,
    GpsSATS = 10,
    RSSI1 = -65,
    RSSI2 = -70,
    Alt = 125.5,
    Speed = 15.3,
    Hdg = 270,
    Pitch = 5.2,
    Roll = -3.1,
    Yaw = 270.5,
    Fuel = 85,
    Temp1 = 45.2,
    Temp2 = 42.1,
  }
  return "Telemetry reset to defaults"
end

-- Get current telemetry value
function telemetrySimulator:getValue(key)
  return self.data[key]
end

-- Set a specific telemetry value
function telemetrySimulator:setValue(key, value)
  -- Special handling for GPS - store directly without validation
  if key == "GPS" then
    self.data[key] = value
    return true, "GPS set"
  end
  
  if self.data[key] ~= nil then
    self.data[key] = value
    return true, key .. " set to " .. tostring(value)
  else
    return false, "Unknown telemetry key: " .. key
  end
end

-- Get all telemetry values
function telemetrySimulator:getAllValues()
  return self.data
end

-- Print telemetry summary
function telemetrySimulator:printSummary()
  print("\n=== Telemetry Summary ===")
  print("Battery: " .. string.format("%.2f", self.data.RxBt) .. "V - " .. string.format("%.1f", self.data.Curr) .. "A - " .. self.data.Capa .. "mAh")
  print("Power: " .. self.data.TPWR .. "%")
  print("GPS: Sat=" .. self.data.GpsSATS .. " Lat=" .. string.format("%.4f", self.data.Lat) .. " Lon=" .. string.format("%.4f", self.data.Lon))
  print("Signal: RSSI1=" .. string.format("%.0f", self.data.RSSI1) .. "dBm RSSI2=" .. string.format("%.0f", self.data.RSSI2) .. "dBm")
  print("Flight: Alt=" .. string.format("%.1f", self.data.Alt) .. "m Spd=" .. string.format("%.1f", self.data.Speed) .. "m/s Hdg=" .. self.data.Hdg .. "deg")
  print("Attitude: Pitch=" .. string.format("%.1f", self.data.Pitch) .. "deg Roll=" .. string.format("%.1f", self.data.Roll) .. "deg Yaw=" .. string.format("%.1f", self.data.Yaw) .. "deg")
  print("Temperature: T1=" .. string.format("%.1f", self.data.Temp1) .. "C T2=" .. string.format("%.1f", self.data.Temp2) .. "C")
  print()
end

-- List available profiles
function telemetrySimulator:listProfiles()
  print("\n=== Available Telemetry Profiles ===")
  for name, profile in pairs(self.profiles) do
    print("  " .. name .. ": " .. profile.description)
  end
  print()
end

return telemetrySimulator
