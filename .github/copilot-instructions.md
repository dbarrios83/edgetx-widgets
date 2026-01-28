# EdgeTX Widgets Development Guide

## Project Overview

Reusable Lua widgets for EdgeTX colour-screen radios (TX16, Jumper T15, TX15) displaying telemetry, model info, and simulator utilities. Target platform: embedded hardware with limited CPU/memory running Lua 5.1.

**Domain Context:**
- Target platform: EdgeTX colour radios running Lua widgets in the main/view pages
- Data sources: OpenTX/EdgeTX telemetry sensors (GPS, RSSI, battery, timers), model metadata, and companion simulators for offline testing
- Interaction model: Widgets render via `lcd` APIs within a zone; options are set through EdgeTX widget settings and refreshed each frame
- Constraints: Runs on embedded hardware with limited CPU/memory; avoid heavy allocations and prefer integer math where possible
- Testing: Lua test harness and telemetry simulator under `tests/` mirror on-radio behaviour for CI-style checks

## Agent Conduct

- **Verify assumptions** before executing commands; call out uncertainties first
- **Ask for clarification** when the request is ambiguous, destructive, or risky
- **Summarise intent** before performing multi-step fixes so the user can redirect early
- **Cite the source** when using documentation; quote exact lines instead of paraphrasing from memory
- **Break work into incremental steps** and confirm each step with the smallest relevant check before moving on

## Project Structure

```
edgetx-widgets/
├── widgets/           # Widget implementations
│   ├── BattWidget/    # Battery voltage and current display
│   ├── Dashboard/     # Full-screen comprehensive telemetry view
│   ├── GPSWidget/     # GPS satellite and coordinate display
│   ├── RXWidget/      # Receiver signal strength display
│   ├── SimWidget/     # Simulator model testing utilities
│   ├── TeleView/      # Compact telemetry display
│   └── common/        # REQUIRED: Shared utilities and assets
│       ├── utils.lua  # Typography, battery helpers, time formatting
│       └── icons/     # Shared icons (battery, connection, GPS)
├── tests/
│   ├── lua/           # 63 widget tests (vanilla Lua 5.1)
│   │   ├── test_battwidget.lua    # 12 tests
│   │   ├── test_dashboard.lua     # 11 tests
│   │   ├── test_teleview.lua      # 16 tests
│   │   ├── test_gpswidget.lua     # 6 tests
│   │   ├── test_rxwidget.lua      # 5 tests
│   │   ├── test_simwidget.lua     # 9 tests
│   │   ├── test_simmodel.lua      # 4 tests
│   │   └── setup.lua              # Lua path configuration
│   ├── utils/
│   │   └── telemetry_simulator.lua  # Mock EdgeTX telemetry
│   ├── run_tests.bat  # Windows test runner
│   └── run_tests.sh   # Linux/Mac test runner
└── docs/
    ├── TELEMETRY_GUIDE.md         # Sensor reference
    └── COMPANION_SIMULATOR_GUIDE.md  # Integration guide
```

## Architecture

### Widget Structure Pattern

Every widget follows this module return pattern in `main.lua`:

```lua
-- Load shared utilities (REQUIRED)
local utils = loadScript("/WIDGETS/common/utils.lua")()

local function create(zone, options)
  -- Preload icons/resources once during creation
  return { zone = zone, cfg = options, icons = {...} }
end

local function update(widget, options)
  widget.cfg = options
end

local function refresh(widget, event, touchState)
  -- Render frame using lcd.drawText() and lcd.drawBitmap()
  -- Use utils.text() for consistent typography
end

local function destroy(widget)
  -- CRITICAL: Clean up bitmaps to prevent memory leaks
  for _, bmp in pairs(widget.icons or {}) do
    if bmp and bmp.delete then bmp:delete() end
  end
end

return { name = "WidgetName", options = {...}, create = create, update = update, refresh = refresh, destroy = destroy }
```

### Required Dependencies

