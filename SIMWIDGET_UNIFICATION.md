# SimWidget Unification - Documentation & Test Updates

## Summary

Successfully unified SimModel and SimStick widgets into a single **SimWidget** and updated all documentation and tests accordingly.

## Changes Made

### 1. Widget Consolidation
- **Deleted**: `SimModel/` and `SimStick/` widget folders
- **Created**: Unified `SimWidget/` with combined functionality
- **Features Combined**:
  - Model information display
  - TX battery status with icons
  - Date/time with 24/12-hour format toggle
  - Timer display (up to 3 timers)
  - Stick visualization (2 charts for all 4 axes)
  - OS version display

### 2. Documentation Updates

#### Main README (`README.md`)
- Updated widget list from SimModel + SimStick to SimWidget only
- Updated simulator model widget configuration (1 widget instead of 2)
- Updated project structure to show SimWidget folder
- Simplified configuration instructions

#### SimWidget README (NEW: `widgets/SimWidget/README.md`)
- Comprehensive widget documentation
- Feature overview with detailed descriptions
- Configuration options
- Installation instructions
- Screen layout diagram
- Stick chart technical details
- Dependencies and compatibility information
- Function reference

#### Tests README (`tests/README.md`)
- Updated test directory structure (removed test_simmodel.lua, test_simstick.lua)
- Added test_simwidget.lua with 10 comprehensive tests
- Updated test summary (from 15 individual Sim tests to 10 unified tests)
- Updated test descriptions to match unified functionality

### 3. New Test Suite

#### SimWidget Test File (`tests/lua/test_simwidget.lua`)
Created comprehensive test suite with 10 tests:
1. Module structure validation
2. Widget creation with options
3. Model info display
4. Battery display with icon
5. Date and time display (24-hour format)
6. Date and time display (12-hour format)
7. Timer display
8. Stick chart visualization
9. Low TX battery warning handling
10. OS version display

**Test Coverage**:
- All major functions tested
- Mock EdgeTX API for isolated testing
- Telemetry simulator integration
- No external dependencies required

### 4. Test Runner Updates

#### Windows Batch Script (`tests/run_tests.bat`)
- Removed: `lua test_simmodel.lua`, `lua test_simstick.lua`
- Added: `lua test_simwidget.lua`
- Updated help text with simwidget option

#### Linux/Mac Shell Script (`tests/run_tests.sh`)
- Removed: `lua test_simmodel.lua`, `lua test_simstick.lua`
- Added: `lua test_simwidget.lua`
- Updated help text with simwidget option

## Configuration Impact

### Before (Simulator Model)
```
Widget 1: SimModel
Widget 2: SimStick
Options: Multiple (simulator_mode, show_sticks, values_down, etc.)
```

### After (Simulator Model)
```
Widget 1: SimWidget
Options: Single (Format24H - 24-hour vs 12-hour time format)
```

## File Structure

```
edgetx-widgets/
├── widgets/
│   ├── SimWidget/
│   │   ├── main.lua           (unified widget code)
│   │   ├── README.md          (NEW - comprehensive documentation)
│   │   └── BMP/               (battery icons)
│   └── ...
├── tests/
│   ├── lua/
│   │   ├── test_simwidget.lua (NEW - 10 tests)
│   │   ├── run_tests.bat      (UPDATED)
│   │   └── run_tests.sh       (UPDATED)
│   └── README.md              (UPDATED)
└── README.md                  (UPDATED)
```

## Breaking Changes

None for end users - the unification maintains backward compatibility in terms of displayed information, just with a cleaner configuration:

- SimWidget replaces both SimModel and SimStick
- Single option (Format24H) vs multiple scattered options
- Cleaner, more maintainable codebase

## Test Execution

Run all tests:
```bash
# Windows
cd tests
run_tests.bat

# Linux/Mac
cd tests
./run_tests.sh
```

Run SimWidget tests only:
```bash
# Windows
cd tests
run_tests.bat simwidget

# Linux/Mac
cd tests
./run_tests.sh simwidget
```

## Documentation Complete ✓

All documentation has been updated to reflect:
1. ✓ Main README.md
2. ✓ SimWidget README.md (new)
3. ✓ Tests README.md
4. ✓ Test runners (both .bat and .sh)
5. ✓ Test suite (10 new tests)
6. ✓ Widget code (comments cleaned up)

---

**Completed**: December 30, 2025
**Status**: Ready for use
