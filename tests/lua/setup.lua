-- Test environment setup
-- Configures Lua paths for running tests from the lua/ directory

-- Add parent directories to package path for require() statements
package.path = package.path 
  .. ";../utils/?.lua"  -- For telemetry_simulator
  .. ";../../?/init.lua;../../?.lua"  -- For widgets

return package
