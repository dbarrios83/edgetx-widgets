@echo off
REM EdgeTX Widgets Test Runner for Windows
REM Usage: run_tests.bat [test_name]

setlocal enabledelayedexpansion

if "%1"=="" (
    echo Running all widget tests...
    cd lua
    lua test_battwidget.lua
    lua test_rxwidget.lua
    lua test_gpswidget.lua
    lua test_simwidget.lua
    cd ..
    goto :eof
)

if "%1"=="help" (
    echo Usage: run_tests.bat [test_name]
    echo.
    echo Commands:
    echo   ^(no args^)    - Run all tests
    echo   battwidget   - Run BattWidget tests only
    echo   rxwidget     - Run RXWidget tests only
    echo   gpswidget    - Run GPSWidget tests only
    echo   simwidget    - Run SimWidget tests only
    echo   help         - Show this help message
    goto :eof
)

echo Running %1 tests...
cd lua
lua test_%1.lua
cd ..
