-- Dashboard Widget Tests (self-contained harness)

-- Minimal test harness fallback
if not describe then
  local function simple_assert()
    return {
      is_not_nil = function(v)
        if v == nil then error("expected non-nil value") end
      end,
      is_function = function(v)
        if type(v) ~= "function" then error("expected function, got " .. tostring(type(v))) end
      end
    }
  end
  assert = assert or simple_assert()
  function describe(name, fn)
    print("\n[Describe] " .. name)
    fn()
  end
  function it(name, fn)
    io.write("  - " .. name .. " ... ")
    local ok, err = pcall(fn)
    if ok then
      print("OK")
    else
      print("FAIL: " .. tostring(err))
    end
  end
end

local dashboardPath = "../../widgets/Dashboard/main.lua"
local dashboard = loadfile(dashboardPath)()

describe("Dashboard Widget", function()
  it("should load without errors", function()
    assert.is_not_nil(dashboard)
  end)
  
  it("should have required functions", function()
    assert.is_function(dashboard.create)
    assert.is_function(dashboard.update)
    assert.is_function(dashboard.refresh)
    assert.is_function(dashboard.destroy)
  end)
  
  it("should create a widget instance", function()
    local options = {
      Format24H = 1,
      ShowSticks = 1,
      CompactMode = 0
    }
    local widget = dashboard.create({w = 480, h = 272}, options)
    assert.is_not_nil(widget)
  end)
  
  it("should not crash on destroy", function()
    local options = {
      Format24H = 1,
      ShowSticks = 1,
      CompactMode = 0
    }
    local widget = dashboard.create({w = 480, h = 272}, options)
    dashboard.destroy(widget)
  end)
end)
