# Widget Testing Setup Guide

## Quick Start

### 1. Install Busted

```bash
luarocks install busted
```

### 2. Run Tests

**Windows:**
```bash
tests/run_tests.bat
```

**Linux/Mac:**
```bash
./tests/run_tests.sh
```

Or directly:
```bash
busted
```

## What's Been Set Up

### File Structure
```
tests/
├── lua/
│   ├── test_telemetry.lua      # BattWidget telemetry scenarios
│   ├── test_rxwidget.lua       # RXWidget signal scenarios
│   ├── test_gpswidget.lua      # GPSWidget satellite scenarios
│   ├── test_clockwidget.lua    # ClockWidget date/time scenarios
│   └── run_all.lua             # Master test runner
├── spec/
│   ├── mocks/
│   │   └── edgetx.lua          # Mock EdgeTX API
│   ├── widgets/
│   │   └── battwidget_spec.lua # BattWidget unit tests
│   └── README.md               # Busted test documentation
├── utils/
│   └── telemetry_simulator.lua # Telemetry simulation module
├── run_tests.bat               # Windows test runner
└── run_tests.sh                # Linux/Mac test runner

docs/
├── TESTING.md                  # This file
├── TELEMETRY_GUIDE.md          # Telemetry variable reference
└── COMPANION_SIMULATOR_GUIDE.md # Integration guide
```

### Current Test Coverage

**Lua Integration Tests (Direct Execution):**
- **test_telemetry.lua**: 4 BattWidget scenarios
- **test_rxwidget.lua**: 5 RXWidget signal scenarios
- **test_gpswidget.lua**: 6 GPSWidget satellite scenarios
- **test_clockwidget.lua**: 7 ClockWidget date/time scenarios
- **Total: 22 realistic test scenarios**

**Busted Unit Tests (Optional):**
- **battwidget_spec.lua**: Widget lifecycle and functionality tests

## Running Tests

### All Lua Tests
```bash
cd tests/lua
lua test_telemetry.lua      # ✓ 4 scenarios
lua test_rxwidget.lua       # ✓ 5 scenarios
lua test_gpswidget.lua      # ✓ 6 scenarios
lua test_clockwidget.lua    # ✓ 7 scenarios
```

### Busted Tests (if installed)
```bash
busted
```

## Test Scenarios by Widget

### BattWidget
1. Healthy battery (12V, 8.5A) - Normal cruising
2. Low battery (10.2V, 12A) - Warning condition
3. Idle state (12.8V, 0.5A) - Ground station
4. High current (12.5V, 15A) - Takeoff phase

### RXWidget
1. No RX Connected (TPWR = 0)
2. Good Signal (-55dBm, 95%)
3. Weak Signal (-85dBm, 55%)
4. Critical Signal (-105dBm, 20%)
5. Single Antenna Failure

### GPSWidget
1. Strong Lock (16 satellites)
2. Medium Lock (9 satellites)
3. Weak Lock (4 satellites)
4. No Lock (0 satellites)
5. Initializing (2 satellites)
6. Lost Lock (last known position)

### ClockWidget
1. 24-Hour Format
2. 12-Hour AM Format
3. 12-Hour PM Format
4. ISO 8601 Timestamp
5. No RX Connection
6. Critical Signal Loss
7. With Timer Display

## Mocking EdgeTX API

The telemetry simulator provides mock implementations of EdgeTX functions:
- `getValue(key)` - Returns mock telemetry data
- `lcd.drawText()` - Mock drawing function
- `lcd.drawBitmap()` - Mock bitmap drawing
- `Bitmap.open()` - Mock bitmap loading

You can modify telemetry values in your tests:
```lua
local TelSim = require("../utils/telemetry_simulator")
TelSim:setValue("RxBt", 12.6)
TelSim:setValue("Curr", 5.5)
```

## Test Results Example

```
✓ BattWidget tests completed
✓ RXWidget tests completed
✓ GPSWidget tests completed
✓ ClockWidget tests completed
```

## Adding New Tests

Create a new file `tests/lua/test_yourwidget.lua`:

```lua
local TelSim = require("../utils/telemetry_simulator")

local function setupMocks()
  _G.getValue = function(key)
    return TelSim:getValue(key)
  end
  -- Add more mocks as needed
end

local function testYourWidget()
  setupMocks()
  
  print("\n╔════════════════════════════════════════╗")
  print("║  YourWidget Telemetry Testing          ║")
  print("╚════════════════════════════════════════╝\n")
  
  local YourWidget = dofile("../../widgets/YourWidget/main.lua")
  local zone = {x = 0, y = 0, w = 100, h = 50}
  local widget = YourWidget.create(zone, {})
  
  -- Test scenarios here
  
  print("✓ YourWidget tests completed\n")
end

testYourWidget()
```

Then run:
```bash
cd tests/lua
lua test_yourwidget.lua
```

## Next Steps

1. ✓ Setup complete with 22 test scenarios
2. Use the telemetry simulator for Companion integration
3. Expand tests for additional widgets
4. Set up CI/CD pipeline for automated testing

## Resources

- [Telemetry Guide](../docs/TELEMETRY_GUIDE.md) - Available telemetry variables
- [Companion Simulator Guide](../docs/COMPANION_SIMULATOR_GUIDE.md) - Integration instructions
