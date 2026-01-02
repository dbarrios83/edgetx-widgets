-- TeleView Widget: Compact telemetry display
-- Consistent spacing + robust GPS handling (no stale GPS when switching models)

local utils = loadScript("/WIDGETS/common/utils.lua")()

-- -----------------------
-- Layout constants
-- -----------------------
local PAD_X        = 10
local PAD_Y        = 2
local ICON_TEXT_GAP = 40   -- X distance from icon left to text start
local ROW_H        = 35
local ICON_Y_NUDGE = 0     -- tweak if your icons sit too high/low
local TEXT_Y_NUDGE = 2     -- baseline alignment

-- Shared text styles
local STYLE_LEFT   = utils.S.left
local STYLE_RIGHT  = utils.S.right
local STYLE_BASE   = utils.S.base

local SIZE_MAIN    = utils.S.mid
local SIZE_SMALL   = utils.S.sml

-- -----------------------
-- Icon loading
-- -----------------------
local function create(zone, options)
  local connIconPath = "/WIDGETS/common/icons/connection-%s.png"
  local battIconPath = "/WIDGETS/common/icons/battery-%s.png"
  local satIconPath  = "/WIDGETS/common/icons/satellite-%s.png"

  local icons = {
    conn_red    = utils.safeOpen(string.format(connIconPath, "red")),
    conn_yellow = utils.safeOpen(string.format(connIconPath, "yellow")),
    conn_green  = utils.safeOpen(string.format(connIconPath, "green")),
    conn_black  = utils.safeOpen(string.format(connIconPath, "black")),

    dead   = utils.safeOpen(string.format(battIconPath, "dead")),
    low    = utils.safeOpen(string.format(battIconPath, "low")),
    yellow = utils.safeOpen(string.format(battIconPath, "yellow")),
    ok     = utils.safeOpen(string.format(battIconPath, "ok")),
    full   = utils.safeOpen(string.format(battIconPath, "full")),

    sat_red    = utils.safeOpen(string.format(satIconPath, "red")),
    sat_yellow = utils.safeOpen(string.format(satIconPath, "yellow")),
    sat_green  = utils.safeOpen(string.format(satIconPath, "green")),
  }

  return {
    zone = zone,
    cfg = options or {},
    icons = icons,

    -- Cache last known position (to show when disconnected)
    lastLat = 0,
    lastLon = 0,

    -- Connection state tracking (to avoid stale telemetry)
    wasConnected = false,

    -- GPS presence tracking per connection
    gpsSeenThisConnection = false,
  }
end

local function update(widget, options)
  widget.cfg = options or {}
end

-- -----------------------
-- Small helpers
-- -----------------------
local function drawIcon(widget, key, x, y)
  local bmp = widget.icons and widget.icons[key]
  if bmp then
    lcd.drawBitmap(bmp, x, y + ICON_Y_NUDGE)
    return true
  end
  return false
end

local function getGpsLatLon(gpsValue)
  if type(gpsValue) ~= "table" then return 0, 0 end

  -- Handle both {lat=..., lon=...} and array-like {lat, lon}
  local lat = tonumber(gpsValue.lat) or tonumber(gpsValue[1]) or 0
  local lon = tonumber(gpsValue.lon) or tonumber(gpsValue[2]) or 0
  return lat, lon
end

local function drawConnectionRow(widget, xIcon, y, xText, tpwr, rqly)
  local state = utils.connectionIconState(tpwr, rqly)
  drawIcon(widget, "conn_" .. state, xIcon - 5, y)

  if (tpwr or 0) <= 0 then
    utils.text(xText, y + TEXT_Y_NUDGE, "No RX Telemetry", STYLE_LEFT, SIZE_SMALL, 0)
  else
    utils.text(xText, y + TEXT_Y_NUDGE, string.format("LQ: %d%%", rqly or 0), STYLE_LEFT, SIZE_MAIN, 0)
  end
end

