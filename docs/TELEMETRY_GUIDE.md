# Telemetry Simulation Guide for EdgeTX Widgets

## Overview

The telemetry simulator allows you to test widget behavior with realistic telemetry data without needing a real drone. It provides predefined scenarios and allows custom telemetry values.

Located at: `tests/utils/telemetry_simulator.lua`

## Available Telemetry Profiles

### 1. **idle** - Ground Station Idle
- Radio powered on, waiting for flight
- Low current draw, strong signal
- Use to: Test baseline widget display

### 2. **takeoff** - Drone Taking Off
- High current draw (15A)
- Rapid altitude gain
- Strong signal from nearby drone
- Use to: Test widgets under high current conditions

### 3. **cruising** - Stable Flight
- Steady altitude and speed
- Medium current draw (8.5A)
- Normal signal strength
- Use to: Test normal operation

### 4. **landing** - Descending and Landing
- Increasing battery voltage drop
- Stable descent
- Strengthening signal
- Use to: Test low altitude behavior

### 5. **lowbattery** - Low Battery Warning
- Battery voltage: 10.2V (critical)
- High current draw (12A)
- Weaker signal
- **Use to: Test battery warning indicators**

## Using the Telemetry Simulator

### Method 1: Direct Lua Script Testing

Run tests with predefined scenarios:
```bash
cd tests/lua
lua test_telemetry.lua
```

This tests:
- BattWidget with 4 scenarios
- RXWidget with signal variation
- GPSWidget with satellite counts

### Method 2: Custom Testing with Manual Control

Create a test script to control telemetry values:

```lua
local TelSim = require("../utils/telemetry_simulator")

-- Apply a profile
TelSim:applyProfile("cruising")

-- Manually set specific values
TelSim:setValue("RxBt", 11.5)    -- Set battery to 11.5V
TelSim:setValue("Curr", 20.0)    -- Set current to 20A
TelSim:setValue("GpsSATS", 5)    -- Set satellites to 5

-- Get a value
local voltage = TelSim:getValue("RxBt")

-- View all telemetry
TelSim:printSummary()
```

### Method 3: Integration with EdgeTX Companion Simulator

To use with the Companion Simulator:

1. **Copy the simulator to your project:**
   ```
   /widgets/MyWidget/
   /tests/utils/telemetry_simulator.lua
   ```

2. **Create a test widget that uses the simulator:**
   ```lua
   local TelSim = require("telemetry_simulator")
   
   -- Your test code here
   -- Widgets will use TelSim telemetry via mocked getValue()
   ```

3. **Run in Companion Simulator:**
   - Load the test script
   - Change profiles via commands
   - Observe widget updates in real-time

## Available Telemetry Variables

### Battery & Power
- `RxBt` - RX battery voltage (volts)
- `Curr` - Current draw (amps)
- `Capa` - Capacity used (mAh)
- `TPWR` - Transmitter power (%)
- `RQly` - Link quality (%)

### GPS
- `Lat` - Latitude (degrees)
- `Lon` - Longitude (degrees)
- `GpsSATS` - Satellite count
- `Gps` - GPS status

### Signal Strength
- `RSSI1` - Signal strength antenna 1 (dBm)
- `RSSI2` - Signal strength antenna 2 (dBm)

### Flight Data
- `Alt` - Altitude (meters)
- `Speed` - Speed (m/s)
- `Hdg` - Heading (degrees)

### Attitude
- `Pitch` - Pitch angle (degrees)
- `Roll` - Roll angle (degrees)
- `Yaw` - Yaw angle (degrees)

### Other
- `Fuel` - Fuel remaining (%)
- `Temp1` - Temperature 1 (°C)
- `Temp2` - Temperature 2 (°C)

## Testing Scenarios for Each Widget

### BattWidget Testing
Test these scenarios:
1. ✓ Normal operation (12V+, 5-10A)
2. ✓ Low battery (10.2V, high current)
3. ✓ Idle state (12.8V, 0.5A)
4. ✓ High current draw (15A during takeoff)

### RXWidget Testing
Test these signal conditions:
1. ✓ Good signal (-50 dBm)
2. ✓ Medium signal (-70 dBm)
3. ✓ Weak signal (-90 dBm)
4. ✓ Dual antenna scenarios

### GPSWidget Testing
Test these satellite scenarios:
1. ✓ Strong lock (12+ satellites)
2. ✓ Medium lock (7-10 satellites)
3. ✓ Weak lock (4-6 satellites)
4. ✓ No lock (0-2 satellites)
5. ✓ Initializing (0 satellites)

### ClockWidget Testing
1. ✓ 24-hour format
2. ✓ 12-hour format with AM/PM
3. ✓ Timer display
4. ✓ Model timers

## Advanced: Creating Custom Profiles

Add to `tests/utils/telemetry_simulator.lua`:

```lua
telemetrySimulator.profiles.customprofle = {
  description = "Your custom scenario",
  RxBt = 12.0,
  Curr = 10.0,
  Capa = 800,
  GpsSATS = 12,
  RSSI1 = -70,
  -- Add more as needed
}
```

Then use:
```lua
TelSim:applyProfile("customprofle")
```

## Troubleshooting

### Widget Not Responding to Telemetry Changes
- Ensure the widget is loading telemetry via `getValue()`
- Check that widget has been created with a valid zone
- Verify telemetry key names match EdgeTX standard names

### Symbol Encoding Issues
The Unicode box-drawing characters may display as `Ôò` on some terminals. This is cosmetic and doesn't affect functionality.

## Next Steps

1. **Test all widgets** with the telemetry simulator
2. **Verify edge cases** (low battery, no GPS, weak signal)
3. **Document behavior** when telemetry is missing
4. **Integrate with CI/CD** to run tests automatically

