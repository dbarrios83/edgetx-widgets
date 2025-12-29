#!/bin/bash
# EdgeTX Widgets Test Runner for Linux/Mac
# Usage: ./run_tests.sh [test_name]

if [ -z "$1" ]; then
    echo "Running all widget tests..."
    cd lua
    lua test_battwidget.lua
    lua test_rxwidget.lua
    lua test_gpswidget.lua
    lua test_clockwidget.lua
    lua test_modelwidget.lua
    lua test_simmodel.lua
    lua test_simstick.lua
    cd ..
elif [ "$1" = "help" ]; then
    echo "Usage: ./run_tests.sh [test_name]"
    echo ""
    echo "Commands:"
    echo "  (no args)    - Run all tests"
    echo "  battwidget   - Run BattWidget tests only"
    echo "  rxwidget     - Run RXWidget tests only"
    echo "  gpswidget    - Run GPSWidget tests only"
    echo "  clockwidget  - Run ClockWidget tests only"
    echo "  modelwidget  - Run ModelWidget tests only"
    echo "  simmodel     - Run SimModel tests only"
    echo "  simstick     - Run SimStick tests only"
    echo "  help         - Show this help message"
else
    echo "Running $1 tests..."
    cd lua
    lua test_$1.lua
    cd ..
fi