local function drawBatteryRow(widget, xIcon, y, xText, rxbt)
  local vpc, cells = utils.getVoltagePerCell(rxbt or 0)
  local state = utils.rxCellState(vpc)
  drawIcon(widget, state, xIcon, y)

  local txt
  if (cells or 1) > 1 then
    txt = string.format("%.2fV-%dS", vpc or 0, cells or 1)
  else
    txt = string.format("%.1fV", rxbt or 0)
  end
  utils.text(xText, y + TEXT_Y_NUDGE, txt, STYLE_LEFT, SIZE_MAIN, 0)
end

local function drawSatsRow(widget, xIcon, y, xText, sats)
  local satColor = utils.satIconColor(sats or 0)
  drawIcon(widget, "sat_" .. satColor, xIcon, y)

  utils.text(xText, y + TEXT_Y_NUDGE, string.format("%d Sats", sats or 0), STYLE_LEFT, SIZE_MAIN, 0)
end

local function drawLastGpsBlock(widget, xText, yTop)
  if (widget.lastLat == 0) and (widget.lastLon == 0) then return end

  local latStr, lonStr = utils.formatLatLon(widget.lastLat, widget.lastLon)
  utils.text(xText, yTop, "Last GPS fix", STYLE_LEFT, SIZE_SMALL, 0)
  utils.text(xText, yTop + 25, "Lat: " .. latStr, STYLE_LEFT, SIZE_SMALL, 0)
  utils.text(xText, yTop + 50, "Lon: " .. lonStr, STYLE_LEFT, SIZE_SMALL, 0)
end

-- -----------------------
-- Main draw
-- -----------------------
local function refresh(widget, event, touchState)
  local z = widget.zone or { x = 0, y = 0, w = 320, h = 240 }

  local tpwr = tonumber(getValue("TPWR")) or 0
  local rqly = tonumber(getValue("RQly")) or 0
  local rxbt = tonumber(getValue("RxBt")) or 0
  local sats = tonumber(getValue("Sats")) or 0

  local gpsValue = getValue("GPS")
  local lat, lon = getGpsLatLon(gpsValue)

  local connected = tpwr > 0

  -- Detect connect/disconnect edge
  if connected and not widget.wasConnected then
    -- New connection: reset GPS presence tracking
    widget.gpsSeenThisConnection = false
  elseif (not connected) and widget.wasConnected then
    -- Just disconnected: don't keep showing stale sats/GPS as "present"
    widget.gpsSeenThisConnection = false
  end
  widget.wasConnected = connected

  -- If we ever see a GPS table during this connection, mark GPS as present
  if connected and type(gpsValue) == "table" then
    widget.gpsSeenThisConnection = true
  end

  -- Cache last known coordinates (only when connected and non-zero)
  if connected and ((lat ~= 0) or (lon ~= 0)) then
    widget.lastLat = lat
    widget.lastLon = lon
  end

  local xIcon = z.x + PAD_X
  local xText = xIcon + ICON_TEXT_GAP
  local y0    = z.y + PAD_Y

  -- Row 1: Connection + LQ / No telemetry
  drawConnectionRow(widget, xIcon, y0, xText, tpwr, rqly)

  if connected then
    -- Row 2: RX battery
    drawBatteryRow(widget, xIcon, y0 + ROW_H, xText, rxbt)

    -- Row 3: Sats
    local y3 = y0 + ROW_H * 2

    if widget.gpsSeenThisConnection then
      drawSatsRow(widget, xIcon, y3, xText, sats)
    else
      -- No GPS module detected for this connection
      -- (prevents stale sats from previous drone)
      utils.text(xText, y3 + TEXT_Y_NUDGE, "No GPS", STYLE_LEFT, SIZE_MAIN, 0)
    end
  else
    -- Disconnected: show last fix block if available
    drawLastGpsBlock(widget, xText, y0 + ROW_H)
  end
end

local function destroy(widget)
  if widget and widget.icons then
    for _, bmp in pairs(widget.icons) do
      if bmp and bmp.delete then bmp:delete() end
    end
    widget.icons = nil
  end
end

return {
  name = "TeleView",
  options = {},
  create = create,
  update = update,
  refresh = refresh,
  destroy = destroy,
}
