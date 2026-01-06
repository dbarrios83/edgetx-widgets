# Dashboard Widget

A comprehensive full-screen widget for EdgeTX that combines all essential telemetry information in a single, organized view.

## Features

The Dashboard widget provides a complete overview of your flight system:

### Top-Left Section
- **Model Name**: Displays the current model name in large, bold text
- **TX Battery**: Shows transmitter battery voltage with color-coded status icon

### Center Section
- **Connection Status**: Visual indicator showing RF link status (green/yellow/red/black)
- **Link Quality (LQ)**: Real-time link quality percentage
- **RX Battery**: 
  - Displays voltage with color-coded battery icon
  - Automatic cell count detection and per-cell voltage display (e.g., "4.12V-4S")
  - Falls back to total voltage for single-cell batteries
- **GPS Satellites**: 
  - Satellite count with color-coded icon
  - "No GPS" or "Last GPS fix" indicators when signal is lost
  - GPS coordinate display (configurable; only shown with a valid fix)

### Right Column
- **Date & Time**: Current date and time with configurable format
- **Timers**: Shows up to 3 active timers with labels and formatted time

### Bottom Section
- **Telemetry Grid** (when ShowRxDetails enabled):
  - Current (CUR), Power (TPWR), Flight Mode (FMODE), RSSI1
  - Capacity (CAP), Antenna (ANT), RF Mode (RFMD), RSSI2
- **GPS Coordinates** (when ShowCoordinates enabled):
  - Latitude and longitude in degrees/minutes/seconds format
  - Shown only when GPS has a valid fix (non-zero lat/lon)
- **Stick Positions** (when ShowSticks enabled):
  - Visual representation of all 4 stick axes
  - Left stick: Rudder (horizontal) and Throttle (vertical)
  - Right stick: Aileron (horizontal) and Elevator (vertical)

### Bottom-Right Corner
- **EdgeTX Version**: Displays the current firmware version

## Options

The Dashboard widget includes several configurable options:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| **Format24H** | Boolean | On | Use 24-hour time format (off for 12-hour AM/PM) |
| **ShowSticks** | Boolean | On | Display stick position visualization |
| **ShowRxDetails** | Boolean | On | Show detailed telemetry grid (RF mode, RSSI, current, etc.) |
| **ShowCoordinates** | Boolean | On | Display GPS coordinates in lat/lon format |
| **ShowTimers** | Boolean | On | Show active model timers |

## Installation

1. Copy the `Dashboard` folder to `/WIDGETS/` on your SD card
2. **REQUIRED**: Copy the `common` folder to `/WIDGETS/common/` (contains shared utilities and icons)
3. The Dashboard widget uses centralized icon assets from:
   - `/WIDGETS/common/icons/battery-*.png` (battery icons)
   - `/WIDGETS/common/icons/connection-*.png` (connection icons)
   - `/WIDGETS/common/icons/satellite-*.png` (GPS icons)

### Full Installation

For the Dashboard widget to work properly with all features, ensure you have these folders on your SD card:
```
/WIDGETS/
├── common/          # REQUIRED - shared utilities and icons
│   ├── utils.lua
│   └── icons/       # Battery, connection, and GPS icons
└── Dashboard/       # The Dashboard widget
```

## Usage

1. Long press the `Page` button to enter screen layout setup
2. Select a full-screen widget slot
3. Choose "Dashboard" from the widget list
4. Configure the widget options as desired
5. Exit the configuration menu

## Required Telemetry

The Dashboard widget works best when the following telemetry sensors are available:

### Essential
- **TPWR**: Transmitter power (connection detection)
- **RQly**: Link quality percentage
- **RxBt**: Receiver battery voltage

### Optional (for full functionality)
- **GPS**: GPS coordinates (lat/lon)
- **Sats**: Satellite count
- **1RSS** / **2RSS**: RSSI values for diversity antennas
- **ANT**: Active antenna
- **RFMD**: RF mode (rate)
- **FM**: Flight mode
- **Curr**: Current draw
- **Capa**: Capacity used

## Layout Details

The Dashboard uses intelligent positioning to prevent overlaps:
- The right column (95px wide) is reserved for date/time/timers
- Center telemetry dynamically positions text to avoid overlapping with the right column
- All elements are carefully spaced to maximize readability on color screen radios

## Compatibility

- **Tested with**: EdgeTX 2.10.5, 2.11.1, and 3.0.0
- **Screen**: Designed for color-screen radios (TX15, Jumper T15, TX16)
- **Dependencies**: Requires the `common/utils.lua` shared library

## Telemetry Caching

The Dashboard caches telemetry values when connected to prevent flickering and improve display stability. The cache is cleared when:
- Connection is lost (TPWR drops to 0)
- Connection is re-established (fresh sensor discovery)

## Tips

- Use "Discover new sensors" in the Telemetry menu before using the Dashboard
- Reset telemetry when switching between different aircraft
- The Dashboard automatically adapts to available telemetry (missing sensors won't cause errors)
- Coordinates are hidden without a valid fix; center section shows "Last GPS fix"

## Known Issues

- **BetaFPV Flight Controllers**: Some models report 0V for RxBt, which will display as "0.0V"
- **Icon Dependencies**: Requires shared icon assets from `/WIDGETS/common/icons/`

## Troubleshooting

- **No RX telemetry displayed**: Ensure your receiver is bound and powered, and TPWR sensor is available
- **Missing icons**: Verify `/WIDGETS/common/icons/` exists with battery, connection, and satellite icons
- **GPS not working**: Check that GPS sensor is discovered in telemetry and has valid satellite lock
- **Common folder error**: Ensure `/WIDGETS/common/utils.lua` exists on your SD card
