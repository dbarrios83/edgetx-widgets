# EdgeTX Widgets Testing Suite

This directory contains a comprehensive testing framework for EdgeTX widgets using **direct Lua execution** with mocked EdgeTX APIs.

## Testing Approach

**Direct Lua Testing** (No external dependencies required):
- ✓ Uses Lua 5.1 (EdgeTX standard)
- ✓ No frameworks needed (vanilla Lua only)
- ✓ Comprehensive telemetry simulation
- ✓ Complete mock EdgeTX API
- ✓ **52 tests across 7 widgets**

## Directory Structure

```
tests/
├── lua/              # Widget test files
│   ├── test_battwidget.lua    # BattWidget tests (12 tests)
│   ├── test_rxwidget.lua      # RXWidget tests (5 scenarios)
│   ├── test_gpswidget.lua     # GPSWidget tests (6 scenarios)
│   ├── test_clockwidget.lua   # ClockWidget tests (7 scenarios)
│   ├── test_modelwidget.lua   # ModelWidget tests (7 tests)
│   ├── test_simmodel.lua      # SimModel tests (6 tests)
│   ├── test_simstick.lua      # SimStick tests (9 tests)
│   ├── test_structure.lua     # Path validation test
│   └── setup.lua              # Lua path configuration
├── utils/            # Testing utilities
│   └── telemetry_simulator.lua  # EdgeTX telemetry simulator
├── run_tests.bat     # Windows test runner
└── run_tests.sh      # Linux/Mac test runner
```

## Quick Start

### Running All Tests

**Windows:**
```batch
run_tests.bat
```

**Linux/Mac:**
```bash
./run_tests.sh
```

### Running Individual Widget Tests

From the `tests/lua/` directory:

```bash
lua test_battwidget.lua   # BattWidget battery, power, and lifecycle tests
lua test_rxwidget.lua     # RXWidget receiver signal tests
lua test_gpswidget.lua    # GPSWidget GPS lock and location tests
lua test_clockwidget.lua  # ClockWidget time display tests
lua test_modelwidget.lua  # ModelWidget TX battery and stick tests
lua test_simmodel.lua     # SimModel simulator mode tests
lua test_simstick.lua     # SimStick visual stick display tests
```

## Test Coverage

### 52 Total Tests:

1. **BattWidget** (12 tests):
   - Module structure validation
   - Widget creation with zone
   - Icon preloading (5 battery states)
   - Widget update function
   - Healthy battery (12V, 8.5A)
   - Low battery warning (10.2V critical)
   - Ground station idle (12.8V, 0.5A)
   - High current takeoff (15A draw)
   - No power (TPWR=0)
   - Single cell battery (3.7V)
   - High capacity discharge
   - Widget cleanup/destroy

2. **RXWidget** (5 scenarios):
   - No RX connection (TPWR=0)
   - Good signal (-55dBm)
   - Weak signal (-85dBm)
   - Critical signal loss (-105dBm)
   - Antenna failure (single antenna)

3. **GPSWidget** (6 scenarios):
   - Strong GPS lock (16 satellites)
   - Medium lock (9 satellites)
   - Weak lock (4 satellites)
   - No GPS lock (0 satellites)
   - Initializing (2 satellites)
   - Lost lock with last position

4. **ClockWidget** (7 scenarios):
   - 24-hour format
   - 12-hour AM format
   - 12-hour PM format
   - ISO 8601 timestamp
   - No RX connection (black indicator)
   - Critical signal loss (red indicator)
   - Timer display

5. **ModelWidget** (7 tests):
   - Module structure validation
   - Widget creation
   - Normal flight (TX battery good)
   - Low TX battery warning
   - Full throttle position
   - All sticks centered
   - Maximum stick deflection

6. **SimModel** (6 tests):
   - Module structure validation
   - Widget creation with options
   - Simulator display
   - ISO 8601 timestamp mode
   - Timer display mode
   - Low TX battery warning

7. **SimStick** (9 tests):
   - Module structure validation
   - Widget creation (simulator detection)
   - All sticks centered
   - Full throttle position
   - Full aileron right
   - Full elevator up
   - Full rudder left
   - Alternative layout (values down)
   - Alternative layout (sticks out)

## How It Works

### Telemetry Simulator

The `utils/telemetry_simulator.lua` module provides:

- **Mock EdgeTX API**: Simulates `getValue()`, `lcd.drawText()`, `Bitmap.open()`
- **Flight Profiles**: 5 realistic scenarios (idle, takeoff, cruising, landing, lowbattery)
- **25+ Telemetry Variables**: Battery, GPS, signal strength, altitude, speed, etc.

### Test Structure

Each test file:
1. Loads `setup.lua` to configure Lua paths
2. Requires `telemetry_simulator` module
3. Sets up mock functions
4. Applies telemetry profiles
5. Executes widget code
6. Validates output

Example:
```lua
require("setup")
require("telemetry_simulator")

-- Apply flight profile
telemetry.applyProfile("lowbattery")

-- Load and run widget
local widget = loadfile("../../widgets/BattWidget/main.lua")()
widget.refresh(widget, {})
```

## Documentation

- [../docs/TESTING.md](../docs/TESTING.md) - Comprehensive testing guide
- [../docs/TELEMETRY_GUIDE.md](../docs/TELEMETRY_GUIDE.md) - Telemetry variables and profiles
- [../docs/COMPANION_SIMULATOR_GUIDE.md](../docs/COMPANION_SIMULATOR_GUIDE.md) - Companion simulator integration

## Requirements

- **Lua 5.1**: EdgeTX standard version (not 5.4)
- **No additional dependencies**: Tests run with vanilla Lua

## Adding New Tests

1. Create test file in `tests/lua/`:
   ```lua
   require("setup")
   require("telemetry_simulator")
   
   -- Your test scenarios here
   ```

2. Update telemetry profiles in `utils/telemetry_simulator.lua` if needed

3. Add test to runner scripts (`run_tests.bat`, `run_tests.sh`)

4. Document scenarios in `../docs/TESTING.md`

## Troubleshooting

### Path Issues
- Tests must run from `tests/lua/` directory
- `setup.lua` configures relative paths automatically
- Widget paths use `../../widgets/[WidgetName]/main.lua`

### Lua Version
- Use Lua 5.1 (EdgeTX standard)
- Lua 5.4 may have compatibility issues

### Mock Conflicts
- Each test file sets up its own mocks
- Don't mix tests in same Lua session
- Run tests individually or via runner scripts
