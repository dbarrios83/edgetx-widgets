# EdgeTX Companion Simulator Integration Guide

## Overview

This guide explains how to use the telemetry simulator with the EdgeTX Companion Simulator to test your widgets with realistic telemetry data before deploying to a real radio.

## What You Have

### Test Files Location
```
tests/lua/
├── test_telemetry.lua       # BattWidget telemetry scenarios
├── test_rxwidget.lua        # RXWidget signal strength scenarios
├── test_gpswidget.lua       # GPSWidget satellite acquisition scenarios  
├── test_clockwidget.lua     # ClockWidget date/time and signal display scenarios
└── test_widgets.lua         # (Legacy) single file test runner
```

### Utility Modules
```
tests/utils/
└── telemetry_simulator.lua  # Core telemetry simulation module
```

### Running Local Tests

All tests run independently without the Companion Simulator:

```bash
cd tests/lua
lua test_telemetry.lua      # Battery widget tests (4 scenarios)
lua test_rxwidget.lua       # Receiver signal tests (5 scenarios)
lua test_gpswidget.lua      # GPS satellite tests (6 scenarios)
lua test_clockwidget.lua    # Clock and timers tests (7 scenarios)
```

**Total: 22 test scenarios covering all widget behaviors**

## Integration with Companion Simulator

### Step 1: Setup Widget Files in Companion

1. In EdgeTX Companion, create a test model
2. Add your widgets to the radio simulator
3. Ensure widget paths are correct:
   ```
   /WIDGETS/BattWidget/
   /WIDGETS/RXWidget/
   /WIDGETS/GPSWidget/
   /WIDGETS/ClockWidget/
   ```

### Step 2: Create a Telemetry Injection Script

Create `simulator_telemetry.lua` in your project:

```lua
-- Telemetry injection script for Companion Simulator
-- Run this in the Companion Simulator's Lua console

local TelSim = require("tests/utils/telemetry_simulator")

-- Apply a profile
TelSim:applyProfile("cruising")

-- Or manually control telemetry
TelSim:setValue("RxBt", 11.8)
TelSim:setValue("Curr", 15.0)
TelSim:setValue("GpsSATS", 12)

-- Check current values
TelSim:printSummary()
```

### Step 3: Test Scenarios in Simulator

#### Test 1: Normal Flight Operations
```lua
local TelSim = require("tests/utils/telemetry_simulator")
TelSim:applyProfile("cruising")
TelSim:printSummary()
```
- Battery: 12.0V, 8.5A
- GPS: 15 satellites
- Signal: -75 dBm
- Altitude: 100m

#### Test 2: Critical Battery
```lua
TelSim:applyProfile("lowbattery")
TelSim:printSummary()
```
- Battery: **10.2V** (warning threshold)
- High current draw: 12A
- Lower signal: -80/-85 dBm

#### Test 3: Poor GPS Lock
```lua
TelSim:setValue("GpsSATS", 3)
TelSim:setValue("RSSI1", -95)
TelSim:setValue("RSSI2", -98)
TelSim:printSummary()
```
- Weak GPS acquisition
- Weak signal strength
- Possible link loss

#### Test 4: Loss of Signal (Link Loss)
```lua
TelSim:setValue("TPWR", 0)
TelSim:printSummary()
```
- Radio powered off
- All widgets should show "No Connection"

## Testing Checklist

### BattWidget
- [ ] Display updates with battery voltage changes
- [ ] Current draw displays correctly (5-20A range)
- [ ] Low battery warning activates below 10.5V
- [ ] Correct icon displayed for each voltage range
- [ ] Capacity counter increments during flight

### RXWidget  
- [ ] Shows "No RX Connected" when TPWR = 0
- [ ] Displays dual antenna RSSI when both available
- [ ] Shows single antenna when one antenna fails
- [ ] Quality percentage reflects signal strength
- [ ] Power display updates correctly

