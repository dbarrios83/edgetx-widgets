# TeleView Widget

A compact telemetry display widget showing connection status, battery voltage, GPS satellite count, and last known GPS position on disconnect.

## Overview

The **TeleView** widget provides a clean, space-efficient display of critical flight telemetry data. It displays telemetry in a simple left-aligned layout with icons and values.

## Features

### When Connected (TPWR > 0)

**Row 1: Connection Status & Link Quality**
- **Connection Icon**:
  - 🔴 Red: Poor link quality (<50%)
  - 🟡 Yellow: Fair link quality (50-79%)
  - 🟢 Green: Good link quality (≥80%)
  - ⚫ Black: No connection (TPWR = 0)
- **Link Quality**: Displays "LQ: XX%" with percentage value

**Row 2: Battery Voltage**
- **Battery Icon** (color-coded by voltage per cell):
  - Dead: <3.2V per cell
  - Low: 3.2-3.6V per cell
  - Yellow: 3.6-3.8V per cell
  - OK: 3.8-4.0V per cell
  - Full: ≥4.0V per cell
- **Voltage Display**: Shows per-cell voltage and cell count (e.g., "3.85V-4S") or total voltage for single cell

**Row 3: GPS Satellites**
- **Satellite Icon** (color-coded by GPS lock quality):
  - 🔴 Red: 0-4 satellites (no lock)
  - 🟡 Yellow: 5-8 satellites (acquiring)
  - 🟢 Green: 9+ satellites (good lock)
- **Satellite Count**: Displays "X Sats"
- **No GPS Module**: Shows "No GPS" text if no GPS module detected

### When Disconnected (TPWR = 0)

**Row 1: Connection Status**
- **Black Icon** with "No RX Telemetry" message

**Rows 2-4: Last GPS Fix** (if coordinates were cached)
- "Last GPS fix" header
- Latitude in DMS format (e.g., "37°46'29"N")
- Longitude in DMS format (e.g., "122°25'9"W")

### Smart GPS Handling
- **GPS Detection**: Widget detects if a GPS module is present on the current model
- **No Stale Data**: Prevents showing GPS data from previously connected models
- **Coordinate Caching**: Stores last known position when connected and displays it when signal is lost

## Configuration

This widget has **no configuration options** - it automatically displays available telemetry data based on what's present.

## Installation

1. Copy the `TeleView` folder to `/WIDGETS/` on your SD card
2. **REQUIRED**: Ensure the `common` folder exists at `/WIDGETS/common/` with:
   - `utils.lua` - Shared utility functions
   - `icons/` - Icon assets (battery, connection, satellite)

### Folder Structure
```
/WIDGETS/
├── common/
│   ├── utils.lua
│   └── icons/
│       ├── connection-*.png (red, yellow, green, black)
│       ├── battery-*.png (dead, low, yellow, ok, full)
│       └── satellite-*.png (red, yellow, green)
└── TeleView/
    └── main.lua
```

## Usage

1. Long press the `Page` button to enter screen layout setup
2. Select a widget slot (works well in any size)
3. Choose "TeleView" from the widget list
4. Exit configuration menu

The widget will automatically detect available telemetry and adjust the display accordingly.

## Required Telemetry

### Essential (Always Required)
- **TPWR**: Transmitter power (connection detection)
- **RQly**: Receiver link quality percentage
- **RxBt**: Receiver battery voltage

### Optional (Auto-Detected)
- **GPS**: GPS position data (table with lat/lon)
- **Sats**: GPS satellite count

## Technical Details

### Key Features
- **GPS Module Detection**: Automatically detects if GPS is present on the current model
- **Smart Coordinate Caching**: Stores last known GPS position only when connected
- **No Stale Data**: Resets GPS tracking on model switch to prevent showing old coordinates
- **Reconnection Handling**: Properly handles connection/disconnection edge cases

### Core Functions
- `create(zone, options)` - Initialize widget, load icons, set up tracking variables
- `update(widget, options)` - Update configuration (no options currently used)
- `refresh(widget, event, touchState)` - Main render loop with smart GPS handling
- `destroy(widget)` - Clean up bitmap resources
- `drawConnectionRow()` - Connection icon and link quality display
- `drawBatteryRow()` - Battery icon and voltage with cell detection
- `drawSatsRow()` - Satellite icon and count display
- `drawLastGpsBlock()` - Last known GPS coordinates when disconnected

### Widget State Variables
- `lastLat`, `lastLon` - Cached GPS coordinates (updated only when connected)
- `wasConnected` - Tracks previous connection state for edge detection
- `gpsSeenThisConnection` - Prevents displaying stale GPS from previous model

### Dependencies
- `/WIDGETS/common/utils.lua` - Shared utilities:
  - `getVoltagePerCell()` - Multi-cell battery calculation
  - `rxCellState()` - Battery icon state determination
  - `connectionIconState()` - Connection icon color selection
  - `satIconColor()` - GPS lock quality color
  - `formatLatLon()` - GPS coordinate formatting (DMS)
  - `safeOpen()` - Safe bitmap loading with error handling
  - `text()` - Consistent text rendering with typography system
  - `S.*` - Shared style constants (alignment, size, emphasis)

## Compatibility

- **EdgeTX Version**: 2.10.5+ (tested with 2.10.5, 2.11.1, 3.0.0)
 - **Screen**: Color screen transmitters (TX15, Jumper T15, TX16)
- **Receiver Telemetry**: ExpressLRS, Crossfire, or any CRSF-compatible system

## Testing

The widget includes a comprehensive test suite with 16 test cases covering:
- Widget creation and initialization
- Connection state handling (black, red, yellow, green icons)
- Battery display (single and multi-cell)
- GPS detection and satellite count display
- GPS coordinate caching and "Last GPS fix" display
- Complete flight scenario from pre-flight through landing

Run tests from `/tests/lua/`:
```bash
lua test_teleview.lua
```
- **Zone Size**: Works best with small to medium widget zones

## Tips

- Use "Discover new sensors" in the Telemetry menu before using the widget
- Satellite count persists during brief signal loss (cached value)
- Perfect for layouts where space is limited but key telemetry is needed
- Pairs well with other widgets like BattWidget or RXWidget for detailed views

## Differences from Dashboard

- **Compact**: Only 3 rows vs full-screen Dashboard
- **No Options**: Minimal configuration for simplicity
- **Essential Data**: Focuses on connection, battery, and GPS only
- **Same Logic**: Uses identical calculation and color-coding algorithms