- **`widgets/common/utils.lua`**: Shared utilities for typography, battery calculations, time formatting. Load via `loadScript("/WIDGETS/common/utils.lua")()`
- **`widgets/common/icons/`**: Shared icon assets (battery, connection, GPS). Load via `Bitmap.open("/WIDGETS/common/icons/battery-full.png")`

### Typography System

Use `utils.text()` and `utils.S` constants for consistent styling:

```lua
utils.text(x, y, "Label", utils.S.left, utils.S.sml)  -- Small left-aligned
utils.text(x, y, "Value", utils.S.right, utils.S.mid, utils.S.bold)  -- Medium right-aligned bold
utils.textLR(cx, y, "Lat:", "37.7749", 10)  -- Left/right pair around center
```

Constants: `utils.S.base`, `utils.S.left`, `utils.S.right`, `utils.S.sml`, `utils.S.mid`, `utils.S.bold`

### Telemetry Access

Use `getValue(key)` to read sensors. **Always guard against nil values:**

```lua
local tpwr = tonumber(getValue("TPWR")) or 0
local rxBt = tonumber(getValue("RxBt")) or 0
```

**Canonical Telemetry Sensors (Project Truth):**

| Purpose | Sensor Key | Type |
|---------|-----------|------|
| RF link | `TPWR` | Transmitter power (%) |
| Link quality | `RQly` | Link quality (%) |
| RX battery | `RxBt` | Battery voltage (V) |
| RSSI | `1RSS`, `2RSS` | Signal strength (dBm) |
| Antenna | `ANT` | Active antenna |
| RF mode | `RFMD` | RF mode string |
| Flight mode | `FM` | Flight mode |
| Current | `Curr` | Current draw (A) |
| Capacity | `Capa` | Used capacity (mAh) |
| Satellites | `Sats` | Satellite count |
| GPS | `GPS` | Table with `lat`, `lon` |
| TX Battery | `tx-voltage` | Transmitter voltage (V) |

**Connection semantics (project-defined):**
```lua
local connected = tonumber(getValue("TPWR")) > 0  -- TPWR=0 means no RF link
```

### Memory Management & Performance Rules

### Critical Performance Constraints

`refresh()` is **real-time code** running at 10-20 Hz on embedded hardware. Inside `refresh()` you **MUST NOT**:
- Allocate tables (including `{}` literals, `table.concat`, etc.)
- Call `string.format` unless the result is cached
- Build strings repeatedly via concatenation
- Load bitmaps or any files
- Encode QR codes or do heavy computation
- Recompute layout geometry every frame

**Allowed in `refresh()`:**
- Reading cached state
- Integer math
- Simple conditionals
- LCD drawing calls (`drawText`, `drawBitmap`, `drawFilledRectangle`, `drawLine`)

Heavy work MUST happen in:
- `create()` - initial setup
- On telemetry state change detection
- Throttled using `getTime()` for periodic updates

### Memory Management

- **Preload all bitmaps** in `create()`, store in widget table
- **Always implement `destroy()`** to call `bitmap:delete()` on all loaded icons
- **Cache derived strings and layout values** - compute once, reuse many times
- **Prefer integer math** over floating point where possible

## Testing Workflow

### Running Tests

```powershell
# Windows - Run all 63 tests
.\tests\run_tests.bat

# Run specific widget test
cd tests\lua
lua test_battwidget.lua    # 12 tests
lua test_dashboard.lua     # 11 tests
lua test_teleview.lua      # 16 tests
```

### Test Structure

Tests use vanilla Lua 5.1 with mocked EdgeTX APIs (no external dependencies):

```lua
require("setup")  -- Configures package.path
local TelSim = require("telemetry_simulator")

-- Mock lcd.drawText, lcd.drawBitmap, getValue, Bitmap.open
local BattWidget = dofile("../../widgets/BattWidget/main.lua")

-- Set telemetry scenario
TelSim:applyProfile("cruising")  -- Predefined profiles: idle, takeoff, cruising, landing, lowbattery

-- Create widget and test
local widget = BattWidget.create({x=10, y=20, w=100, h=50}, {})
BattWidget.refresh(widget)
```