### GPSWidget
- [ ] Displays satellite count (0-20+)
- [ ] Location displays in DMS format
- [ ] Icons change color: red (<5), yellow (5-7), green (8+)
- [ ] Shows "No GPS" with 0 satellites
- [ ] Coordinates option toggle works
- [ ] Retains last known position on signal loss

### ClockWidget
- [ ] 24-hour format displays correctly (00:00-23:59)
- [ ] 12-hour format with AM/PM works
- [ ] ISO 8601 format displays (YYYY-MM-DD HH:MM)
- [ ] Connection indicator changes color:
  - Black: No power (TPWR=0)
  - Red: Poor signal (RQly<60%)
  - Yellow: Fair signal (RQly 60-80%)
  - Green: Good signal (RQly>80%)
- [ ] Timers display correctly when enabled
- [ ] Hidden timers (mode=off) don't display

## Telemetry Profiles Reference

### idle
```
Ground station, radio on, no flight
RxBt: 12.8V, Curr: 0.5A
GpsSATS: 12, RSSI: -45/-50
```

### takeoff  
```
Rapid acceleration and altitude gain
RxBt: 12.5V, Curr: 15.0A
GpsSATS: 15, RSSI: -65/-68
```

### cruising
```
Stable steady flight
RxBt: 12.0V, Curr: 8.5A
Alt: 100m, Speed: 10m/s
GpsSATS: 15, RSSI: -75/-78
```

### landing
```
Descent and landing sequence
RxBt: 11.5V, Curr: 10.0A
Alt: 5m, Speed: 1m/s
GpsSATS: 14, RSSI: -55/-60
```

### lowbattery
```
CRITICAL - Battery low
RxBt: 10.2V, Curr: 12.0A
GpsSATS: 10, RSSI: -80/-85
```

## Advanced: Custom Telemetry Scenarios

Add your own profiles to `tests/utils/telemetry_simulator.lua`:

```lua
telemetrySimulator.profiles.windy_conditions = {
  description = "High wind during flight",
  RxBt = 11.8,
  Curr = 18.0,      -- Higher current fighting wind
  Capa = 600,
  TPWR = 100,
  GpsSATS = 8,      -- Wind affects GPS
  RSSI1 = -88,      -- Weaker signal
  RSSI2 = -92,
  Alt = 80,
  Speed = 8,        -- Slower due to wind
  Pitch = 15,       -- More pitch angle
  Roll = -12,
}
```

Then use:
```lua
TelSim:applyProfile("windy_conditions")
```

## Tips for Effective Testing

1. **Test Edge Cases**: Low battery, no GPS, weak signal
2. **Test State Changes**: Transition between profiles smoothly
3. **Monitor Display Updates**: Watch how widgets respond to changes
4. **Check Icon Colors**: Verify visual warnings are clear
5. **Verify Text Accuracy**: Ensure displayed values match telemetry
6. **Test All Options**: Toggle widget configuration options
7. **Check Formatting**: Verify date/time/coordinate formatting

## Troubleshooting

### Widgets Not Updating
- Ensure telemetry keys match widget expectations
- Check widget is calling `getValue()` correctly
- Verify Companion Simulator is running the test script

### Incorrect Display Format
- GPS coordinates should be DMS (degrees-minutes-seconds)
- Time should match format configuration (24h or 12h)
- Battery should show voltage with decimal places

### Missing Telemetry Values
- Check telemetry key names in widget code
- Add missing keys to `tests/utils/telemetry_simulator.lua`
- Use mock functions that map widget expectations

## Real Radio Testing

After simulating successfully:

1. Deploy widgets to real radio
2. Connect battery (safely, disconnected from drone)
3. Power on and verify displays
4. Test with different power levels (50%, 100%)
5. Monitor for any edge cases

## Support

For issues or questions:
1. Check widget Lua files for expected telemetry keys
2. Review telemetry simulator profiles
3. Add custom telemetry values as needed
4. Create new test scenarios for specific conditions
