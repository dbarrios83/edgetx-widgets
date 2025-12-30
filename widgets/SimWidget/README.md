# SimWidget

## Overview

**SimWidget** is a unified widget for EdgeTX simulator mode that combines the functionality of the previous SimModel and SimStick widgets into a single, cohesive display.

It provides:
- **Model Information**: Displays the current model name
- **TX Battery Status**: Shows transmitter battery voltage with icon
- **Date & Time**: Configurable 12/24-hour format with auto-formatting
- **Stick Visualization**: Two cross-hair stick charts showing stick positions (Aileron/Elevator and Rudder/Throttle)
- **Version Info**: OS and firmware version in bottom right corner

## Features

### Model Name Display
- Shows the model name in large bold text at the top-left
- Automatically reads from `model.getInfo().name`

### Battery Status
- TX voltage displayed in large text
- Battery icon indicates charge state:
  - **Green**: Full charge
  - **Yellow**: Medium charge
  - **Orange**: Low battery
  - **Red**: Critical battery
  - **Gray**: Dead battery
- Icon positioned at left, voltage at offset position

### Date & Time
- **Right-aligned** at the top of the screen
- Date shown first (e.g., "30 Dec")
- Time shown below (e.g., "14:45")
- **Format24H option**: Toggle between 24-hour and 12-hour formats

### Stick Visualization
- Two stick charts showing:
  - **Left Chart**: Rudder (X-axis) and Throttle (Y-axis)
  - **Right Chart**: Aileron (X-axis) and Elevator (Y-axis)
- Cross-hair axes with:
  - Gray center dot (stick center position)
  - Green dot (current stick position)
- Centered on screen, below model/battery info

### OS Version
- Displayed in small text at bottom-right
- Format: `EdgeTX 2.10.5`

## Configuration Options

```lua
options = {
  { "Format24H", BOOL, 1 },  -- 1 = 24-hour, 0 = 12-hour
}
```

## Installation

1. Copy the `SimWidget` folder to `/WIDGETS/` on your transmitter's SD card
2. Also ensure the `common` folder is in `/WIDGETS/common/` (required for utility functions)
3. Load the widget in your simulator model's widget setup

## Usage

### In EdgeTX Transmitter

1. Create or select a simulator model
2. Add a screen or use existing screen
3. Add widget and select **SimWidget**
4. Configure the **Format24H** option (optional, default is 24-hour)

### Widget Configuration

The widget automatically:
- Reads transmitter battery voltage
- Gets current date/time
- Reads stick positions from transmitter input

No manual telemetry setup required!

## Screen Layout

```
┌─────────────────────────────────────────┐
│ Model Name                    30 Dec    │
│                                14:45    │
│ [🔋] 7.5V                               │
│                                         │
│          [Left Sticks]  [Right Sticks]  │
│          ╋                ╋             │
│          │ • (pos)        │ • (pos)     │
│          │                │             │
│                                         │
│    EdgeTX 2.10.5                        │
└─────────────────────────────────────────┘
```

## Stick Chart Details

### Axes
- **Horizontal (X-axis)**: Aileron (-1024 left, +1024 right) or Rudder
- **Vertical (Y-axis)**: Elevator (-1024 down, +1024 up) or Throttle

### Visualization
- **Cross-hair pattern** with fine lines
- **Gray square** (center): Stick neutral position
- **Green square** (offset): Current stick position
- Each chart area is 90 pixels wide and tall

## Files

- `main.lua` - Main widget code with all display functions

## Dependencies

- `/WIDGETS/common/utils.lua` - Utility functions for text rendering and icons
- `/WIDGETS/common/icons/battery-*.png` - Battery state icons

## Technical Details

### Functions

- `create(zone, options)` - Initialize widget
- `update(widget, options)` - Update configuration
- `refresh(widget, event, touchState)` - Main render function
- `drawModelInfo(widget)` - Display model name
- `drawBattery(widget)` - Display TX battery
- `drawDateAndTime(widget)` - Display date/time
- `drawTimers(widget)` - Display active timers
- `drawSticksChart(widget)` - Render stick visualization
- `drawOsVersionBottomRight(widget)` - Display OS version

### Field IDs Used

The widget reads from these transmitter fields:
- `rud` - Rudder stick input
- `thr` - Throttle stick input
- `ail` - Elevator stick input
- `tx-voltage` - Transmitter battery voltage

## Compatibility

- **EdgeTX Version**: 2.10.5+
- **Transmitter**: Any EdgeTX color screen transmitter
- **Simulator Mode**: Yes (designed for simulator model testing)
- **Real Hardware**: Yes (works on real transmitters too)

## Notes

- The widget displays on full-screen or partial-screen depending on zone configuration
- All positions are relative to the widget's zone
- Battery icons are loaded from external BMP files
- Stick visualization uses utility drawing functions for consistency

---

**Original Widget**: Unified from SimModel and SimStick  
**Version**: 1.0  
**License**: Same as EdgeTX