Available profiles in `tests/utils/telemetry_simulator.lua`: `idle`, `takeoff`, `cruising`, `landing`, `lowbattery`, `disconnected`

## Coding Conventions

### Battery Calculations

Use `utils.getVoltagePerCell(totalVoltage)` for cell count detection:

```lua
local totalBatt = tonumber(getValue("RxBt")) or 0
local voltagePerCell, cellCount = utils.getVoltagePerCell(totalBatt)
-- Returns: 4.12V, 4 for 16.48V battery (4S)
```

### GPS Handling

GPS is returned as a table with potential zero values:

```lua
local gps = getValue("GPS")
if type(gps) == "table" then
  local lat = type(gps.lat) == "number" and gps.lat or 0
  local lon = type(gps.lon) == "number" and gps.lon or 0
end
```

**Critical GPS Rules:**
- GPS may exist with `lat=0` and `lon=0` (invalid fix)
- **Cache the last valid fix** (`lastFixLat`, `lastFixLon`) in widget state
- When RX disconnects, show last fix if available ("Last GPS fix")
- **Do not clear last fix on disconnect** - preserve for user reference
- Only update last fix when a new non-zero fix appears

```lua
-- Example caching pattern
if lat ~= 0 or lon ~= 0 then
  widget.lastFixLat = lat
  widget.lastFixLon = lon
end
-- On disconnect, use widget.lastFixLat/lastFixLon if available
```

### Options Pattern

Define widget options using this format:

```lua
local options = {
  { "Format24H", BOOL, 1 },      -- Boolean, default ON
  { "ShowSticks", BOOL, 1 },
  { "SomeNumber", VALUE, 5, 1, 10 },  -- Min 1, Max 10, Default 5
}
```

## Project-Specific Rules

1. **Never hardcode paths** - Always use `/WIDGETS/common/` prefix for shared assets
2. **Always check telemetry values** - Use `tonumber(getValue(key)) or 0` to handle nil/missing sensors
3. **Zone-relative coordinates** - All drawing uses `widget.zone.x`, `widget.zone.y` offsets
4. **No print/debug in production** - Remove debug statements from `widgets/` (keep in `tests/`)
5. **Test every widget change** - Run corresponding test file before committing
6. **Behavioral safety** - Do not change behavior unless explicitly requested; layout and telemetry semantics are intentional
7. **No filesystem writes at runtime** - Widgets are read-only except for bitmap preloading
8. **No new dependencies without approval** - Keep the codebase minimal and focused

### QR Feature Contract (If Used)

If a widget renders QR codes:
- QR payload should be short (prefer `geo:lat,lon`)
- QR encoding must be cached (encode once per content change)
- Drawing may be throttled using `getTime()` if needed
- QR module should live under `/WIDGETS/common/` and expose:
  - `encodeText(text)` → matrix/size or object with `getModule(x,y)`
- **Never encode QR in `refresh()`** - always cache the result

## Documentation

- [TELEMETRY_GUIDE.md](../docs/TELEMETRY_GUIDE.md): Full sensor reference
- [TESTING.md](../docs/TESTING.md): Detailed test setup and coverage
- [COMPANION_SIMULATOR_GUIDE.md](../docs/COMPANION_SIMULATOR_GUIDE.md): EdgeTX Companion integration

## Quick Reference

### Creating a New Widget

1. Create `widgets/NewWidget/main.lua` following the module pattern above
2. Add test file `tests/lua/test_newwidget.lua` with scenarios
3. Update `tests/run_tests.bat` and `run_tests.sh` to include new test
4. Document in widget's `README.md` (features, options, layout)

### Common EdgeTX Constants

`LEFT`, `RIGHT`, `CENTER`, `WHITE`, `BLACK`, `SHADOWED`, `SMLSIZE`, `MIDSIZE`, `BOLD`

### File Paths Used

- Widget code: `/WIDGETS/WidgetName/main.lua`
- Shared utils: `/WIDGETS/common/utils.lua`
- Icons: `/WIDGETS/common/icons/*.png`
