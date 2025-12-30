-- Shared utilities for EdgeTX widgets

local utils = {}

-- =========================
-- Safe helpers
-- =========================

-- Safely open a bitmap and avoid crashing if missing
function utils.safeOpen(path)
  local ok, bmp = pcall(Bitmap.open, path)
  return ok and bmp or nil
end

utils.months = {"Jan", "Feb", "Mar", "Apr", "May", "Jun",
                "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}

-- =========================
-- Typography system
-- =========================
-- One source of truth for style: color/shadow + alignment + size + emphasis
utils.S = {
  base  = WHITE + SHADOWED,      -- base (no LEFT/RIGHT baked in)
  left  = WHITE + LEFT + SHADOWED,
  right = WHITE + RIGHT + SHADOWED,

  sml   = SMLSIZE,
  mid   = MIDSIZE,

  bold  = BOLD,
}

-- Draw text consistently everywhere.
-- align: utils.S.left / utils.S.right / utils.S.base (or nil -> left)
-- size:  utils.S.sml / utils.S.mid (or nil -> none)
-- extra: utils.S.bold or 0
function utils.text(x, y, txt, align, size, extra)
  align = align or utils.S.left
  size  = size  or 0
  extra = extra or 0
  lcd.drawText(x, y, txt, align + size + extra)
end

-- Helper to draw a left/right pair around a center (e.g., Lat/Lon)
-- leftText is RIGHT-aligned at (cx-gap); rightText is LEFT-aligned at (cx+gap)
function utils.textLR(cx, y, leftText, rightText, gap, baseStyle, sizeStyle, extraStyle)
  gap = gap or 10
  baseStyle = baseStyle or utils.S.base
  sizeStyle = sizeStyle or 0
  extraStyle = extraStyle or 0

  lcd.drawText(cx - gap, y, leftText,  baseStyle + RIGHT + sizeStyle + extraStyle)
  lcd.drawText(cx + gap, y, rightText, baseStyle + LEFT  + sizeStyle + extraStyle)
end

-- =========================
-- Time / Battery helpers
-- =========================

function utils.getFormattedTime(datetime, is24Hour)
  local hour = datetime.hour
  local amPm = ""

  if not is24Hour then
    if hour == 0 then
      hour = 12
      amPm = " AM"
    elseif hour == 12 then
      amPm = " PM"
    elseif hour > 12 then
      hour = hour - 12
      amPm = " PM"
    else
      amPm = " AM"
    end
  end

  return string.format("%02d:%02d%s", hour, datetime.min, is24Hour and "" or amPm)
end

-- Transmitter battery info helper
function utils.txBatteryInfo()
  local v = tonumber(getValue("tx-voltage")) or 0
  local state = "low"
  if v >= 7.9 then
    state = "full"
  elseif v >= 7.5 then
    state = "ok"
  elseif v >= 7.1 then
    state = "yellow"
  end
  return v, state
end

-- Estimate voltage per cell and cell count from total RX battery voltage
function utils.getVoltagePerCell(totalVoltage)
  local maxCellVoltage = 4.35
  local minCellVoltage = 3.0

  if (totalVoltage or 0) > 5 then
    local estimatedCellCount = math.floor(totalVoltage / maxCellVoltage) + 1
    local averageVoltagePerCell = totalVoltage / estimatedCellCount

    if averageVoltagePerCell >= minCellVoltage and averageVoltagePerCell <= maxCellVoltage then
      return averageVoltagePerCell, estimatedCellCount
    end
  end
  return totalVoltage or 0, 1
end

-- Map per-cell voltage to battery icon state
function utils.rxCellState(perCellVoltage)
  perCellVoltage = perCellVoltage or 0
  if perCellVoltage < 3.2 then
    return "dead"
  elseif perCellVoltage < 3.6 then
    return "low"
  elseif perCellVoltage < 3.8 then
    return "yellow"
  elseif perCellVoltage < 4.0 then
    return "ok"
  else
    return "full"
  end
end

-- Satellite icon color by count (matches GPSWidget thresholds)
function utils.satIconColor(sats)
  sats = sats or 0
  if sats <= 5 then
    return "red"
  elseif sats <= 7 then
    return "yellow"
  else
    return "green"
  end
end

-- Connection icon state based on TPWR and RQly (matches ClockWidget)
function utils.connectionIconState(tpwr, rqly)
  if (tpwr or 0) <= 0 then
    return "black"
  end
  rqly = rqly or 0
  if rqly < 60 then
    return "red"
  elseif rqly < 80 then
    return "yellow"
  else
    return "green"
  end
end

-- Calculate base Y offset for telemetry rows (baseY = yStart + offset)
function utils.getBaseY(yStart, offset)
  offset = offset or 2
  return (yStart or 0) + offset
end

-- Clamp X to stay left of a reserved right column
function utils.clampToRightCol(x, rightColLeft)
  if rightColLeft and x and x > rightColLeft - 5 then return rightColLeft - 5 end
  return x or 0
end

-- =========================
-- GPS formatting
-- =========================

function utils.toDMS(value)
  value = value or 0
  local degrees = math.floor(value)
  local minutes = math.floor((value - degrees) * 60)
  local seconds = ((value - degrees) * 60 - minutes) * 60
  return degrees, minutes, seconds
end

function utils.formatLatLon(lat, lon)
  lat = lat or 0
  lon = lon or 0
  local latDeg, latMin, latSec = utils.toDMS(math.abs(lat))
  local lonDeg, lonMin, lonSec = utils.toDMS(math.abs(lon))
  local latDir = lat >= 0 and "N" or "S"
  local lonDir = lon >= 0 and "E" or "W"
  return string.format("%d°%d'%d\"%s", latDeg, latMin, latSec, latDir),
         string.format("%d°%d'%d\"%s", lonDeg, lonMin, lonSec, lonDir)
end

-- =========================
-- Misc telemetry formatting
-- =========================

function utils.getFlightModeName(fmode)
  if model and model.getFlightMode then
    local fm = model.getFlightMode(fmode)
    if fm and fm.name and fm.name ~= "" then
      return fm.name
    end
  end
  return tostring(fmode)
end

function utils.getRFMDString(rfmd)
  local rfModes = {"", "25Hz", "50Hz", "100Hz", "100HzF", "150Hz", "200Hz", "250Hz", "333HzF", "500Hz", "D250", "D500", "F500", "F1000"}
  return (rfModes and rfModes[(rfmd or 0) + 1]) or tostring(rfmd or 0)
end

-- =========================
-- Drawing primitives
-- =========================

function utils.drawGridLines(leftMargin, rightMargin, col2X, col3X, col4X, gridY, rowHeight, padding, color)
  local gridHeight = rowHeight * 2
  lcd.drawLine(leftMargin, gridY - padding, rightMargin, gridY - padding, SOLID, color)
  lcd.drawLine(leftMargin, gridY + gridHeight + padding, rightMargin, gridY + gridHeight + padding, SOLID, color)
  lcd.drawLine(leftMargin, gridY - padding, leftMargin, gridY + gridHeight + padding, SOLID, color)
  lcd.drawLine(rightMargin, gridY - padding, rightMargin, gridY + gridHeight + padding, SOLID, color)

  lcd.drawLine(col2X, gridY - padding, col2X, gridY + gridHeight + padding, SOLID, color)
  lcd.drawLine(col3X, gridY - padding, col3X, gridY + gridHeight + padding, SOLID, color)
  lcd.drawLine(col4X, gridY - padding, col4X, gridY + gridHeight + padding, SOLID, color)

  lcd.drawLine(leftMargin, gridY + rowHeight, rightMargin, gridY + rowHeight, SOLID, color)
end

function utils.drawSquare(cx, cy, halfSize, fillColor, borderColor)
  local size = halfSize * 2 + 1
  lcd.drawFilledRectangle(cx - halfSize, cy - halfSize, size, size, fillColor)
  lcd.drawRectangle(cx - halfSize, cy - halfSize, size, size, borderColor)
end

return utils
